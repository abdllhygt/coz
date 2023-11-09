Red [
	title:   "QUANTIZE function"
	purpose: "Quantize a float sequence into rounded bits"
	author:  @hiiamboris
	license: 'BSD-3
]


; #include %assert.red

quantize: function [
	"Quantize a float sequence into rounded bits, minimizing the overall bias"
	sequence [vector! block!]
	/scale quant [number!] "Round to this value instead of 1"
	/floor "Ensure bias is never positive (i.e. final sum does not exceed the original sum, up to FP rounding error)"
][
	quant:  any [quant 1]								;@@ use 'default'
	result: make block! n: length? sequence
	error:  0											;-- accumulated rounding error is added to next value
	repeat i n [
		append result hit: round/to/:floor aim: sequence/:i + error quant
		error: aim - hit
	]
	result
]

#assert [
	[]          = quantize []
	[1]         = quantize [1.4]
	[2]         = quantize [1.6]
	[1]         = quantize/floor [1.9]
	[1.6]       = quantize/scale [1.69] 0.2
	[1.8]       = quantize/scale [1.71] 0.2
	[1.6]       = quantize/scale/floor [1.71] 0.2
	[1 2]       = quantize [1.4 1.4]
	[2 1]       = quantize [1.51 1.4]
	[1 1]       = quantize/floor [1.51 1.4]
	[1 2]       = quantize/floor [1.51 1.5]
	[160% 140%] = quantize/scale [1.51 1.5] 20%
]