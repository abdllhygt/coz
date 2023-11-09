Red [
	title:   "MAPPARSE loop"
	purpose: "Leverage parse power to replace stuff in series"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		See also: forparse.red

		What is this:
			`mapparse spec series code`
			is somewhat analogous to
			`parse series [any [thru [change spec (do code)]]]`
			or
			`parse series [any [change spec (do code) | skip]]`
		So, self-modification is implied in this implementation.
		Not sure if we want to copy/deep first by default?

		Why not just use PARSE?
			Compare readability:
				parse spec-of :fun [any [thru [
					change [set w arg-typeset] (
						loop 1 [						;-- trick to make `continue` work
							...code...
							if cond [continue]
							...code...
						]
					)
				]]]
			Versus:
				mapparse [set w arg-typeset] spec-of :fun [
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
			>> mapparse [set x integer!] [0 1.0 "abc" 2] [probe x x * 2]
			0
			4
			== [0 1.0 "abc" 4]

			>> mapparse [set x integer!] [0 1.0 "abc" 2] [break]
			== [0 1.0 "abc" 2]
			(series is unchanged)
	}
]


#include %selective-catch.red
; #include %new-apply.red

;@@ BUG: this traps exit & return - can't use them inside forparse
;@@ BUG: break/return will return nothing, because - see #4416
;@@ modifies series in place, similar to replace (undecided if it's good or not)

;@@ BUG: Parse will deadlock if used carelessly,
;@@   e.g. `mapparse [any rule] "whatever" ["x"]` will insert "x" indefinitely
;@@   should we detect if match is empty and not evaluate the body for it?

;@@ or name it `rewrite`? but `mapparse` name is consistent with `forparse`
mapparse: function [
	"Changes every match of pattern in series with result of body evaluation"
	;-- pattern then series rather than series then pattern: follows other loops and forparse in particular
    pattern [any-type!] "Parse rule to match"
    series  [any-block! any-string! binary!] "The series to be modified in place"	;-- types accepted by parse
    body    [block!] "Block of code to evaluate"
    ; /all   "Replace all matches, not just the first"
    ; /deep  "Replace pattern in all sub-lists as well (implies /all)"
    /once  "Replace only first match, return position after replacement"	;-- makes no sense with /deep, returns series unchanged if no match
    																		;-- not sure /once is even needed as we have break
    /only  "Treat series result of body evaluation as single value"			;-- no effect on pattern
    /deep  "Replace pattern in all sub-lists as well"
    /case  "Search for pattern case-sensitively"
    /part  "Limit the length of replacement"
    	length [number! any-block! any-string! binary!]
][
	; if deep [all: true]									;-- /deep doesn't make sense without /all
	; if deep [once: false]								;-- /deep doesn't make sense with /once
	if all [deep once] [do make error! "/deep and /once refinements are mutually exclusive"]
	unless any-block? :series [deep: no]

	=else=: pick [
		[ahead any-list! into =rule= | skip]
		[skip]
	] deep
	=change=: pick [
		[change only pattern (catch-continue body)]
		[change      pattern (catch-continue body)]
	] only
	=rule=: pick [
		[thru =change= series:]
		[any [=change= | =else=]]
	] once
	catch-a-break [parse/:case/:part series =rule= length]
	series
]


; probe mapparse [set x integer!] [0 1.0 "abc" 2] [probe x x * 2]
