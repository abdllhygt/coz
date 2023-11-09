Red [
	title:   "#embed-image macro"
	purpose: "Embed images into the script when compiling them"
	author:  @hiiamboris
	license: 'BSD-3
	usage: {
		img: #embed-image %my-image.png
		view [image img]
		...
	}
]

#macro [#embed-image skip] func [s e /local p x] [
	unless file? s/2 [print ["#embed-image expects a file! value, not" mold/flat/part s/2 100] return []]
	p: s/2
	if #"/" <> p/1 [									;-- prepend script location for relative paths
		insert p either rebol [							;-- assumes last argument is script's full pathname
			first split-path to-rebol-file last system/options/args
		][
			system/options/path
		]
	]
	x: select [%.jpeg 'jpeg %.jpg 'jpeg %.png 'png %.gif 'gif] suffix? p
	compose [load/as (read/binary p) (:x)]
]

