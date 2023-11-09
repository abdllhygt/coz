Red [
	title:   "SCROLLPANEL style"
	purpose: "Provides automatic scrolling capability to a panel, until such is available out of the box"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		Use in place of PANEL. Scrollers will be shown automatically when it's contents grows big.
		Should be ElasticUI-friendly ;)
		No margins around the panel contents are supported yet (works in tight mode). Need margins?
	}
]


#include %setters.red
#include %do-atomic.red
#include %do-unseen.red
#include %relativity.red
; #include %show-trace.red

if object? :system/view [								;-- CLI programs skip this

context [
	by: make op! :as-pair
	
	update-total: function [panel] [
		if panel/updates <= 0 [exit]
		e: negate s: 99999x99999
		foreach face any [panel/pane []] [
			if all [
				face/offset
				face/visible?
				face/type <> 'scroller
			][
				s: min s face/offset
				e: max e face/offset + face/size
			]
		]
		if e/x < s/x [e: s]
		maybe panel/total: e - s
		; maybe panel/total: e - s + 1					;-- +1 for possible rounding errors during scrollbar positioning
		maybe panel/origin: 0x0 - s
		quietly panel/updates: 0
	]

	watched: make hash! 100
	watched?: func [face] [find/skip/same watched face 2]
	;; checks if pane was modified and updates `total` and creates reactions for all inner faces
	check-pane: function [panel] [
		;; scrollers should be on top, so should always be the last
		hsc: panel/hsc  vsc: panel/vsc
		pane: panel/pane
		do-atomic [
			unless hsc =? pick tail pane -2 [
				take find/same pane hsc					;-- someone might have deleted the scrollbars :/
				append pane hsc
			]
			unless vsc =? last pane [
				take find/same pane vsc
				append pane vsc
			]
		]
		;; now create reactions
		foreach face any [pane []] [
			#assert [object? face]
			if face/type = 'scroller [continue]			;-- don't watch the scrollers
			unless pos: watched? face [pos: tail watched]
			if pos/2 =? panel [continue]				;-- don't make 2 reactions for 1 face!
			modified?: yes
			change change pos face panel
			react/link/later func [panel face] [		;-- don't do update-total for each face, do it only once
				[face/offset face/size]
				;@@ TODO: use react/unlink to remove reactions from the old panel when face moves from one into another
				if panel =? select face 'parent [panel/updates: 1 + select panel 'updates]
			] [panel face]
		]
		if modified? [
			panel/updates: panel/updates + 1
			update-total panel							;-- force an update since reactivity often skips it due to cycles
		 ]
	]

	;; determine scrollers positions, offsets, visibility based on panel/total and panel size
	check-size: function [panel [object!]] [
		hsc: panel/hsc  vsc: panel/vsc
		total: panel/total
		psize: panel/size
		; ?? total ?? psize
		hsize: psize * 1x0
		vsize: psize * 0x1
		if total/y >  psize/y            [vsize/x: 16]
		if total/x > (psize/x - vsize/x) [hsize/y: 16]
		if total/y > (psize/y - hsize/y) [vsize/x: 16]
		maybe hsc/offset: psize - hsize
		maybe vsc/offset: psize - vsize
		hsize/x: hsize/x - vsize/x
		vsize/y: vsize/y - hsize/y
		maybe hsc/size: hsize
		maybe vsc/size: vsize
		check-scrollers panel
		scroll panel
	]

	check-scrollers: function [panel [object!]] [
		hsc: panel/hsc  vsc: panel/vsc
		viewsize: panel/size - (vsc/size/x by hsc/size/y)
		maybe hsc/steps: 1.0 * maybe hsc/selected: min 100% 100% * viewsize/x / panel/total/x
		maybe vsc/steps: 1.0 * maybe vsc/selected: min 100% 100% * viewsize/y / panel/total/y
	]

	;; offset inner faces according to scroller data and panel/total
	scroll: function [panel [object!]] [
		hsc: panel/hsc  vsc: panel/vsc
		hidden: max 0x0 panel/total - panel/size + (vsc/size/x by hsc/size/y)
		;@@ BUG: for some reasons scroller/data + selected goes out of [0..1] segment
		ox: hidden/x * max 0.0 min 1.0 hsc/data / (1.0 - hsc/selected)
		oy: hidden/y * max 0.0 min 1.0 vsc/data / (1.0 - vsc/selected)
		if hidden/x = 0 [ox: 0]
		if hidden/y = 0 [oy: 0]
		origin: ox by oy
		if 0x0 <> shift: origin - panel/origin [
			do-atomic [do-unseen [
				panel/updates: panel/updates + 1		;-- this adds a pending update-total and avoids every face/offset from triggering it
				foreach face panel/pane [
					if face/type <> 'scroller [
						; print ["MOVING" face/type "FROM" face/offset "BY" 0x0 - shift]
						face/offset: face/offset - shift
					]
				]
				panel/origin: origin
				; attempt [show panel]
			]]
		]
		;@@ reaction may have left untriggered due to cycle (how to avoid?):
		;@@ update-total -> /total change -> check-size -> scroll -> child/offset change -> update-total
	]

	scrollpanel?: function [face [object!]] [
		all [face/type = 'panel  select face 'scroll-to]
	]

	scroll-to-face: function [panel [object!] face [object!]] [
		hsc: panel/hsc  vsc: panel/vsc
		xy1: face-to-face 0x0       face panel
		xy2: face-to-face face/size face panel
		viewsize: panel/size - (vsc/size/x by hsc/size/y)
		if all [within? xy1 0x0 viewsize  within? xy2 0x0 viewsize] [exit]

		xy1': (max 0 min viewsize/x - face/size/x xy1/x)
		   by (max 0 min viewsize/y - face/size/y xy1/y)
		shift: xy1' - xy1
		hidden: max 0x0 panel/total - viewsize
		dx: 1.0 * shift/x / hidden/x * (1 - hsc/selected)
		dy: 1.0 * shift/y / hidden/y * (1 - vsc/selected)
		do-atomic [
			maybe hsc/data: max 0.0 min 1.0 hsc/data - dx		;@@ BUG: scroller/data won't work with `0`, only `0.0`
			maybe vsc/data: max 0.0 min 1.0 vsc/data - dy
			scroll panel
		]
	]

	scroller-actors: [
		on-change [
			do-atomic [scroll face/parent]			;-- don't trigger reactions or it'll re-enter `scroll` a lot of times!
			if f: attempt [:panel/actors/on-scroll] [f face/parent event]
			show face/parent
		]
		on-created [
			check-scrollers face/parent
		]		;@@ BUG workaround: scrollers don't remember `selected` facet set before their creation
	]

	sp-list: make hash! []								;-- registry of all scrollpanels - for faster event funcs

	extend system/view/VID/styles [
		scrollpanel: [
			default-actor: 'on-scroll
			template: [
				type: 'panel
				size: 100x100
				pane: []
				
				origin: 0x0
				total:  0x0
				updates: 0								;-- counter used to group multiple offset updates
				scroll-to: func ["Scroll to the FACE to make it visible" face [object!]] [
					scroll-to-face self face
				]
				hsc: make-face/spec/size 'scroller scroller-actors 2x1	;-- initial size to ensure the proper direction
				vsc: make-face/spec/size 'scroller scroller-actors 1x2
				repend pane [hsc vsc]
				append sp-list self
			]
			init: [
				context copy/deep [
					panel: face
					react [[panel/pane]             check-pane panel]
					react [[panel/size panel/total] check-size panel]		;-- size & total change may trigger scrollers update
					react [[panel/updates]          update-total panel]
				]
			]
		]
	]

	wrapping-panel-of: func [fa [object! none!]] [		;-- find the parent panel of the face
		while [fa] [
			if scrollpanel? fa [return fa]
			fa: fa/parent
		]
		none
	]

	;; scrolls to the face that received focus
	on-focus-handler: function [fa ev] [
		unless all [
			ev/type = 'focus							;-- skip other events
			panel: wrapping-panel-of fa/parent			;-- no related to scrollpanel
		] [return none]
		scroll-to-face panel fa
		'done
	]

	unless find/same system/view/handlers :on-focus-handler [
		insert-event-func 'on-focus-handler :on-focus-handler
	]

	wheel-handler: function [fa ev] [
		unless ev/type = 'wheel [return none]			;-- skip other events

		f2s: :face-to-screen
		ofs: f2s ev/offset fa
		foreach panel sp-list [							;-- find if offset is above any scrollpanel
			if within? ofs  f2s 0x0 panel  panel/size [found?: yes  break]
		]
		unless found? [return none]

		vsc: panel/vsc
		new: max 0.0
		     min 1.0 - vsc/selected
		     ev/picked * vsc/selected * -0.5 + vsc/data		;-- scroll by half-pages - good enough?
		if vsc/data <> new [
			vsc/data: new
			scroll panel
			show panel
		]
		'done
	]

	unless find/same system/view/handlers :wheel-handler [
		insert-event-func 'wheel-handler :wheel-handler
	]
]


; layout*: collect [
; 	keep [backdrop white]
; 	loop 5 [
; 		loop 5 [
; 			keep reduce [
; 				'base  40x40 + random 80x80  c: random white  white - c + 50
; 				ankx: random/only [#ignore-x #fix-x #fill-x #scale-x]
; 				anky: random/only [#ignore-y #fix-y #fill-y #scale-y]
; 				form reduce [ankx anky]
; 			]
; 		]
; 		keep 'return
; 	]
; ]

; layout*: compose/only [s: scrollpanel (layout*) 300x300 #scale]

; #include %..\red-view-test\elasticity.red

; view/no-wait/flags elastic layout* 'resize

; view/no-wait/flags elastic [p: scrollpanel 100x200 [b: base 200x150] #scale] 'resize
; view/flags probe [s: scrollpanel with [anchors: [scale scale]] 500x400 [t: base 500x400] react [probe t/size: face/size - 20]] 'resize
; view/flags probe elastic [s: scrollpanel 500x400 [t: base 500x400] #scale react [probe t/size: s/size - 20]] 'resize

];if object? :system/view [
 