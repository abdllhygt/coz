Red [
	title:   "FORMAT-NUMBER mezzanine"
	purpose: "Simple number formatter with the ability to control integer & fractional parts size"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		Use case: timestamps and other sort-friendly output
			For more advanced output see FORMAT-READABLE or Gregg's formatting repository
			
		Limitation:
			Does not round the incoming number, just truncates it
			(that would produce adverse effects in TIMESTAMP, e.g. 60 seconds when it's 59.9995)
	}
]

; #include %assert.red
#include %exponent-of.red


format-number: function [
	"Format a number"
	num      [number!]
	integral [integer!] "Minimal size of integral part (>0 to pad with zero, <0 to pad with space)"
	frac     [integer!] "Exact size of fractional part (0 to remove it, >0 to enforce it, <0 to only use it for non-integer numbers)"
][
	#assert [
		1.#inf <> absolute num
		not nan? num
	]
	frac: either integer? num [max 0 frac][absolute frac]	;-- support for int/float automatic distinction
	expo: any [exponent-of num  0]
	if percent? num [expo: expo + 2]
	;; form works between 1e-4 <= x < 1e16 for floats, < 1e13 for percent so 12 is the target
	digits: form absolute num * (10.0 ** (12 - expo))	;-- 10.0 (float) to avoid integer overflow here!
	remove find/last digits #"."
	if percent? num [take/last digits]					;-- temporarily remove the suffix
	if expo < -1 [insert/dup digits #"0" -1 - expo]		;-- zeroes after dot
	insert dot: skip digits 1 + expo #"."
	if 0 < n: (absolute integral) + 1 - index? dot [	;-- pad the integral part
		char: pick "0 " integral >= 0
		insert/dup digits char n
		dot: skip dot n
	]
	clear either frac > 0 [								;-- pad the fractional part
		dot: change dot #"."
		append/dup digits #"0" frac - length? dot
		skip dot frac
	][
		dot
	]
	if percent? num [append digits #"%"]
	if num < 0 [insert digits #"-"]
	digits
]

#assert [
	"0"                 = format-number 0 0 0
	"123"               = format-number 123 0 0
	"-123"              = format-number -123 0 0
	"123"               = format-number 123.456 0 0
	"123.4"             = format-number 123.456 0 1
	"123.45"            = format-number 123.456 0 2
	"123.456000"        = format-number 123.456 0 6
	"-123.456000"       = format-number -123.456 0 6
	".456000"           = format-number 0.456 0 6
	"-.456000"          = format-number -0.456 0 6
	"0.456000"          = format-number 0.456 1 6
	"-0.456000"         = format-number -0.456 1 6
	"000.456000"        = format-number 0.456 3 6
	"000.000000"        = format-number 0.000000456 3 6
	"000.0000004"       = format-number 0.000000456 3 7
	"000.000000456000"  = format-number 0.000000456 3 12
	"-000.000000456000" = format-number -0.000000456 3 12
	"0%"                = format-number 0% 0 0
	"123%"              = format-number 123% 0 0
	"-123%"             = format-number -123% 0 0
	"123%"              = format-number 123.456% 0 0
	"123.456000%"       = format-number 123.456% 0 6
	"000.000000%"       = format-number 0.000000456% 3 6
	"000.000000456000%" = format-number 0.000000456% 3 12
	"-000.000000456000%"= format-number -0.000000456% 3 12
]