Red [
	title:   "MEDIAN mezzanine"
	purpose: "Simple sample median function"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {https://en.wikipedia.org/wiki/Median}
]


; #include %assert.red


median: function [
	"Return the sample median"
	sample [block! hash! vector!]
][
    sample: sort copy sample
    n: length? sample
    case [
    	odd? n [pick sample n + 1 / 2]
    	n = 0  [none]
    	'even  [(pick sample n / 2) + (pick sample n / 2 + 1) / 2]
    ]
]


#assert [
	none? median []
	3   = median [3]
	2.5 = median [2 3]
	2   = median [1 2 3]
	3   = median [2 3 4]
	3.5 = median [2 3 4 5]
	3.5 = median [5 3 4 2]
	3.5 = median [5 2 4 3]
	3.5 = median [5 3 4 -999]
]