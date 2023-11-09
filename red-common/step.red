Red [
	title:   "STEP function"
	purpose: "Increment/decrement long paths and values within a series"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		Summary...
		
		Compare:
		    step/by 'self/map/vscroll/offset 9x0
		vs: self/map/vscroll/offset: self/map/vscroll/offset + 9x0
		
		Also:
		    step/down at tail stack -2
		vs: change p: at tail stack -2 p/1 - 1
		or: change at tail stack -2 -1 + first at tail stack -2
		
		What is more readable and involves less repetition?
			
		For design chat see:
		https://gist.github.com/greggirwin/1f8c1a7f59b4d47cefd9267ae0ccb0af#gistcomment-4060922
	}
]

#include %hide-macro.red

step: none
context [
	ref-type!: union any-word! any-path!
	
	set 'step function [
		"Steps (increments) a value or series index by 1"
		target [any-word! any-path! block! hash! vector! binary! image!]
		      "Value referenced must be a series or scalar (incl. within a series)"
		/down "Reverse step direction (decrement)"
		/by   "Change by this amount, instead of 1"
			amount [integer! float! pair! percent! time! tuple! money!] ;-- = exclude [scalar!] [char! date!]
	][
		amount: any [amount 1]
		name:   either find ref-type! type? target [target]['target/1]
		value:  get name
		set name case [
			series?  :value [skip value amount * pick [-1  1 ] down]
			percent? :value [add  value amount * pick [-1% 1%] down]	;-- 1% to avoid /by
			down [:value - amount]										;-- `-` for tuples
			'up  [:value + amount]
		]
	]
]


#hide [#assert [
	x: 0
	1 = step 'x
	1 = x
	
	c: 10.20.30
	11.21.31 = step         'c
	10.20.30 = step/down    'c
	 0.10.20 = step/down/by 'c 10
	
	p: 90%
	91% = step         'p
	
	b: [k 3]
	4   = step         'b/k
	6   = step/by      'b/k 2
	3   = step/down/by 'b/k 3
	
	[3] = step 'b
	4   = step         b
	2   = step/by      b -2
	5   = step/down/by b -3
	
	b: [k [1 2 3]]
	[2 3] = step 'b/k
	3     = step b/k
]]
