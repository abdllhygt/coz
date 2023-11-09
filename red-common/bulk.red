Red [
	title:   "BULK mezzanine"
	purpose: "Evaluate an expression for multiple items at once"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		See https://github.com/greggirwin/red-hof/tree/master/code-analysis#bulk-syntax for design notes
	}
]


#include %hide-macro.red
#include %assert.red
#include %error-macro.red
#include %new-each.red									;-- we want map-each


bulk: function [
	"Evaluate an expression, expanding path masks into paths with index for all series items"
	expr [block!] "Should contain at least one path with an asterisk '*'"
	/all "Return all iteration results rather than the last one"
	/local p *
][
	paths: clear []
	expr: copy/deep expr
	parse expr rule: [any [
		ahead set p any-path!
		into [any [
			change '* (to get-word! '*)					;-- replace it with a locally bound '*'
			(append/only paths p)						;-- remember the path for later check
		|	skip
		]]
	|	ahead [block! | paren!] into rule
	|	skip
	]]
	ns: unique map-each p unique paths [				;-- ensure all masked series lengths are equal
		length? get copy/part p find p '*
	]
	case [
		empty?      ns [ERROR "No path masks found in expression: (mold/part expr 50)"]
		not single? ns [ERROR "Path masks refer to series of different lengths in: (mold/part expr 50)"]
	]
	either all [
		collect [repeat * ns/1 [keep/only do expr]]		;-- '*' is the index word here
	][
		repeat * ns/1 expr
	]
]

#hide [#assert [
	(ss: ["ab-c" "-def"] a: [1 2 3] b: [2 3 4])			;-- init test vars
	ms: [#(a: 1 b: 2) #(a: 2 b: 3) #(b: 4)]
	[2 3 4 ] = bulk/all [b/*           ]
	[3 5 7 ] = bulk/all [a/* + b/*     ]
	[2 6 12] = bulk/all [a/* * b/*     ]				;-- should not override multiply operator
	[2 6 12] = bulk/all [(a/* * b/*)   ]				;-- should affect parens
	[2 6 12] = bulk/all [do [a/* * b/*]]				;-- should affect inner blocks
	12       = bulk     [a/* * b/*     ]
	[2 4 6 ] = (bulk    [a/*: a/* * 2] a)				;-- set-words must work
	[2 3 4 ] = bulk/all [ms/*/b]						;-- asterisk doesn't have to be the last part of the path
	[["ab" "c"] ["" "def"]] = bulk/all [split ss/* "-"]
	error? try [bulk [         ]]
	error? try [bulk [b/1      ]]						;-- no asterisk
	error? try [bulk [ss/*: a/*]]						;-- lengths do not match
]]


