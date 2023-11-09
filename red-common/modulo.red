Red [
	title:   "Proper MODULO function"
	purpose: "Tired of waiting for it to be fixed in Red"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		Info about various definitions:
			https://en.wikipedia.org/wiki/Modulo_operation#Variants_of_the_definition
		
		What is `a mod 0`?
			https://math.stackexchange.com/questions/516251/why-is-n-mod-0-undefined/516270#516270
		there is not a single answer
		1) a mod 0 = a
			though it makes sense in ring theory, it's hardly practical or expected
			it seems more logical to me to think of `a mod 0` as `lim (a mod x) where x->+0`
			the lesser the x the lesser the result, so limit = +0
			so..
		2) a mod 0 = 0
			this is however nonstandard as it does not follow any definition on the web I could find
			plus, for `r: a mod x` we expect r >= 0 and r < x
			for n=0 this means an empty range [0,0) and there is no number that can satisfy it
			so..
		3) a mod 0 = NaN/error
			let the user deal with edge cases
			this is how the modulo below is implemented (error for both integer arguments, NaN otherwise)
	}
]


#include %hide-macro.red
#include %assert.red

modulo: //:  none
context [
	abs: :absolute
	positives!: make typeset! [char! tuple!]				;-- limited types (can't be negated)
	roundable!: make typeset! [float! time!]				;-- types that may be rounded

	set 'modulo function [
		"Returns a modulo R of A divided by B. Defaults to Euclidean definition of modulo (R >= 0)"
		a [number! char! pair! any-point! tuple! vector! time!]
		b [number! char! pair! any-point! tuple! vector! time!]
		/floor "Follow the Floored definition: sgn(R) = sgn(B)"
		/trunc "Follow the Truncated definition: sgn(R) = sgn(A)"
		/round "Round near-terminal results (e.g. near zero or near B) to zero"
		; return: [number! char! pair! tuple! vector! time!] "Same type as A"
	][
		#assert [not all [floor trunc] "/floor & /trunc are mutually exclusive"]

		r: a % b
		case [
			find positives! type? a [
				#assert [any [							;-- check allowed divisor combinations
					(type? a) = type? b					;-- tuple+tuple, char+char
					all [
						integer? b    					;-- require integer divisor otherwise
					    any [b > 0  not floor]			;-- >0 in case of Floor (R cannot be negative)
					]									;-- (=0 case triggers error on the 1st line)
				]]
			]
			trunc   []
			floor   [r: r + b % b]
			'euclid [|b|: abs b  r: r + |b| % b]
		]

		;; integral types just skip rounding
		;; in vectors we would have to round every item separately, which is inefficient, so we skip them too
		if all [round  find roundable! type? r] [		;-- force result to satisfy `0 <= abs(r) < abs(b)` equation
			|b|:  any [|b| abs b]
			|r|+|b|: |b| + abs r
			if any [
				|r|+|b| - |b| == |b|					;-- result is near b, as it turns into b with r+b-b
				|r|+|b| + |b| == (|b| * 2)				;-- result is near 0, as it gets lost by appending 2b
														;-- (r+2b=2b is more aggressive than r+b=b, for symmetry with r+b-b)
			][
				r: r * 0								;-- zero multiplication preserves the original type and sign (even zero sign)
			]
		]

		r
	]

	set '// make op! func [
		"Returns a modulo R of A divided by B, following Euclidean definition of it (R >= 0)"
		a [number! char! pair! any-point! tuple! vector! time!]
		b [number! char! pair! any-point! tuple! vector! time!]
		; return: [number! char! pair! any-point! tuple! vector! time!] "Same type as A"
	][
		modulo a b
	]
]

;@@ TODO: Linux and esp. ARM may produce different results for floats, and may need tests update

#hide [#assert [
	;; need a few values defined
	-1.3877787807814457e-17 =? -x: 0.15 - 0.05 - 0.1	;-- comes from some test on the internet IIRC
	 1.3877787807814457e-17 =? +x: 0 - -x
	-a: -1e-16											;-- just a few values near float/epsilon
	+a:  1e-16
	-b: -1e-17
	+b:  1e-17
	-c: -1e-18
	+c:  1e-18
	+max:  2147483647									;-- extreme integers
	-max: -2147483648
	 0.1 + -x =? +I:   0.09999999999999999				;-- results of adding epsilon to a value near 1
	-0.1 + +x =? -I:  -0.09999999999999999
	 0.1 + -a =? +IA:  0.09999999999999991
	-0.1 + +a =? -IA: -0.09999999999999991
	+a + 0.1 - 0.1 =? +a':  9.71445146547012e-17 		;-- FP rounding errors distort original small value
	-a - 0.1 + 0.1 =? -a': -9.71445146547012e-17 
	+b + 0.1 - 0.1 =? +b':  1.3877787807814457e-17 
	-b - 0.1 + 0.1 =? -b': -1.3877787807814457e-17 

	;  0.1 + -c =? +C:  0.09999999999999991
	; -0.1 + +c =? -C: -0.09999999999999991

	;; euclidean definition - always nonnegative
	+I   =? modulo -x  0.1            
	+I   =? modulo -x -0.1            
	+x   =? modulo +x  0.1            
	+x   =? modulo +x -0.1            

	+IA  =? modulo -a  0.1            
	+IA  =? modulo -a -0.1            
	+a'  =? modulo +a  0.1            		;-- gets distorted by addition/subtraction
	+a'  =? modulo +a -0.1            

	+I   =? modulo -b  0.1            
	+I   =? modulo -b -0.1            
	+b'  =? modulo +b  0.1            		;-- gets distorted by addition/subtraction
	+b'  =? modulo +b -0.1            

	0.0  =? modulo -c  0.1            		;-- small enough to disappear
	0.0  =? modulo -c -0.1            
	0.0  =? modulo +c  0.1            
	0.0  =? modulo +c -0.1            

	0.0  =? modulo/round -x  0.1      
	0.0  =? modulo/round -x -0.1      
	0.0  =? modulo/round +x  0.1      
	0.0  =? modulo/round +x -0.1      

	+IA  =? modulo/round -a  0.1      		;-- big enough not to get rounded
	+IA  =? modulo/round -a -0.1      
	+a'  =? modulo/round +a  0.1      
	+a'  =? modulo/round +a -0.1      

	0.0  =? modulo/round -b  0.1      
	0.0  =? modulo/round -b -0.1      
	0.0  =? modulo/round +b  0.1      
	0.0  =? modulo/round +b -0.1      

	0.0  =? modulo/round -c  0.1      
	0.0  =? modulo/round -c -0.1      
	0.0  =? modulo/round +c  0.1      
	0.0  =? modulo/round +c -0.1      


	;; floored definition - same sign as divisor
	+I   =? modulo/floor -x  0.1      
	-x   =? modulo/floor -x -0.1      
	+x   =? modulo/floor +x  0.1      
	-I   =? modulo/floor +x -0.1      

	+IA  =? modulo/floor -a  0.1      
	-a'  =? modulo/floor -a -0.1      
	+a'  =? modulo/floor +a  0.1      
	-IA  =? modulo/floor +a -0.1      

	+I   =? modulo/floor -b  0.1      
	-b'  =? modulo/floor -b -0.1      
	+b'  =? modulo/floor +b  0.1      
	-I   =? modulo/floor +b -0.1      

	 0.0 =? modulo/floor -c  0.1      
	-0.0 =? modulo/floor -c -0.1      		;-- =? (same?) allows to distinguish -0 from +0
	 0.0 =? modulo/floor +c  0.1      
	-0.0 =? modulo/floor +c -0.1      

	 0.0 =? modulo/floor/round -x  0.1
	-0.0 =? modulo/floor/round -x -0.1
	 0.0 =? modulo/floor/round +x  0.1
	-0.0 =? modulo/floor/round +x -0.1

	+IA  =? modulo/floor/round -a  0.1
	-a'  =? modulo/floor/round -a -0.1
	+a'  =? modulo/floor/round +a  0.1
	-IA  =? modulo/floor/round +a -0.1

	 0.0 =? modulo/floor/round -b  0.1
	-0.0 =? modulo/floor/round -b -0.1
	 0.0 =? modulo/floor/round +b  0.1
	-0.0 =? modulo/floor/round +b -0.1

	 0.0 =? modulo/floor/round -c  0.1
	-0.0 =? modulo/floor/round -c -0.1
	 0.0 =? modulo/floor/round +c  0.1
	-0.0 =? modulo/floor/round +c -0.1


	;; truncated definition - same sign as dividend
	-x   =? modulo/trunc -x  0.1      
	-x   =? modulo/trunc -x -0.1      
	+x   =? modulo/trunc +x  0.1      
	+x   =? modulo/trunc +x -0.1      

	-a   =? modulo/trunc -a  0.1      
	-a   =? modulo/trunc -a -0.1      
	+a   =? modulo/trunc +a  0.1      
	+a   =? modulo/trunc +a -0.1      

	-b   =? modulo/trunc -b  0.1      
	-b   =? modulo/trunc -b -0.1      
	+b   =? modulo/trunc +b  0.1      
	+b   =? modulo/trunc +b -0.1      

	-c   =? modulo/trunc -c  0.1      
	-c   =? modulo/trunc -c -0.1      
	+c   =? modulo/trunc +c  0.1      
	+c   =? modulo/trunc +c -0.1      

	-0.0 =? modulo/trunc/round -x  0.1
	-0.0 =? modulo/trunc/round -x -0.1
	 0.0 =? modulo/trunc/round +x  0.1
	 0.0 =? modulo/trunc/round +x -0.1

	-a   =? modulo/trunc/round -a  0.1
	-a   =? modulo/trunc/round -a -0.1
	+a   =? modulo/trunc/round +a  0.1
	+a   =? modulo/trunc/round +a -0.1

	-0.0 =? modulo/trunc/round -b  0.1
	-0.0 =? modulo/trunc/round -b -0.1
	 0.0 =? modulo/trunc/round +b  0.1
	 0.0 =? modulo/trunc/round +b -0.1

	-0.0 =? modulo/trunc/round -c  0.1
	-0.0 =? modulo/trunc/round -c -0.1
	 0.0 =? modulo/trunc/round +c  0.1
	 0.0 =? modulo/trunc/round +c -0.1


	;; integer tests
	   0 = modulo       1000  500

	 123 = modulo        123  500
	 123 = modulo        123 -500
	 377 = modulo       -123  500
	 377 = modulo       -123 -500

	 123 = modulo/floor  123  500
	-377 = modulo/floor  123 -500
	 377 = modulo/floor -123  500
	-123 = modulo/floor -123 -500

	 123 = modulo/trunc  123  500
	 123 = modulo/trunc  123 -500
	-123 = modulo/trunc -123  500
	-123 = modulo/trunc -123 -500

	  23 = modulo        123  50 
	  23 = modulo        123 -50 
	  27 = modulo       -123  50 
	  27 = modulo       -123 -50 

	  23 = modulo/floor  123  50 
	 -27 = modulo/floor  123 -50 
	  27 = modulo/floor -123  50 
	 -23 = modulo/floor -123 -50 

	  23 = modulo/trunc  123  50 
	  23 = modulo/trunc  123 -50 
	 -23 = modulo/trunc -123  50 
	 -23 = modulo/trunc -123 -50 

	2    =? modulo       -max  10		;-- extreme ints produce ints, not floats
	2    =? modulo       -max -10
	7    =? modulo       +max  10
	7    =? modulo       +max -10

	 2   =? modulo/floor -max  10
	-8   =? modulo/floor -max -10
	 7   =? modulo/floor +max  10
	-3   =? modulo/floor +max -10

	-8   =? modulo/trunc -max  10
	-8   =? modulo/trunc -max -10
	 7   =? modulo/trunc +max  10
	 7   =? modulo/trunc +max -10


	;; time tests
	 0:03:45 = modulo        1:23:45  0:10
	 0:03:45 = modulo        1:23:45 -0:10
	 0:06:15 = modulo       -1:23:45  0:10
	 0:06:15 = modulo       -1:23:45 -0:10

	 0:03:45 = modulo/floor  1:23:45  0:10
	-0:06:15 = modulo/floor  1:23:45 -0:10
	 0:06:15 = modulo/floor -1:23:45  0:10
	-0:03:45 = modulo/floor -1:23:45 -0:10

	 0:03:45 = modulo/trunc  1:23:45  0:10
	 0:03:45 = modulo/trunc  1:23:45 -0:10
	-0:03:45 = modulo/trunc -1:23:45  0:10
	-0:03:45 = modulo/trunc -1:23:45 -0:10


	;; vector tests
	vec: func [x][make vector! x]
	+v: vec[-4 -3 -2 -1 0 1 2 3 4]
	-v: (copy +v) * -1

	(vec[2 0 1 2 0 1 2 0 1])      = modulo        copy +v  3
	(vec[2 0 1 2 0 1 2 0 1])      = modulo        copy +v -3
	(vec[1 0 2 1 0 2 1 0 2])      = modulo        copy -v  3
	(vec[1 0 2 1 0 2 1 0 2])      = modulo        copy -v -3

	(vec[2 0 1 2 0 1 2 0 1])      = modulo/floor  copy +v  3
	(vec[1 0 2 1 0 2 1 0 2]) * -1 = modulo/floor  copy +v -3
	(vec[1 0 2 1 0 2 1 0 2])      = modulo/floor  copy -v  3
	(vec[2 0 1 2 0 1 2 0 1]) * -1 = modulo/floor  copy -v -3

	(vec[-1 0 -2 -1 0 1 2 0 1])   = modulo/trunc  copy +v  3
	(vec[-1 0 -2 -1 0 1 2 0 1])   = modulo/trunc  copy +v -3
	(vec[1 0 2 1 0 -1 -2 0 -1])   = modulo/trunc  copy -v  3
	(vec[1 0 2 1 0 -1 -2 0 -1])   = modulo/trunc  copy -v -3


	;; pair tests
	 2x4  = modulo        12x34  5x10 
	 2x4  = modulo        12x34 -5x10 
	 3x4  = modulo       -12x34  5x10 
	 3x4  = modulo       -12x34 -5x10 

	 2x4  = modulo/floor  12x34  5x10 
	-3x4  = modulo/floor  12x34 -5x10 
	 3x4  = modulo/floor -12x34  5x10 
	-2x4  = modulo/floor -12x34 -5x10 

	 2x4  = modulo/trunc  12x34  5x10 
	 2x4  = modulo/trunc  12x34 -5x10 
	-2x4  = modulo/trunc -12x34  5x10 
	-2x4  = modulo/trunc -12x34 -5x10 


	;; point tests
	( 2, 4) = modulo       ( 12, 34) ( 5, 10) 
	( 2, 4) = modulo       ( 12, 34) (-5, 10) 
	( 3, 4) = modulo       (-12, 34) ( 5, 10) 
	( 3, 4) = modulo       (-12, 34) (-5, 10) 

	( 2, 4) = modulo/floor ( 12, 34) ( 5, 10) 
	(-3, 4) = modulo/floor ( 12, 34) (-5, 10) 
	( 3, 4) = modulo/floor (-12, 34) ( 5, 10) 
	(-2, 4) = modulo/floor (-12, 34) (-5, 10) 

	( 2, 4) = modulo/trunc ( 12, 34) ( 5, 10) 
	( 2, 4) = modulo/trunc ( 12, 34) (-5, 10) 
	(-2, 4) = modulo/trunc (-12, 34) ( 5, 10) 
	(-2, 4) = modulo/trunc (-12, 34) (-5, 10) 


	;; positives tests
	23.34.56.7 = modulo       123.234.56.7 100
	23.34.56.7 = modulo/floor 123.234.56.7 100
	23.34.56.7 = modulo/trunc 123.234.56.7 100
	23.34.56.7 = modulo       123.234.56.7 -100	;-- allow negative divisor when result will be positive
	23.34.56.7 = modulo/trunc 123.234.56.7 -100

	23.34.56.7 = modulo       123.234.56.7 50.100.200.250
	23.34.56.7 = modulo/floor 123.234.56.7 50.100.200.250
	23.34.56.7 = modulo/trunc 123.234.56.7 50.100.200.250

	#"^A" = modulo       #"^I" #"^D"
	#"^A" = modulo/floor #"^I" #"^D"
	#"^A" = modulo/trunc #"^I" #"^D"
	#"^A" = modulo       #"^I" 4
	#"^A" = modulo/floor #"^I" 4
	#"^A" = modulo/trunc #"^I" 4
	#"^A" = modulo       #"^I" -4	;-- allow negative divisor when result will be positive
	#"^A" = modulo/trunc #"^I" -4
	   1  = modulo       9 #"^D"
	   1  = modulo/floor 9 #"^D"
	   1  = modulo/trunc 9 #"^D"

	;; terminal cases tests
	0    = modulo       123  1     
	0    = modulo/floor 123  1     
	0    = modulo/trunc 123  1     
	0.5  = modulo       12.5 1     
	0.5  = modulo       12.5 1.0   
	error? try [modulo       123 0]		;-- division by zero
	error? try [modulo/floor 123 0]
	error? try [modulo/trunc 123 0]
	nan?   modulo       123  0.0   		;-- qnan
	nan?   modulo/floor 123  0.0   
	nan?   modulo/trunc 123  0.0   
	nan?   modulo       12.5 0     
	nan?   modulo       12.5 0.0   
	nan?   modulo       123  1.#inf
	nan?   modulo/floor 123  1.#inf
	123 =  modulo/trunc 123  1.#inf
	nan?   modulo       123 -1.#inf
	nan?   modulo/floor 123 -1.#inf
	123 =  modulo/trunc 123 -1.#inf
	nan?   modulo       123  1.#nan
	nan?   modulo/floor 123  1.#nan
	nan?   modulo/trunc 123  1.#nan
]]