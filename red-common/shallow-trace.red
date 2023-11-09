Red [
	title:   "SHALLOW-TRACE mezzanine"
	purpose: "Step-by-step evaluation of a block of expressions with a callback"
	author:  @hiiamboris
	license: 'BSD-3
	usage: {
		SHALLOW-TRACE is a basis function to build upon.
		See CLOCK-EACH, STEPWISE and SHOW-TRACE for example usage
		
		NOTE: Renamed to SHALLOW-TRACE to avoid conflict with the TRACE instrumentation mezz.
		This function is still used by the profiler, but new TRACE is still unsuitable for it
		because of it's exception handling and being crash happy, so I'm not rewriting this yet. 
	}
	limitations: {
		- diverts `return`, `exit` and `local` (will be fixed once we have fast native bind/only; without it will be too slow)
		- slower than the macro version - computational cost is paid at run time during each invocation
		- number of evaluated expressions is limited by stack depth (only a problem when profiling loading of a lot of files)
	}
]

shallow-trace: func [
	"Evaluate each expression in CODE and pass it's result to the INSPECT function"
	inspect	[function!] "func [result [any-type!] next-code [block!]]"
	code	[block!]	"If empty, still evaluated once (resulting in unset)"
	/local r
][
	; #assert [parse spec-of :inspect [thru word! quote [any-type!] thru word! not to word! to end]]	;@@ affects clock-each
	set/any 'r do/next code 'code					;-- eval at least once - to pass unset from an empty block
	inspect :r code
	either tail? code [:r][shallow-trace :inspect code]
]

{
	;-- this version deadlocked if traced code contained `continue` (because it then applied to the `until` of `trace`)

	trace: func [
		"Evaluate each expression in CODE and pass it's result to the INSPECT function"
		inspect	[function!] "func [result [any-type!] next-code [block!]]"
		code	[block!]	"If empty, still evaluated once (resulting in unset)"
		/local r
	][
		#assert [parse spec-of :inspect [thru word! quote [any-type!] thru word! not to word! to end]]	;@@ affects clock-each
		until [
			set/any 'r do/next code 'code					;-- eval at least once - to pass unset from an empty block
			inspect :r code
			tail? code
		]
		:r
	]
}