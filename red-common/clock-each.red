Red [
	title:   "CLOCK-EACH mezzanine with baseline support"
	purpose: "Allows you to profile each expression in a block of code"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		Obsoleted by PROF/EACH (profiling.red)
		Left for backward compatibility
	}
	usage: {
		Embed inside your script to find what's causing the most delay:
		 >> clock-each [
				1 + 2
				append/dup [] 1 1000000
				recycle
				wait 0.01
			]
		<1>       0      ms           0 B [1 + 2]
		<1>      20      ms  33'555'392 B [append/dup [] 1 1000000]
		<1>      11.6    ms -33'260'184 B [recycle]
		<1>      23      ms           0 B [wait 0.01]
		Obviously the columns are:
		| #iterations       | RAM usage per iteration
		|      |            |             |                       |
		       | time per iteration       | expression

		Or simpler, add `***` into any block to profile each expression after `***`:
			my-function [...][
				1 + 2
			***	append/dup [] 1 1000000			;) will print timings starting at this line
				recycle
				wait 0.01
			]

		Use /times to profile synthetic code or code without side effects:
		 >> clock-each/times [
				wait 0.01
				wait 0.02
				wait 0.03
			] 10
		<10>     14.9    ms           0 B [wait 0.01]		;) note the OS timer resolution is ~15ms
		<10>     31      ms           0 B [wait 0.02]
		<10>     33      ms           0 B [wait 0.03]

		Units of measure:
			Time is displayed in milliseconds per iteration because:
			- sub-microseconds are usually beyond TRACE resolution and only can be found in CLOCK mezz
			- less columns wasted for formatting, frees up space for code lines
			- output is nicely balanced around a central dot, helps visually compare the results
			RAM is displayed in bytes per iteration because:
			- this aligns the column
			- bytes are integers so can be known precisely

		 >> clock-each/times [1 2 + 3 add 4 5] 1000000
		<1000000>    .0002 ms           0 B [1]
		<1000000>    .0004 ms           0 B [2 + 3]
		<1000000>    .00038ms           0 B [add 4 5]
	}
]

#include %profiling.red
