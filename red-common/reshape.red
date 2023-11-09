Red [
	title:   "RESHAPE mezzanine"
	purpose: "Build a block of code using expressions and conditions"
	author:  @hiiamboris
	license: 'BSD-3
	usage: {See in the docs, and in the tests below}
	notes: {
		Problem of this design is there's no good way to put reshape into other reshape.
		/skip is one option but I don't like it
		Maybe mark each processed inner block somehow?
		That is, it would still deeply scan it, but will skip unmarked blocks?
		Seems even more boring
		On/off markers?
		[ [< processed >] not processed] ??
		Just don't process expressions?
		[ [processed] @([not processed]) ] ??
		
		For 'light' version I wanted `? ... /if cond` syntax, but `?` is a word so has a lot of parsing overhead
		`/? ... /if cond` is much faster
	}
]

#include %hide-macro.red
#include %assert.red

;@@ TODO: implement it in R/S to be more useful
reshape: reshape-light: none
context [
	group!:  make typeset! [paren! block!]
	; line-junk!: complement make typeset! [group! ref! refinement!] 
	boring!: complement make typeset! [group! ref! refinement! word!] 
	
	keep?: func [x [any-type!]] [
		switch/default type?/word :x [none! unset! [[]]] [:x]
	]
	
	;; this version has vastly reduced syntax, but is also much faster, about 4x slower than compose+when combo, but better on big data
	;; syntax:
	;;   @(expr)  - mix in expr result if it's not none or unset
	;;   @[expr]  - insert expr result as single value
	;;   ? data /if condition  - if condition succeeds, process data and keep it
	set 'reshape-light function [
		"Rewrite INPUT block using lightened set of RESHAPE rules"
		input [group!] /local e x
	][
		=common=: [
			@ p: [
				paren! keep pick (keep? do p/1)
			|	block! keep            (do p/1)
			]
		|	ahead block! into =block=
		|	ahead paren! into [collect set x =group= keep (as paren! x)]	;-- into =block= will force block type, have to work around
		]
		=keep-line=: [any [
			keep pick some boring!
		|	=common=
		|	not /if keep skip
		]]
		=line=: [
			/? p: thru /if s: [
				;; fails to backtrack `:p`, because `e` may be overridden by deeper levels:
				if (do/next s 'e) :e opt [:p =keep-line= end skip] 
			|	:e
			]
		]
		=group=: [any [
			keep pick some boring!
		|	=common=
		|	=line=
		|	keep skip
		]]
		as input parse/case input =block=: [collect =group=]
	]
	
	set 'reshape function [
		"Deeply replace construction patterns in the BLOCK"
		block [block! paren!] "Will not be copied if does not contain any patterns"
		/local x
	][
		unless parse/case block [											;-- scan the block first - if no patterns are found, just return itself
			to [
				block! | paren! | '! | @ |
				/if | /else | /do | /use | /mixin | /skip
			] p: to end
		] [return block]

		while [not any [new-line? p head? p]] [p: back p]					;-- get back to the start of the line
		r: clear copy block													;-- preallocate the result
		append/part r block p												;-- copy the part that contains nothing special
		block: p															;-- start on the line of first found pattern

		=line-end=:   [p: [end | if (new-line? p) if (not line-start =? p)]]
		=bad-syntax=: [p: (do make error! rejoin ["Invalid syntax at: " mold/part p 40])]
		=update-end=: [p: opt if ((index? p) > index? line-end) line-end:]	;-- used after multiline expressions to ensure they are not repeated

		=expand+include-line=: [
			:line-start
			; (print ["INCLUDING:" mold/flat copy/part line-start line-end])
			while [
				p: if (p =? cond-start) break
			|	               set x [block! | paren!] (append/only r     reshape x)
			|	[['! | /use  ] set x           paren!] (append/only r  do reshape x)
			|	[[ @ | /mixin] set x           paren!] (append r keep? do reshape x)
			|	[[     /skip ] set x skip            ] (append/only r :x)	;@@ needs more design, I don't like it
			|	set x skip (append/only r :x)
			]
			:line-end
		]
		=global-conditions=: [
			while [
				=line-end= break
			|	/if   p: [if (include?: global-test: do/next p 'p) :p =update-end=]
			|	/else    [if (include?: not :global-test)]
			|	/do   p: [(do/next p 'p) :p =update-end=]
			|	ahead [/if | /else] :line-end break
			|	(print "GLOBAL") =bad-syntax=
			]
		]
		=line-conditions=: [
			while [															;-- `any` has a bad habit of stopping halfway, so using `while`
				/if   p: t: [if (last-test: do/next p 'p) :p]					;-- not using set/any by design: conditions should not return unset
			|	/else p: [if (not :last-test)]
			|	/do   p: [(do/next p 'p) :p]
			|	=line-end= =expand+include-line= break
			|	ahead [/if | /else] break									;-- condition failed, skip to the next line
			|	(print "LOCAL") =bad-syntax=
			]
			:line-end
		]

		include?: last-test: global-test: yes								;-- inclusion flags are true by default
		unless parse/case block [any [										;-- use /case or it will accept words for refinements
																			;-- can't use `collect into r` because `keep` works as `keep/only` always
			;; find the condition start and line end first
			line-start: to [
				=line-end= line-end:
			|	[/if | /else | /do] to [=line-end= line-end:]
			] cond-start:
			; (print ["||" mold/flat/only copy/part line-start cond-start "||" mold/flat/only copy/part cond-start line-end "||"])

			;; now process conditions and decide what to include
			[
				if (cond-start =? line-start) =global-conditions=			;-- empty line => process global conditions
			|	if (include?) [												;-- skip it if inclusion is forbidden by global condition
					if (cond-start =? line-end) =expand+include-line=		;-- no conditions in this line => include it
				|	=line-conditions=										;-- else process conditions and decide
				]
			|	none														;-- just skip it if it's not allowed to be included
			]
			:line-end
		] end] [do make error! rejoin ["Internal Error: " mold line-start]]	;-- should always process the whole block
		r
	]
]

#hide [#assert [
	[             ] = reshape []
	( quote ()    ) = reshape quote ()
	[ 1           ] = reshape [!(1)]
	[ []          ] = reshape [!([])]
	( reduce [()] ) = reshape [!(())]
	[ #[none]     ] = reshape [!(none)]
	[             ] = reshape [@([])]
	[             ] = reshape [@(())]
	[             ] = reshape [@(none)]
	[ #[false]    ] = reshape [@(false)]
	[ 1           ] = reshape [!(x) /do x: 1]
	[ []          ] = reshape [!(x) /do x: []]
	[             ] = reshape [@(x) /do x: []]
	[ ()          ] = reshape [!(x) /do x: quote ()]
	[             ] = reshape [@(x) /do x: quote ()]
	[             ] = reshape [@(:x) /do set/any 'x ()]

	;; conditional inclusion
	[             ] = reshape [1 2 /if no]
	[ 1 2         ] = reshape [1 2 /if yes]
	[ 1 2         ] = reshape [!(x) !(y) /if yes /do y: 1 + x: 1]
	[             ] = reshape [!(x) !(y) /if no  /do y: 1 + x: 1]

	[ 2           ] = reshape [
				/if no
		1
				/if yes
		2
				/else
		3
	]
	[             ] = reshape [1 2 /else]

	;; global flags should not affect line flags; multiple /elses act like one
	[ 2 4         ] = reshape [
				/if no
		1			/if yes
				/else
		2			/if yes
		3			/if no
				/else
		4
	]


	;; conditional /do
	[ 3           ] = reshape [
				/do y: 3
		!(x) 	/if no /do y: 1 + x: 1
		!(y)
	]
	[ 1 2         ] = reshape [
				/do y: 3
		!(x) 	/if yes /do y: 1 + x: 1
		!(y)
	]

	;; test that multi-line expressions are only evaluated once
	(
		i: 0
		reshape [
			/do i:
			i
			+
			1
			/do i: i + 1 /do i: i +
			1
		]
		i = 3
	)

	;; should not skip everything before the first pattern
	[ x [3] x 7 ] = reshape [
		x
		[!(1 + 2)]
		x
		!(3 + 4)
	]

	;; should inline the inner block, expanded but not nested
	[ 1 2        ] = reshape [
		@([	/if true
			1
			2
		])
	]

	;; one-liners should work
	[(1)     ] = reshape [ (1 /if yes)]
	[( )     ] = reshape [ (1 /if no )]
	[ 1      ] = reshape [@(1 /if yes)]
	[        ] = reshape [@(1 /if no )]
	[ 1      ] = reshape [!(1 /if yes)]
	unset? first reshape [!(1 /if no )]

	; ;; escape mechanism: needed when reshape block contains other calls to reshape
	[[! (1 + 2)]] = reshape [  /skip [!(1 + 2)] ]
	[ ! (1 + 2) ] = reshape [@(/skip [!(1 + 2)])]


	;; light version tests

	[             ] = reshape-light []
	( as paren! []) = reshape-light as paren! []
	[ 1           ] = reshape-light [@(1)]
	[ []          ] = reshape-light [@[[]]]
	( reduce [()] ) = reshape-light [@[()]]
	[ #[none]     ] = reshape-light [@[none]]
	[             ] = reshape-light [@([])]
	[             ] = reshape-light [@(())]
	[             ] = reshape-light [@(none)]
	[ #[false]    ] = reshape-light [@(false)]

	;; conditional inclusion
	[(1 2) /if no ] = reshape-light [(1 2) /if no]
	[(1 2) /if yes] = reshape-light [(1 2) /if yes]
	[             ] = reshape-light [/? 1 2 /if no]
	[ 1 2         ] = reshape-light [/? 1 2 /if yes]
	[ x y         ] = reshape-light [/? @['x] @('y) /if yes]
	[             ] = reshape-light [/? @['x] @('y) /if no ]
	[(1)          ] = reshape-light [(/? 1 /if yes)]
	[( )          ] = reshape-light [(/? 1 /if no )]
	[             ] = reshape-light [/? (/? 1 /if yes) /if no]
	[( )          ] = reshape-light [/? (/? 1 /if no)  /if yes]
	[(1)          ] = reshape-light [/? (/? 1 /if yes) /if yes]
	
	;; deep processing
	[ x [3] x (7) ] = reshape-light [x [@[1 + 2]] x (@[3 + 4])]

	;; resilience to keep/collect type issues and word overrides
	[1 (2 (3) (4)) (5 6)] = reshape-light [1 (2 (3) (/? 4 /if yes)) (/? 5 6 /if yes)]

	;; no processing of disabled items
	[             ] = reshape-light [/? @(do make error! "oops") /if no]

]]
