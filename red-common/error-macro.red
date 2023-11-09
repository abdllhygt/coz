Red [
	title:   "ERROR macro"
	purpose: "Shortcut for raising an error using string interpolation"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		`ERROR msg` gets expanded into `do make error! #composite msg`, so all composite's quirks apply
		Examples:
			ERROR "Unexpected spec format (mold spc)"
			ERROR "command (mold-part/flat code 30) failed with:^/(form/part output 100)"
			ERROR "Images are expected to be of equal size, got (im1/size) and (im2/size)"
	}
]


#include %composite.red									;-- doesn't make sense to include this file without #composite also

;; I'm intentionally not naming it `#error` or the macro may be silently ignored if it's not expanded
;; (due to many issues with the preprocessor)
#macro [
	p: 'ERROR
	(either "ERROR" == mold p/1 [p: []][p: [end skip]]) p		;@@ this idiocy is to make R2 accept only uppercase ERROR
	skip
] func [[manual] ss ee] [
	unless string? ss/2 [
		print form make error! form reduce [
			"ERROR macro expects a string! argument, not" mold copy/part ss/2 50
		]
	]
	remove ss
	insert ss [do make error! #composite]
	ss		;-- reprocess it again so it expands #composite
]
