Red [
	title:   "SPLIT function"
	purpose: "Generalized series splitting"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		Backward-compatible with native 170 LOC split implementation.
		Funny, but it's also twice faster than the native one
		(likely because it leverages Parse `to` rule optimization).
		
		Syntax:
			USAGE:
			     SPLIT series delimiter
			
			DESCRIPTION: 
			     SPLIT is a function! value.
			
			ARGUMENTS:
			     series       [series!] "Series to be split."
			     delimiter    [any-type!] {Use integer!/float! for parts of absolute, and percent! - of relative length.}
			
			REFINEMENTS:
			     /before      => Split before the delimiter.
			     /after       => Split after the delimiter.
			     /rule        => Treat delimiter as parse rule.
			     /slices      => Treat delimiter as a list of slices; also makes /rule keep matches instead.
			     /only        => Treat token as a single value when splitting any-block! series.
			     /case        => Use case sensitive comparison.
			     /same        => Use sameness comparison (incompatible with /rule).
			     /into        => 
			        result       [any-block!] "A buffer to write into."
		
		Supported splitting modes:
		1. By delimiter - used with /only or when delimiter is not a number! or any-function!
		2. By Parse rule - turned on by /rule (generally faster than by delimiter)
		3. Extraction of parts that match a Parse rule - use /rule/slices combo
		4. Into parts of equal length (possibly decimal)
		   - integer! or float! delimiter (> 0) specify length in chars
		   - percent! delimiter (> 0) specifies length as share of the total
		5. Into fixed number N of parts - use percent! delimiter, e.g.:
			>> split "123456" 100% / 3
			== ["12" "34" "56"]
		6. Into length as specified in a list - use /slices with a block, e.g.:
			>> split/slices "123456" [1 2 3]
			== ["1" "23" "456"]
			>> split/slices "123456" [1 1x1 2x1]	;) integer = length, pair = skip x length
			== ["1" "3" "6"]
	}
]

; #include %assert.red
#include %error-macro.red
#include %with.red

split: :system/words/split
splitting: context [
	skip?: func [series [series!]] [-1 + index? series]	;@@ split this out?
	by: make op! :as-pair								;@@ split this out?
	
	;@@ support true/false (slow) finders like :< ? unary finders like :odd? ?
	split-by-finder: function [
		series [series!]
		mode   [word!] ;(find [by around before after slice] mode)
		finder [any-function!] ;(2 = preprocessor/func-arity? spec-of :finder)
		result [any-block!]
	][
		#assert [2 = preprocessor/func-arity? spec-of :finder]
		if mode = 'before [bgn: 1]
		pos:   1
		range: 0x0
		
		state: make [] 2								;-- lets finder initialize itself
		while [range: finder at series pos: pos + range/2 state] switch mode [
			by     [[append result 0 by range/1 + pos]]
			after  [[append result 0 by range/2 + pos]]
			before [[append result bgn by bgn: pos + range/1]]
			around [[append append result 0 by range/1 + pos range + pos]]
			slice  [[append result range + pos]]
		]
		if mode = 'before [pos: bgn]
		
		if mode <> 'slice [append result as-pair pos 1 + length? series]
		forall result [result/1: copy/part series result/1]
		result
	]
	
	#hide [#assert [
		finder: function [s b] [all [p: find s ","  0x1 + offset? s p]]
		["abcdef"]                                    = split-by-finder   "abcdef"    'by     :finder []
		["a" "bc" "def"]                              = split-by-finder   "a,bc,def"  'by     :finder []
		["" "" "a" "bc" "def" ""]                     = split-by-finder ",,a,bc,def," 'by     :finder []
		["a" ",bc" ",def"]                            = split-by-finder   "a,bc,def"  'before :finder []
		["" "," ",a" ",bc" ",def" ","]                = split-by-finder ",,a,bc,def," 'before :finder []
		["a," "bc," "def"]                            = split-by-finder   "a,bc,def"  'after  :finder []
		["," "," "a," "bc," "def," ""]                = split-by-finder ",,a,bc,def," 'after  :finder []
		["a" "," "bc" "," "def"]                      = split-by-finder   "a,bc,def"  'around :finder []
		["" "," "" "," "a" "," "bc" "," "def" "," ""] = split-by-finder ",,a,bc,def," 'around :finder []
		["," ","]                                     = split-by-finder   "a,bc,def"  'slice  :finder []
		["," "," "," "," ","]                         = split-by-finder ",,a,bc,def," 'slice  :finder []
	]]
	
	split-by-rule: function [
		series [series!]
		mode   [word!] ;(find [by around before after] mode)
		rule   [series! char! bitset! datatype! typeset!]
		result [any-block!]
		/case
	][
		finder: [to rule delim: rule end:]
		keeper: switch mode [
			by     [ [keep (copy/part start delim) (start: end)] ]
			before [ [keep (copy/part start start: delim)] ]
			after  [ [keep (copy/part start start: end)] ]
			around [ [keep (copy/part start delim) keep (copy/part delim start: end)] ]
			slice  [ [keep (copy/part delim start: end)] ]
		]
		parse/:case series [
			collect after result [
				start: any [finder keeper] to end if (mode <> 'slice) keep (copy start)
			]
		]
		result
	]
	
	#assert [
		["abcdef"]                                    = split-by-rule   "abcdef"    'by     #"," []
		["a" "bc" "def"]                              = split-by-rule   "a,bc,def"  'by     #"," []
		["" "" "a" "bc" "def" ""]                     = split-by-rule ",,a,bc,def," 'by     #"," []
		["a" ",bc" ",def"]                            = split-by-rule   "a,bc,def"  'before #"," []
		["" "," ",a" ",bc" ",def" ","]                = split-by-rule ",,a,bc,def," 'before #"," []
		["a," "bc," "def"]                            = split-by-rule   "a,bc,def"  'after  #"," []
		["," "," "a," "bc," "def," ""]                = split-by-rule ",,a,bc,def," 'after  #"," []
		["a" "," "bc" "," "def"]                      = split-by-rule   "a,bc,def"  'around #"," []
		["" "," "" "," "a" "," "bc" "," "def" "," ""] = split-by-rule ",,a,bc,def," 'around #"," []
		["," ","]                                     = split-by-rule   "a,bc,def"  'slice  #"," []
		["," "," "," "," ","]                         = split-by-rule ",,a,bc,def," 'slice  #"," []
	]
	
	set 'split function [
		series    [series!]   "Series to be split"
		delimiter [any-type!] "Use integer!/float! for parts of absolute, and percent! - of relative length"
		; /by     "Exclude delimiter from results"
		/before "Split before the delimiter"
		/after  "Split after the delimiter"
		; /around "Split both before and after the delimiter"
		/rule   "Treat delimiter as parse rule"
		/slices "Treat delimiter as a list of slices; also makes /rule keep matches instead"
		/only   "Treat token as a single value when splitting any-block! series"
		/case   "Use case sensitive comparison"
		/same   "Use sameness comparison (incompatible with /rule)"
		/into result [any-block!] "A buffer to write into"
		;; incompatible refinements:
		;; /same and /rule - parse has no sameness check
		;; /case and /same - different modes
		;; /only and /rule - /only is only meaningful for normal delimiters ?
		;; /by /before /after /around /slices - different modes
		;; /slices w/o /rule and any of /only /case /same - they have no meaning for slice lengths
	][
		;@@ check refinements compatibility
		unless result   [result: make [] sqrt length? series]
		if tail? series [return append/only result copy series]
		mode: either slices ['slice][pick pick [[around before] [after by]] before after]
		any [
			if rule [
				if only [delimiter: reduce ['quote :delimiter]]
				split-by-rule/:case series mode :delimiter result
			]
			if slices [
				unless block? :delimiter [delimiter: reduce [:delimiter]]
				split-by-finder series 'slice :list-slicer result
			]
			unless only [
				switch type?/word :delimiter [
					integer! [									;-- parts of given fixed length
						if delimiter <= 0 [ERROR "Invalid part length: (delimiter)"]
						split-by-finder series 'by :integer-slicer result
					]
					float!										;-- parts of given fixed length
					percent! [									;-- parts of relative length
						if delimiter <= 0 [ERROR "Invalid part length: (delimiter)"]
						if percent? delimiter [delimiter: to float! delimiter * length? series]
						split-by-finder series 'by :float-slicer result
					]
					function! native! action! routine! [		;-- custom finder func
						split-by-finder series mode :delimiter result
					]
					op! [										;-- adjacent items comparator
						split-by-finder series 'by :op-slicer result
					]
				]
			]
			;; no type in switch above leads here too
			if any-string? series [								;-- parse splitting is faster for strings
				unless bitset? :delimiter [delimiter: form delimiter]
				split-by-rule/:case series mode :delimiter result
			]
			split-by-finder series mode :delimiter-slicer result
		]
		result
	]
	
	;; factory default finder functions...
	
	integer-slicer: function [pos [series!] state [block!] "unused"] with :split [
		if delimiter < length? pos [1x1 * delimiter]
	]
	
	;; state format:
	;;   1. integer! length added so far
	;;   2. integer! limit for end detection
	float-slicer: function [pos [series!] state [block!]] with :split [
		unless state/1 [
			n: round/ceiling/to n': (length? series) / delimiter 1
			if n' + 1 = n [n: n - 1]					;-- fix for rounding of epsilon (split "1234567890" 100% / 3 case)
			append append state 0 n 
		]
		;; flooring gives more expected results eg on split "12345" 1.5: ["1" "23" "4" "5"] vs ["12" "3" "45" ""]
		end: to integer! delimiter * state/1: state/1 + 1
		if state/1 < state/2 [1x1 * (end - skip? pos)]
	]
	
	op-slicer: function [pos [series!] state [block!] "unused"] with :split [
		end: next pos: next pos
		forall end [
			if :end/-2 delimiter :end/-1 [
				return 1x1 * offset? pos end
			]
		]
		none
	]
	
	;; state format: 1. delimiter length in source series
	delimiter-slicer: function [pos [series!] state [block!]] with :split [
		if bgn: find/:case/:same/:only pos :delimiter [
			unless state/1 [
				end: find/:case/:same/:only/match/tail bgn :delimiter
				append state offset? bgn end
			]
			0 by state/1 + offset? pos bgn
		]
	]
	
	list-slicer: function [pos [series!] state [block!] "unused" /extern delimiter] with :split [
		switch/default type?/word also range: :delimiter/1 delimiter: next delimiter [
			integer! [0 by range]						;-- just slice length
			pair!    [range/1 * 0x1 + range]			;-- slice begin and end
			none!    [none]								;-- range = none at list tail, terminating the search
		][												;-- single delimiter
			bgn: find/:only/:case/:same pos :delimiter
			end: find/:only/:case/:same/match bgn :delimiter
			(0 by offset? bgn end) + offset? pos bgn
		]
	]
]

#hide [#assert [
	upper!: charset [#"A" - #"Z"]
	
	;; split by fixed lengths
	error? try [split "12345"  0]
	error? try [split "12345" -1]
	error? try [split "12345"  0.0]
	error? try [split "12345" -0.1]
	error? try [split "12345"  0%]
	error? try [split "12345" -1%]
	["1" "2" "3" "4" "5"] = split "12345" 1
	["1" "2" "3" "4" "5"] = split "12345" 20%
	["1" "2" "3" "4" "5"] = split "12345" 1.0
	["1" "2" "3" "45"   ] = split "12345" 1.25			;-- 0 1.25 2.5 3.75 5(group)
	["1" "23"    "4" "5"] = split "12345" 1.5			;-- 0 1.5 3(group) 4.5 5
	["1" "23"    "4" "5"] = split "12345" 30%			;-- 0 1.5 3(group) 4.5 5
	["12"    "34"    "5"] = split "12345" 2
	["12"    "34"    "5"] = split "12345" 40%
	["12"    "345"      ] = split "12345" 2.5
	["12"    "345"      ] = split "12345" 50%
	["123"       "45"   ] = split "12345" 3
	["1234"          "5"] = split "12345" 4.0
	["12345"            ] = split "12345" 100%
	["12345"            ] = split "12345" 150%
	["" "" "1" "" "" "2" "" "" "3" "" "" "4" "" "" "5"] = split "12345" 1 / 3
	["" "1" "" "2" "" "3" "" "4" "" "5"] = split "12345" 1 / 2
	["" "1" "" "2" "" "3" "" "4" "" "5"] = split "12345" 1 / 2
	["" "1" "" "2" "" "3" "" "4" "" "5"] = split "12345" 10%
	["123" "456" "7890"]  = split "1234567890" 100% / 3	;-- a case prone to rounding issues
	
	;; split by delimiter
	["1"     "2"     "3"] = split              "1,2,3" #","
	["1"     "2"     "3"] = split              "1,2,3" charset ",."
	["1"     "2"     "3"] = split              "1,2,3" ","
	["1"    ",2"    ",3"] = split/before       "1,2,3" ","
	["1,"    "2,"    "3"] = split/after        "1,2,3" ","
	["1" "," "2" "," "3"] = split/before/after "1,2,3" ","
	["1"     "3"        ] = split              "1,2,3" ",2,"
	["1" "2" "3" ""     ] = split              "1,2,3," ","
	["1" "2" "3" "" ""  ] = split              "1,2,3,," ","
	["" "1" "2" "3"     ] = split              ",1,2,3" ","
	["" "" "1" "2" "3"  ] = split              ",,1,2,3" ","
	["a" "c" "e"        ] = split              "a<b>c<b>e" <b>
	[[a] [c] [e]        ] = split      [a <b> c <d> e] tag!
	[[a <b> c <d> e]    ] = split/only [a <b> c <d> e] tag!
	[[a] [c] [e]        ] = split      [a <b> c <d> e] any-string!
	[[a] [c] [e]        ] = split      [a - - c - - e] [- -]
	[[a] [c] [e]        ] = split/only [a [- -] c [- -] e] [- -]
	
	;; split by list; length of output = length of list
	["YYYY" "MM" "DD" "HH" "MM" "SS"] = split/slices "YYYYMMDD/HHMMSS"  [4 2 2 1x2 2 2]	
	["Mon" "24" "Nov" "1997"        ] = split/slices "Mon, 24 Nov 1997" [3 2x2 1x3 1x4]	
	
	;; split by rule; /slices makes it match instead of delimiting
	[[a] [c] [e]                  ] = split/rule              [a 1 2 c 3 4 e] [2 integer!]
	[[a] [1 2 c] [3 4 e]          ] = split/rule/before       [a 1 2 c 3 4 e] [2 integer!]
	[[a 1 2] [c 3 4] [e]          ] = split/rule/after        [a 1 2 c 3 4 e] [2 integer!]
	[[a] [1 2] [c] [3 4] [e]      ] = split/rule/before/after [a 1 2 c 3 4 e] [2 integer!]
	[[1 2] [3 4]                  ] = split/rule/slices       [a 1 2 c 3 4 e] [2 integer!]
	[[] [1 2] [3 4] []            ] = split/rule              [a 1 2 c 3 4 e] [word!]
	[[] [a 1 2] [c 3 4] [e]       ] = split/rule/before       [a 1 2 c 3 4 e] [word!]
	[[a] [1 2 c] [3 4 e] []       ] = split/rule/after        [a 1 2 c 3 4 e] [word!]
	[[] [a] [1 2] [c] [3 4] [e] []] = split/rule/before/after [a 1 2 c 3 4 e] [word!]
	[[a] [c] [e]                  ] = split/rule/slices       [a 1 2 c 3 4 e] [word!]
	[   "lets" "Hoard" "Some" "Camels"] = split/rule/slices "letsHoardSomeCamels" [skip [to upper! | to end]]
	[          "Hoard" "Some" "Camels"] = split/rule/slices "letsHoardSomeCamels" [upper! any [not upper! skip]]
	[   "lets"  "oard"  "ome"  "amels"] = split/rule        "letsHoardSomeCamels" [upper!]
	["" "Lets" "Hoard" "Some" "Camels"] = split/rule/before "LetsHoardSomeCamels" [upper!]
	
	;; split by comparator
	[[1 2 3] [3 4] [2 3 4]] = split [1 2 3 3 4 2 3 4] :>=
	camel: make op! func [a b] [to logic! find upper! b]
	["lets" "Hoard" "Some" "Camels"] = split "letsHoardSomeCamels" :camel
	["Lets" "Hoard" "Some" "Camels"] = split "LetsHoardSomeCamels" :camel
	
	;; split by custom function
	["Lets" "Hoard" "Some" "Camels"] = split "LetsHoardSomeCamels"
		function [pos state] [if end: find next pos upper! [1x1 * offset? pos end]]
]]
	