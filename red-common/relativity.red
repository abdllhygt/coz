Red [
	title:   "Face coordinate systems translation mezzanines"
	author:  @hiiamboris
	license: 'BSD-3
	usage: {
		Scaling between DPI-aware logical coordinates (units) and real screen pixels:
			units-to-pixels 100
			units-to-pixels 100x100
			pixels-to-units 100
			pixels-to-units 100x100

		Translation:
			face-to-window point face			;) = point in window CS
			window-to-face point face			;) = point in face CS
			face-to-screen point face			;) = point in screen CS
			face-to-screen/real point face		;) = same, but scaled into real screen pixels
			screen-to-face point face			;) = point in face CS
			screen-to-face/real point face		;) = same, but takes point in real screen pixels
			face-to-face point face1 face2		;) = point belonging to face1, in face2 CS

		Helpers:
			window-of face          -- returns owning window face
			parent parent-of? face  -- checks if face belongs to parent
	}
	limitations: {
		`screen-to-face` and `face-to-screen` return wrong coordinates,
		because window's client area coordinates cannot be known without R/S
		In `face-to-face` these effects negate each other, so this one is correct.
	}
]


units-to-pixels: pixels-to-units: window-of: parent-of?:
face-to-window: window-to-face: face-to-screen: screen-to-face: face-to-face:
	does [do make error! "No View module!"]
	
if object? :system/view [								;-- CLI programs skip this
	context [
		dpi: any [attempt [system/view/metrics/dpi] 96]			;@@ temporary workaround for #4740
		ppd: dpi / 96.0	 						       			;-- pixels per (logical) dot = display scaling factor / 100%
		u2p:  func [x] [round/to x * ppd 1]						;-- units to pixels, one-dimensional
		u2p': func [x] [x * ppd]
		p2u:  func [x] [round/to x / ppd 1]						;-- pixels to units, one-dimensional
		p2u': func [x] [x / ppd]
	
		set 'units-to-pixels function [
			"Convert amount in virtual pixels into screen pixels"
			size [pair! point2D! integer! float!]
		][
			switch type?/word size [
				pair! [as-pair u2p size/x u2p size/y]
				point2D! [u2p' size]
				integer! float! [u2p size]
			]
		]
	
		;; should be careful here not to turn 1 into 0 (dangers of zero division, zero sized images..)
		;; does it make sense to clip the result at 1x1 (2D) and 1 (1D)?
		set 'pixels-to-units function [
			"Convert amount in screen pixels into virtual pixels"
			size [pair! point2D! integer!]
		][
			switch type?/word size [
				pair!    [as-pair p2u size/x p2u size/y]
				point2D! [p2u' size]
				integer! [p2u size]
			]
		]
	
		set 'window-of func [
			"Get the window object of FACE"
			face [object!]
		][
			while [all [face  'window <> face/type]] [face: face/parent]
			face
		]
	
		set 'parent-of? make op! func [
			"Checks if PA is a (probably deep) parent of FA"
			pa [object!]
			fa [object!]
		][
			while [fa: select fa 'parent] [if pa =? fa [return yes]]
			no
		]
	
		translate: func [
			"Translate coordinate XY between face FA and screen, using OP"
			xy [pair! point2D!]
			fa [object!]
			op [op!] ":+ for face-to-screen; :- for screen-to-face"
			/limit lim [word!] "Stop at this face type (default: 'screen)"
		][
			lim: any [lim 'screen]
			while [fa/type <> lim] [
				xy: xy op fa/offset
				fa: fa/parent
				#assert [fa "Face is not connected to window!"]
			]
			xy
		]
	
		set 'face-to-window func [
			"Translate a point XY in FACE space into window space"
			xy [pair! point2D!] face [object!]
		][
			translate/limit xy face :+ 'window
		]
	
		set 'window-to-face func [
			"Translate a point XY in window space into FACE space"
			xy [pair! point2D!] face [object!]
		][
			translate/limit xy face :- 'window
		]
	
		set 'face-to-screen func [
			"Translate a point in face space into screen space"
			xy [pair! point2D!] face [object!]
			/real "Translate to screen pixels (not scaled by DPI)"
		][
			xy: translate xy face :+
			if real [xy: units-to-pixels xy]
			xy
		]
	
		set 'screen-to-face func [
			"Translate a point in screen space into face space"
			xy [pair! point2D!] face [object!]
			/real "XY is in screen pixels (not scaled by DPI)"
		][
			if real [xy: pixels-to-units xy]
			translate xy face :-
		]
	
		set 'face-to-face func [
			"Translate a point XY from FACE1 space into FACE2 space"
			xy [pair! point2D!] face1 [object!] face2 [object!]
		][
			screen-to-face face-to-screen xy face1 face2
		]
	]
];if object? :system/view [
