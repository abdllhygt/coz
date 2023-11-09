Red [
	title:   "SIFT & LOCATE mezzanines"
	purpose: "High-level series items locator & filter"
	author:  @hiiamboris
	license: BSD-3
	notes: {
		See sift-locate.md for usage details
		
		Design notes:
		
		Loop would be faster if I could expand it into `any [all [...]]` construct.
		But expansion requires expansion of standalone blocks, and replacement of standalone type(set) names.
			e.g. `find [1 | 3 | 5]` should not become expanded into any/all
			or `parse x ['a | 'b | 'c]`...
			and `number!` should become `find number! type? :subject`
			but `find number! :x` should not
		To know what token stands alone that requires preprocessor.
		But preprocessor is a source of very unexpected bugs.
		E.g. if pattern uses path `x/p/q` where `x` at runtime will be an object,
		but globally `x` will be `func [/p a /q b]`, it will mess the arity!
		or preprocessor may fail saying that `x` has no /p or /q refinements!
		Moreover, `x` may be of different type on every iteration and `x/p/q` have different arity!
		
		Current implementation does not use the preprocessor, so it should be correct.
		Price is it has to make do with slower loop performance.
		But since both sift & locate are based on mezz apply and new-each, they're slow anyway!
		
		Path existence (to silence errors coming from invalid path items) is checked with `try`.
		But I have to still raise errors if path is not part of the rule (e.g. comes from a called function).
		So path in the returned error is looked up in the rule to be sure. Error rethrown if path not found.
	}
]

#include %include-once.red
#include %hide-macro.red
#include %assert.red

#include %setters.red									;-- we need `anonymize`
#include %new-each.red									;-- based on extended foreach/map-each capabilities
; #include %new-apply.red									;-- need `apply` to dispatch refinements


sift: locate: none
context [
	ref-or-block!: make typeset! [refinement! block!]
	expand-paths: function [
		tests   [block!] "Modified in place!"
		subject [word! none!]
		/local ref
	][
		repl: pick [
			(as path! compose [(subject) (to word! ref)])
			(ERROR "Cannot use refinements without column selected at (mold/only/part p 40)")
		] word? subject
		parse tests rule: compose/deep [any [
			p: change only set ref refinement! (repl)
		|	ahead block! into rule
		|	to [ref-or-block! | end]
		]]
		tests
	]
	
	#assert [
		[.. subj/x = 1 subj/y [subj/z <> 2]] = expand-paths [.. /x = 1 /y [/z <> 2]] 'subj
	]
	
	run-tests: function [
		tests   [block!] "Paths should be expanded already"
		subject [block!] "Code to get subject or to throw the error" 
	][
		trap/catch [									;@@ without /all may crash - #5239
			while [not any [tail? tests :tests/1 == '|]] [	;-- succeed by reaching tail or pipe
				set/any 'result do/next pos: tests 'tests
				if pos =? back tests [					;-- standalone token
					switch type?/word :result [
						block!    [if block? :pos/1 [result: run-tests pos/1 subject]]		;-- new ruleset
						datatype! [if word?  :pos/1 [result: result = type? do subject]]
						typeset!  [if word?  :pos/1 [result: find result type? do subject]]
					]
				]
				any [
					:result								;-- succeed, test forward
					tests: find/case/tail tests '|		;-- fail, find next alternative
					return no							;-- fail the whole
				]
			]
			yes
		][
			unless all [
				error? e: thrown
				e/type = 'script
				find [unset-path invalid-path bad-path-type bad-path-type2] e/id
				find/only/same pos e/arg1				;-- path comes from the tests, not from deeper code
			][
				do e
			]
			no
		]
	]
	

	anonymous-hyphen: anonymize '- none					;-- a safe-to-assign hyphen for use in spec
	
	prepare: function [series pattern] [
		;; split pattern into spec and tests
		parse/case pattern [
			;; spec may extend up to the tail, useful e.g. for sifting of some columns unconditionally
			copy spec to [quote .. | end] opt skip tests:
		]
		tests: copy/deep tests							;-- will be deeply modified
		;; anonymize hyphens and collect word/paren slots (to figure out if default subject is possible to assign)
		subject: parse/case spec [collect any [
			change quote - (anonymous-hyphen)
		|	ahead word! '| to end						;-- no subject after pipe delimiter
		|	block!
		|	keep skip
		]]
		;; subject can only be an explicit word
		;; default subject only possible if spec is empty (no hyphens, no parens)
		words: either set-word? :spec/1 [next spec][spec]	;-- [p:] is considered an empty spec - needs a subject
		system/words/case [
			tail? words [insert words subject: anonymize 'subject none]
			all [single? subject] [subject: subject/1]
			'else [subject: none]
		]
		
		expand-paths tests subject
		subject: either subject [
			reduce [to get-word! subject]
		][
			[ERROR "Cannot use type checks without column selected"]	;-- no space in the message for location :(
		]
		
		reduce [spec tests subject]
	]
	
	set 'locate function [
		"Locate a row within SERIES that matches PATTERN"
		series  [series!] "Will be returned at found row index"
		pattern [block!]  "[row spec .. chain of tests]"
		/back "Locate last occurrence (starts from the tail)"
		/case "Values are matched using strict comparison"
		/same "Values are matched using sameness comparison"
		/local spec tests pos result
	][
		set [spec: tests: subject:] prepare series pattern
		unless set-word? spec/1 [						;-- we need position to track & return
			insert spec to set-word! 'pos
		]
		__iter: func [tests subject 'pos] [				;@@ temporary kludge - there's risk of spec overriding used words
			if run-tests tests subject [
				set/any 'result get/any pos
				break
			]
		]
		code: compose/only [__iter (tests) (subject) (spec/1)]
		apply 'for-each [(spec) series code /case case /same same /reverse back]
		result
	]

	;-- cannot be based on remove-each because it also selects columns not marked by '-'
	set 'sift function [
		"Select only rows of SERIES that match PATTERN, and only named columns"
		series  [series! map! integer! pair!]					;-- all types supported by map-each
		pattern [block!]  "[row spec .. chain of tests]"
		/case "Values are matched using strict comparison"
		/same "Values are matched using sameness comparison"
	][
		set [spec: tests: subject:] prepare series pattern
		columns: parse spec [collect any [				;-- selected columns to keep in the result
			'- | '| | set w word! keep (to get-word! w)
		|	skip
		]]
		buf: copy columns
		__iter: func [tests subject columns] [			;@@ temporary kludge - there's risk of spec overriding used words
			reduce/into columns clear buf				;-- tests may change word values, so we have to reduce them before that
			; either run-tests tests subject [buf][continue]	;@@ no longer works when tests evaluate to unset!
			any [all [run-tests tests subject  buf] continue]
		]
		unless scalar? series [series: copy series]		;-- don't modify the original
		code: compose/only [__iter (tests) (subject) (columns)]
		map-each/self/drop/:case/:same (spec) series code	;-- /self/drop to preserve input type, omit rows not passing the tests
	]
	
]


#hide [#assert [
	;-- basic tests
	[a b c      ] = sift [a 1 b 2 c] [.. word!]                           
	[1 2        ] = sift [a 1 b 2 c] [.. integer!]                        
	[1 2 3      ] = sift [1 2 3 4 5] [x .. x <= 3]                        
	[3 4 5      ] = sift [1 2 3 4 5] [x .. x >= 3]                        
	[3 4        ] = sift [1 2 3 4 5] [x .. x >= 3 x <= 4]                 
	[1 4 5      ] = sift [1 2 3 4 5] [x .. x >= 4 | x <= 1]               
	[2 3 5      ] = sift [1 2 3 4 5] [x .. x >= 2 [x = 5 | x <= 3]]       
	[2 3 5      ] = sift [1 2 3 4 5] [x .. (x >= 2) [(x = 5) | (x <= 3)]] 
	[1 3 5      ] = sift [1 2 3 4 5] [x .. find [1 | 3 | 5] x]            	;-- block should be untouched

	[1 3 5      ] = sift [1 2 3 4 5] [x -]                                	;-- has to remove 2nd column
	[1 3 5      ] = sift [1 2 3 4 5] [x - ..]                             
	[2 4 #[none]] = sift [1 2 3 4 5] [- x]                                	;-- has to remove 1st column
	[2 4        ] = sift [1 2 3 4 5] [- x |]                              
	[2 3 4 5    ] = sift [1 2 3 4 5] [- | x]                              
	[3 5        ] = sift [1 2 3 4 5] [- | x .. odd? x]                    

	[1 2 3 4 5  ] = sift [1 2 3 4 5] []                                   	;-- empty tests are truthy
	[1 2 3 4 5  ] = sift [1 2 3 4 5] [..]                                 
	[1 2 3 4 5  ] = sift [1 2 3 4 5] [.. | ]                              
	[1 2 3 4 5  ] = sift [1 2 3 4 5] [.. none | ]                         
	[           ] = sift [1 2 3 4 5] [.. none]                            
	[           ] = sift [1 2 3 4 5] [.. (none)]                          

	;-- tests inspired from the HOF selection
	o1: object [p: object [q: 1]]
	o2: object [p: object [r: 2]]
	o3: object [p: object [r: 3]]
	(reduce [o1]) = sift reduce [o1 o2 o3] [x .. x/p/q        ] 	;-- should not error out on non-existing paths
	(reduce [o1 o2 o3]) = sift reduce [o1 o2 o3] [x .. :x/p/q ] 	;-- get-paths too!
	(reduce [o1 o2 o3]) = sift reduce [o1 o2 o3] [x .. :x/p/q ] 	;-- x/p/q returns unset, which is truthy - all items pass
	(reduce [o1]) = sift reduce [o1 o2 o3]       [x .. x/p/q > 0    ] 
	(reduce [o2]) = sift reduce [o1 o2 o3]       [x .. /p x = o2    ]	;-- 'x' as subject 
	(reduce [o2]) = sift reduce [o1 1 o2 2 o3 3] [x - .. /p x = o2  ]	;-- even in presence of an anonymous column
	(reduce [o3]) = sift reduce [o1 o2 o3]       [x .. y: /p y/r > 2] 
	(reduce [o3]) = sift reduce [o1 o2 o3]       [x .. x: /p x/r > 2] 	;-- x: override should not affect the result
	error?     try [sift reduce [o1 o2 o3]       [x .. (x/p/q)     ]] 	;-- should error out since path is escaped
	(reduce [o3]) = sift reduce ['a 'b o3]       [.. object!        ] 
	(reduce [o3]) = sift reduce ['a o2 o3]       [.. object!  [r: 3] = to [] /p] 
	unset [o1 o2 o3]

	"^/^/^/" = sift "ab^/cd^/ef^/gh" [x .. x = lf]					;-- should preserve input type
	#(1 2)   = sift #(a 1 b 2)       [- x]        
	(s: sift s0: "ab^/cd^/ef^/gh" [x .. x = lf]  not s =? s0)		;-- should not modify original series
	(m: sift m0: #(a 1 b 2) [- x] m <> m0)

	[1x1 2x2 3x3] = sift [1x1 a 2x2 b 3x3 c] [.. pair!           ] 	;-- type filter
	[1x1 2x2 3x3] = sift [1x1 a 2x2 b 3x3 c] [x .. pair? x       ] 	;-- normal Red code as filter
	[1x1 2x2 3x3] = sift [1x1 a 2x2 b 3x3 c] [p: .. odd? index? p] 	;-- uses position
	[1x1 2x2 3x3] = sift [1x1 a 2x2 b 3x3 c] [.. /x              ] 	;-- path existence test as filter
	[1x1 2x2 3x3] = sift [1x1 a 2x2 b 3x3 c] [p .. p/x           ] 	;-- same, more explicit

	(reduce [face!]) = sift reduce [face! reactor! deep-reactor! scroller!] [.. /type = 'face] 

	[5 7 9] = (i: 1 sift [1 3 5 7 9] [x .. (i: i + 1) x > i     ]) 	;-- usage of side effects
	[5 7 9] = (i: 2 sift [1 3 5 7 9] [x .. x > i | (i: i + 1) no]) 

	;-- LOCATE basic tests
	[a 1 b 2 c  ] = locate      [a 1 b 2 c] [.. word!   ] 
	[  1 b 2 c  ] = locate      [a 1 b 2 c] [.. integer!] 
	[c          ] = locate/back [a 1 b 2 c] [.. word!   ] 
	[2 c        ] = locate/back [a 1 b 2 c] [.. integer!] 
	none?           locate/back [a 1 b 2 c] [.. none!   ] 
	none?           locate/back [         ] [.. integer!] 
	[1 2 3 4 5  ] = locate      [1 2 3 4 5] [x .. x <= 3]                        
	[    3 4 5  ] = locate      [1 2 3 4 5] [x .. x >= 3]                        
	[  2 3 4 5  ] = locate      [1 2 3 4 5] [x .. x >= 2 [x = 5 | x <= 3]]       
	[  2 3 4 5  ] = locate      [1 2 3 4 5] [x .. (x >= 2) [(x = 5) | (x <= 3)]] 
	[        5  ] = locate/back [1 2 3 4 5] [x .. (x >= 2) [(x = 5) | (x <= 3)]] 
	[    3 4 5  ] = locate      [1 2 3 4 5] [x .. find [3 | 5] x]                	;-- block should be untouched

	[1 2 3 4 5  ] = locate [1 2 3 4 5] [x -]             
	[1 2 3 4 5  ] = locate [1 2 3 4 5] [- x]             
	[    3 4 5  ] = locate [1 2 3 4 5] [- x .. x >= 3]   
	[        5  ] = locate [1 2 3 4 5] [x - .. x >= 5]   
	none?           locate [1 2 3 4 5] [x - | .. x >= 5] 	;-- last value is filtered out by `|`

	[1 2 3 4 5  ] = locate [1 2 3 4 5] []           	;-- empty tests are truthy
	[1 2 3 4 5  ] = locate [1 2 3 4 5] [..]         
	[1 2 3 4 5  ] = locate [1 2 3 4 5] [.. | ]      
	[1 2 3 4 5  ] = locate [1 2 3 4 5] [.. none | ] 
	none?           locate [1 2 3 4 5] [.. none]    
	none?           locate [1 2 3 4 5] [.. (none)]  

	;-- tests inspired from the HOF selection
	(
		mon: "sep"
		months: ["december" "november" "september"]
		["september"] = locate months [m .. find/match m mon]
	)
	(
		pts: [0x0 10x0 0x10 10x10 3x3 8x8]
		[3x3 8x8] = locate pts [p .. within? p - 5x5 -2x-2 3x3]
	)
	faces: reduce [
		make face! [size: 2x0]
		make face! [size: 0x0]
		make face! [size: 0x2]
	]
	single? locate/back faces [f .. [f/size/x * f/size/y = 0]] 
	single? locate/back faces [.. s: /size [s/x * s/y = 0]   ] 
	single? locate/back faces [.. s: /size [s/x * s/y = 0]   ] 
	single? locate      faces [.. /size = 0x2                ] 
	
	3 = index? locate [1 [a] 2 [b] 3 [c]] [- b .. b = [b]]
 
]]
; #include %prettify.red
; print "------ WORK HERE ------"
