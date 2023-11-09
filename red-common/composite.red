Red [
	title:   "#composite macro & mezz"
	purpose: "String interpolation"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		It supports only parens as expression designators.
		To escape opening paren, add a backslash after it: `(\`

		EXAMPLES:

		#composite

			stdout: #composite %"(working-dir)stdout-(index).txt"
			pid: call/shell #composite {console-view.exe (to-local-file name) 1>(to-local-file stdout)}
			log-info #composite {Started worker (name) (\PID:(pid))}		;-- escaped opening brace!
			#composite "Worker build date: (var/date) commit: (var2)^/OS: (system/platform)"
			write/append cfg-file #composite "config: (mold config)"
		
			#macro [#print string!] func [[manual] s e] [insert remove s [print #composite] s]
			#print {invoking: (cmd)^/from: "(to-local-file what-dir)"}
			#print "error reading the config file: (msg)"

		composite

			cmd: composite['root] get bind either afile ['avcmd]['vcmd] :a+v
			prints: func [b [block!] s [string!]] [print composite b s]

		See `composite.md` for more details
	}
]


#include %assert.red
#include %with.red			;-- used by composite func to bind exprs
#include %catchers.red		;-- used by composite func to trap errors


composite: none
context [
	non-paren: charset [not #"("]

	trap-error: function [on-err [function! string!] :code [paren!]] [
		trap/catch
			as [] code
			pick [ [on-err thrown] [on-err] ] function? :on-err
	]

	set 'composite function [
		"Return STR with parenthesized expressions evaluated and formed"
		ctx [block!] "Bind expressions to CTX - in any format accepted by WITH function"
		str [any-string!] "String to interpolate"
		/trap "Trap evaluation errors and insert text instead"	;-- not load errors!
			on-err [function! string!] "string or function [error [error!]]"
	][
		s: as string! str
		b: with ctx parse s [collect [
			keep ("")									;-- ensures the output of rejoin is string, not block
			any [
				keep copy some non-paren				;-- text part
			|	keep [#"(" ahead #"\"] skip				;-- escaped opening paren
			|	s: (set [v: e:] transcode/next s) :e	;-- paren expression
				keep (:v)
			]
		]]

		if trap [										;-- each result has to be evaluated separately
			forall b [
				if paren? b/1 [b: insert b [trap-error :on-err]]
			]
			;@@ use map-each when it becomes native
			; b: map-each/eval [p [paren!]] b [['trap-error quote :on-err p]]
		]
		as str rejoin b
		; as str rejoin expand-directives b		-- expansion disabled by design for performance reasons
	]
]


;; has to be both Red & R2-compatible
;; any-string! for composing files, urls, tags
;; load errors are reported at expand time by design
#macro [#composite any-string! | '` any-string! '`] func [[manual] ss ee /local r e s type load-expr wrap keep] [
	set/any 'error try [								;-- display errors rather than cryptic "error in macro!"
		s: ss/2
		r: copy []
		type: type? s
		s: to string! s									;-- use "string": load %file/url:// does something else entirely, <tags> get appended with <>

		;; loads "(expression)..and leaves the rest untouched"
		load-expr: has [rest val] [						;-- s should be at "("
			rest: s
			either rebol
				[ set [val rest] load/next rest ]
				[ val: load/next rest 'rest ]
			e: rest										;-- update the end-position
			val
		]

		;; removes unnecesary parens in obvious cases (to win some runtime performance)
		;; 2 or more tokens should remain parenthesized, so that only the last value is rejoin-ed
		;; forbidden _loadable_ types should also remain parenthesized:
		;;   - word/path (can be a function)
		;;   - set-word/set-path (would eat strings otherwise)
		;@@ TODO: to be extended once we're able to load functions/natives/actions/ops/unsets
		wrap: func [blk] [					
			all [								
				1 = length? blk
				not find [word! path! set-word! set-path!] type?/word first blk
				return first blk
			]
			to paren! blk
		]

		;; filter out empty strings for less runtime load (except for the 1st string - it determines result type)
		keep: func [x][
			if any [
				empty? r
				not any-string? x
				not empty? x
			][
				if empty? r [x: to type x]				;-- make rejoin's result of the same type as the template
				append/only r x
			]
		]

		marker: to char! 40								;@@ = #"(": workaround for #4534
		do compose [
			(pick [parse/all parse] object? rebol) s [
				any [
					s: to marker e: (keep copy/part s e)
					[
						"(\" (append last r marker)
					|	s: (keep wrap load-expr) :e
					]
				]
				s: to end (keep copy s)
			]
		]
		;; change/part is different between red & R2, so: remove+insert
		remove/part ss ee
		insert ss reduce ['rejoin r]
		return next ss									;-- expand block further but not rejoin
	]
	print ["***** ERROR in #COMPOSITE *****^/" :error]
	ee													;-- don't expand failed macro anymore - or will deadlock
]







;-- -- -- -- -- -- -- -- -- -- -- -- -- -- TESTS -- -- -- -- -- -- -- -- -- -- -- -- -- --

#assert [
	[#composite %"()() - (1 + 2) - (<abc)))>) - (func)(1)()()"] == [
		rejoin [
			%""				;-- first string determines result type - should not be omitted
			() ()			;-- () makes an unset, no empty strings inbetween
			" - "			;-- subsequent string fragments of string type
			(1 + 2)			;-- 2+ tokens are parenthesized
			" - "
			<abc)))>		;-- an explicit tag! - not a string!; without parens around
			" - "
			(func)			;-- words are parenthesized
			1				;-- single token without parens
			() ()			;-- no unnecessary empty strings
		]
	]
]

#assert [
	[#composite <tag flag=(mold 1 + 2)/>] == [
		rejoin [
			<tag flag=>		;-- result is a <tag>
			(mold 1 + 2)
			{/}				;-- other strings should be normal strings, or we'll have <<">> result
		]
	]
]

#assert [ 
	[#composite <tag flag=(mold 1 + 2)/>] == [` <tag flag=(mold 1 + 2)/> `]		;@@ `<a b>` is buggy when compiled
	[#composite %"()() - (1 + 2) - (<abc)))>) - (func)(1)()()"] == [` %"()() - (1 + 2) - (<abc)))>) - (func)(1)()()" `]
]


; #assert [			;-- this is unloadable because of tag limitations
; 	[#composite <tag flag="(form 1 + 2)">] == [
; 		rejoin [
; 			<tag flag=">	;-- result is a <tag>
; 			(form 3)
; 			{"}				;-- other strings should be normal strings, or we'll have <<">> result
; 		]
; 	]
; ]


#assert [
	%" - 3 - <abc)))> - func1" == composite[] %"()() - (1 + 2) - (<abc)))>) - ('func)(1)()()"
	<tag flag=3/>              == composite[] <tag flag=(mold 1 + 2)/>
	"((\\))"                   == composite[] "(\(\\\))"
	""                         == composite[] "()"
	""                         == composite[] "([])"
	"*ERROR*"                  == composite/trap[] "(1 / 0)" "*ERROR*"
	"zero-divide expect-arg"   == composite/trap[] "(1 / 0) ({a} + 1)" func [e][e/id]
	"print"                    == composite/trap[] "(1 / 0)" func [e]['print]		;-- no second error from double evaluation
	; "123"                      == composite[] "(append {1} #composite {2(1 + 2)})"	;-- macro expansion within composite exprs -- disabled for performance reasons

	"((\\))" == #composite "(\(\\\))"
	""       == #composite "()"
	""       == #composite "([])"					;-- result is string not block

	"((\\))" == `"(\(\\\))"`
	""       == `"()"`
	""       == `"([])"`

	[#composite "(\(\\\))"] == [rejoin ["((" "\\))"]]			;-- escaping
	[#composite "()"      ] == [rejoin ["" ()]      ]
	[#composite "([])"    ] == [rejoin ["" []]      ]			;-- paren removal from obvious cases
	[#composite "(1)"     ] == [rejoin ["" 1]       ]

	"123" == #composite "(append {1} #composite {2(1 + 2)})"	;-- macro expansion within composite exprs
	
	[ #composite "(append {1} #composite {2(1 + 2)})" ]
	== [ rejoin ["" (append "1" rejoin ["2" (1 + 2)])] ]

	;@@ this is bugged, fixed in #rejoin PR
	; [ #composite "(1 + 2)(\text)" ] = [ "" (1 + 2) "(" "text)" ]

	;-- line comments handling
	"9" == #composite  {(;-- comment
		1 + 2 * 3					;-- another
	)}
	"9" ==            `{(;-- comment
		1 + 2 * 3					;-- another
	)}`
	"9" == composite[] {(;-- comment
		1 + 2 * 3					;-- another
	)}
]


