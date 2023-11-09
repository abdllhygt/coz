Red [
	title:   "Second experiment on alternate (pull) reactivity"
	author:  @hiiamboris
	license: BSD-3
	notes: {
		This implementation is instrumentation-based.
		Also I decided not to include any triggers and recompute the value every time it's accessed.
		Previous benchmarks have shown that it makes sense up to a certain number of dependencies.
		
		Compared to the first (function-based) implementation of pull-react.red:
		+ We are no longer bound by functions, recomputation is transparent
		+ Can be used in View, as facet datatype does not change
		- Reactive code has to be wrapped in a `trace`, slowing interpreter down ~100x times!!!
		  (as can be seen from "function" (blue) graph comparison speed with pull-react.red)
		- The algorithm depends on word binding and can be cheated with `get in obj 'word`
		  It won't know the properly bound word as received by `get`, and will not recompute it
	}
]


; #include %assert.red
; #include %show-trace.red


lazy: reactive: none
context [
	catalog: make hash! []
	
	word-types!: make typeset! [word! get-word! lit-word!]
	
	reactive-tracer: function [
	    event  [word!]
	    code   [any-block! none!]
	    offset [integer!]
	    value  [any-type!]
	    ref    [any-type!]
	    frame  [pair!]
	    /local obj
	][
	    [fetch]
	    switch event [
	    	fetch [
	    		; print ["code:" mold/flat/part code 80 "value:" mold value]
	    		if find word-types! type? :value [
	    			if any-path? code [
		    			subpath: append/part clear as path! [] code offset
		    			if any [
		    				empty? subpath
		    				not object? set/any 'obj get/any subpath
		    			] [exit]
		    			value: bind value obj
	    			]
					if formula: select/same/skip catalog to word! value 2 [
						trace on						;-- compute dependencies if they're lazy too
						set value do formula
					]
		    	]
	    	]
	    ]
	]
	
	set 'lazy make op! func [
		[no-trace]
		"Define a lazy relation that gets recomputed only when one of it's sources change in value"
		'target  [set-word!] "Target to set"			;@@ paths don't work - see #3179
		code     [block!] "Formula to compute target value (sources are determined automatically)"
	][
		pos: any [find/same/skip catalog target 2  tail catalog]
		reduce/into [to word! target  code] pos
	]
	
	set 'reactive func [code [block!]] [
		do/trace code :reactive-tracer
	]
]

; reactive [
	; o: object [x: 1 y: 2 z: lazy [x + y] w: lazy [o/y * o/z]]
	; ?? o
	; print ["o/w:" o/w]
	; ?? o
	
	; a: object [
		; x: 1
		; y: 2
		; z: lazy [print "computing" wait 1 probe x * y]
	; ]
	
	; b: object [
		; x: lazy [a/x * 2]
		; y: lazy [a/x * x]
		; z: lazy [x + y * a/z]
		; w: lazy [probe now/time]
		; v: lazy [mold w]
		; u: lazy [also a/x + a/y ? a]
	; ]
	
	; ? a
	; a/z
	; ? a
	; probe b/z
	; probe b/v
	; ? b
; ]

#include %clock.red

reactive [
	
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
		pen blue  text 20x50 "function-based recomputation on read"
		pen red   text 20x65 "pull-reactive recomputation on read"
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
		cnt: 100
		xy0: none
		clr: select [a red b blue c green] s
		repeat i 10 [
			o: get to word! rejoin [s i - 1]
			t: 0:0 n: 0
			if s = 'c [i: 11 - i]
			code: copy/deep pick [
				[loop cnt [o/x]]
				[loop cnt [o/x: 1]]
			] s <> 'c
			while [t < 0:0:0.05] [
				t: t + dt code
				n: n + cnt
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
]