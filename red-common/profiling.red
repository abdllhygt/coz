Red [
	title:   "Inline profiling macros and functions"
	purpose: "Profile any runtime piece of code with ease"
	author:  @hiiamboris
	license: 'BSD-3
	usage: {
		Memo: (* *), ***, PROF/EACH, PROF/SHOW, PROF/RESET, PROF/MANUAL

		(* *) MACRO that silently collects stats of any code piece

			Wrap a part of your code with (* ... *) to profile it each time it is evaluated:
				loop 5 [
					print "some code"
				(*
					1 + 2
					append/dup [] 1 1000000
					recycle
					wait 0.01
				*)
					print "rest of the code"
				]
			Then call PROF/SHOW to see the stats:
				<5>      0%     0      ms           0 B [1 + 2]
				<5>     54%    93      ms  51'943'976 B [append/dup [] 1 1000000]
				<5>     35%    61      ms -25'166'638 B [recycle]
				<5>     11%    19      ms          46 B [wait 0.01]
			You can see that it was evaluated <5> times, total time spent in each expression, and what took more CPU or RAM.
			This macro is good for collecting stats on small operations, possibly in different parts of the code.


		*** MACRO that profiles each expression after it, and immediately shows the stats
		
			add `***` into any block to profile each expression after `***`:
				my-function [...][
					1 + 2
				***	append/dup [] 1 1000000			;) will print timings starting at this line
					recycle
					wait 0.01
				]
			It's fast to type and is good for quick performance analysis of complex operations,
			but will produce extensive output if iterated too many times.

		Both macros are wrappers around PROF/EACH and PROF/SHOW functions


		PROF/EACH [code]
			Profiles each expression while evaluating a block of code.
		
			Use /TIMES to profile synthetic code or code without side effects:
				>> prof/each/times [1 2 + 3 add 4 5] 999999
				<999999> 20%      .00071ms           0 B [1]
				<999999> 37%      .00127ms           0 B [2 + 3]
				<999999> 43%      .00147ms           0 B [add 4 5]

			Note: normally it returns the value of the last expression so it can be inlined,
			      but with /times it returns unset to reduce noise in the console.

			Units of measure:
				Time is displayed in milliseconds per iteration because:
				- sub-microseconds are beyond SHALLOW-TRACE resolution and only can be found in CLOCK mezz
				- less columns wasted for formatting, freeing space for code lines
				- output is nicely balanced around a central dot
				RAM is displayed in bytes per iteration because:
				- this aligns the column
				- bytes are integers so can be known precisely


		PROF/SHOW
			Shows all profiling stats collected so far.
			Called automatically by PROF/EACH unless it's used with /QUIET refinement.

		PROF/RESET
			Forgets all profiling stats collected so far.
			
		PROF/MANUAL/START 'marker 
		PROF/MANUAL/END 'marker
			Measures time elapsed between /start and /end calls in real code. Marker is usually a word identifying the scope.
			This is meant for global profiling of various complex aspects of the system.
			Single aspect may be spread across multiple functions, so a single marker is used to unify them.
			For example in Spaces I may run any test demo and using the profiling log analyze what parts need more optimization:
				<42>      0%      .121   ms       4'980 B process-event
				<40>      0%      .119   ms         528 B hovering
				<58>      1%      .23    ms       2'982 B timers
				<182>     0%      .041   ms         131 B invalidation
				<58>     95%    38       ms      16'587 B drawing
				<531>     0%      .0169  ms           2 B render
				<935>     0%      .01    ms          89 B cache
				<116>     0%      .062   ms         498 B list
				<58>      0%      .082   ms       2'468 B fps-meter
				<669>     1%      .041   ms           0 B deep-restore
				<70>      0%      .085   ms         293 B scrollable
				<10>      0%      .137   ms         484 B scroll-timer
				<119>     0%      .033   ms         271 B vscroll
				<20>      0%      .05    ms         356 B back-arrow
				<20>      0%      .05    ms         250 B back-page
				<20>      0%      .05    ms         310 B thumb
				<20>      0%     0       ms         278 B forth-page
				<20>      0%      .099   ms         334 B forth-arrow
				CPU load of profiled code: 77%
	}
]


#include %assert.red
#include %shallow-trace.red
#include %format-readable.red
#include %without-gc.red

; #macro [ahead word! '*** to end] func [[manual] s e] [	;-- [manual] to support macros inside of it ;@@ + workaround for #3554
#macro [p: word! :p '*** to end] func [[manual] s e] [	;-- [manual] to support macros inside of it ;@@ + workaround for #3554
	back clear change s reduce ['clock-each copy next s]
]

; #macro [ahead paren! into [ahead word! '* some [thru [ahead word! '*]]]] func [[manual] s e] [	-- this doesn't work in compiler (R2 parse)
#macro [
	p: paren! :p into [
		p: word! :p '* to end p: (p: back p) :p word! :p '* end
	]
] func [[manual] s e] [
	e: s/1
	if '* = pick e length? e [							;-- R2 compatibility headaches
		remove s
		remove back tail e
		insert s reduce ['prof/each/quiet to block! next e]
	]
	s
]

;@@ need to use tracer's EXPR event for /each profiling to descend into scopes!
clock-each: none
prof: context [
	;; data format: [marker [iteration-count total-time total-ram] ...] (can't use a map because marker is code (block))
	data:         make hash! 20
	
	;; stack of markers of currently entered into scopes (used by /manual)
	marker-stack: make block! 60
	
	;; memoized copied expression blocks (used by /each)
	expressions:  make hash! 60
	
	last-time:    none
	last-stats:   none

	reset: func ["Forget all collected profiling stats"] [
		clear data
		clear marker-stack
		clear expressions
		set [last-time last-stats] none
	]

	format-delta: function [
		"Number formatter used internally by PROF/EACH"
		delta [number!] dot-index [integer!]
	][
		s: case [
			nan?     delta ["NaN"]
			percent? delta [format-readable/size/clean   delta 0]
			'else          [format-readable/extend/clean delta]
		]
		dot: index? any [find s #"."  tail s]			;-- align the dot
		pad/left s dot-index - dot + length? s
	]

	ordered?: function [
		"Check if value1 comes before value2 in sort order"
		value1 [any-type!] value2 [any-type!]
	][
		value =? first sort reduce/into [:value1 :value2] clear []
	]
	
	;@@ get stats as a table (block)
	show: function [
		"Print all profiling stats collected so far" 
		/order column [word! block!] "Order output by one or more of: [count share time bytes marker]"
		/reverse "Reverse the output order"
		/header  "Output the column header"
	][
		if empty? data [exit]									;-- nothing to show
		width:   any [attempt [system/console/size/x - 43] 40]	;-- 42 = len(<999999> 99% 9'999.99999 ms 999'000'000 B )
		t-total: elapsed: 0:0									;-- collect totals first
		foreach [marker info] data [
			if marker [t-total: t-total + info/2]				;-- no need to count time between markers
			elapsed: elapsed + info/2
		]
		t-total: 1e3 * to float! t-total
		elapsed: 1e3 * to float! elapsed
		
		;; form a queue to sort it
		either column [
			queue: append clear [] data
			set [marker: info: count: time: bytes:] [1 2 1 2 3]
			foreach column compose [(column)] [
				#assert [find [count share time RAM marker] column]
				cmp: func [a b] switch column [
					count  [[a/:info/:count >= b/:info/:count]]
					time   [[(a/:info/:time  / a/:info/:count) >= (b/:info/:time  / b/:info/:count)]]
					bytes  [[(a/:info/:bytes / a/:info/:count) >= (b/:info/:bytes / b/:info/:count)]]
					share  [[a/:info/:time  >= b/:info/:time]]
					marker [[ordered? a/1 b/1]]			;-- ascending order here by default
				]
				sort/skip/compare/all queue 2 :cmp
			]
		][
			queue: data
		]
		if reverse [system/words/reverse/skip queue 2]
		
		if header [print "Count   Share    Time/Run         Bytes/Run    Marker"]
		foreach [marker info] queue [
			if marker = none [continue]							;-- no need to show the baseline or time between markers
			set [n: dt: ds:] info
			dt:     (1e3 * to float! dt) / n					;-- always switch to millisecs so bigger times stand out
			time:   pad format-delta dt 5 11					;-- 9'999.99999 ms: dot=5 total=11
			ram:    format-delta (round/to ds / n 1) 12			;-- 999'999'999 b: dot=12, total=11
			count:  pad mold to tag! n 9						;-- '<999999> ' iterations: total=9
			share:  pad format-delta 100% * dt * n / t-total 4 4	;-- '100%' = 4 chars total
			marker: system/tools/tracers/mold-part marker width
			print to string! reduce [count share " " time "ms " ram " B " marker]
		]
		if last-time [
			load: format-readable/size 100% * (t-total / elapsed) 2
			print ["CPU load of profiled code:" load]
		]
		exit													;-- no return value
	]

 	commit: function [marker [immediate! any-string! block!] dt [time!] "elapsed time" ds [integer!] "RAM change"] [
		same: block? marker
		either cell: select/skip/only/:same data marker 2 [
			change change change cell
				cell/1 + 1
				cell/2 + dt
				cell/3 + ds
		][
			reduce/into [marker cell: reduce [1 dt ds]] tail data
		]
		cell
	]
	
	manual: function [
		"Profile time between start and end (can be reentrant)"
		marker [immediate! any-string!] "ID token that should be same for start and end"
		/start /end
		/extern last-time last-stats
	][
		time: now/precise/utc
		
		either last-time [
			dt: difference time last-time
			ds: stats - last-stats
			commit last marker-stack dt ds				;-- commit last interval (no marker = unrelated code)
		][
			last-time:  time
			last-stats: stats
		]
		
		#assert [any [start end]]
		either start [
			append/only marker-stack :marker
		][
			#assert [marker = last marker-stack]
			take/last marker-stack
		]
		last-stats: stats
		last-time:  now/precise/utc						;-- repeat timestamp for more precision
	]

	set 'clock-each										;-- left for backward compatibility
	each: function [									;-- new interface: PROF/EACH
		"Display execution time of each expression in CODE"
		code [block!] "Evaluation result is only returned if N = 1"
		/times n [integer! float!] "Repeat the whole CODE N times (default: once); displayed time/RAM is per iteration"
		/quiet "Don't print anything, just save the results for later display via PROF/SHOW"
		/local result
	][
		n: to integer! any [n 1]
		code-copy: copy/deep code						;-- preserve the original code in case it changes during execution ;@@ copy maps too
		test-code: compose [#[none] #[none] (code)]		;-- need 2 no-ops to: (1) negate startup time of `shallow-trace`, (2) establish a baseline
		
		timer: func [result [any-type!] pos [block!]] [	;-- collects timing of each expression
			t2: now/utc/precise							;-- 2 time markers here - to minimize `timer` influence on timings
			s2: stats
			switch/default i: index? pos [
				2 []									;-- ignore startup-related 'none'
				3 [base: difference t2 t1]
			][
				code-pos: at head code i: i - 2			;-- use original (unique) code block+offset as marker
				unless expr: select/only/same/skip expressions code-pos 2 [
					expr: copy/part code-copy code-copy: at head code-copy i
					append/only append/only expressions code-pos expr
				]
				dt: max 0:0 (difference t2 t1) - base
				commit expr dt (s2 - s1)
			]
			s1: stats
			t1: now/utc/precise							;-- /utc is 2x faster
			:result
		]

		without-GC [
			loop n [									;-- profile the code
				s1: stats
				t1: now/utc/precise
				set/any 'result shallow-trace :timer test-code	;-- this may throw out of the profiler
			]
		]

		unless quiet [show/header reset]
		either n = 1 [:result][exit]					;-- result is needed for transparent profiling with `***` and `(* *)`
	]
	
]

; ; loop 10000 [(* 1 2 3 *)]
; loop 10 [(* wait 0.1 wait 0.01 wait 0.03 make [] 100000 *)]
; loop 100 [(* 1 2 3 wait 0.002 *)]
; prof/show
; prof/each/times [1] 10000

; prof/manual/start 'x
; wait 0.5
; prof/manual/start 'y
; wait 0.5
; prof/manual/start 'z
; wait 0.5
; prof/manual/end 'z
; prof/manual/end 'y
; wait 0.5
; prof/manual/end 'x
; prof/show

; prof/manual/start 'x
; prof/manual/start 'x
; wait 0.5
; prof/manual/end 'x
; wait 0.5
; prof/manual/end 'x
; prof/show

; loop 10000 [(* 1 2 3 continue 4 5 6 7 *) 2]
; probe 1
; prof/show
; halt

