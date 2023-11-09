Red [
	title:   "Value setters"
	purpose: "Varies... ;)"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		Why set-words/set-paths?
			Set-words because this gets words automatically collected by `function`, and just reads better.
			Set-paths - to have syntax similar to set-words.
		Why I'm not using `set/any` but `set` in these functions, and do not allow unset for the value?
			To follow the normal `word: value` behavior, which throws an error when value is unset

		ONCE
			Syntax:
				once my-word: my-value
			Sets my-word to my-value only if the former is unset.

			If you have some initialization code in your script, and you reload this script often,
			use `once` to stop these code pieces from being re-evaluated upon loading.
			Simple values, functions, do not require it, but if the code affects global state - it becomes very handy.

			Question is, should it support paths?
				once my/path: my-value ?
			I haven't had a use case so far.

			Another question: should `once` and `default` be unified?
			Their use cases are somewhat different, even though similar in implementation.

		DEFAULT
			Syntax:
				default my-word: my-value
				default my/path: my-value
			Sets my-word or my/path to my-value only if former is none.
			
			This is similar to the construct we must be all using sometime in functions:
				my-word: any [my-word my-value]
			but reads better.
			
			Another subtle difference:
				my-word: any [my-word calculate-it]     -- will not call `calculate-it`
				default my-word: calculate-it           -- will call `calculate-it`
			When critical not to call extra code (slowdowns/crashes?), just resort to `any` form.
			I find that such cases are relatively rare and do not justify the `default my-word: [calculate-it]` form.

		MAYBE
			Syntax:
				maybe my-word: my-value
				maybe my/path: my-value
			Sets my-word or my/path to my-value only if it's current value does not strictly equal the new one.
				maybe/same my/path: my-value
			Ditto, if current value is not same as the new one.

			This is handy in reactivity to stop unnecessary events from firing, reduce lag, break dependency loops.
			It uses strict equality, because otherwise we won't be able to change e.g. "Text" to "TEXT".
			For numerics it's a drawback though, as changing from `0` to `0.0` to `0%` to `1e-100` produces an event.
			/same is useful mostly for object values

		QUIETLY (a macro)
			Syntax:
				quietly my-word: my-value
				quietly my/path: my-value
			Sets my-word or my/path to my-value without triggering on-change* function (thus any kind of reactivity).
			
			Similar to (and is based on) set-quiet routine but supports paths and more readable set-word syntax.
			It's useful either to group multiple changes into one on-change signal,
			or when on-change incurs too much overhead for no gain (e.g. setting of face facets is 25x faster this way).

		IMPORT
			Syntax:
				import my-ctx
			Import all words from a given context into the global namespace.

			This is sometimes useful in debugging, when you have multiple internal functions in some context,
			and you wanna play with those functions in console until you're satisfied with their results.

		EXPORT
			Syntax:
				export [my-func1 my-func2 ...]
			Is similar to `import`, but should be called from inside a context, and takes a list of words.

			This is handy when you want to define a word in the context, but also want it globally available.
			You can't write `set 'my-func my-func: ...` because 'my-func will be bound to the context itself.

		ANONYMIZE
			Syntax:
				anonymize 'my-word my-value
			It returns 'my-word set to my-value in an anonymous context.

			Useful when you want to have a collection of similarly spelled words with different values.
			It intentionally accepts word!-s only (not set-word!-s),
			because returned word does not belong to the wrapping function's context and should not be /local-ized.
	}
]


; #include %assert.red


once: func [
	"Set value of WORD to VAL only if it's unset"
	'word [set-word!]
	val   [default!] "New value"
][
	if unset? get/any word [set word :val]
	:val
]

default: func [
	"If SUBJ's value is none, set it to VAL"
	'subj [set-word! set-path!]
	val   [default!] "New value"
][
	; if set-path? subj [subj: as path! subj]				;-- get does not work on set-paths
	if none =? get/any subj [set subj :val]				;-- `=?` is like 5% faster than `=`, and 2x faster than `none?`
	:val
]

maybe: func [
	"If SUBJ's value is not strictly equal to VAL, set it to VAL (for use in reactivity)"
	'subj [set-word! set-path!]
	val   [default!] "New value"
	/same "Use =? as comparator"
][
	if either same [:val =? get/any subj][:val == get/any subj] [return :val]
	set subj :val
]

import: function [
	"Import words from context CTX into the global namespace"
	ctx [object!]
	/only words [block!] "Not all, just chosen words"
][
	either only [
		foreach word words [set/any 'system/words/:word :ctx/:word]
	][
		set/any  bind words-of ctx system/words  values-of ctx
	]
]

export: function [
	"Export a set of bound words into the global namespace"
	words [block!]
][
	foreach w words [set/any 'system/words/:w get/any :w]
]

anonymize: function [
	"Return WORD bound in an anonymous context and set to VALUE"
	word [any-word!] value [any-type!]
][
	o: construct change [] to set-word! word
	set/any/only o :value
	bind word o
]


;-- there's a lot of ways this function can be written carelessly...
#assert [
	'w     == anonymize 'w 0
	'value  = get anonymize 'value 'value
	true    = get anonymize 'value true
	'true   = get anonymize 'value 'true
	'none   = get anonymize 'value 'none
	unset?    get/any anonymize 'value ()
	[1 2]   = get/any anonymize 'value [1 2]
	#(a: 1) = get/any anonymize 'value #(a: 1)
	(object [a: 1]) = get/any anonymize 'value object [a: 1]
	set-word? get/any anonymize 'value quote value:
	lit-word? get/any anonymize 'value quote 'value
]


;; macro allows to avoid a lot of runtime overhead, thus allows using `quietly` with paths in critical code
;@@ unfortunate limitation: only applicable to objects, set-quiet cannot work with /x /y of a pair or components of time/date
#macro [p: 'quietly :p word! [set-path! | set-word!]] func [s e /local path] [
	either set-word? s/2 [
		compose [set-quiet quote (s/2)]					;-- set-quiet returns the value after #5146
	][
		path: to block! s/2								;-- required for R2 that can't copy/part paths!
		token: switch type?/word token: last path [
			word! [to lit-word! token]
			get-word! paren! [token]
		]
		compose [set-quiet in (to path! copy/part path back tail path) (:token)]	
	]	
]
