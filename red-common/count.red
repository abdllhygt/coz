Red [
	title:   "COUNT mezzanine"
	purpose: "Count occurences of an item in the series"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		It is FIND-based (for performance)
		Due to bugs in FIND, the result is different from using operators =/==/=?:
			>> count [1 1.0 1 1.0000000000000001] 1
			== 2          ;) find-version
			== 4          ;) operator-version
		OTOH, allows to count types/typesets!
	}
]


#include %assert.red
; #include %new-apply.red

count: function [
	"Count occurrences of value in series (using `=` by default)"
	series [series!]									;-- docstrings & arg names mirror FIND action
	value  [any-type!]
	/part "Limit the counting range"
		length [number! series!]
	/only "Treat series and typeset value arguments as single values"
	/case "Perform a case-sensitive search"
	/same {Use "same?" as comparator}
	/skip "Treat the series as fixed size records"
		size [integer!]
	; /reverse only complicates it - use /part instead
	;  also /reverse makes little sense since counting has no direction, while /part adds meaning of counting region
	; /any & /with - TBD in FIND
	; return: [integer!]
][
	n: 0
	reverse: negative? any [length 0] 
	either skip [										;-- /skip support doesn't work with the /tail trick
		while [series: find/:only/:case/:same/:part/:reverse/skip series :value length size] [
			n: n + 1
			series: system/words/skip series size
		]
	][
		while [series: find/:only/:case/:same/:part/:reverse/tail series :value length] [n: n + 1]
	]
	n
]


#assert [
	0 = count              [          ] 1
	3 = count              [1 1 1     ] 1 
	2 = count              [1 2 1     ] 1 
	3 = count              [1 2 3     ] integer! 
	2 = count/skip         [1 2 3 4   ] integer! 2 
	3 = count/skip         [1 2 3 4 5 ] integer! 2 
	0 = count/only         [1 2 3     ] integer! 
	1 = count/only  reduce [1 integer!] integer! 
	2 = count         next [1 2 3     ] integer! 
	; 1 = count/part    next [1 2 3     ] integer! -1		;@@ find is broken by this 
	; 3 = count/part    tail [1 2 3     ] integer! -10 	;@@ find is broken by this
	2 = count              [1 [1] 1   ] [1]
	1 = count/only         [1 [1] 1   ] [1]
]

