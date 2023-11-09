Red [
	title:   "Leak checker"
	purpose: "Find words leaking from complex code"
	author:  @hiiamboris
	license: 'BSD-3
	usage: {
		do %leak-check.red
		leak-check [code...] -- will eval `code...` and print what's leaking
		
		Obviously if some branch is not covered during evaluation it can't be reported
		so the real task here is to ensure maximum coverage of called code
	}
]


leak-check: function [
	"Find words leaking from complex code"
	code [block!] "Will be evaluated"
][
	print ["checking" mold/flat/part code 70]			;-- to distinguish multiple checks
	old: values-of system/words
	also do code (
		new: values-of system/words
		repeat i length? words: words-of system/words [
			unless any [
				:old/:i =? :new/:i
				all [									;-- newly loaded words
					i > length? old
					unset? :new/:i
				]
				all [									;@@ workaround for #5065
					any-function? :old/:i
					:old/:i = :new/:i
				]
			][
				w: pad words/:i 15
				s1: mold/flat/part :old/:i 30
				s2: mold/flat/part :new/:i 30
				print rejoin ["leak: "w"^-= "s1" -> "s2]
			]
		]
	)
]
