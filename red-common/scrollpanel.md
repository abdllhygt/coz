# [SCROLLPANEL STYLE](scrollpanel.red)

Usage: as you would use normal `panel` face.

Here's a quick example from [scrollpanel-test](scrollpanel-test.red):
```
#include %scrollpanel.red

view [
	s: scrollpanel 700x700 [
		base 1000x10000 draw [
			fill-pen linear cyan 0.0 gold 0.5 magenta 1.0 0x0 500x500 reflect box 0x0 1000x10000
		]
	]
]
```
[Follow this link to open the GIF and see it](https://i.gyazo.com/00abe772d3dcd4ca6778dbf21f36fe64.gif)