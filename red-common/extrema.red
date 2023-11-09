Red [
	title:   "Extrema-related mezzanines"
	purpose: "Find minimum and maximum points over a series"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		There's a subtle distinction between "brute" versions and sort-based:
		- former will evaluate literal functions and use their result values, while latter won't
		- former will error out on incompatible types for min/max, while latter will group by type
		- former will mix pairs and tuples with integers, producing a complex scalar, latter will group by type
		- once NaN PR gets merged, former will return NaN if single NaN is present, latter will glitch
		
		But I guess the performance win is worth using sort (until these become routines)
	}
]

minmax-of: function [
	"Compute [min max] pair along XS"
	xs [block! hash! vector! image! binary! any-string!]
][
	x-: x+: first xs
	foreach x next xs [x-: min x- x  x+: max x+ x]
	reduce [x- x+]
]

minimum-of: maximum-of: none
context [
	;; these versions are usually 3-4 times slower
	brute-minimum-of: func [
		"Find minimum value among XS"
		xs [block! hash! vector! image! binary! any-string!]
	][
		x-: first xs
		foreach x next xs [x-: min x- x]
		x-
	]

	brute-maximum-of: func [
		"Find minimum value among XS"
		xs [block! hash! vector! image! binary! any-string!]
	][
		x+: first xs
		foreach x next xs [x+: max x+ x]
		x+
	]

	containers: object [
		block!:  make system/words/block!  50
		hash!:   make system/words/block!  50
		string!: make system/words/string! 50
		email!:  make system/words/string! 50
		file!:   make system/words/string! 50
		ref!:    make system/words/string! 50
		url!:    make system/words/string! 50
		binary!: make system/words/binary! 50
		;; not for image! and tag! - those should use the brute version
		;; not for vector! - since they are of incompatible types which are unknown
	]

	set 'minimum-of func [
		"Find minimum value among XS"
		xs [block! hash! vector! image! binary! any-string!]
	][
		either buf: select containers type?/word :xs [
			also first sort append buf xs
				clear buf
		][	brute-minimum-of xs
		]
	]

	set 'maximum-of func [
		"Find minimum value among XS"
		xs [block! hash! vector! image! binary! any-string!]
	][
		either buf: select containers type?/word :xs [
			also last sort append buf xs
				clear buf
		][	brute-maximum-of xs
		]
	]
]
