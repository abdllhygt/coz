Red [
	title:   "MODULO compliance plots"
	purpose: "Visually compare modulo implementation with Wikipedia"
	author:  @hiiamboris
	license: 'BSD-3
	note:    https://en.wikipedia.org/wiki/Modulo_operation
]


#include %modulo.red

~offset: 20x0
~size: 400x250
make-plot: func [flavor sign color shift /local ps] [
	ps: collect [
		i: -6.0 while [i <= 6.0][
			keep as-pair (~size/x / 12) * i (~size/x / 12) * do compose [(flavor) i 3 * sign]
			i: i + 0.05
		]
	]
	compose/deep [
		pen (color) line-width 1.5
		text (~offset: ~offset + 0x20) (rejoin [form flavor ", " either sign < 0 ["negative"]["positive"] " divisor"])
		translate (~size / 2 + shift) [scale 1 -1 [shape [line (ps) move (first ps)]]]
	]
]

view compose/deep [
	across
	base coal (~size) draw [
		pen white line (~size / 2 * 0x1) (~size / 1x2) line (~size / 2 * 1x0) (~size / 2x1)
		(make-plot [modulo/floor] 1  green 0x0)
		(make-plot [modulo/floor] -1 red   0x2)
	]
	(~offset: 20x0 [])
	base coal (~size) draw [
		pen white line (~size / 2 * 0x1) (~size / 1x2) line (~size / 2 * 1x0) (~size / 2x1)
		(make-plot [modulo/trunc] 1  green 0x0)
		(make-plot [modulo/trunc] -1 red   0x2)
	]
	(~offset: 20x0 [])
	base coal (~size) draw [
		pen white line (~size / 2 * 0x1) (~size / 1x2) line (~size / 2 * 1x0) (~size / 2x1)
		(make-plot [modulo] 1  green 0x0)
		(make-plot [modulo] -1 red   0x2)
	]
]
