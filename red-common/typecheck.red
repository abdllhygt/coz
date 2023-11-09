Red [
	title:   "TYPECHECK function"
	purpose: "Mini-DSL for type checking and constraint validity insurance"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		TIP: wrap it into #debug [] macro so it doesn't affect release code performance
		
		DSL summary:
		
			typecheck [
				word1 [type! (condition to test if of this type) ...]
				word2 [type1! (...) type2! ...]			;) multiple types and conditions are possible
				word3 [typeset!] 						;) conditions are optional and typesets are supported
				word4 [type1! type2!] (global test)		;) outside condition is tested regardless of the type
				...
			]
	}
]

#include %assert.red
#include %setters.red									;-- uses 'anonymize'
#include %catchers.red
#include %hide-macro.red


typecheck: none
typechecking: context [
	;; another approach is to put 'do' directly into on-change-dispatch (and bind to it)
	;; but then even unchecked words will pay the price of a function call
	;; and unfortunately, both these approaches are unfit for advanced-function
	;; as it will either become a mold hell, or not copyable (due to use of a bound decorated word for matrix)
	make-check-func: function [field [get-word!] types [block! none!] fallback [paren! none!]] [
		set [types: options:] if types [extract-value-checks types]
		matrix: make-type-matrix field types fallback options
		check: function compose [(to word! field) [any-type!]] compose [
			;; trick here is to use paths (faster), and that needs a word (can't start it with a map)
			;; besides, map is quite big, in case function gets molded (on error?) it's no good
			do (as path! reduce [
				anonymize 'matrix matrix
				as paren! compose [type?/word (field)]
			])
		]
		foreach [key blk] matrix [if block? blk [bind blk :check]]
		:check
	]
	
	;; must return 'none' when check succeeded!
	skeleton: copy []									;@@ use map-each (not using to avoid dependency)
	#hide [
		foreach type to [] any-type! [repend skeleton [type none]]
	]
	skeleton: make map! skeleton
	
	make-type-matrix: function [word [get-word!] types [block! none!] fallback-check [paren! none!] options [block! none!]] [
		matrix:   copy skeleton
		accepted: either types [make typeset! types][any-type!]
		if types [type-error: make-type-error word types]
		foreach [type _] matrix [
			matrix/:type: case [
				not find accepted get type [type-error]
				check: any [
					if pos: find find options type paren! [pos/1]
					fallback-check
				][
					make-value-check word check
				]
			]											;@@ or use remove/key instead of 'none'?
		] 
		matrix
	]
	
	make-value-check: function [field [get-word!] check [paren!]] [
		compose/deep [
			unless (check) [
				form reduce ["Failed" (mold check) "for" type? (field) "value:" mold/flat/part (field) 40]
			]
		]
	]
	
	make-type-error: function [field [get-word!] types [block!]] [
		compose/deep [									;@@ use reshape for this when it's fast
			rejoin [(compose pick [						;-- new-lines matter here
				["Word " (form field) " is locked and cannot be set to " mold/flat/part (field) 40]
				["Word " (form field) " can't accept " type? (field) " value: " mold/flat/part (field) 40 ", only " (mold types)]
			] empty? types)]
		]
	]

	extract-value-checks: function [types [block!] /local check words] [
		typeset: clear []
		options: clear []
		parse types [any [
			copy words some word! (append typeset words)
			opt [
				set check paren! #debug [(
					mask: to block! make typeset! words	;-- break typesets into type names
					append/only append options mask check
				)]
			]
		]]
		reduce [typeset options]						;-- no copy needed, temporary blocks
	]

	
	;; each check block is compiled once, saved here, then reused
    memoized-typechecks: make hash! 64
    
    compile-spec: function [spec [block!]] [
		checks: clear []
		parse spec [any [
			set field word! set types opt block! set fallback opt paren! (
				field: to get-word! field
				repend checks [make-check-func field types fallback  field]
			)
		]]
		copy checks
	]
		
	set 'typecheck function [
		"Check types of all given words"
		spec [block!] "A sequence of: word [type! (type-test) ...] (global-test)"
	][
		unless checks: select/only/same memoized-typechecks spec [
			repend memoized-typechecks [spec checks: compile-spec spec] 
		]
		trap/catch [do checks  yes] [print thrown  no]
	]
]


#hide [#assert [
	(x: 1 y: 'y)
	typecheck [x [integer!] y [word!]]
	typecheck [x [none! integer!] y [any-word!]]
	typecheck [x [number! (x > 0)] y [any-word! (find [y] y)]]
]]
