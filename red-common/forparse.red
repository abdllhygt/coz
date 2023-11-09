Red [
	title:   "FORPARSE loop"
	purpose: "Leverage parse power to filter series"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		What is this:
			`forparse spec series code`
			is somewhat analogous to
			`parse series [any [thru spec (do code)]]`
			or
			`parse series [any [spec (do code) | skip]]`

		Why not just use PARSE?
			Compare readability:
				parse spec-of :fun [any [
					thru set w arg-typeset (
						loop 1 [						;-- trick to make `continue` work
							...code...
							if cond [continue]
							...code...
						]
					)
				]]
			Versus:
				forparse [set w arg-typeset] spec-of :fun [
					...code...
					if cond [continue]
					...code...
				]
			See? ;)
			Then mind that PARSE has no BREAK support so it's hardly suitable for loops...

		Limitations:
			- traps exit & return - can't use them inside forparse
			- break/return will return nothing, because - see #4416

		BREAK and CONTINUE are working as expected

		Examples:
			>> forparse [set x integer!] [0 1.0 "abc" 2] [probe x]
			0
			2
			== 2

			>> forparse [set x integer!] [0 1.0 "abc" 2] []
			>> forparse [set x integer!] [0 1.0 "abc" 2] [break]
			>> forparse [set x integer!] [0 1.0 "abc" 2] [if 2 = x [break]]
			>> forparse [set x integer!] [0 1.0 "abc" 2] [if x = 2 [continue]]
			(these return unset, as expected)
			
			>> forparse [set x integer!] [0 1.0 "abc" 2] [if x = 0 [continue]]
			== none
			(2nd iteration gives x=2, so `if` returns none - correct)

			>> forparse [set x integer!] [0 1.0 "abc" 2] [if x = 2 [make error! ""]]
			*** User Error: ""
			*** Where: ??? 
			(error is returned as expected)
	}
]


#include %selective-catch.red
; #include %new-apply.red

;@@ BUG: this traps exit & return - can't use them inside forparse
;@@ BUG: break/return will return nothing, because - see #4416
forparse: function [
	"Evaluate body for every match of pattern in series"
	pattern	[block!] "Parse rule to match"
	series	[any-block! any-string! binary!] "Series to parse"
    body    [block!] "Block of code to evaluate"
    /deep  "Match inside all sub-lists as well"
    /case  "Search for pattern case-sensitively"
    /part  "Limit the length of iteration"
    	length [number! any-block! any-string! binary!]
	/local r
][
	unset 'r											;-- unset if never matched the spec
	unless any-block? :series [deep: no]

	=else=: pick [
		[ahead any-list! into =rule= | skip]
		[skip]
	] deep
	=match=: [pattern (set/any 'r catch-continue body)]	;-- set r to result of last iteration
	=rule=: [any [=match= | =else=]]
	if error? catch-a-break [parse/:case/:part series =rule= length] [
		unset 'r										;-- break should return unset
	]
	:r
]

