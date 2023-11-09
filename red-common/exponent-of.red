Red [
	title:   "EXPONENT-OF helper function"
	purpose: "Used in number formatters"
	author:  @hiiamboris
	license: 'BSD-3
]

;; returns none for: zero (undefined exponent), +/-inf (overflow), NaN (undefined)
exponent-of: function [
	"Returns the exponent E of number X = m * (10 ** e), 1 <= m < 10"
	x [number!]
][
	attempt [to 1 round/floor log-10 absolute to float! x]
]
