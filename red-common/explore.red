Red [
	title:   "EXPLORE mezzanine"
	purpose: "Provides UI to interactively inspect a Red value in detail"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		Plan is to make it accept any complex Red value and let it find the best layout to display it.
		Throw something onto it and don't care.
		Current version only supports images!!!

		Some design ramblings:

		It should display the path to the value represented in a window (in the title?)

		Should somehow be embeddable into a side-by-side comparison layout used in the View test system
		For that, will require a refinement that will generate and return the layout only (to be added into a panel in a window)

		For complex values there are 2 rendering types: short/thumbnail and full (in a separate window)

		Hardest task here is to display a block of code with the ability to also explore each word's value
		(use Toomas's work for that)

		How to display values?
		These should be just molded:
			datatype! 
			unset! 
			none! 
			logic! 
			char! 
			integer! 
			issue! 
			path! 
			lit-path! 
			set-path! 
			get-path! 
			pair! 
			time! 
			money! 
			date! 

		Word is not just a symbol, it's also a binding
		it should be possible to see (on hover) and follow (on click) it's binding
		thus being able to deeply inspect function bodies, blocks
			word! 
			set-word! 
			lit-word! 
			get-word! 
			refinement! 
			? not sure if issue! deserves to be here - probably not

		Floats may require formatting? Or maybe not; then also molded (mold/all)
			float! 
			percent! 

		Mold/all?
			handle! 

		For strings it depends:
		short strings should be just molded;
		paragraphs require a text/base/area to display them formatted
		big multiline strings (e.g. >10 lines) should be considered "text" and allow opening a new window
		(or maybe allow that for paragraphs too?)
			string! 
		other stringy types should be immediate one-liners (though long; possibly wrapped into a few lines)
			tag! 
			file! 
			url! 
			email! 
			ref! 

		Hovering over should display the contains:
			typeset! 

		Any-func should be looked up in system/words
		then if it's a known native/whatever - just display it's name
		and when hovered/clicked - open it's source
		When unknown - show summary - num of args, code length, last expression(?)
		then when hovered/clicked - open it's source (for natives - use nsource? but this opens up a question of R/S codebase exploration..)
		Function bodies should be explorable as code
		also it makes sense to highlight differently bound words in different colors: one for global, one for func-local, others grouped by context
		e.g. `?? help-string` will output a body with lot of references to other functions
		to understand the code, how can you find out what those functions are? it's a total hell to do in console
			op! 
			function! 
			routine! 
			native! 
			action! 

		Block - try to find out if it's a table - when types of values are different but match 2+ columns set
		Each table cell should be explorable or not - applying same general by-type rules
		Normal linear blocks (esp if all value types are the same) - probably show as 1 column? or by 10 values in a row? (also explorable)
		this may depend on type too: blocks of images; blocks of bitsets; blocks of strings - a lot of room for heuristics
		If it's code (requires heuristics to know) - requires formatting, caret-to-word metrics, and tooltips/openable windows
				heuristics for code:
				- lots of words
				- small percentage of final values of logic/unset/datatype/any-func/typeset/bitset/any-object/image/event/port type - those not having lexical forms
				- not a table
				- known control flow constructs, used properly - very reliable marker; but not for one-liners
				- ......?
			block! 
			hash! 

		Paren is CODE; a small expression, but may contain explorable values - this is the hard part
		like functions, should highlight binding of words
			paren! 

		Vector is not explorable and not a table - arrange in 1 or 10 columns?
		Technically it can be a table - but hard to determine that (maybe find columns by repeatable patterns in value magnitude?)
			vector! 

		Object & map is a 2-column table; values all explorable. For map - keys too. Events - use accessors list.
			object! 
			error! 
			map! 
			event!

		Bitset will need 8-bit grouping; maybe visual form - b/w squares with bit numbers? or characters? or both?
		Arrange long bitset into multiple rows; possibly explorable if huge?? (e.g. unicode chars)
			bitset! 

		Binary: formatting is essential for >8digit values, explorable if big (same rules as for strings)
			binary! 

		Tuples - 3/4-tuples may be colors, should be displayed as a box of that color
			tuple! 

		Image - display thumbnail in lists, explore it in detail when clicked/hovered
		On thumbnail: info (size, has alpha or not)
		Alpha enabled images - diplay on checkered background
			image! 

		Not known yet:
			port! 

		One possibility is to add a 2-state or multi-state button that will toggle the meaning of blocks/bitsets,
		but esp. blocks - whether it's code/data, and maybe a way to control the number of columns
		heuristic then will only be used to guess the starting values
	}
]


#include %assert.red
#include %setters.red
#include %with.red
#include %xyloop.red
#include %relativity.red
#include %contrast-with.red

#include %clock.red
#include %clock-each.red
#include %do-queued-events.red
; do https://gitlab.com/hiiamboris/red-elastic-ui/-/raw/master/elasticity.red
; #include %..\red-elasticity\elasticity.red
; recycle/off

if object? :system/view [								;-- CLI programs skip this

;@@ TODO: make a routine out of this, or wait for `draw` to get nearest-neighbor scale method (will need a grid though)
;@@ should this be globally exported?
upscale: function [
	"Upscale an IMAGE by a ratio BY so that each pixel is identifiable"
	image [image!]
	by    [integer!] "> 1"
	/into "Specify a target image (else allocates a new one)"
		tgt [image!]
	/only "Specify a region to upscale (else the whole image)"
		from [pair!] "Offset (0x0 = no offset; left top corner)"
		size [pair!] "Size of the region"
][
	#assert [1 < by]
	box: [pen coal box 0x0 0x0]							;-- single pixel
	box/5: by * 1x1
	unless only [from: 0x0 size: image/size]

	cache: [0x0 1]										;-- somewhat faster having cache
	if any [cache/1 <> size cache/2 <> by] [			;-- build the skeleton
		repend clear cache [size by]
		xyloop xy size [
			append cache reduce [
				'fill-pen 0.0.0
				'translate xy - 1x1 * by
				box
			]
		]
	]

	i: 4
	xyloop xy size [									;-- fill it with the colors
		cache/:i: any [image/(from + xy) white]			;-- make absent pixels white
		i: i + 5
	]

	draw any [tgt size * by + 1] skip cache 2
]

context [
	by: make op! :as-pair

	curly: charset "{}"
	color-to-hex: func [c [tuple! none!]] [
		if c [replace/all form to binary! c curly ""]
	]

	zoom-factor?: function [
		"Determine the maximum zoom factor that allows to fit SRC-SIZE within DST-SIZE"
		src-size [pair!] dst-size [pair!]
	][
		min 1.0 * dst-size/x / max 1 src-size/x			;-- use the narrowest dimension
			1.0 * dst-size/y / max 1 src-size/y
	]

	fit-entirely: function [src-size [pair!] dst-size [pair!]] [
		src-size * zoom-factor? src-size dst-size
	]

	lens-zoom-factor: 5													;-- lower values generate too much latency
	max-zoomed-size: system/view/screens/1/size							;-- for zooming up to full screen; reduce to lessen RAM footprint
	calc-sizes: function [p [object!]] [
		unless im: p/data [return [0x0 0x0 1 1]]						;-- no image assigned? return dummy defaults
		min-zoom: 4														;-- if can't be zoomed to this ratio - needs a separate magnifier
		max-zoom: 20													;-- do not scale single pixel to the whole screen
		max-whole-size: min p/size max-zoomed-size
		fully-fit?: within? im/size * min-zoom 0x0 max-whole-size		;-- does the zoomed image fully fit?

		either fully-fit? [												;-- determine the final zoom ratio and "whole image" size
			zoom: min max-zoom to integer! zoom-factor? im/size max-whole-size
			#assert [zoom >= min-zoom]
			lens-sz: zoom * im/size + 1
			whole-sz: 0x0
		][
			zoom: lens-zoom-factor
			whole-sz: p/size * 2x1 / 3x1 - 0x35							;-- 35 for label + padding, otherwise 2/3 of width
			whole-sz: min im/size fit-entirely im/size whole-sz			;-- reduce `whole` to free the unused space and provide uniform scaling
			lens-sz: (p/size/x - whole-sz/x - 8) by whole-sz/y			;-- 8 for padding (can be 8-12 after rounding)
			lens-sz: max 0x200 lens-sz									;-- don't make the window too slim
			lens-sz: (min lens-sz / zoom im/size + 10x10) * zoom + 1	;-- align to full pixel boxes, but don't exceed the image dimensions (+ convenience margins)
		]
		lens-sz: min lens-sz max-zoomed-size							;-- don't let +1 borders exceed max allowed size
		reduce [lens-sz whole-sz zoom]
	]

	resize: function [p [object!] "panel"] [
		set [lens-sz: whole-sz: zoom:] calc-sizes p
		if fit?: 0x0 = whole-sz [
			if lens-sz <> p/lens/size [									;-- if magnifier was hidden and whole image now fits into the lens
				upscale/into p/data zoom p/canvas						;-- populate the lens with whole image's pixels
			]
			p/frame/offset: 0x0											;-- coordinates are relative to the image 0x0
		]
		maybe p/fit?: fit?
		do with p/lens [
			maybe size:  lens-sz
			maybe extra: zoom
		]
		do with p/whole [
			; maybe offset/x: lens-sz/x + 10							;@@ BUG #4454 :(
			maybe offset: (lens-sz/x + 10) by offset/y					;@@ workaround
			maybe size:  whole-sz
		]
		do with p/overlay [
			maybe extra: 1.0 * whole-sz/x / p/data/size/x
		]
		unless fit? with p/frame [										;-- re-aim the lens after resize, as frame size may change
			size: lens-sz / zoom
			aim-at p p/overlay size / 2 + offset * p/overlay/extra
		]
	]

	fnt: make font! [name: system/view/fonts/fixed size: 7 style: 'bold]		;-- font for coordinates in `draw`
	aim-at: function [panel [object!] fa [object!] "Lens or Overlay" ofs [pair! point2D!] "Pointer coordinate"] [
		if point2D? ofs [ofs: to pair! ofs]
		old: system/view/auto-sync?
		system/view/auto-sync?: no
		lens?:   fa =? panel/lens
		zoom:    fa/extra
		frame:   panel/frame
		img-ofs: ofs / zoom + 1 + either lens? [frame/offset][0x0]		;-- lens coords are relative to the frame
		dpi-ofs: pixels-to-units img-ofs								;-- face coords, useful in case image is a face shot
		txt-ofs: max 0x0 ofs - 60x12									;-- don't put text outside of the canvas
		txt-ofs: min txt-ofs fa/size - 60x40
		color-str: color-to-hex color: panel/data/:img-ofs

		box: []
		unless lens? [
			box: compose/deep [
				scale (zoom) (zoom) [
					box (frame/offset) (frame/offset + frame/size)
				]
			]
		]
		draw: compose [
			pen (contrast-with any [color white])
			fill-pen off  font fnt
			line (ofs * 1x0) (ofs/x by fa/size/y)		;-- draw the crosshair
			line (ofs * 0x1) (fa/size/x by ofs/y)
			(box)										;-- the box outline
			pen violet
			fill-pen 255.255.255.50
			box (txt-ofs) (txt-ofs + 50x40)				;-- background for the text
			text (txt-ofs)        (form img-ofs)		;-- and the coordinates
			text (txt-ofs + 0x16) (form dpi-ofs)
			text (txt-ofs + 0x30) (any [color-str ""])
		]
		change/only next fa/draw draw

		pl: panel/label
		pl/data: compose [								;-- duplicate the text in case it's invisible
			"offset:"       (img-ofs) 
			"  offset/dpi:" (dpi-ofs)
			"  color:"      (color)
		]
		;@@ BUG: #4778 - too much flicker! have to use static face
		; pl/size: 500x25  show pl							;-- enlarge before measuring! or will never be big enough
		; pl/size: size-text pl
		unless lens? [									;-- if aiming at the whole...
			attempt [show panel/overlay]				;-- update the overlay first, so it's less laggy!
			project panel								;-- update the lens
		]
		attempt [show panel]							;-- update the rest of the panel (`show` fails before on-created)
		system/view/auto-sync?: old
	]

	move-frame: function [panel [object!] center [pair! point2D!]] [
		panel/frame/offset: to pair! center - (panel/frame/size / 2)
	]

	aim: function [fa ev] [
		case/all [
			none? p: fa/parent           [exit]
			all [fa =? p/lens  ev/away?] [change/only next fa/draw [] exit]	;-- remove crosshair from the lens when away
			fa =? p/overlay [
				unless ev/down? [exit]									;-- no action on overlay with LMB up
				move-frame p ev/offset / fa/extra
			]
		]
		aim-at p fa ev/offset
	]

	project: function [panel [object!]] [
		do with panel [
			unless fit? [
				upscale/into/only data lens/extra panel/canvas frame/offset frame/size
				lens/draw: lens/draw									;-- force redraw
			]
		]
	]

	extend system/view/VID/styles [
		image-explorer: [
			default-actor: 'on-down
			template: [
				type:   'panel
				size:   600x300
				pane:   []
				frame:  object [offset: 0x0 size: 1x1]
				canvas: make image! max-zoomed-size		;-- where to project the zoomed image into
				fit?:   no								;-- true when no separate lens is visible
				label: lens: overlay: whole: none
			]
			init: [
				context with face copy/deep [
					panel: face
					do [
						label: make-face/offset/spec 'text 0x0 [500 no-wrap]	;@@ should be big enough until #4778 is fixed
						lens:  make-face/offset/spec 'base 0x25 [
							all-over on-over :aim
							draw [[image canvas 0x0]]
							extra 1												;-- holds zoom factor of the lens
						]
						overlay: make-face/spec 'base compose [
							(0.0.0.1 xor glass)									;-- not fully transparent - to receive mouse events
							all-over on-over :aim on-down :aim
							draw [[]]											;-- empty block helps `aim`
							extra 1												;-- holds zoom factor of the whole image
						]
						whole: make-face/offset 'base 0x25						;-- holds a static image that dramatically lowers the redraw time of the panel
						pane: reduce [label lens whole overlay]

						react [
							[panel/size panel/data]
							whole/image: panel/data
							resize panel										;-- image choice affects the size for we need to scale it uniformly
						]
						react [overlay/offset: whole/offset]
						react [overlay/size:   whole/size]
						size: as-pair
							max label/size/x whole/size/x + lens/size/x + 30
							lens/size/y + lens/offset/y						;@@ autoadjust the height for VID or not??
					]
				]
			]
		]
	]
]


explore: function [
	"Opens up a window to explore an image in detail (TODO: other types)"
	im [image!]
	/title txt [string!]
][
	window-sz: system/view/screens/1/size * 0.8					;-- do not make the window too big
	view/flags/options
		either function? :elastic
			[elastic compose [image-explorer (window-sz) data im #scale]]
			[compose [image-explorer (window-sz) data im]]
		'resize
		[
			text: any [txt rejoin ["Image size=" im/size]]
			actors: object [
				on-key-up: func [fa ev] [if ev/key = #"^[" [unview/only fa]]	;-- make it ESC-closable
			]
		]
]

; print 1
; explore to image! system/view/screens/1
; explore make image! 5x5 quit

];if object? :system/view [
