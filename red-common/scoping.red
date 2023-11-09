Red [
	title:   "Scoping support"
	purpose: "Basis for scope-based resource management"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		See https://en.wikipedia.org/wiki/Resource_acquisition_is_initialization for background

		just a simple macro for now
		exception-safe macro TBD
		because it incurs usage of `try/all` which has it's issues
		notably disabling of non local control flow
		which we want to pass through but still release resources
	}
]


;; this is useful when errors/throws are not normally expected in the code and end of block is known to be reached
;; one strategy is to insert `also` before last token of the block, but this does not reverse the finalization order
;; another is to use `also do rest do finalizer` but `do` will prevent compilation
;;   `also (rest) (finalizer)` - possible but dangerous (there have been many stack issues with parens)
;;   so I'm using `also if true [rest] (finalizer)` - both compilable, safe, does not divert control flow (as loop 1 would do)
#macro [#leaving block!] func [[manual] s e /local rest finalizer] [
	either tail? e [									;-- unlikely case, but have to secure against it
		change s 'do
		s
	][
		finalizer: s/2
		rest: copy e
		append/only
			clear change/only change s [also if true] rest
			to paren! finalizer
		s
	]
]


; probe [1 + 2 #leaving [3]]
; probe do probe [1 + 2 #leaving [3 * 4] #leaving ['x] 5 + 6]
