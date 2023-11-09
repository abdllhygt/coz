Red [
	title:   "SHOW-TRACE mezzanine and ??? macro"
	purpose: "Example TRACE wrapper that just prints the evaluation log to console"
	author:  @hiiamboris
	license: 'BSD-3
	usage: {
		>> show-trace [1 + 2  3 * 4  5 ** 6]
		1 + 2                                    => 3
		3 * 4                                    => 12
		5 ** 6                                   => 15625
		== 15625

		Insert `???` into your code (not into console!) to see the result of each expression following the `???`:
			do [
				1 + 2						;) will be silently evaluated
				???
				3 * 4
				5 ** 6
				append [] [1 2 3 4 5]		;) should not display `append [1 2 3 4 5] [1 2 3 4 5]`
				this-is-an-error!
			]
		Output:
			3 * 4                                    => 12
			5 ** 6                                   => 15625
			append [] [1 2 3 4 5]                    => [1 2 3 4 5]
			*** Script Error: this-is-an-error! has no value
			*** Where: do
			*** Stack: show-trace shallow-trace 
	}
]


#include %shallow-trace.red

; #macro [ahead word! '??? copy code to end] func [[manual] s e] [	ahead is not known to R2, can't compile
#macro [p: word! :p '??? copy code to end] func [[manual] s e] [	;-- has to support inner `???`s inside the `???` block
	back clear change s reduce ['show-trace code]
]

show-trace: function [
	"Print the step by step evaluation log of a set of expressions"
	code [block!] "Code to evaluate"
	/widths "Specify custom output column widths"
		left  [integer!] "Expression column (default: 40)"
		right [integer!] "Result column (default: 40)"
][
	unless widths [left: right: 40]
	orig: copy/deep code								;-- preserve the original code in case it changes during execution
	shallow-trace
		func [rslt [any-type!] more [block!]] compose [
			print [
				pad mold/part/flat/only
						copy/part orig part: offset? code more
					(left) (left)
				"=>" mold/part/flat :rslt (right)
			]
			code: more
			orig: skip orig part
			:rslt
		]
		code
]

comment {
	;; nested test
	do [
		1 + 2
		???
		3 * 4
		do [
			5 ** 6
			???
			append [] [1 2 3 4 5]
		]
		this-is-an-error!
	]
}
