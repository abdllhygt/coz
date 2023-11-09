Red [
	title:   "SHOW-DEEP-TRACE mezzanine"
	purpose: "Example TRACE-DEEP wrapper that just prints the evaluation log to console"
	author:  @hiiamboris
	license: 'BSD-3
	usage: {
		>> show-deep-trace [1 + 2 * 3 ** 4]
		1 + 2                => 3
		3 * 3                => 9
		9 ** 4               => 6561
		== 6561

		>> show-deep-trace/widths [
			f: func [x] [does [10]]
			x: f: :f
			(g: f (1))
			((g) * 2)
		] 30 30
		f: func [x] [does [10]]        => func [x][does [10]]
		:f                             => func [x][does [10]]
		(1)                            => 1
		g: f 1                         => func [][10]
		((quote func [][10]))          => func [][10]
		(g)                            => 10
		10 * 2                         => 20
		(20)                           => 20
		== 20
	}
]


#include %trace-deep.red

show-deep-trace: function [
	"Print the step by step evaluation log of each subexpression in a set of expressions"
	code [block!] "Code to evaluate"
	/widths "Specify custom output column widths"
		left  [integer!] "Expression column (default: 20)"
		right [integer!] "Result column (default: 40)"
][
	unless widths [left: 20  right: 40]
	trace-deep/preview
		func [expr [block!] rslt [any-type!]] compose [
			print [mold/part/flat :rslt (right)]
			:rslt
		]
		code
		func [expr [block!]] [
			prin [pad mold/part/flat/only expr (left) (left) "=> "]
		]
]

