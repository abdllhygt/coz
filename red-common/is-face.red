Red [
	title:   "IS-FACE? mezzanine"
	purpose: "Reliable replacement for FACE? which doesn't work on user-defined faces"
	author:  [@hiiamboris @qtxie]
	license: 'BSD-3
]


; #include %map-each.red

is-face?: none
if object? :face! [										;-- for non-view-enabled builds
	context [
	
		set 'is-face? function [
		    "Test if VALUE is a face! instance"
		    value      "Value to test"
		    /alive     "Return TRUE only if the face has a low-level handle"
		    ; return:	[logic!]
		][
			to logic! all [
				object? :value
				any [
					(class-of value) = class-of face!
					all tests
				]
				any [
					not alive
					all [
						block? state: select value 'state
						handle? first state
					]
				]
			]
		]
	
		tests: map-each/eval w words-of face! [[
			'in bind 'value :is-face? to lit-word! w
		]]
	]
]

comment {
	this version is 2x faster but it allocates ~440 bytes per call!

	model: words-of face!
	set 'is-face? function [
	    "Test if VALUE is a face! instance"
	    value      "Value to test"
	    /alive     "Return TRUE only if the face has a low-level handle"
	    ; return:	[logic!]
	][
		to logic! all [
			object? :value
			any [
				(class-of value) = class-of face!
				find/match words-of value model			;@@ words-of allocates, unfortunately, ~400b per call
			]
			any [
				not alive
				all [
					block? state: select value 'state
					handle? first state
				]
			]
		]
	]

	
}