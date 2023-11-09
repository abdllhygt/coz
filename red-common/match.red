Red [
	title:   "Primitive MATCH function"
	purpose: "Determine if string matches a given pattern (evolution of find/match)"
	notes: {
		Only supports wildcards for now (not implemented find/any syntax), and find/match.
		Matching is done via naive recursive algorithm (but Parse-backed).
		Discussion: https://matrix.to/#/%23red_sandbox%3Agitter.im/%24v_tat02NPmSF_PCj_0qAHJZOEHMO0Nwg4I6I_VGYD1A
	}
]


#include %assert.red

;@@ what should the default mode be?
;@@ should regex be supported? I don't wanna open this can ov worms... also regex's greediness is controlled within it
;@@ longest common substring?
;@@ edit distance?
;@@ how far to stretch this func?
;@@ return location after the match? requires greediness control, incompatible with whole-string matching
matching: context [

	match: function [
		"Test if whole string matches a given pattern, returns logic! value"
		string  [any-string!] "String to test"
		pattern [string!]     "Pattern to match against; by default a leading substring"
		/glob "Mask is wildcard-based: * (zero or more chars) and ? (single char)"	;-- https://en.wikipedia.org/wiki/Glob_(programming)
		; /greedy "Return location after the maximum possible match"	;@@ will it makes sense for these to apply to all wildcards? 
		; /lazy   "Return location after the minimum possible match"
	][
		either glob
			[parse string compile-mask pattern]
			[to logic! find/match string pattern]
	]

	non-wild: charset [not "*?"]
	memoized: make map! 10
	
	compile-mask: function [
		"Compile wildcard-based mask into a Parse rule"
		mask [string!]
	][
		if rule: memoized/:mask [return rule]
		
		end-once: [end keep ('end) (end-once: [])]		;-- simplifies rule by keeping only innermost end requirement
		wilds: [
			keep some non-wild
		|	#"?" keep ('skip)
		|	some #"*" keep ('thru) [
				end-once								;-- simplify thru [end] as thru end (latter is optimized)
			|	collect [any wilds end-once]
			]
		]
		put memoized copy mask rule: parse mask [collect any wilds]
		rule
	]
	
	#assert [
		[#"1" skip "23" thru end]                    == compile-mask "1?23**"
		[#"1" skip "23" thru [#"4" end]]             == compile-mask "1?23*4"
		[#"1" skip "23" thru [#"4" thru end]]        == compile-mask "1?23*4*"
		[#"1" skip "23" thru [#"4" thru [#"5" end]]] == compile-mask "1?23*4*5"
		match     "12234" "122"
		not match "12234" "122345"
		match/glob      "12234555" "1?23*4*5"			;-- whole string matches, not just '122345'
		not match/glob "122345556" "1?23*4*5"
	]
]

match: :matching/match
