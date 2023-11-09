Red [
	title:   "SELECTIVE-CATCH mezz & wrappers"
	purpose: "For use in building custom loops"
	author:  @hiiamboris
	license: 'BSD-3
	usage: {
		See FORPARSE for an example

		Another option would be to make custom functions `break` and `continue`, then bind the loop body.
		Could be faster perhaps?
	}
]

;@@ BUG: this turns return/exit/break/continue into errors (when not caught) - they should be rethrown separately using their natives
;@@ BUG: throw cannot be used from inside CODE block, because it will be turned into an error before being rethrown!
selective-catch: func [
	"Evaluate CODE and return errors of given TYPE & ID only, while rethrowing all others"
	type	[word!]
	id		[word!]
	code	[block!]
	/default value [any-type!] "Return this value on successful catch instead of the error object"
	/local e r
][
	all [
		error? e: try/all/keep [set/any 'r do code  'ok]	;-- r <- code result (maybe error or unset);  e <- error or ok
		any [											;-- muffle & return the selected error only
			e/type <> type
			e/id <> id
			return either default [:value][e]
		]
		do e											;-- rethrow errors we don't care about
	]
	:r													;-- pass thru normal result
]

;;@@ catching it is all cool, but how to actually propagate it further up as `return`,
;;   not as an error, considering `return` will be caught by the function anyway?
catch-return:  func [
	"Evaluate CODE catching RETURN and EXIT (for use in loops)"
	code	[block!]
][
	selective-catch 'throw 'return code
]

;;@@ should this use some /default value or detection by error is okay?
catch-a-break:  func [
	"Evaluate CODE catching BREAK (for use in loops)"
	code	[block!]
][
	selective-catch 'throw 'break code
]

catch-continue: func [
	"Evaluate CODE catching CONTINUE (for use in loops)"
	code	[block!]
][
	selective-catch/default 'throw 'continue code ()	;-- return unset on continue, in accord with other loops
]
