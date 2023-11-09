Red [
	title:   "PARSE-DUMP dumper and PARSEE tool wrapper"
	purpose: "Visualize parsing progress using PARSEE command-line tool"
	author:  @hiiamboris
	license: 'BSD-3
	usage: {
		See https://codeberg.org/hiiamboris/red-spaces/src/branch/master/programs/README.md#parsee-parsing-flow-visual-analysis-tool-parsee-tool-red
	}
]

#include %setters.red									;-- `anonymize`
#include %advanced-function.red							;-- `function` (defaults)
#include %composite.red									;-- interpolation in print/call
#include %catchers.red									;-- `following`
#include %timestamp.red									;-- for dump file name
#include %reactor92.red									;-- for changes tracking

parsee: inspect-dump: parse-dump: none
context expand-directives [
	skip?: func [s [series!]] [-1 + index? s]
	clone: function [									;@@ export it?
		"Obtain a complete deep copy of the data"
		data [any-object! map! series!]
	] with system/codecs/redbin [
		decode encode data none
	]

	keywords: make hash! [								;@@ duplicate! also in parsee.red
		| skip quote none end
		opt not ahead
		to thru any some while
		if into fail break reject
		set copy keep collect case						;-- collect set/into/after? keep pick?
		remove insert change							;-- insert/change only?
		#[true]
	]

	;@@ workaround for #5406 - unable to save global words and words within functions
	;@@ unfortunately this has to modify parse rules in place right in the function
	;@@ so next `parse` run may not work at all... how to work around this workaround? :/
	unloadable?:  func [w [any-word!]] [any [function? w: context? w  w =? system/words]]
	fallback:     func [x [any-type!] y [any-type!]] [any [:y :x]]
	isolate-rule: function [
		"Split parse rule from local function context for Redbin compatibility"
		block [block!]
		/local w v
	][
		unique-rules: make hash! 32						;-- avoid recursing and repeating same rules processing
		;@@ this same code may also collect rule names (dedup)
		parse block rule: [
			end
		|	p: if (find/only/same unique-rules head p) to end
		|	p: (append/only unique-rules head p)
			any [
				change [set w any-word! if (unloadable? w)] (
					fallback							;-- 'w' will be overridden by recursive parse
						w
						attempt [						;-- defend from get/any errors
							set/any 'v get/any w
							anonymize w either block? :v [also v parse v rule][:v]
						]
				)
			; |	ahead any-block! into rule				;@@ doesn't work
			|	ahead block! into rule
			|	skip
			]
		]
		block
	]

	make-dump-name: function [] [
		if exists? filename: rejoin [%"" timestamp %.pdump] [
			append filename enbase/base to #{} random 7FFFFFFFh 16	;-- ensure uniqueness
		]
		filename
	]
	
	set 'parsee function [
		"Process a series using dialected grammar rules, visualizing progress afterwards"
		; input [binary! any-block! any-string!] 
		input [any-string!]								;@@ other types TBD
		rules [block!] 
		/case "Uses case-sensitive comparison" 
		/part "Limit to a length or position" 
			length [number! series!]
		/timeout "Force failure after certain parsing time is exceeded"
			maxtime [time! integer! float!] "Time or number of seconds (defaults to 1 second)"
		/keep "Do not remove the temporary dump file"
		/auto "Only visualize failed parse runs"
		; return: [logic! block!]
	][
		path: to-red-file to-file any [get-env 'TEMP get-env 'TMP %.]
		file: make-dump-name
		parse-result: apply 'parse-dump [
			input rules
			/case    case
			/part    part    length
			/timeout timeout maxtime
			/into    on      path/:file 
		]
		unless all [auto parse-result] [inspect-dump path/:file]
		unless keep [delete path/:file]
		parse-result
	]
	
	config: none
	default-config: #(tool: "parsee")
	
	set 'inspect-dump function [
		"Inspect a parse dump file with PARSEE tool"
		filename [file!] 
	][
		filename: to-local-file filename
		self/config: any [
			config
			attempt [make map! load/all %parsee.cfg]
			default-config
		]
		call-result: call/shell/wait/output command: `{(config/tool) "(filename)"}` output: make {} 64
		; #debug [print `"Tool call output:^/(output)"`]
		if call-result <> 0 [
			print `"Call to '(command)' failed with code (call-result)."`
			if object? :system/view [
				if tool: request-file/title "Locate PARSEE tool..." [
					config/tool: `{"(to-local-file tool)"}`
					call-result: call/shell/wait command: `{(config/tool) "(filename)"}`
					either call-result = 0 [
						save %parsee.cfg mold/only to [] config
					][
						print `"Call to '(command)' failed with code (call-result)."`
					]
				]
			]
			if call-result <> 0 [
				print `"Ensure 'parsee' command is available on PATH, or manually open the saved dump with it."`
				print `"Parsing dump was saved as '(filename)'.^/"`
			]
		]
		exit
	]
	
	set 'parse-dump function [
		"Process a series using dialected grammar rules, dumping the progress into a file"
		input [binary! any-block! any-string!] 
		rules [block!] 
		/case "Uses case-sensitive comparison" 
		/part "Limit to a length or position" 
			length [number! series!]
		;@@ maybe timeout PER char, per 1k chars? or measure and compare end proximity?
		;@@ also 1 second dump generates whole hell of data, with 5-10 secs processing it
		/timeout "Specify deadlock detection timeout"
			maxtime: 0:0:1 [time! integer! float!] "Time or number of seconds (defaults to 1 second)"
		/into filename: (make-dump-name) [file!] "Override automatic filename generation"
		; return: [logic! block!]
	][
		;@@ cloning will pose quite a problem in block parsing! #5406
		cloned:  clone input
		changes: make [] 64
		events:  make [] 512
		limit:   now/utc/precise + to time! maxtime
		age:     0										;-- required to sync changes to events
		reactor: make deep-reactor-92! [
			tracked: input
			on-deep-change-92*: :logger
		]
		following [parse/:case/:part/trace input rules length :tracer] [
			data: reduce [
				cloned
				new-line/all/skip events on 5
				changes
			]
			save/as filename isolate-rule data 'redbin
		]
	]
	
	tracer: function [event [word!] match? [logic!] rule [block!] input [series!] stack [block!] /extern age] with :parse-dump [
		reduce/into [age: age + 1 input event match? rule] tail events
		not all [age % 20 = 0  now/utc/precise > limit]			;-- % to reduce load from querying time
	]
	
	;@@ into rule may swap the series - won't be logged, how to deal? save all visited series? redbin will, but not cloned before modification
	logger: function [
		word        [word!]    "name of the field value of which is being changed"
		target      [series!]  "series at removal or insertion point"
		part        [integer!] "length of removal or insertion"
		insert?     [logic!]   "true = just inserted, false = about to remove"
		reordering? [logic!]   "removed items won't leave the series, inserted items came from the same series"
	] with :parse-dump [
		if zero? part [exit]
		#assert [same? word in reactor 'tracked]				;-- only able to track the input series, nothing deeper
		#assert [same? head target head reactor/tracked]
		action: pick [insert remove] insert?
		repend changes [
			age
			pick [insert remove] insert?
			skip? target
			copy/part target part
		]
	]
]

