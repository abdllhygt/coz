Red [
	title:   "Experiment on alternate (pull) reactivity"
	author:  @hiiamboris
	license: BSD-3
	notes: {
		Drawbacks compared to native 'push' reactivity:
		- When probing the object, target fields are displayed as functions, not as values
		  Ideally we want a tapping point that will trigger recomputation on read (if needed)
		  which can only be done at R/S side of the interpreter...
		  Then it won't be necessary to box values with functions.
		  (It can possibly be done with a datatype, but such datatype will box all other ones, unlike anything in Redbol)
		- View cannot use functions as it's facets, so it won't update itself based on new values
		  I think this is not solvable, except by refreshing the view on timer
		- Being a function, pull-reactive field cannot expose it's inner structure, e.g. /x /second /1 /:n etc
		  One has to assign it to a temporary value then access inner fields of that value 
		- Non-scalar dependencies do not trigger recomputation if they're "same"
		  e.g. field/text remains the same value even when it changes - have to copy it every time to compare against.
		- Long series have to be copied or scanned fully for a change, which is slow
		  Both above points could be solved by creating separate links from each source to each of it's targets,
		  and then keeping the `dirty?` flag for each such source+target pair, and setting it upon source modification.
		  Then, it opens a way for event streams, but 'push' reactivity is already a better foundation for it.
		- No cycle resolution: cycles will overflow the stack

		Benefits:
		- dead simple
		- lazy evaluation
		- reactors are not needed, any named value can be a source
		- since there are no triggered events or queued events, code flow is predictable
	}
]


#include %assert.red
; #include %show-trace.red

formula: lazy: none
context [
	;-- same? is better for words, == is better for strings that are result of evaluation - what to choose?
	fetch: function [cache] [
		set/any [val: code: src: old-val: new-val:] cache
		reduce/into src clear new-val
		; either find/match/same old-val new-val [
		either old-val == new-val [
			:val
		][
			swap at cache 4 at cache 5
			set/any 'cache/1 do code
		]
	]

	;-- to be able to use other lazy formula fields, we have to accept nullary functions
	;-- this adds nullary funcs (which auto-excludes operators), and all other values
	spec-arg!: make typeset! [word! get-word! lit-word!]	;-- return: and /ref are okay here
	+source: function [where [block!] what [any-path! any-word!]] [
		unless attempt [								;-- success of spec-of means any-function automatically
			find spec-arg! type? first find spec-of get/any what all-word!
		][
			append/only where what
		]
	]

	source-type!: [word! | lit-word! | get-word! | path! | lit-path! | get-path!]
	set 'formula function [
		"Define a lazy relation that gets recomputed only when one of it's sources change in value"
		'sources [block! word!] "'auto or reducible list of sources formula depends on"
		'target  [set-word! set-path!] "Target to set"
		code     [block!] "Formula to compute target value"
	][
		if word? sources [
			#assert ['auto = sources]
			sources: copy []
			parse code rule: [any [
				set w source-type! (+source sources w)
			|	ahead [block! | paren!] into rule
			|	skip
			]]
			sources: unique sources
		]

		r: set target does [fetch none]					;-- externalized, it reduces func's RAM size
		change/only next body-of :r						;-- change it after it's bound or `func` may change bindings
			reduce [do code  code  sources  reduce sources  copy []]
		:r
	]

	set 'lazy make op! func [
		"Define a lazy relation that gets recomputed only when one of it's sources change in value"
		'target  [set-word!] "Target to set"			;@@ paths don't work - see #3179
		code     [block!] "Formula to compute target value (sources are determined automatically)"
	][
		formula auto (target) code
	]
]

; a: object [
; 	x: 1
; 	y: 2
; 	formula [x y] z: [print "computing" wait 1 probe x * y]
; ]

; b: object [
; 	x: lazy [a/x * 2]				;@@ should be x: [x: a/x] [x * 2] ?
; 	y: lazy [a/x * x]
; 	z: lazy [x + y * a/z]
; 	w: lazy [probe now/time]
; 	v: lazy [mold w]
; 	formula [a/x + a/y] u: [? a]
; ]

; ? a
; a/z
; probe b/z

#include %clock.red

a0: object [x: 1]
a1: object [x: lazy [a0/x + a0/x]]
a2: object [x: lazy [a1/x + a1/x]]
a3: object [x: lazy [a2/x + a2/x]]
a4: object [x: lazy [a3/x + a3/x]]
a5: object [x: lazy [a4/x + a4/x]]
a6: object [x: lazy [a5/x + a5/x]]
a7: object [x: lazy [a6/x + a6/x]]
a8: object [x: lazy [a7/x + a7/x]]
a9: object [x: lazy [a8/x + a8/x]]

b0: object [x: 1]
b1: object [x: does [b0/x + b0/x]]
b2: object [x: does [b1/x + b1/x]]
b3: object [x: does [b2/x + b2/x]]
b4: object [x: does [b3/x + b3/x]]
b5: object [x: does [b4/x + b4/x]]
b6: object [x: does [b5/x + b5/x]]
b7: object [x: does [b6/x + b6/x]]
b8: object [x: does [b7/x + b7/x]]
b9: object [x: does [b8/x + b8/x]]

c0: reactor [x: 1]
c1: reactor [x: 0 react [self/x: c0/x + c0/x]]
c2: reactor [x: 0 react [self/x: c1/x + c1/x]]
c3: reactor [x: 0 react [self/x: c2/x + c2/x]]
c4: reactor [x: 0 react [self/x: c3/x + c3/x]]
c5: reactor [x: 0 react [self/x: c4/x + c4/x]]
c6: reactor [x: 0 react [self/x: c5/x + c5/x]]
c7: reactor [x: 0 react [self/x: c6/x + c6/x]]
c8: reactor [x: 0 react [self/x: c7/x + c7/x]]
c9: reactor [x: 0 react [self/x: c8/x + c8/x]]


d: [
	translate 10x10
	text 290x-2 "200μs"
	text 290x148 "100μs"
	text 290x285 "0μs"
	pen blue  text 20x50 "full tree recomputation on read"
	pen red   text 20x65 "lazy tree recomputation on read"
	pen green text 20x80 "branch update on write (reactivity.red)"
	text 90x315 "# reactions fired"
	pen magenta text 90x15 "# dependencies"
	pen gray rotate -90 [text -240x270 "time per single read/write"]
	shape [
		move 300x0
		'hline 10
		'move -10x30
		'hline 10
		'move -10x30
		'hline 10
		'move -10x30
		'hline 10
		'move -10x30
		'hline 10
		'move -10x30
		'hline 10
		'move -10x30
		'hline 10
		'move -10x30
		'hline 10
		'move -10x30
		'hline 10
		'move -10x30
		'hline 10
		'move -10x30
		'hline 10
	]
]

foreach s [a b c] [
	xy0: none
	clr: select [a red b blue c green] s
	repeat i 10 [
		o: get to word! rejoin [s i - 1]
		t: 0:0 n: 0
		if s = 'c [i: 11 - i]
		code: copy/deep pick [
			[loop 1000 [o/x]]
			[loop 1000 [o/x: 1]]
		] s <> 'c
		while [t < 0:0:0.05] [
			t: t + dt code
			n: n + 1000
		]
		t: t / n
		xy: as-pair i - 1 * 30 y: 1.0 - (t/second / 2e-4) * 300
		repend d ['pen clr 'line any [xy0 xy] xy]
		repend d ['pen magenta 'text xy * 1x0 form 2 ** (i - 1)]
		repend d ['pen green 'text xy * 1x0 + 0x300 form (i - 1)]
		xy0: xy
	]
]

view [base white 330x350 draw d]
