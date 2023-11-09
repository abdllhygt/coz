Red [
	title:   "BMATCH mezzanine"
	purpose: "Detect possibly mismatched brackets positions from indentation"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		Ever had an error about unclosed bracket in a 1000+ line file?
		This script turns the challenge of finding it into a triviality.

		This is a mezz version, for use with the Smarter Load experiment.
	}
]


#include %tabs.red
#include %composite.red

; #include https://gitlab.com/hiiamboris/red-mezz-warehouse/-/raw/master/tabs.red
; #include https://gitlab.com/hiiamboris/red-mezz-warehouse/-/raw/master/composite.red

bmatch: function [
	"Detect unmatched brackets based on indentation"
	source [string! binary!]
	/origin    script [file! url! string!] "Filename where the data comes from"
	/tabsize   tab [integer!] "Override tab size (default: 4)"
	/tolerance tol [integer!] "Min. indentation mismatch to report (default: 0)"
	/into      tgt [string!]  "Buffer to output messages into (otherwise prints)"
	/throw "Throw the lexer error if any (otherwise ignores)"
][
	tol: max 0 any [tol 0]
	tab: max 0 any [tab 4]
	script: any [script "(unknown)"]
	report: either into [ func [s][repend tgt [s #"^/"]] ][ :print ]

	source: detab/size/into source tab clear #{}		;-- using binary because transcode works with binary internally
	remove-each c source [c = #"^M"]					;@@ otherwise each CR counts as a line!!
	indents: clear []
	parse source [collect into indents any [			;-- list possible indentations for all lines
		s1: any #" " s2: opt [some #"|" any #" "] s3:	;-- special case for parse's `   | [` pattern - accept both indents
		keep (as-pair offset? s1 s2  offset? s1 s3)
		thru [#"^/" | end]
	]]
	types: reduce [block! paren! string! map!]
	opened: clear []
	finish: [
		foreach [line type] opened [
			report #composite "(script): No ending (type) marker after opening at line (line)"
		]
	]
	transcode/into/trace source clear [] function [event input type line token] [
		[open close error]
		unless find types type [return true]
		switch event [
			open [reduce/into [line type] tail opened]
			close [
				take/last opened
				line1: take/last opened
				either line1 [
					i1: indents/:line1  i2: indents/:line
					dist: max i1/1 - i2  i1/2 - i2		;-- find the closest indentation variant
					if tol < max dist/1 dist/2 [
						report #composite "(script): Unbalanced (type) markers between lines (line1) and (line)"
					]
				][
					report #composite "(script): Unexpected closing (type) marker at line (line)"
				]
			]
			error [
				unless throw [
					input: next input					;-- advance input or it deadlocks
					return false
				]
				do finish
			]
		]
		true
	]
	do finish
	tgt
]

