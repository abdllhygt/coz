Red [
	title:   "APPLY mezzanine"
	purpose: "Experimental APPLY implementation for inclusion into Red runtime"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		See https://github.com/greggirwin/red-hof/blob/master/apply.md for some background

		Usage patterns:

		I	apply :function 'local						;) 'local carries the context of the caller
			apply  funcname 'local
			apply :function object [arg-name: expression ...]
			apply  funcname object [arg-name: expression ...]

			Set arguments of function to their values from given (directly or indirectly by 'local)
			context and evaluate it. Context will typically be a wrapping function.
			Use cases:
			- function (or native) extension, when argument names are the same, with maybe minor variations.
			- sharing of argument list between a set of functions (CLI lib is an example)
			Example:
				my-find: function
					compose [(spec-of :find) /my-ref]
					[
						..handle /my-ref..
						apply find 'my-ref				;) if no /local refinement, use what have you
					]
				my-find/my-ref/same/skip/only series needle n


		II	apply :function [arg-name: expression ref-name: logic ...]
			apply  funcname [arg-name: expression ref-name: logic ...]
			apply/verb :function [arg-name: value ref-name: logic ...]
			apply/verb  funcname [arg-name: value ref-name: logic ...]

			Call func with arguments and refinements from evaluated expressions
			or verbatim values followng the respective set-words.
			These set-words don't interfere with the expressions,
			so `apply .. [arg: arg]` is a valid usage, not requiring a `compose` call.
			Use case: programmatic call construction, esp. when refinements depend on data.
			Example:
				response: apply send-request [
					link:    params/url
					method:  params/method
					with:    yes						;) refinement state is trivially set
					args:    request
					data:    data						;) sets `data` argument to value of `data` word
					content: bin
					raw:     raw
				]

		Notes on 1st argument:
		- it has to support literal function values for they may be unnamed
		- it has to support function names for better informed stack trace
		- `apply name` form is chosen over `apply 'name` because if we make operator out of apply it will look better:
			->: make op! :apply
			find -> [series: s value: v]				;) rather than `'find -> [series: s value: v]`

		For simplicity in usage, APPLY ignores argument type (normal, lit-arg, get-arg).
		Values given are values passed to the function.
	}
]


#include %assert.red
#include %error-macro.red
#include %hide-macro.red

;@@ NOTE: this impelementation is intentionally not optimized as Red code, but written in R/S style for easier transition!
;@@ TODO: automatically set refinement to true if any of it's arguments are provided?
mezz-apply: function [									;@@ name to be used during transition; to be excluded eventually
	"Call a function NAME with a set of arguments ARGS"
	;@@ support path here or `(in obj 'name)` will be enough?
	;@@ operators should be supported too
	'name [word! function! action! native!] "Function name or literal"
	args [block! function! object! word!] "Block of [arg: expr ..], or a context to get values from"
	/verb "Do not evaluate expressions in the ARGS block, use them verbatim"
	/local value
][
	if word? :args [args: context? args]
	if all [not verb  block? :args] [					;-- evaluate expressions, create a /verb-like block
		buf: clear copy args
		pos: args
	 	while [not tail? bgn: pos] [
	 		either word? :pos/1 [
	 			repend buf [pos/1 get/any pos/1]
	 			pos: next pos
	 		][
		 		unless set-word? :pos/1 [
		 			ERROR "Expected word or set-word at (mold/part args 30)"
		 		]
		 		while [set-word? first pos: next pos][]	;-- skip 1 or more set-words
		 		set/any 'value do/next end: pos 'pos
		 		repeat i offset? bgn end [repend buf [bgn/:i :value]]
		 	]
	 	]
	 	args: buf
	]
	
	;@@ TODO: hopefully in args=block case we'll be able to make it O(n)
	;@@ by having O(1) lookups of all set-words into some argument array specific to each particular function
	;@@ this implementation for now just uses `find` within args block, which makes it O(n^2)
	
	either word? :name [
		set/any 'fun get/any name
		unless any-function? :fun [ERROR "NAME argument (name) does not refer to a function"]
	][
		anonymous: fun: :name
		name: 'anonymous
	]

	;@@ won't be needed in R/S
	call: reduce [path: to path! name]					;@@ in Red - impossible to add refinements to function literal
	
	get-value: [
		either block? :args [
			select/skip args to set-word! word 2
		][
			w1: to word! word
			all [
				not w1 =? w2: bind w1 :args				;-- if we don't check it, binds to global ctx
				get/any w2
			]
		]
	]

	use-words?: yes
	foreach word spec-of :fun [
		;@@ the below part will be totally different in R/S,
		;@@ hopefully just setting values at corresponding offsets
		type: type? word
		case [
			type = refinement! [
				if set/any 'use-words? do get-value [append path to word! word]
			]
			not use-words? []							;-- refinement is not set, ignore words
			type = word!     [repend call ['quote do get-value]]
			;@@ extra work that won't be needed in R/S:
			type = lit-word! [append call as paren! reduce [do get-value]]
			type = get-word! [repend call [do get-value]]
			;@@ type checking - where? should interpreter do it for us?
		]
	]
	; print ["Constructed call:" mold call]
	do call
]

#hide [#assert [
	-1  = mezz-apply negate [number: 1]
	-2  = mezz-apply negate [number: 1 + 1]					;-- evaluation of arguments
	 5  = mezz-apply add [value1: 2  value2: 3]
	 5  = mezz-apply add [value2: 2  value1: 3]				;-- order independence
	 5  = mezz-apply add [value2: 2  value1: 3  value3: 4]	;-- no error on extra args given, by design
	 4  = mezz-apply add [value1: value2: 2]					;-- chaining of set-words
	 5  = mezz-apply add [value1: value1: 2  value2: 3]		;@@ should this be an error? (extra check may slow down the code)
	 5  = mezz-apply add [value1: 2  value1: value2: 3]		;@@ right now it uses first defined value, not the last one
	yes = mezz-apply none? []								;-- omission of args sets them to 'none'
	
	(value1: 10 value2: 20)
	 30 = mezz-apply add [value1: value1  value2: value2]	;-- args do not shadow expression words 

	 5  = mezz-apply add object [value1: 2  value2: 3]		;-- accepts objects 
	yes = mezz-apply none? object []
	
	none? mezz-apply quote [value: none]						;-- able to pass get-args
	word? mezz-apply quote [value: quote none]
	word? mezz-apply quote [value: 'none]
	
	x: 0												;-- prevent leakage
	 2  = mezz-apply repeat [word: 'x value: 2 body: [x]]	;-- able to pass lit-args
	 2  = mezz-apply repeat [word: quote ('x) value: 2 body: [x]]
	
	word?       mezz-apply/verb quote [value: none]			;-- /verb doesn't evaluate 
	 5        = mezz-apply/verb add   [value2: 2  value1: 3]
	set-word?   mezz-apply/verb quote [value: value:]
	error? try [mezz-apply/verb add   [value1: value2: 2]]	;-- obv no chaining in verbatim mode
	
	find-me-needle: function exclude spec-of :find [value [any-type!]] [
		value: ["needle"]
		case: only: yes
		mezz-apply find 'local								;-- value becomes /local, so it's valid here
	]
	"needle"     = mezz-apply find-me-needle [series: "here's the needle"]  
	none?          mezz-apply find-me-needle [series: "here's the nEedle"]  
	none?          mezz-apply find-me-needle [series: ["needle"]]  
	[["needle"]] = mezz-apply find-me-needle [series: ["dont poke me with yer" ["needle"]]]  

	obj: object [value1: 1 value2: 2]					;-- shortened form
	3 = do bind [mezz-apply add [value1 value2]] obj
		
	
	;@@ calling literals not possible at mezz level:
	 ; 5  = apply :add [value2: 2  value1: 3]				;-- should accept function/native literals
	; yes = apply :none? []
	; "needle"     = apply :find-me-needle [series: "here's the needle"]  
	; none?          apply :find-me-needle [series: "here's the nEedle"]  
]]

; value: "d"
; probe apply find [series: "abcdef" value: value only: case: yes]

; probe apply find object [series: "abcde" value: "d" only: case: yes]

; my-find: function spec-of :find [
	; case: yes
	; only: no
	; apply find 'only
; ]
; probe my-find/only "abcd" "c"
