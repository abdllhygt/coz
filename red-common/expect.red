Red [
	title:   "EXPECT mezzanine"
	purpose: "Test a condition, showing full backtrace when it fails"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		This function originated from the Red View Test System: https://gitlab.com/hiiamboris/red-view-test-system
		Since the whole system is pretty big, when some test fails I didn't want to poke around in search of a broken element.
		Rather I wanted to immediately see where the behavior started to become unexpected.

		Limitations of TRACE-DEEP apply.
	}
]


#include %trace-deep.red

expect: function [
	"Test a condition, showing full backtrace when it fails; return true/false"
	expr [block!] "Falsey results: false, none and unset!"
	/buffer buf [string!] "Print into the provided buffer rather than the console"
	/local r
][
	orig: copy/deep expr								;-- preserve the original code in case it changes during execution
	red-log: make block! 20								;-- accumulate the reduction log here
	err: try/all [										;-- try/all as we don't want any returns/breaks inside `expect`
		set/any 'r trace-deep
			func [expr [block!] rslt [any-type!]] [
				repend red-log [expr :rslt]
				:rslt
			]
			expr
		'ok
	]

	if all [value? 'r  :r] [							;-- `value?` if not unset, `:r` if not false/none (or error=none)
		return yes
	]

	;; now that we have a failure, let's report
	buf: any [buf make string! 200]
	append buf form reduce [
		"ERROR:" mold/flat/part expr 100
		either error? err [
			reduce ["errored out with^/" err]
		][	reduce ["check failed with" mold/flat/part :r 100]
		]
		"^/  Reduction log:^/"
	]
	foreach [expr rslt] red-log [
		append buf form reduce [
			"   " pad mold/part/flat/only expr 30 30
			"=>" mold/part/flat :rslt 50 "^/"
		]
	]
	unless buffer [prin buf]
	no
]
