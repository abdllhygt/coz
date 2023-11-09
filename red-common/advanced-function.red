Red [
	title:       "Advanced function constructor"
	description: "Adds support for value checks and defaults into FUNCTION's spec argument"
	author:      @hiiamboris
	license:     'BSD-3
	usage: {
		Function argument specification is extended with the following:
		- per-type value checks (as parenthesis following the type or typeset name(s))
		- fallback value checks (as parenthesis following the type block if any, or the argument name)
		- default values (as value after the argument name written as a set-word)
		
		Notes:
		- !! Checks are only active in debug mode! (needs %debug.red) !!
		  So `#debug off` removes all the overhead, but still keeps the default.
		- No checks are applied to the default value (for performance reasons).
		  It's up to the user to ensure that the default is within acceptable range.
		- Per-type check applies to all previously listed types(ets) up to the previous per-type check,
		  i.e. x [integer! float! (x >= 0) none!] applies check to both integer and float. 
		- Fallback checks apply only to types not covered by per-type checks.
		
		Example:
			>> probe f: function [/ref x: 1  [integer! (x >= 0) string!]  (find x "0")] [x]
			;;                            ^default     ^check for integer  ^fallback check (applies for string)
			func [/ref x [integer! string!]][
			    switch/default type? :x [
			        none! [x: 1] 						;) applies default when X is not given
			        integer! [							;) integer value check
			            unless (x >= 0) [
			                do make error! form reduce [
			                    "Failed" "(x >= 0)" "for" type? :x "value:" mold/flat/part :x 40
			                ]
			            ]
			        ]
			    ] [
			        unless (find x "0") [				;) fallback value check
			            do make error! form reduce [
			                "Failed" {(find x "0")} "for" type? :x "value:" mold/flat/part :x 40
			            ]
			        ]
			    ] 
			    x										;) actual body starts...
			]
			
			>> f
			== 1										;) default applied
			
			>> f/ref 0
			== 0										;) accepted 0 argument
			
			>> f/ref -1
			*** User Error: "Failed (x >= 0) for integer value: -1"
			*** Where: do
			*** Near : 40
			*** Stack: f  
			
			>> f/ref "102"								;) accepted string with "0"
			== "102"
			
			>> f/ref "12"
			*** User Error: {Failed (find x "0") for string value: "12"}
			*** Where: do
			*** Near : 40
			*** Stack: f  
			
		Code injected into the function body is optimized for performance, so it's not worse than hand-written:
			>> probe f: function [/ref x: 1] [x]
			== func [/ref x][
			    switch type? :x [
			        none! [x: 1]						;) only affects 'none' but not 'false' which X can accept too
			    ] 
			    x
			]
			
			>> probe f: function [/ref x: 1 [integer! float!]] [x]
			func [/ref x [integer! float!]][
			    unless :x [x: 1]						;) since X does not accept 'false', uses simpler check 
			    x
			]
			
			>> probe f: function [/ref x [integer! float!] (x >= 0)] [x]
			func [/ref x [integer! float!]][
			    if :x [									;) if is required to see if value was even set
			    	unless (x >= 0) [					;) general value check does not require a switch
				        do make error! form reduce [
				            "Failed" "(x >= 0)" "for" type? :x "value:" mold/flat/part :x 40
				        ]
			        ]
			    ] 
			    x
			]
			
			>> probe f: function [/ref x: 1 [integer! float!] (x >= 0)] [x]
			func [/ref x [integer! float!]][
			    either :x [								;) either+unless solve both default application and general check
			        unless (x >= 0) [
			            do make error! form reduce [
			                "Failed" "(x >= 0)" "for" type? :x "value:" mold/flat/part :x 40
			            ]
			        ]
			    ] [x: 1] 
			    x
			]
	}
	design: {
		Implementation goals:
		* unification of common function requirements under single umbrella
		* fast function runtime performance at the expense of some lag during function construction
				
		Why is it based on `function`?
			It's most high-level out of function constructors, and the one I'm using in 95% cases.
			It makes most sense to extend it, but not the low-level ones.
		
		Why override `function` instead of a new name?
			It's backward compatible, so why not.
			Sure, there's a performance hit for this, even in release mode, as spec has to be parsed.
			I imagine function specs even taken all together are a quite small amount of data though.
			If all this was backed by R/S, it would have been an overall performance win
			and an increase in language's declarativity.
			Checks/defaults could even then appear in the help output.
		
		Why use set-word for default?
			I don't see much use for defaults on lit-args and get-args (which are rare anyway).
			So set-word just seems like a natural addition to the function spec syntax.
			Lit-args and get-args defaults must still be handled manually if this need ever arises.
			`return:` is reserved by function spec DSL and is not touched by this implementation.
		
		How is /extern handled?
			Currently no special handling, so since I'm parsing the spec before native `function`,
			 defaults and checks will apply even to /extern-al words.
		
		Can default values be used for mandatory arguments?
			Yes, no error is raised, and I can even imagine use cases for that.
			E.g. a function with refinements simply passes all arguments to another function without refinements.
			
		Can default values be used for locals?
			Yes, but arguably a very rare need.
			
		Can value checks be used for locals?
			Not forbidden, because /local can be a normal refinement.
			But makes zero sense to do when it's not one.
			
		What default values are accepted?
			I cannot make default an expression, or I won't know where it ends.
			So default value is always a single token. Accepted types: 
				scalar! series! map!							;) most types with lexical forms (save for hash & vector)
				word! lit-word! get-word! refinement! issue!	;) words excluding set-word
			Note: series! includes paren! which can be used for arbitrary expressions.
			Default value gets evaluated normally during function evaluation,
			so e.g. `none` word will become a `none!` value. 
		
		Why separate error messages for each type?
			Error messages have to be short and I want to display the failed check so user can understand what's wrong.
			Single message for every type would mean including whole `switch` structure into the message, quite a mess.
			
		Why insert all those checks into the function body, why not call external checking functions?
			Main point is to be able to see whole function logic in mold output,
			and be able to copy it without any redbind efforts.
			There's a danger that some of the used words are redefined by a function:
			SWITCH TYPE? UNLESS EITHER DO MAKE ERROR FORM REDUCE
			If function redefines any of that, it should not use any of the supported extensions.
			External functions would not eliminate this danger completely,
			I would just have to use some weird decorated names for them to minimize the risk.
			
		Can checks be abused?
			They are arbitrary code, so can include even return/exit. Abuse at your risk and readiness to uglify the code.
			The whole point was to make code more readable and concise by eliminating supplemental stuff.
		
		There's no guarantee about checks evaluation order between multiple arguments.
			Don't create dependencies, as spec is seen as an orderless thing. Use body for ordered code.
		
		See also %classy-object.red for some notes on syntax design.
	}
	TODO: {
		- ability to apply a single by-type checks to multiple types/typesets?
		  maybe apply the check to all previously listed types, not just one?
		- need to find how to unify this with classy-object as syntax is mostly similar
		- should this insert assertions instead of error checks?
		  probably not, as assertions are soft failures, but worth considering
		- function names as words for checks? 
		- automated test suite
	}
]

#include %debug.red
#include %error-macro.red
; #debug off


; function: :system/words/function						;@@ unset inside context, unless this file is the first included
if native? :function [
	context [
		make-check: function [check [paren!] word [get-word!]] [
			compose/deep [
				unless (check) [
					do make error! form reduce [
						"Failed" (mold check) "for" type? (word) "value:" mold/flat/part (word) 40
					]
				]
			]
		]
	
		make-switch: function [word [get-word!] options [block!] values [block! none!]] [
			compose/only pick [[						;-- options may be empty; new-lines matter here
				switch/default type? (word) (options) (values)
			][
				switch type? (word) (options)
			]] block? values
		]
		
		extract-value-checks: function [field [any-word!] types [block!] values [block! none!] /local check words] [
			field: to get-word! field
			typeset: clear []
			options: clear []
			parse types [any [
				copy words some word! (append typeset words)
				opt [
					set check paren! #debug [(
						mask: reduce to block! make typeset! words		;-- break typesets into types
						append/only append options mask make-check check field
					)]
				]
			]]
			reduce [copy typeset  copy options]
		]
	
		spec-word!: make typeset! [word! lit-word! get-word!]
		defaults!: make typeset! [
			scalar! series! map!								;-- most types with lexical forms (save for hash & vector)
			word! lit-word! get-word! refinement! issue!		;-- words excluding set-word
		]
		
		insert-check: function [
			body            [block!]
			word            [get-word!]
			ref?			[logic!] "True if words comes after a refinement"
			default         [defaults! none!]
			types           [block! none!]
			options         [block! none!]
			general-check   [block! none!]
		][
			if types [typeset: make typeset! types]
			if default [
				default: reduce [to set-word! word default]
				logic?: either types [to logic! find typeset logic!][yes]
			]
			need-none-check?: all [ref? either types [not find typeset none!][no]]
			check: case [
				any [not empty? options  all [default logic?]] [	;-- general case - switch
					unless options [options: make block! 2]
					if default [insert options reduce [none! default] ]
					new-line/skip options on 2
					make-switch word options general-check
				]
				all [default general-check] [					;-- optimizations...
					compose/only [								;-- new-line matters here
						either (word) (general-check) (default)
					]
				]
				default [
					compose/only [								;-- new-line matters here
						unless (word) (default)
					]
				]
				all [general-check need-none-check?] [			;-- 'none' = no parameter, and should not be checked
					compose/only [								;-- new-line matters here
						if (word) (general-check)
					]
				]
				general-check [general-check]					;-- 'none' is valid and should be checked as any other value
				'else [ [] ]
			]
			new-line insert body check on
		]
		
		native-function: :function
		set 'function native-function [
			"Defines a function, making all set-words in the body local, and with default args and value checks support"
			spec [block!] body [block!]
			/local word
		][
			ref?: no
			parse spec: copy spec [any [				;-- copy so multiple functions can be created
				[	set word spec-word!
				|	not quote return: change set word set-word! (to word! word)
					[	remove set default defaults!
					|	pos: (ERROR "Invalid default value for '(word) at (mold/flat/part :pos 20)")
					]
				]
				pos: set types opt block!
				opt string!
				remove set values opt paren!
				(
					#debug [general-check: if values [make-check values to get-word! word]]
					if types [
						set [types: options:] extract-value-checks word types general-check
						change/only pos types
					]
					if any [types values default] [
						insert-check body to get-word! word ref? default types options general-check
					]
					set [default: values: options: general-check:] none
				)
			|	refinement! (ref?: yes)					;-- refinements args can be none even if it's not in the typeset
			|	skip
			]]
			native-function spec body
		]
	]
]

; #include %assert.red
#assert [find/case spec-of function [abc return: [logic!]] [] quote return:]
#assert [
	equal? body-of function [z [block!] /x a: 1 b: 2] []
	[
	    switch type? :b [
	        #[none!] [b: 2] 
	    ] 
	    switch type? :a [
	        #[none!] [a: 1]
	    ]
	]
]

; do [
comment [
	probe do probe [f: function [x: 1 [integer! float! (x >= 0)] (x < 0)] [probe x]]
	probe do probe [f: function [x: 1] [probe x]]
	probe do probe [f: function [x: 1 (x < 0)] [probe x]]
	probe do probe [f: function [x: 1 [integer! float!] (x < 0)] [probe x]]
	probe do probe [f: function [x [integer! float!] (x < 0)] [probe x]]
	probe do probe [f: function [x: 1 [integer! (x >= 0)]] [probe x]]
	probe do probe [f: function [/ref x: 1  [integer! (x >= 0) string!]  (find x "0")] [probe x]]
]
