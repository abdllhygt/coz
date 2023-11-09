Red [
	title:   "Dichotomic search function"
	purpose: "Find root of a function with better than linear complexity"
	author:  @hiiamboris
	license: 'BSD-3
	usage: {
		*** SYNTAX ***
		
		SEARCH returns [x1 f(x1) x2 f(x2)] where x1..x2 bounds the segment where x is located such that F(x)=0
		ARRAY-SEARCH (wrapper on SEARCH) returns [x1 x2] where abs(x2-x1) is either 0 or 1
		
		>> ? search
			USAGE:
			     SEARCH 'word X1 X2 F
			
			DESCRIPTION: 
			     Iteratively narrow down segment X1..X2 while it contains F(x)=offset, return [X1 F(X1) X2 F(X2)] box. 
			     SEARCH is a function! value.
			
			ARGUMENTS:
			     'word        [word! set-word!] "X argument name for the F(x) function."
			     X1           [number!] {When both X1 and X2 are integers, treats X as discrete variable.}
			     X2           [number!] 
			     F            [block!] "Monotonic function F(x)."
			
			REFINEMENTS:
			     /for         => F(x) value to look for (default: 0).
			        offset       [number!] 
			     /range       => Minimally acceptable X1..X2 interval to stop the search (default: 0).
			        xrange       [number!] 
			     /error       => Minimally acceptable F(X1)..F(X2) interval to stop the search (default: 0).
			        frange       [number!] 
			     /limit       => Max number of allowed iterations (throws an error if doesn't converge within it, default: 100).
			        nmax         [integer!] 
			     /mode        => Use predefined [binary interp jump] or custom func [x1 f1 x2 f2] guessing algorithm (default: binary).
			        guess        [word! function!] 
			     /with        => Provide F(X1) and F(X2) if they are known.
			        F1           [number!] 
			        F2           [number!] 
		
		>> ? array-search
			USAGE:
			     ARRAY-SEARCH array value
			
			DESCRIPTION: 
			     Look for a smallest segment in a sorted array that contains value, return [X1 X2]. 
			     ARRAY-SEARCH is a function! value.
			
			ARGUMENTS:
			     array        [block! hash! vector!] 
			     value        [number!] 
			
			REFINEMENTS:
			     /mode        => Use predefined [binary interp jump] or custom func [x1 f1 x2 f2] guessing algorithm (default: binary).
			        guess        [word! function!] 
        
        
		*** EXAMPLES ***
		
		Example: searching for an analytic function F(x)=sin(x) root within [-2..1]:
			>> search/mode x: -2.0 1.0 [sin x] 'interp
			== [3.337434002681952e-27 0.0 3.337434002681952e-27 0.0]		;-- converged in 6 iterations
			>> search/mode x: -2.0 1.0 [sin x] 'binary
			== [-1.1102230246251565e-16 0.0 -1.1102230246251565e-16 0.0]	;-- converges in 54 iterations
		Note that both x1 & x2 have to be float! (or percent!) for functions with a continuous domain.
		
		Example: numeric computation of 'e' up to 1e-5 precision
		(searching for a value 1.0 of an analytic function F(x)=log-e(x) within [0.1 .. 5.0]):
			>> search/mode/range/for x: 0.1 5.0 [log-e x] 'binary 1e-5 1.0
			== [2.7182748794555662 0.9999974436012159 2.718284225463867 1.0000008818084054]
			>> 2.718284225463867 - 2.7182748794555662
			== 9.346008300603614e-6											;-- <= 1e-5
		
		Example: locating arbitrary point on a sorted array:
			>> array-search probe sort loop 10 [append [] random 100] 20
			[3 4 13 48 51 53 67 71 81 92]
			== [3 4]														;-- 20 is between 3rd(13) and 4th(48)
		Likewise you can define the function on array of any layout and use SEARCH
		
		Example: using APPLY to improve readability of a SEARCH call:
			apply 'search [HE: H- H+ HE2TWE /with on TW2 TW1 /for on TW /error on tolerance /mode on 'binary]
		Compare to the basic call where you've no idea what argument corresponds to what refinement:
			search/with/for/error/mode HE: H- H+ HE2TWE TW2 TW1 TW tolerance 'binary
	}
	notes: {
		Since it's a Red-level implementation it makes most sense for:
		- slow functions (like grid column width estimation, or disk/network reads)
		- big data sets (over thousands of items)
		
		Currently supported search modes:
		- binary (or bisection) - simplest, most robust
		  divides segment at its center until reaching a solution
		  http://web.archive.org/web/20230527222343/https://xlinux.nist.gov/dads/HTML/binarySearch.html
		  O(log(n)) complexity
		- interpolation (or false position method) - fastest when points are uniformly distributed
		  divides segment at linear approximation point until reaching a solution
		  http://web.archive.org/web/20230520012531/https://xlinux.nist.gov/dads//HTML/interpolationSearch.html
		  https://en.wikipedia.org/wiki/Regula_falsi
		  O(1) best case, O(log(log(n))) average case, O(n) worst case complexity
		  (worst case is smth like sin(x)^-10, on log(x) it is also worse than binary search)
		- jump - makes sense if getting F(x) forward is faster than backward
		  chops sqrt(n) parts off the segment's head, when close to the solution switches to linear traversal
		  jump mode doesn't need the right value F(X2), however the algorithm requires it to check the F(X2)-F(X1) range
		  so for this mode it is best to provide a big fake F(X2) value to search using /with refinement (e.g. infinity)
		  http://web.archive.org/web/20230516174547/https://xlinux.nist.gov/dads//HTML/jumpsearch.html
		  http://web.archive.org/web/20230528005556/https://www.baeldung.com/cs/jump-search-algorithm
		  O(sqrt(n)) complexity
		
		F(x) is required to be monotonic and is assumed to be strictly monotonic. So:
		- if F(x) contains multiple roots an arbitrary one can be returned, no guarantees
		- if F(x) picks from an array, array must be sorted
		F(x) doesn't have to intersect zero: in this case zero edge segment closest to F(x)=0 is returned.
		
		X is considered discrete if both X1 and X2 are integers. F(x) in this case will always receive integer X argument.
		
		It may return zero segment [X 0 X 0], esp. on discrete set.
		
		Search stops when:
		  - any of X and F intervals become less or equal than the allowed ranges
			one could formulate F so that it returns zero when reaching some threshold, 
			but this would distort the returned values of F(X1) and F(X2), which may be useful to the caller
		  - new X guess equals X1 or X2
		    this in particular avoids deadlock with /range=0 on discrete X
		
		Why it throws an error if it doesn't converge within given number of iterations?
			Because these search algorithms should be converging by design,
			otherwise it's either an error in the implementation or algorithm misapplication.
			Given that function F is expected to be slow, letting it run for too many iterations will freeze the program.
			If this freeze goes unchecked it goes repeated, causing sluggish behavior 
			and requiring one to debug the program to track down the source of the problem.
			Timely error message may just save this debugging effort by telling exactly what's wrong.
		
		Why add a /for refinement?
			Otherwise user has to manually offset returned F1 and F2, which is grunt work. 
		
		Other methods maybe to add (in the future):
		- Secant, Newton, Steffensen, Inverse interp, Fixed point iteration - https://en.wikipedia.org/wiki/Root-finding_algorithms
		- Illinois, Anderson-Bjorck, ITP - https://en.wikipedia.org/wiki/Regula_falsi#Improvements_in_regula_falsi
		- Ridder's - https://en.wikipedia.org/wiki/Ridders%27_method
		- Brent's and derivatives - https://en.wikipedia.org/wiki/Brent%27s_method
		How to generalize it to ternary or golden-ratio/fibonacci search, where we look not for zero but for an unknown extemum?
	}
]


#include %hide-macro.red	
#include %assert.red	
#include %advanced-function.red	
	
array-search: search: none
context [
	abs: :absolute
	
	;; useful when either array is big or when value is not present in it as is; also in tests
	set 'array-search function [
		"Look for a smallest segment in a sorted array that contains value, return [X1 X2]"
		array [block! hash! vector!]
		value [number!]
		/skip period: 1 [integer!] (period > 0) "Data record size (searches in 1st column)"
		/mode "Use predefined [binary interp jump] or custom func [x1 f1 x2 f2] guessing algorithm (default: binary)"
			guess [word! function!]
	][
		f:     pick [[array/:i] [array/(i - 1 * period + 1)]] period = 1
		n:     round/ceiling/to (length? array) / period 1		;-- round up because it may be not at 1st column
		found: search/for/:mode i: 1 n f value :guess
		i1:    found/1 - 1 * period + 1
		i2:    found/3 - 1 * period + 1
		head clear change change found i1 i2
	]
	
	set 'search function [
		"Iteratively narrow down segment X1..X2 while it contains F(x)=offset, return [X1 F(X1) X2 F(X2)] box"
		'word [word! set-word!] "X argument name for the F(x) function"
		X1    [number!] "When both X1 and X2 are integers, treats X as discrete variable"
		X2    [number!] (same? type? X1 type? X2)
		F     [block!]  "Monotonic function F(x)"
		/for   "F(x) value to look for (default: 0)"
			offset: 0 [number!]
		/range "Minimally acceptable X1..X2 interval to stop the search (default: 0)"
			xrange: 0 [number!] (xrange >= 0)
		/error "Minimally acceptable F(X1)..F(X2) interval to stop the search (default: 0)"
			frange: 0 [number!] (frange >= 0)
		/limit "Max number of allowed iterations (throws an error if doesn't converge within it, default: 100)"
			nmax: 100 [integer!] (nmax > 0)
		;; 'binary chosen for robustness, e.g. 'interp can't work with infinity at either side
		/mode "Use predefined [binary interp jump] or custom func [x1 f1 x2 f2] guessing algorithm (default: binary)"
			guess: 'binary [word! (find [binary interp jump] guess) function!]
		/with "Provide F(X1) and F(X2) if they are known"
			F1: (call-f X1) [number!] 
			F2: (call-f X2) [number!] 
	][
		;; special cases not handled by the general algorithm - for more robustness
		case [
			f1 == offset [return reduce [x1 f1 x1 f1]]				;-- zero is already found
			f2 == offset [return reduce [x2 f2 x2 f2]]
			same? sign? df1: f1 - offset sign? df2: f2 - offset [	;-- F(x) does not intersect zero
				return reduce pick [ [x2 f2 x2 f2] [x1 f1 x1 f1] ] (abs df1) > (abs df2) 
			]
		]
		
		discrete?: integer! = type: type? x1
		sign: sign? f2 - f1
		if word? :guess [
			if guess = 'jump [
				if type <> integer! [ERROR "Jump guessing mode is only applicable to discrete dataset"]
				step: max 1 to integer! sqrt abs x2 - x1
			]
			guess: get bind guess self
		]
		
		loop nmax + 1 [									;-- +1 to keep nmax meaning as "maximum _allowed_ iterations"
			either any [
				xrange >= abs x2 - x1
				frange >= abs f2 - f1					;-- this also ensures f1<>f2 for guess functions
			][
				return reduce [x1 f1 x2 f2]
			][
				fx: call-f x: guess x1 f1 x2 f2
				; print [to tag! i: 1 + any [i 0] x1 f1 ".." x2 f2 "->" x fx]
				if any [x == x1 x == x2] [return reduce [x1 f1 x2 f2]]	;-- avoid deadlock on discrete sets with xrange=0
				switch sign * sign? fx - offset [
					 1 [x2: x f2: fx]					;-- F(x) has the sign of F2(x), replaces it
					-1 [x1: x f1: fx]					;-- F(x) has the sign of F1(x), replaces it
					 0 [return reduce [x fx x fx]]		;-- found zero, may stop right here
				]
			]
		]
		ERROR "Search did not converge in (nmax) iterations for (mold :f)"	;-- too much precision will slow it down, better to error out
	]
	
	call-f: func [x] with :search [set word x do f]
	
	binary: func [x1 f1 x2 f2] with :search [to type x1 + x2 / 2] 
	
	;; slope = (f2-f1)/(x2-x1) = f2/(x2-x) = f1/(x1-x), so x = x2 - f2/slope = x1 - f1/slope
	;; x = x2 - f2*(x2-x1)/(f2-f1) = (x2f2-x2f1-x2f2+x1f2)/(f2-f1) = (x1f2-x2f1)/(f2-f1)
	;; constant case f1=f2 is handled by frange check in the search body
	interp: func [x1 f1 x2 f2 /local x] with :search [
		either discrete? [
			to type divide subtract f2 - offset * (x1 + 1) f1 - offset * x2 f2 - f1
		][
			divide subtract f2 - offset * x1 f1 - offset * x2 f2 - f1
		]
	] 
	
	;; only defined on discrete sets, so can fall back to +1 linear scanning
	jump:   func [x1 f1 x2 f2] with :search [
		either step < abs x2 - x1 [x1 + step][x1 + 1]
	]
]

#hide [#assert [
	[ 2  2] = array-search [-5 0 5] 0
	[ 1  2] = array-search [-5 1 5] 0
	[ 2  2] = array-search [-5 1 5] 1
	[ 2  2] = array-search [5 1 -5] 1
	[ 2  2] = array-search [5 1 -2 -5] 1
	[ 6  6] = array-search [-10 -8 -7 -7 -2 0 1 1 1 3 7 9] 0
	[ 5  5] = array-search [-10 -8 -7 -7 -2 0 1 1 1 3 7 9] -2
	[ 4  5] = array-search [-10 -8 -7 -7 -2 0 1 1 1 3 7 9] -3
	[ 4  5] = array-search/mode [-10 -8 -7 -7 -2 0 1 1 1 3 7 9] -3 'jump
	[ 4  5] = array-search/mode [-10 -8 -7 -7 -2 0 1 1 1 3 7 9] -3 'interp
	[ 8  9] = array-search [9 7 3 1 1 1 0 -2 -7 -7 -8 -10] -3
	[ 1  1] = array-search [-10 -8 -7 -7 -2 0 1 1 1 3 7 9] -11
	[ 1  1] = array-search/mode [-10 -8 -7 -7 -2 0 1 1 1 3 7 9] -10 'jump
	[ 1  1] = array-search/mode [-10 -8 -7 -7 -2 0 1 1 1 3 7 9] -11 'jump
	[ 1  1] = array-search/mode [-10 -8 -7 -7 -2 0 1 1 1 3 7 9] -10 'interp
	[ 1  1] = array-search/mode [-10 -8 -7 -7 -2 0 1 1 1 3 7 9] -11 'interp
	[12 12] = array-search [-10 -8 -7 -7 -2 0 1 1 1 3 7 9] 9
	[12 12] = array-search [-10 -8 -7 -7 -2 0 1 1 1 3 7 9] 10
	[ 6  6] = array-search [-10.3 -8.1 -7.9 -7.6 -2.2 0.0 0.01 0.1 3.2 7.1 9.8] 0
	[ 6  7] = array-search [-10.3 -8.1 -7.9 -7.6 -2.2 0.0 0.01 0.1 3.2 7.1 9.8] 1e-6
	[11 11] = array-search [-10.3 -8.1 -7.9 -7.6 -2.2 0.0 0.01 0.1 3.2 7.1 9.8] 1e6
	[11 11] = array-search [-10.3 -8.1 -7.9 -7.6 -2.2 0.0 0.01 0.1 3.2 7.1 9.8] 1e15	;-- near the limit of precision because of subtraction
	[ 1  1] = array-search [-10.3 -8.1 -7.9 -7.6 -2.2 0.0 0.01 0.1 3.2 7.1 9.8] -1e15	;-- near the limit of precision because of subtraction
	[ 2  3] = array-search/mode [1 2 3 4 5 6 7 8 9 10] 2.1 'interp		;-- should't be [2 10]
	[ 2  3] = array-search/mode [1 2 3 4 5 6 7 8 9 10] 2.9 'interp
	[ 3  3] = array-search/skip [5 a 1 b -2 c -5 d] 1 2
	[ 3  5] = array-search/skip [5 a 1 b -2 c -5 d] 0 2
	[ 5  5] = array-search/skip [5 a 1 b -2 c -5 d] -2 2
	[ 1  1] = array-search/skip [5 a 1 b -2 c -5 d] 6 2
	[ 7  7] = array-search/skip [5 a 1 b -2 c -5 d] -6 2
	[ 7  7] = array-search/skip [5 a 1 b -2 c -5  ] -6 2

	[ 3.337434002681952e-27  0.0  3.337434002681952e-27  0.0] = search/mode x: -2.0 1.0 [sin x] 'interp	;-- converges in 6 iterations
	[-1.1102230246251565e-16 0.0 -1.1102230246251565e-16 0.0] = search/mode x: -2.0 1.0 [sin x] 'binary	;-- converges in 54 iterations
	
	set [x1: _: x2: _:] search/mode/range/for x: 0.1 5.0 [log-e x] 'binary 1e-5 1.0
	x2 - x1 <= 1e-5
]]
 