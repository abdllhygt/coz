Red [
	title:   "WITH function - a convenient/readable BIND variant"
	author:  @hiiamboris
	license: 'BSD-3
	usage: {
		USAGE SUMMARY
			with x  [..]          == bind [..] x
			with 'x [..]          == bind [..] 'x
			with :fun [..]        == bind [..] :fun
			with [:fun] [..]      == bind [..] :fun
			with [x y 'z] [..]    == bind bind bind [..] 'z y x
			with [x: 1 y: 2] [..] == bind [..] context [x: 1 y: 2]

		EXAMPLES
		;; omit the path to an object, but work inside it's context:

			do with face/parent/pane/1 [
				color: red
				text: mold color
				visible?: yes
			]
			
			if true with system/view/fonts [print [serif size]]

			f: func [/- /+ /*] [		;-- redefines important globals locally
				(do something with local flags)
				foreach x [set..] with system/words [
					(do something with global * + -)
				]
			]

		;; create static storage for functions where existing literal forms don't allow you to:

			factorial: func [x] with [cache: make hash! [0 1]] [
				any [
					select/skip cache x 2
					put cache x x * factorial x - 1
				]
			]

		;; anonymize words used during initialization of the program:
		   first item in the block should be of set-word! type

			do with [x: 1 y: 2] [
				z: x * y
				... other code that uses x or y ...
			]

		;; bind a block to multiple contexts at once (in the list order):
		   first item in the block should be of word!/get-word!, path!/get-path! or lit-word! type
		   1) words and paths values are fetched, while lit-words are converted into words
		      get-words and get-paths should be used for function context, otherwise they get evaluated
		   2) if resulting value is a context, block is bound to it
		      if resulting value is a word, block is bound to the context of this word

		    the following example illustrates usage of words and lit-words:

			a: b: x: y: none
			c: context [
				a: 1
				b: 2
				f: func [x y] [
					print composite [self 'x] "a=(a) b=(b) x*y=(x * y)"		;) calls `with` internally
					print composite [self :f] "a=(a) b=(b) x*y=(x * y)"		;) equivalent
				]
			]
			
			Thus, `with [c]` is equivalent to `with c`, while `with ['c]` - to `with 'c`.

		TODO: make an R/S version which will not evaluate functions, and get-variants won't be needed
	}
	notes: {
		Why is it designed like this?

		1. It does not evaluate
		
		`with` does not evaluate the block, so:
		- it can be used after `context`s, `if`s, `loop`s, `func`s, etc.
		- it can be chained `with x with y ...`
		I've found that this makes code much more readable than it would be with `bind`.
		Prefix it with `do` if you want immediate evaluation.

		2. It accepts blocks

		Design question here was - if we allow block! for `ctx`, how should we treat it?
		- convert it to a context? `ctx: context ctx`
			that shortens the `with context [locals...] [code]` idiom
		- list multiple contexts in a block as a sequence and bind to each one?
			that shortens `with this with that [code]` idiom
		Personally, I've used the 1st at least a few times, but 2nd - never, though I admit there are use cases.
		
		This can be solved by checking type of the 1st item in the block is a set-word or not ;)
		But still ambiguous! When `with` gets a `word!` argument it can:
		- get the value of this word, which should be an `object!`, and bind to this object
		- get the context of this word, and bind to this context

		When inside a context, 2nd option is nice:
			context [
				a: 1
				f: func [x y] [
					with [self x] [x * y * a]
				]
			]
		..where the alternative would be:
			context [
				a: 1
				f: func [x y] [
					with context? 'x with self [x * y * a]
				]
			]

		When outside of it, 1st option is better:
			x: context [x: 10]
			y: context [y: 20]
			do with [x y] [x * y]
		..where the alternative would be:
			x: context [x: 10]
			y: context [y: 20]
			do with in x 'x with in y 'y [x * y]

		But this still can be solved: let `word!`s evaluate to contexts and `lit-word!`s,
		same as we have `bind code ctx` vs `bind code 'ctx`:
			context [
				a: 1
				f: func [x y] [
					with [self 'x] [x * y * a]
				]
			]

			x: context [x: 10]
			y: context [y: 20]
			do with [x y] [x * y]
	}
]


#include %hide-macro.red
#include %assert.red


with: func [
	"Bind CODE to a given context CTX"
	ctx [any-object! function! any-word! block!]
		"Block [x: ...] is converted into a context, [x 'x ...] is used as a list of contexts"
	code [block!]
][
	case [
		not block? :ctx  [bind code :ctx]
		set-word? :ctx/1 [bind code context ctx]
		'otherwise       [foreach ctx ctx [bind code do :ctx]  code]		;-- `do` decays lit-words and evals words, but doesn't allow expressions
		; 'otherwise       [while [not tail? ctx] [bind code do/next ctx 'ctx]  code]		;-- allows expressions
		; 'otherwise       [foreach ctx reduce ctx [bind code :ctx]  code]	;-- `reduce` is an extra allocation
	]
]

#hide [#assert [
	(c: context [x: 4 y: 5]
	20 == do with [c] [x * y])

; 	(c: context [x: 4 y: 5]
; 	20 == do with [context? in c 'x] [x * y])

	200 == do with [
		x: context [x: 10]
		y: context [y: 20]
	][
		do with [x y] [x * y]							;) multiple contexts
	]

	90 == do with [
		x: context [y: context [x: 3 y: 30]]
	][
		do with [x/y] [x * y]							;) path support
	]

	8 == do with [
		b: [x ** y]
		c: context [x: 2]
	][
		context [y: 3 return do with ['y c] b]			;) mixed lit- and normal words
	]
]]
