Red [
	title:   "TRACE-DEEP mezzanine"
	purpose: "Step-by-step evaluation of each sub-expression with a callback"
	author:  @hiiamboris
	license: 'BSD-3
	usage: {
		It evaluates every sub-expression of every expression in a separate step, feeding it to the callback.
		See SHOW-DEEP-TRACE and EXPECT for an examples.
		It's handy e.g. if you have an assertion but want to know all intermediate values to tell what's wrong with it.
	}
	limitations: {
		* diverts `return`, `exit` and `local` (will be fixed once we have function attributes)
		* it's simple now - no lit/get-args support in called functions; handle with care or extend (or ask me to extend :)
		* does not recurse into function bodies or any blocks
		  it's possible to hardcode all loops, if/either/case/switch, and reproduce the function call stack
		  to turn it into a full-featured debugger with breakpoints, stepping in/out, etc.
		  but do we want to?
		* it has to make 2 copies of each code part:
		  - a deep copy - for `inspect` - in case any internal block gets modified by the code
		    (although this doesn't stop one from modifying objects, and `inspect` will receive modified versions anyway)
		  - a shallow copy - for evaluation - otherwise side effects after deep copy will apply to copied values rather than those user wants
		* `inspect` function may (by design) replace the evaluation results with it's own values
		  but when to call inspect and when not, if result will depend on it? there are no clearly defined rules so far
		  e.g. `a: b: 1` won't be inspected as the result is immediately obvious, but `(1)` will be as paren may contain more than one value
	}
]


trace-deep: none
context [
	eval-types: make typeset! reduce [		;-- value types that should be traced
		paren!		;-- recurse into it

		; block!	-- never known if it's data or code argument - can't recurse into it
		; set-word!	-- ignore it, as it's previous value is not used
		; set-path!	-- ditto

		word!		;-- function call or value acquisition - we wanna know the value
		path!		;-- ditto

		get-word!	;-- value acquisition - wanna know it
		get-path!	;-- ditto

		native!		;-- literal functions should be evaluated but no need to display their source; only result
		action!		;-- ditto
		routine!	;-- ditto
		op!			;-- ditto
		function!	;-- ditto
	]

	;; this is used to prevent double evaluation of arguments and their results
	;@@ TODO: remove this once we have `apply` native
	wrap: func [x [any-type!]] [
		if any [										;-- quote non-final values (that do not evaluate to themselves)
			any-word? :x
			any-path? :x
			any-function? :x
			paren? :x
		][
			return as paren! reduce ['quote :x]
		]
		:x												;-- other values return as is
	]

	;; reduces each expression in a chain
	rewrite: func [code inspect preview] [
		code: copy code									;-- will be modified in place; but /deep isn't applicable as we want side effects
		while [not empty? code] [code: rewrite-next code :inspect :preview]
		head code										;-- needed by `trace-deep`
	]
	
	;; fully reduces a single value, triggering a callback
	rewrite-atom: function [code inspect preview] [
		if find eval-types type: type? :code/1 [
			to-eval:   copy/part      code 1			;-- have to separate it from the rest, to stop ops from being evaluated
			to-report: copy/deep/part code 1			;-- report an unchanged (by evaluation) expr to `inspect` (here: can be a paren with blocks inside)
			change/only code
				either type == paren! [
					as paren! rewrite as block! code/1 :inspect :preview
				][
					preview to-report
					wrap inspect to-report do to-eval
				]
		]
	]

	;; rewrites an operator application, e.g. `1 + f x`
	;; makes a deep copy of each code part in case a value gets modified by the code
	rewrite-op-chain: function [code inspect preview] [
		until [
			rewrite-next/no-op skip code 2 :inspect :preview	;-- reduce the right value to a final, but not any subsequent ops
			to-eval:   copy/part      code 3			;-- have to separate it from the rest, to stop ops from being evaluated
			to-report: copy/deep/part code 3			;-- report an unchanged (by evaluation) expr to `inspect`
			preview to-report
			change/part/only code wrap inspect to-report do to-eval 3
			not all [									;-- repeat until the whole chain is reduced
				word? :code/2
				op! = type? get/any :code/2
			]
		]
	]

	;; deeply reduces a single expression, recursing into subexpressions
	rewrite-next: function [code inspect preview /no-op /local end' r] [
		;; determine expression bounds & skip set-words/set-paths - not interested in them
		start: code
		while [any [set-path? :start/1 set-word? :start/1]] [start: next start]		;@@ optimally this needs `find` to support typesets
		if empty? start [do make error! rejoin ["Unfinished expression: " mold/flat skip start -10]]
		end: preprocessor/fetch-next start
		no-op: all [no-op  start =? code]				;-- reset no-op flag if we encounter set-words/set-paths, as those ops form a new chain

		set/any [v1: v2:] start							;-- analyze first 2 values
		rewrite?: yes									;-- `yes` to rewrite the current expression and call a callback
		case [											;-- priority order: op (v2), any-func (v1), everything else (v1)
			all [											;-- operator - recurse into it's right part
				word? :v2
				op! = type? get/any v2
			][
				rewrite-atom start :inspect :preview		;-- rewrite the left part
				if no-op [return next start]				;-- don't go past the op if we aren't allowed
				rewrite-op-chain start :inspect :preview	;-- rewrite the whole chain of operators
				rewrite?: no								;-- final value; but still may need to reduce set-words/set-ops
			]

			all [										;-- a function call - recurse into it
				any [
					if word? :v1 [fpath: v1]
					all [									;-- get the path in objects/blocks.. without refinements
						path? :v1
						also set/any [fpath: _:] preprocessor/value-path? v1
							if single? fpath [fpath: :fpath/1]	;-- turn single path into word
					]
				]
				find [native! action! function! routine!] type?/word get/any fpath
			][
				v2: get fpath
				arity: either path? v1 [
					preprocessor/func-arity?/with spec-of :v2 v1
				][	preprocessor/func-arity?      spec-of :v2
				]
				end: next start
				loop arity [end: rewrite-next end :inspect :preview]	;-- rewrite all arguments before the call, end points past the last arg
			]

			paren? :v1 [								;-- recurse into paren; after that still `do` it as a whole
				change/only start as paren! rewrite as block! v1 :inspect :preview
			]

			'else [										;-- other cases
				rewrite-atom start :inspect :preview
				rewrite?: no								;-- final value
			]
		]

		if any [
			rewrite?									;-- a function call or a paren to reduce
			not start =? code							;-- or there are set-words/set-paths, so we have to actually set them
		][
			preview copy/deep/part code end
			set/any 'r either rewrite? [
				to-report: copy/deep/part code end
				inspect to-report do/next code 'end'
			][
				do/next code 'end'
			]
			;; should not matter - do (copy start end) or do/next, if preprocessor is correct
			unless end =? end' [
				do make error! rejoin [
					"Miscalculated expression bounds detected at "
					mold/flat copy/part code end
				]
			]
			change/part/only code wrap :r end
		]
		return next code
	]

	set 'trace-deep function [
		"Deeply trace a set of expressions"				;@@ TODO: remove `quote` once apply is available
		inspect	[function!] "func [expr [block!] result [any-type!]]"
		code	[block!]	"If empty, still evaluated once"
		/preview
			pfunc [function! none!] "func [expr [block!]] - called before evaluation"
	][
		do rewrite code :inspect :pfunc					;-- `do` will process `quote`s and return the last result
	]
]

; inspect: func [e [block!] r [any-type!]] [print [pad mold/part/flat/only e 20 20 " => " mold/part/flat :r 40] :r]

; #include %assert.red			;@@ assert uses this file; cyclic inclusion = crash

; 	() = trace-deep :inspect []
; #assert [() = trace-deep :inspect [()]]
; #assert [() = trace-deep :inspect [1 ()]]
; #assert [3  = trace-deep :inspect [1 + 2]]
; #assert [9  = trace-deep :inspect [1 + 2 * 3]]
; #assert [4  = trace-deep :inspect [x: y: 2 x + y]]
; #assert [20 = trace-deep :inspect [f: func [x] [does [10]] g: f 1 g * 2]]
; #assert [20 = trace-deep :inspect [f: func [x] [does [10]] (g: f (1)) ((g) * 2)]]


#hide [#assert [										;-- prevent leakage of all these x y f words
	() = trace-deep func [x y [any-type!]][:y] []
	() = trace-deep func [x y [any-type!]][:y] [()]
	() = trace-deep func [x y [any-type!]][:y] [1 ()]
	3  = trace-deep func [x y [any-type!]][:y] [1 + 2]
	9  = trace-deep func [x y [any-type!]][:y] [1 + 2 * 3]
	4  = trace-deep func [x y [any-type!]][:y] [x: y: 2 x + y]
	20 = trace-deep func [x y [any-type!]][:y] [f: func [x] [does [10]] g: f 1 g * 2]
	20 = trace-deep func [x y [any-type!]][:y] [f: func [x] [does [10]] x: f: :f (g: f (1)) ((g) * 2)]
]]