Red [
	title:   "CLIP function"
	purpose: "Contain a value within given range"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		See https://github.com/red/red/pull/5194
		
		On resulting type:
		Unfortunately, `min` and `max` do not guarantee type extension; just return the appropriate value:
			>> min 0 1.0
			== 0
			>> min 2 1.0
			== 1.0
		Consequently, `clip` may return any type occurring among its operands:
			>> clip 0 1 0.5
			== 0.5
			>> clip 0 1 1.5
			== 1			
		When type is enforced by type constraint, this may not be desirable:
			>> f: function [p [percent!]] []
			== func [p [percent!]][]
			>> f clip 0% 100% result-of-computation: 0.5
			*** Script Error: f does not allow float! for its p argument
			*** Where: f
			*** Near : f clip 0% 100% result-of-computation: 0.5
			*** Stack: run-console run eval-command f  
		Red-level type extension would be too costly here,
		so a manual result conversion (e.g. `to percent!`) is required for these cases.
	}
]

; #include %assert.red

#assert [												;-- check for arithmetic sanity
	(2,3)      = max (1,3) 2x2 
	(2,3)      = max 2x2 (1,3) 
	(2,1.#inf) = max 2x2 (1,1.#inf) 
	(2,1.#inf) = max (1,1.#inf) 2x2 
	(1,2)      = min 2x2 (1,1.#inf) 
	(1,2.5)    = min 2.5 (1,1.#inf) 
]

;@@ remove it if PR #5194 gets merged
clip: func [
	"Return A if it's within [B,C] range, otherwise the range boundary nearest to A"
	a [scalar!] b [scalar!] c [scalar!]
	return: [scalar!]
][
	min max a b max min a b c
]

#assert [(8,16) = clip 8x16 (20,0) (0,1.#inf)]
