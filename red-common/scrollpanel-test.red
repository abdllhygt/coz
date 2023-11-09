Red [
	title:   "SCROLLPANEL style demo"
	purpose: "Shows how to use the style"
	author:  @hiiamboris
	license: 'BSD-3
]

#include %scrollpanel.red

view [
	s: scrollpanel 600x600 [
		base 1000x10000 draw [
			fill-pen linear cyan 0.0 gold 0.5 magenta 1.0 0x0 500x500 reflect box 0x0 1000x10000
		]
	]
]
