Red [
	title:   "TIMESTAMP mezzanine"
	purpose: "Ready-to-use and simple timestamp formatter for naming files"
	author:  @hiiamboris
	license: 'BSD-3
]


#include %stepwise-macro.red
#include %format-number.red

;@@ should it have a /utc refinement? if so, how will it work with /from?
timestamp: function [
	"Get date & time in a sort-friendly YYYYMMDD-hhmmss-mmm format"
	/from dt [date!] "Use provided date+time instead of the current"
][
	dt: any [dt now/precise]
	r: make string! 32									;-- 19 used chars + up to 13 trailing junk from dt/second
	foreach field [year month day hour minute second] [
		append r format-number dt/:field 2 -3
	]
	#stepwise [
		skip r 8  insert . "-"
		skip . 6  change . "-"
		skip . 3  clear .
	]
	r
]
