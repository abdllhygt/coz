Red [
	title:   "HSL/RGB conversions"
	purpose: "Reliable statistically neutral conversion between common color models"
	author:  @hiiamboris
	license: 'BSD-3
	TODO:    {HSV, HSI does anyone use these?}
]


; #include %assert.red
; #include %hide-macro.red

;@@ consider moving these out into another module
;; these are designed to be statistically neutral:
;; 0/255    1/255    2/255     ..       253/255      254/255      255/255 <- [0,1]
;; ^        ^        ^         ..             ^            ^            ^ <- how byte range maps into [0,1]
;; 0        1        2         ..           253          254          255 <- byte range
;; ^^^^^^^^ ^^^^^^^^ ^^^^^^^^  ..  ^^^^^^^^^^^^ ^^^^^^^^^^^^ ^^^^^^^^^^^^ <- how [0,1] maps into byte range
;; 0..1/256 1..2/256 2..3/256  ..  253..254/256 254..255/256 255..256/256 <- [0,1]
;; so each 1/256th inteval during roundtrip conversion collapses into a point in the same interval
;; this point's offset within the inteval is (N-1)/(255*256) where N is the interval number 1-256
;; but most importantly 0 maps to 0 and 1 to 1, to have pure black/white colors during color conversion
to-byte: function [
	"Convert VALUE from [0,1] range into a byte [0..255]"
	value [number!]
][
	to integer! value * 255.999'999'999'999				;-- 256 would round contested values up
]
from-byte: function [
	"Convert byte value [0..255] into [0,1] range"
	value [integer!]
][
	value / 255
]

#hide [
	#assert [
		do [
			#include %map-each.red
			; sample: map-each i 10000 [i / 10000]				;-- slow test
			sample: map-each i 100 [i / 100]
			sum1:  sum sample
			loop  1 [map-each/self x sample [from-byte to-byte x]]
			sum2:  sum sample
			loop 10 [map-each/self x sample [from-byte to-byte x]]
			sum3:  sum sample
			error: (absolute sum1 - sum2)
			; ?? [sum1 sum2 sum3 error]
		]
		error <= 0.05									;-- initial error should be small on uniform sample
		sum2 == sum3									;-- no additional error should be introduced by subsequent conversions
	]
]


;; https://en.wikipedia.org/wiki/HSL_and_HSV#Color_conversion_formulae
RGB2HSL: function [
	"Convert colors from RGB into HSL color model"
	; RGB [block! (parse RGB [3 number!]) tuple!] "0-1 each if block"
	RGB [block! tuple!] "0-1 each if block"
	/tuple "Return as a 3-tuple"
][
	if tuple? RGB [RGB: reduce [from-byte RGB/1 from-byte RGB/2 from-byte RGB/3]]	;@@ use map-each
	set [R: G: B:] RGB
	X+: max max R G B									;-- max of channels = value
	X-: min min R G B									;-- min of channels
	C:  X+ - X-											;-- chroma
	L:  X+ + X- / 2										;-- lightness
	S:  either C = 0 [0.0][C / 2 / min L 1 - L]			;-- saturation
	H:  60 * case [										;-- hue
		C  =  0 [0.0]
		X+ == R [G - B / C // 6]
		X+ == G [B - R / C +  2]
		X+ == B [r - G / C +  4]
	]
	HSL: reduce [H S L]
	if tuple [
		forall HSL [HSL/1: to-byte HSL/1]				;@@ use map-each
		HSL: to tuple! HSL
	]
	HSL
]
HSL2RGB: function [
	"Convert colors from HSL into RGB color model"
	; HSL [block! (parse HSL [3 number!]) tuple!] "0-360 hue, 0-1 others if block"
	HSL [block! tuple!] "0-360 hue, 0-1 others if block"
	/tuple "Return as a 3-tuple"
][
	if tuple? HSL [HSL: reduce [from-byte HSL/1 from-byte HSL/2 from-byte HSL/3]]	;@@ use map-each
	set [H: S: L:] HSL
	H': H / 60
	C:  S * 2 * min L 1 - L								;-- chroma
	D:  L - (C / 2)										;-- darkest channel
	B:  C + D											;-- brightest channel
	M:  C * (1 - absolute H' % 2 - 1) + D				;-- middle channel
	RGB: reduce pick [
		[B M D] [M B D] [D B M] [D M B] [M D B] [B D M] [B M D]	;-- 7th=1th - for H=360 case
	] 1 + to integer! H'
	if tuple [
		forall RGB [RGB/1: to-byte RGB/1]				;@@ use map-each
		RGB: to tuple! RGB
	]
	RGB
]


#hide [#assert [
	~=: make op! func [a b] [							;-- account for byte rounding error
		all [
			0.3% >= absolute a/1 - b/1
			0.3% >= absolute a/2 - b/2
			0.3% >= absolute a/3 - b/3
		]
	]
  	[  0   0%   0%] ~= RGB2HSL 0.0.0
  	[  0   0% 100%] ~= RGB2HSL 255.255.255
  	[  0 100%  50%] ~= RGB2HSL 255.0.0
  	[120 100%  50%] ~= RGB2HSL 0.255.0
  	[240 100%  50%] ~= RGB2HSL 0.0.255
  	[ 60 100%  50%] ~= RGB2HSL 255.255.0
  	[180 100%  50%] ~= RGB2HSL 0.255.255
  	[300 100%  50%] ~= RGB2HSL 255.0.255
  	[  0   0%  75%] ~= RGB2HSL 191.191.191
  	[  0   0%  50%] ~= RGB2HSL 127.127.127
  	[  0 100%  25%] ~= RGB2HSL 127.0.0
  	[ 60 100%  25%] ~= RGB2HSL 127.127.0
  	[120 100%  25%] ~= RGB2HSL 0.127.0
  	[300 100%  25%] ~= RGB2HSL 127.0.127
  	[180 100%  25%] ~= RGB2HSL 0.127.127
  	[240 100%  25%] ~= RGB2HSL 0.0.127
]]
#assert [
  	(HSL2RGB/tuple [  0   0%   0%]) = 0.0.0
  	(HSL2RGB/tuple [  0   0% 100%]) = 255.255.255
  	(HSL2RGB/tuple [  0 100%  50%]) = 255.0.0
  	(HSL2RGB/tuple [120 100%  50%]) = 0.255.0
  	(HSL2RGB/tuple [240 100%  50%]) = 0.0.255
  	(HSL2RGB/tuple [ 60 100%  50%]) = 255.255.0
  	(HSL2RGB/tuple [180 100%  50%]) = 0.255.255
  	(HSL2RGB/tuple [300 100%  50%]) = 255.0.255
  	(HSL2RGB/tuple [  0   0%  75%]) = 191.191.191
  	(HSL2RGB/tuple [  0   0%  50%]) = 127.127.127
  	(HSL2RGB/tuple [  0 100%  25%]) = 127.0.0
  	(HSL2RGB/tuple [ 60 100%  25%]) = 127.127.0
  	(HSL2RGB/tuple [120 100%  25%]) = 0.127.0
  	(HSL2RGB/tuple [300 100%  25%]) = 127.0.127
  	(HSL2RGB/tuple [180 100%  25%]) = 0.127.127
  	(HSL2RGB/tuple [240 100%  25%]) = 0.0.127
  	
  	(HSL2RGB/tuple RGB2HSL 0.0.0      ) = 0.0.0      
  	(HSL2RGB/tuple RGB2HSL 255.255.255) = 255.255.255
  	(HSL2RGB/tuple RGB2HSL 255.0.0    ) = 255.0.0    
  	(HSL2RGB/tuple RGB2HSL 0.255.0    ) = 0.255.0    
  	(HSL2RGB/tuple RGB2HSL 0.0.255    ) = 0.0.255    
  	(HSL2RGB/tuple RGB2HSL 255.255.0  ) = 255.255.0  
  	(HSL2RGB/tuple RGB2HSL 0.255.255  ) = 0.255.255  
  	(HSL2RGB/tuple RGB2HSL 255.0.255  ) = 255.0.255  
  	(HSL2RGB/tuple RGB2HSL 191.191.191) = 191.191.191
  	(HSL2RGB/tuple RGB2HSL 128.128.128) = 128.128.128
  	(HSL2RGB/tuple RGB2HSL 128.0.0    ) = 128.0.0    
  	(HSL2RGB/tuple RGB2HSL 128.128.0  ) = 128.128.0  
  	(HSL2RGB/tuple RGB2HSL 0.128.0    ) = 0.128.0    
  	(HSL2RGB/tuple RGB2HSL 128.0.128  ) = 128.0.128  
  	(HSL2RGB/tuple RGB2HSL 0.128.128  ) = 0.128.128  
  	(HSL2RGB/tuple RGB2HSL 0.0.128    ) = 0.0.128    
]


brightness?: none
context [
	;; gamma (transfer function) comes from https://en.wikipedia.org/wiki/SRGB#Transformation
	gamma-inverse: func [c] [
		either (c: c / 255) <= 0.04045 [c / 12.92][c + 0.055 / 1.055 ** 2.4]
	]
	gamma: func [x] compose/deep [
		either x <= 0.0031308 [x * 12.92][x ** (1 / 2.4) * 1.055 - 0.055]
	]

	;; CIELab L* formula comes from https://stackoverflow.com/a/13558570 
	;; see also https://en.wikipedia.org/wiki/Relative_luminance#Relative_luminance_and_%22gamma_encoded%22_colorspaces
	;; grayscale example:  https://i.gyazo.com/bbdfa22004bc06ecd0cfa1a6276b784b.jpg
	set 'brightness? function [
		"Get brightness [0..1] of a color tuple as CIELAB achromatic luminance L*"
		color [tuple!]
	][
		gamma add add
			0.212655 * gamma-inverse color/1
			0.715158 * gamma-inverse color/2
			0.072187 * gamma-inverse color/3
	]
]

