Red [
	title:   "XYLOOP loop"
	purpose: "Iterate over 2D area - image or just size"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		It's very similar to REPEAT, just 2-dimensional.
		Which makes me wonder if we should just extend REPEAT native?
		Or to even more unify loops, why not let FOREACH accept integers and pairs? See FOR-EACH for more info.

		Limitations:
			Diverts RETURN & EXIT. BREAK/CONTINUE are fully working.

		Examples:

			;; inspect an image somehow
			xyloop xy image [
				color: image/:xy
				print ["row=" xy/y "column=" xy/x "color=" color]
			]

			;; upscale an image
			xyloop xy image [
				append draw-upscaled compose/only [
					fill-pen (image/:xy)
					translate (xy - 1x1 * zoom-factor)
					(box)
				]
			]

			;; iterate over 3 images at once to produce an image difference mask
			xyloop xy diff/size [if i1/:xy = i2/:xy [diff/:xy: black]]
	}
]


;@@ BUG: diverts return and exit
xyloop: function [
	"Iterate over 2D series or size"
	'word	[word! set-word!]
	srs		[pair! image!]
	code	[block!]
][
	any [pair? srs  srs: srs/size]
	repeat i srs/y * w: srs/x compose [
		set word as-pair  i - 1 % w + 1  i - 1 / w + 1		;-- OMG those index magicks
		(code)
	]
]
