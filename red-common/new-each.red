Red [
	title:   "*EACH loops"
	purpose: "Experimental new design of extended FOREACH, MAP-EACH, REMOVE-EACH"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		See foreach-design.md for info
	}
]

; recycle/off
#include %hide-macro.red
#include %assert.red
#include %error-macro.red
; #include %bind-only.red
#include %setters.red
#include %selective-catch.red
#include %reshape.red

; #include %show-trace.red

for-each: map-each: remove-each: none
context [
	;-- this should be straightforward and fast in R/S
	;-- one particular side effect of type checking is we can avoid/accept `none` we get when outside series limits
	types-match?: function [
		"Check if items in SERIES match TFILTER"
		ii [object!]
	][
		s: skip ii/series ii/offset
		foreach i ii/tfilter-idx [
			unless find ii/tfilter/:i type? :s/:i [return no]
		]
		yes
	]

	;-- this should also be a piece of cake
	;-- again, value can be used to filter in/out `none` values outside series limits
	values-match?: function [
		"Check if items in SERIES match VFILTER for all chosen VFILTER-IDX"
		ii [object!]
	][
		op: :ii/cmp
		s: skip ii/series ii/offset
		foreach i ii/vfilter-idx [
			unless :s/:i op :ii/vfilter/:i [return no]
			if tail? at s i [return no]					;-- special case: after-the-tail `none` should not count as sought value=none
		]												;@@ TODO: raise this design question in docs
		yes
	]
	; #assert [r: values-match? [1 2 3] [   ] [3 2 3] := 'r]
	; #assert [r: values-match? [1 2 3] [3  ] [3 2 3] := 'r]
	; #assert [r: values-match? [1 2 3] [2 3] [3 2 3] := 'r]

	ranges!:   make typeset! [integer! pair!]			;-- supported non-series types
	is-range?: func [x] [find ranges! type? :x]

	;; helpers for non-series types (ranges) iteration:
	int2pair: func [i [integer!] w [integer!]] [1x1 + as-pair  i - 1 % w  i - 1 / w]
	fill-with-ints: function [spec [block!] from [integer!] dim [integer!]] [
		foreach w spec [
			set w all [from <= dim  from]				;-- none after the 'tail'
			from: from + 1
		]
	]
	fill-with-pairs: function [spec [block!] from [integer!] dim [pair!]] [
		foreach w spec [
			xy: int2pair from dim/x
			set w all [xy/y <= dim/y  xy]				;-- none after the 'tail'
			from: from + 1
		]
	]
	append-ints: function [tgt [block!] from [integer!] count [integer!]] [
		loop count [
			append tgt from
			from: from + 1
		]
	]
	append-pairs: function [tgt [block!] from [integer!] count [integer!] dim [pair!]] [
		loop count [
			append tgt int2pair from dim/x
			from: from + 1
		]
	]

	;; `compose` readability helper - won't be needed in RS
	when: make op! func [value test] [either :test [:value][[]]]


	;-- this structure is required to share data between functions
	;-- (although it's one step away from a proper iterator type)
	;-- in R/S it will be set by foreach and used by foreach-next
	iteration-info!: object [
		matched?:    no
		offset:      0				;-- zero-based; cannot (easily) be series, as need to be able to point past the end or before the head
		iter:        0

		spec:        none
		series:      none
		code:        none
		cmp:         none
		fill:        none			;-- how many words to fill in the spec at every iteration - if series is shorter, fails
		width:       0				;-- how many words are in the spec (to fill)
		step:        none			;-- none value is used to detect duplicate pipes; <0 if iterating backward
		vfilter:     none			;-- none when filter is not used
		vfilter-idx: none
		tfilter:     none			;-- none when filter is not used
		tfilter-idx: none
		pos-word:    none
		idx-word:    none
	]

	fill-info: function [
		spec [word! block!]
		series [series! map! pair! integer!]
		code [block!]
		back-flag [logic!]
		case-flag [logic!]
		same-flag [logic!]
	][
		if case [
			integer? series [series <= 0]
			pair?    series [any [series/x <= 0 series/y <= 0]]
			'else [empty? series]
		] [return none]			;-- optimization; also works for /reverse, as we don't go before the current index

		on-series?: series? series
		if map? series [
			series: to hash! series
			forall series [								;@@ temporary adjustment - won't be needed in RS
				if set-word? :series/1 [series/1: to word! series/1]
			]
		]

		ii: copy iteration-info!
		ii/spec:   spec: compose [(spec)]
		ii/series: series
		ii/code:   copy/deep code						;-- copy/deep or binding will be shared on recursive calls!
		ii/cmp: get pick pick [[=? =?] [== =]] same-flag case-flag
		if all [same-flag case-flag] [
			ERROR "/case and /same refinements are mutually exclusive"
		]

		switch type?/word spec/1 [						;@@ TODO: consider supporting both iteration and position?
			set-word! [
				ii/pos-word: to word! spec/1
				unless on-series? [						;-- fail on ranges and maps (latter cannot be modified as series)
					ERROR "Series index can only be used when iterating over series"
				]
				remove spec
			]
			refinement! [
				ii/idx-word: to word! spec/1
				remove spec
			]
		]

		ii/vfilter:     copy []
		ii/tfilter:     copy []
		ii/vfilter-idx: copy []
		ii/tfilter-idx: copy []
		while [not tail? spec] [
			value: types: none
			switch/default type?/word spec/1 [
				paren! [
					if is-range? series [				;-- complicates filter and makes little sense
						ERROR "Cannot use value filters on ranges"
					]
					set/any 'value do spec/1
					append ii/vfilter-idx index? spec
					change spec anonymize '_ none		;-- at R/S side it will be just dumb loop rather than single `set`
				]
				word! [
					case [
						spec/1 = '| [
							if ii/step [ERROR "Duplicate pipe in spec"]
							ii/fill: yes
							ii/step: -1 + index? spec
							; if ii/step = 0 [ERROR ""]	;@@ error or not? one can use such loop to advance manually
							remove spec
							continue					;-- don't add this entry
						]
						block? spec/2 [
							if is-range? series [		;-- pointless: we always know the item type in ranges
								ERROR "Cannot use type filters on ranges"
							]
							;@@ TODO: use single typesets and types as is, without allocating a new typeset
							types: make typeset! spec/2
							append ii/tfilter-idx index? spec
							remove next spec
						]
					]
				]
			][
				ERROR "Unexpected occurrence of (mold spec/1) in spec"
			]
			append/only ii/vfilter :value
			append/only ii/tfilter :types
			spec: next spec
		]												;-- spec is now native-foreach-compatible
		spec: head spec
		if empty? spec [ERROR "Spec must contain at least one mandatory word"]

		#assert [(length? spec) = length? ii/vfilter]
		#assert [(length? spec) = length? ii/tfilter]

		if empty? ii/tfilter-idx [ii/tfilter: ii/tfilter-idx: none]		;-- disable empty filters
		if empty? ii/vfilter-idx [ii/vfilter: ii/vfilter-idx: none]

		ii/width: length? spec
		ii/step: any [ii/step ii/width]
		ii/fill: either ii/fill [ii/width][1]
		if all [0 = ii/step  not ii/pos-word] [
			ERROR "Zero step is only allowed with series index"			;-- otherwise deadlocks
		]

		ii/offset: 0
		if back-flag [									;-- requires step known
			n: case [
				integer? series [series]
				pair? series [series/x * series/y]
				'else [length? series]
			]
			n: n - ii/fill								;-- ensure needed number of words is filled
			; n: round/floor/to n max 1 ii/step			;-- align to step
			n: n - (n % max 1 ii/step)					;-- align to step
			if pair? p: series [n: as-pair  n % p/x  n / p/x]
			ii/offset: n
		]

		if back-flag [ii/step: 0 - ii/step]

		;@@ in R/S we won't need this, as `function` supports `foreach`:
		anon-ctx: construct collect [
			foreach w spec [keep to set-word! w]
			if ii/pos-word [keep to set-word! ii/pos-word]
			if ii/idx-word [keep to set-word! ii/idx-word]
		]
		bind ii/spec anon-ctx
		if ii/pos-word [ii/pos-word: bind ii/pos-word anon-ctx]
		if ii/idx-word [ii/idx-word: bind ii/idx-word anon-ctx]
		bind ii/code anon-ctx

		ii					;-- fill OK
	]


	more-of?: function [ii [object!] size [integer!]] [
		either ii/step < 0 [
			ii/offset >= 0
		][
			case [
				pair? ii/series [
					ii/series/x * ii/series/y - ii/offset >= size
				]
				integer? ii/series [
					ii/series - ii/offset >= size
				]
				'else [
					(length? ii/series) - ii/offset >= size	;-- supports series length change during iteration
				]
			]
		]
	]

	more-items?: function [ii [object!]] [more-of? ii 1]
	more-iterations?: function [ii [object!]] [more-of? ii ii/fill]

	copy-to: function [
		"Append a part of II/series into TGT"
		tgt  [series!]
		ii   [object!] "iterator info"
		ofs  [integer! series!] "from where to start a copy"
		part [integer! series! none!] "number of items or offset; none for unbound copy"
	][
		case [
			series? ii/series [
				src: skip ii/series ofs
				part: either part [
					copy/part src part					;@@ append/part doesn't work - #4336
				][	copy      src						;-- still need a copy so series is not shared (in case appending a string to block)
				]
				if vector? part [part: to [] part]		;@@ workaround: append block vector enforces /only
				append tgt part
			]
			integer? ii/series [
				unless part [part: ii/series - ofs - 1]
				append-ints  tgt 1 + ofs part
			]
			'pair [
				unless part [part: ii/series/x * ii/series/y - ofs - 1]
				append-pairs tgt 1 + ofs part ii/series
			]
		]
	]


	;@@ should maps iteration be restricted to [k v] or not?
	;@@ I don't like arbitrary restrictions, but here it's a question of how easy it will be
	;@@ to support unrestricted iteration in possible future implementations of maps
	;@@ leave this question in docs!

	{
		for-each allows loop body to modify `pos:` and then possibly call `continue`
		in R/S we'll be able to catch `continue` directly
		in Red it's tricky: need to not let `continue` mess index logic, and yet allow `break` somehow
		the only solution I've found is to save the pos-word, then check it for changes before each iteration
	}

	for-each-core: function [
		ii [object!] "iteration info"
		on-iteration [block!] "evaluated when spec matches"
		after-iteration [block!] "evaluated after on-iteration succeeds and offsets are updated"
		/local new-pos
	][
		upd-pos-word?: [								;-- code that reads user modifications of series position
			if ii/pos-word [
				set/any 'new-pos get/any ii/pos-word
				unless series? :new-pos [
					ERROR "(ii/pos-word) does not refer to series"
				]
				unless same? head new-pos head ii/series [	;-- most likely it's a bug, so we report it
					ERROR "(ii/pos-word) was changed to another series"
				]
				ii/offset: offset? ii/series new-pos
			]
		]

		to-next-possible-match: [						;-- by default tries to match series at every step
			if more-iterations? ii [ii/iter: ii/iter + 1]
		]
		if all [										;-- however when vfilter is defined...
			ii/vfilter									;-- we can use find to faster locate matches, esp. on hash & map
			ii/step <> 0								;-- but step=0 means find direction is undefined and can't benefit from this optimization
		][
			val-ofs: ii/vfilter-idx/1
			val: ii/vfilter/:val-ofs
			if typeset? :val [							;@@ #4911 - typeset is too smart - this is a workaround
				val: compose [(val)]					;@@ however this still disables hash advantages
				no-only?: yes							;@@ to be removed once #4911 is fixed
			]
			|skip|: absolute ii/step

			if all [
				ii/step < 0									;-- when going backwards
				tail? at skip ii/series ii/offset val-ofs	;-- and sought value is after the tail
			][
				ii/offset: ii/offset - |skip|				;-- then we can skip this iteration already
				ii/iter: ii/iter + 1						;-- as after-the-tail `none` does not count as value `none`
			]
			;-- this special case may be disabled
			;-- but then `from` may be misaligned with `/skip` as Red doesn't allow after-the-tail positioning
			;-- so if disabled, it will require special index adjustment during first two iterations (should be easier in RS)

			find-call: as path! compose [				;-- construct a relevant `find` call
				find
				skip
				('reverse when (ii/step < 0))
				('only when not no-only?)				;@@ /only disables "type!" smarts, but not "typeset!" - #4911
				('case when (:ii/cmp =? :strict-equal))
				('same when (:ii/cmp =? :same?))
			]

			to-next-possible-match: reshape [
				all [
					pos: !(find-call) from: at skip ii/series ii/offset val-ofs :val |skip|
					ii/offset: (index? pos) - val-ofs
					more-iterations? ii
					ii/iter: add  ii/iter  (offset? from pos) / ii/step
				]
			]
		]

		catch-a-break [									;@@ destroys break/return value
			while to-next-possible-match [
				;-- do all updates before calls to `continue` are possible
				case [
					ii/pos-word [set ii/pos-word skip ii/series ii/offset]
					ii/idx-word [set ii/idx-word ii/iter]	;-- unfortunately with this design, image does not get a pair index
				]

				;-- do filtering
				if ii/matched?: all [
					any [not ii/tfilter  types-match? ii]
					any [not ii/vfilter  values-match? ii]
				][
					;-- fill the spec - only if matched
					case [
						series?  ii/series [foreach (ii/spec) skip ii/series ii/offset [break]]
						integer? ii/series [fill-with-ints  ii/spec 1 + ii/offset ii/series]
						'pair              [fill-with-pairs ii/spec 1 + ii/offset ii/series]
					]
					catch-continue [
						continued?: yes
						do on-iteration
						continued?: no
					]
				]

				do upd-pos-word?
				ii/offset: ii/offset + ii/step
				if all [ii/matched? not continued?] after-iteration
			]
		]
	]

	;-- the frontend
	set 'for-each function [
		"Evaluate CODE for each match of the SPEC on SERIES"
		'spec  [word! block!]                "Words & index to set, values/types to match"
		series [series! map! pair! integer!] "Series, map or limit"
		code   [block!]                      "Code to evaluate"
		/reverse "Traverse in the opposite direction"
		/case    "Values are matched using strict comparison"
		/same    "Values are matched using sameness comparison"
		/local r
	][
		unset 'r										;-- returns unset by default (empty series, fill-info failed)
		if ii: fill-info spec series code reverse case same [
			for-each-core ii [
				if ii/matched? [						;-- not matched iterations do not affect the result
					unset 'r							;-- in case of `continue`, result will be unset
					set/any 'r do ii/code
				]
			] []
		]
		:r
	]

	set 'map-each function [
		"Map SERIES into a new one and return it"
		'spec  [word! block!]                "Words & index to set, values/types to match"
		series [series! map! pair! integer!] "Series, map or range"
		code   [block!]                      "Should return the new item(s)"
		/only "Treat block returned by CODE as a single item"
		/eval "Reduce block returned by CODE (else includes it as is)"
		/drop "Discard regions that didn't match SPEC (else includes them unmodified)"
		/case "Values are matched using strict comparison"
		/same "Values are matched using sameness comparison"
		/self "Map series into itself (incompatible with ranges)"
		/local part
	][
		all [
			self
			scalar? series								;-- change/part below relies on this error
			ERROR "/self is only allowed when iterating over series or map"
		]

		;-- where to collect into: always a block, regardless of the series given
		;-- because we don't know what type the result should be and block can be converted into anything later
		buf: make [] system/words/case [				;-- try to guess the length
			integer? series [series]
			pair? series [series/x * series/y]
			'else [length? series]
		]
		if all [eval not only] [red-buf: copy []]		;-- buffer for reduce/into
		;@@ TODO: trap & rethrow errors (out of memory, I/O, etc), ensuring buffers are freed on exit

		;-- in map-each ii/step is never negative as it does not support backwards iteration
		add-skipped-items: [skip-bgn: skip-end]
		add-rest: []
		unless drop [
			add-skipped-items: [
				if skip-end > skip-bgn [				;-- can be <= in case of step=0 or user intervention - in this case don't add anything
					copy-to buf ii skip-bgn skip-end - skip-bgn
				]
				skip-bgn: skip-end
			]
			add-rest: [
				ii/offset: skip-bgn						;-- offset used by `more-items?`
				if more-items? ii [copy-to buf ii skip-bgn none]
			]
		]

		if ii: fill-info spec series code no case same [	;-- non-empty series/range?
			skip-bgn: ii/offset
			for-each-core ii [
				skip-end: ii/offset						;-- remember skipped region before ii/offset changes in iteration code
				set/any 'part do ii/code
				if all [eval block? :part] [			;-- /eval only affects block results by design (for more strictness)
					part: either only [					;-- has to be reduced here, in case it calls continue or break, or errors
						reduce      part				;-- /only has to allocate a new block every time
					][	reduce/into part clear red-buf	;-- else this can be optimized, but buf has to be cleared every time in case it gets partially reduced and then `continue` fires
					]
				]
			][
				do add-skipped-items					;-- by putting it here, we can group multiple `continue` calls into a single append
				either only [append/only buf :part][append buf :part]
				;-- `max` is used to never add the same region twice, in case user rolls back the position:
				skip-bgn: skip-end: max skip-end ii/offset
			]
			do add-rest									;-- after break or last continue, add the rest of the series

			;-- to avoid O(n^2) time complexity of in-place item changes (e.g. inserted item length <> removed),
			;-- original series is changed only once, after iteration is finished
			;-- this produces a single on-deep-change event on owned series
			;-- during iteration, intermediate changes will not be detected by user code
			if self [
				either map? series [
					extend clear series buf
				][
					change/part series buf tail series
				]
			]
		]												;-- otherwise, empty series: buf is already empty

		;@@ TODO: in R/S free the `red-buf` here (not possible in Red)
		either self [ 									;-- even if never iterated, a block or series is returned
			;@@ TODO: in R/S free the `buf` here (not possible in Red)
			series
		][
			buf											;-- no need to free it
		]
	]

	;@@ TODO: maps require a special fill function so keys don't appear as set-words, also to avoid a copy
	;@@ at RS level it's a hash so it'll be easier there
	;@@ so, map at least should be converted into a hash, not block
	set 'remove-each function [
		"Remove parts of SERIES that match SPEC and return a truthy value"
		'spec  [word! block!]                "Words & index to set, values/types to match"
		series [series! map! pair! integer!] "Series, map or range"
		code   [block!]                      "Should return the new item(s)"
		/drop "Discard regions that didn't match SPEC (else includes them unmodified)"
		/case "Values are matched using strict comparison"
		/same "Values are matched using sameness comparison"
		/local part
	][
		unless ii: fill-info spec series code no case same [	;-- early exit - series is empty
			return either any [series? series map? series] [series] [copy []]
		]

		;-- where to collect into: always a block, regardless of the series given
		;-- because we don't know what type the result should be and block can be converted into anything later
		buf: make [] system/words/case [				;-- try to guess the length
			integer? series [series]
			pair? series [series/x * series/y]
			'else [length? series]
		]
		;@@ TODO: trap & rethrow errors (out of memory, I/O, etc), ensuring `buf` is freed on exit

		skip-bgn: ii/offset
		for-each-core ii [
			skip-end: ii/offset							;-- remember skipped region before ii/offset changes in iteration code
			set/any 'drop-this? do ii/code
		][
			unless drop [copy-to buf ii skip-bgn skip-end - skip-bgn]
			unless :drop-this? [copy-to buf ii skip-end ii/step]
			skip-bgn: skip-end: ii/offset
		]
		unless drop [copy-to buf ii skip-bgn none]

		;-- to avoid O(n^2) time complexity of in-place item removal,
		;-- original series is changed only once, after iteration is finished
		;-- this produces a single on-deep-change event on owned series
		;-- during iteration, intermediate changes will not be detected by user code
		system/words/case [
			series? series [
				either any-string? series [
					change/part series rejoin buf tail series		;@@ just a workaround for #4913 crash
				][
					change/part series        buf tail series
				]
			]
			map? series [
				extend clear series buf
			]
			'ranges [
				return buf								;-- no need to free it
			]
		]
		;@@ TODO: in R/S free the buffer (not possible in Red)
		series
	]

]


#hide [#assert [

	;---------------------------- FOR-EACH -----------------------------

	;; return value tests
	error? try [for-each [] [1] [1]]
	unset? for-each x [] [1]
	unset? for-each x [1 2 3] [continue]
	unset? for-each x [1 2 3] [break]
	; 123 =  for-each x [1 2 3] [break/return 123]	;@@ broken in Red
	3 =    for-each x [1 2 3] [x]

	;; spec unfolding tests
	empty?    collect [for-each  x       [       ] [keep x]]
	[1    ] = collect [for-each  x       [1      ] [keep x]]
	[1 2  ] = collect [for-each  x       [1 2    ] [keep x]]
	[1 2 3] = collect [for-each  x       [1 2 3  ] [keep x]]
	[2 3 4] = collect [for-each  x  next [1 2 3 4] [keep x]]
	[1    ] = collect [for-each [x]      [1      ] [keep x]]
	[1 2  ] = collect [for-each [x]      [1 2    ] [keep x]]
	[1 2 3] = collect [for-each [x]      [1 2 3  ] [keep x]]
	[[1 2] [3 #[none]]      ] = collect [for-each [x y] [1 2 3    ] [keep/only reduce [x y]]]
	[[1 2] [3 4]            ] = collect [for-each [x y] [1 2 3 4  ] [keep/only reduce [x y]]]
	[[1 2] [3 4] [5 #[none]]] = collect [for-each [x y] [1 2 3 4 5] [keep/only reduce [x y]]]

	;; `continue` & `break` support
	[1 2 3] = collect [for-each  x [1 2 3] [keep x continue]]
	[     ] = collect [for-each  x [1 2 3] [continue keep x]]
	[1    ] = collect [for-each  x [1 2 3] [keep x break]   ]

	;; indexes & /reverse
	[1 2 3  ] = collect [for-each [/i x]   [x y z]     [keep i       ]]
	[1 2 3  ] = collect [for-each [p: x]   [x y z]     [keep index? p]]
	[2 3 4  ] = collect [for-each [p: x] next [1 2 3 4] [keep x]]			;-- was buggy once
	[1 2 3  ] = collect [for-each [/i x y] [a b c d e] [keep i       ]]
	[1 3 5  ] = collect [for-each [p: x y] [a b c d e] [keep index? p]]
	[1 3 4 5] = collect [for-each [p: x y] [a b c d e] [keep index? p p: back p]]	;-- 1st `back` fails
	[1 4    ] = collect [for-each [p: x y] [a b c d e] [keep index? p p: next p]]
	error?         try  [for-each [p: x] [a b c] [p: 1]] 
	error?         try  [for-each [p: x] [a b c] [p: ""]]
	[1 2 3  ] = collect [for-each/reverse [/i x]   [x y z]     [keep i       ]]
	[3 2 1  ] = collect [for-each/reverse [p: x]   [x y z]     [keep index? p]]
	[1 2 3  ] = collect [for-each/reverse [/i x y] [a b c d e] [keep i       ]]
	[5 3 1  ] = collect [for-each/reverse [p: x y] [a b c d e] [keep index? p]]
	[3 2 1  ] = collect [for-each/reverse x 3                  [keep x ]]
	[3 4 1 2] = collect [for-each/reverse [x y] 4              [keep reduce [x y]]]
	[3 #[none] 1 2] = collect [for-each/reverse [x y] 3        [keep reduce [x y]]]
	empty?      collect [for-each/reverse x            0       [keep x]]
	empty?      collect [for-each/reverse x           -1       [keep x]]
	[3 2    ] = collect [for-each/reverse x next      [1 2 3]  [keep x]]		;-- should stop at initial index
	[2 3    ] = collect [for-each/reverse [x y]  next [1 2 3]  [keep reduce [x y]]]
	[3      ] = collect [for-each/reverse x next next [1 2 3]  [keep x]]
	empty?      collect [for-each/reverse x next next [1 2]    [keep x]]
	[1 4    ] = collect [for-each         [/i x [word!]  ] [a 2 3 b 5] [keep i]]	;-- iteration number counts even if not matched
	[2 5    ] = collect [for-each/reverse [/i x [word!]  ] [a 2 3 b 5] [keep i]]	;-- /reverse reorders iteration number
	[2      ] = collect [for-each/reverse [/i x y [word!]] [a 2 3 b 5] [keep i]]	;-- iteration number accounts for step size
	[1      ] = collect [for-each/reverse [/i x y [word!]] [a 2 3 b  ] [keep i]]

	;; pipe
	[1 2 3] = collect [for-each [x |]           [1 2 3] [keep x]]
	[1 2 3] = collect [for-each [/i x |]        [x y z] [keep i]]
	[x y z] = collect [for-each [/i x |]        [x y z] [keep x]]
	[1 2 3] = collect [for-each [p: x |]        [x y z] [keep index? p]]
	[x y z] = collect [for-each [p: x |]        [x y z] [keep x]]
	[x y z] = collect [for-each [p: | x]        [x y z] [keep x p: next p]]			;-- zero step, manual advance
	error?        try [for-each [p: |] [x y z] [p: next p]]							;-- no mandatory words
	[[x y] [y z]] = collect [for-each [x | y]   [x y z] [keep/only reduce [x y]]]
	[[x y z]    ] = collect [for-each [x | y z] [x y z] [keep/only reduce [x y z]]]
	empty?          collect [for-each [x | y z] [x y]   [keep/only reduce [x y z]]]		;-- too short to fit in
	[1 2 3]       = collect [for-each [x y | z] [1 2 3]       [keep reduce [x y z]]]
	[1 2 3]       = collect [for-each [x y | z] [1 2 3 4]     [keep reduce [x y z]]]
	[1 2 3 3 4 5] = collect [for-each [x y | z] [1 2 3 4 5]   [keep reduce [x y z]]]
	[1 2 3 3 4 5] = collect [for-each [x y | z] [1 2 3 4 5 6] [keep reduce [x y z]]]
	[3 2 1] = collect [for-each/reverse [x |]           [1 2 3] [keep x]]
	[1 2 3] = collect [for-each/reverse [/i x |]        [x y z] [keep i]]
	[z y x] = collect [for-each/reverse [/i x |]        [x y z] [keep x]]
	[3 2 1] = collect [for-each/reverse [p: x |]        [x y z] [keep index? p]]
	[z y x] = collect [for-each/reverse [p: x |]        [x y z] [keep x]]
	[[y z] [x y]] = collect [for-each/reverse [x | y]   [x y z] [keep/only reduce [x y]]]
	[[x y z]    ] = collect [for-each/reverse [x | y z] [x y z] [keep/only reduce [x y z]]]
	empty?          collect [for-each/reverse [x | y z] [x y]   [keep/only reduce [x y z]]]		;-- too short to fit in

	;; any-string support
	[#"a" #"b" #"c"] = collect [for-each c "abc" [keep c]]
	[#"a" #"b" #"c"] = collect [for-each c <abc> [keep c]]
	[#"a" #"b" #"c"] = collect [for-each c %abc  [keep c]]
	[#"a" #"@" #"b"] = collect [for-each c a@b   [keep c]]
	[#"a" #":" #"b"] = collect [for-each c a:b   [keep c]]

	;; image support
	im: make image! [2x2 #{111111 222222 333333 444444}]
	; [17.17.17.0 34.34.34.0 51.51.51.0 78.78.78.0] = collect [for-each c i [keep c]]		;@@ uncomment me when #4421 gets fixed
	; [1x1 2x1 1x2 2x2] = collect [for-each [/i c] im  [keep i]]				;-- special index for images - pair
	[1 2 3 4        ] = collect [for-each [p: c] im  [keep index? p]]

	;; 1D/2D ranges support
	not error?              try [for-each [/i x] 2x2 []]
	    error?              try [for-each [p: x] 2x2 []]					;-- series indexes with ranges forbidden
	[1x1 2x1 1x2 2x2] = collect [for-each i     2x2 [keep i]]				;-- unfold size into pixel coordinates
	[1x1 1x2        ] = collect [for-each [i j] 2x2 [keep i]]
	[1 3 5 7 9      ] = collect [for-each [i j] 10  [keep i]]				;-- unfold length into integers

	;; maps support
	    error?              try [for-each [p: x] #(1 2 3 4) []]							;-- no series index for maps allowed
	not error?              try [for-each [/i x] #(1 2 3 4) []]
	[1 2 3 4        ] = collect [for-each [k v]       #(1 2 3 4) [keep k keep v]]		;-- map iteration is very relaxed
	[1 2 3 4        ] = collect [for-each x           #(1 2 3 4) [keep x]]       
	[1 2 3 4 #[none]] = collect [for-each [a b c d e] #(1 2 3 4) [keep reduce [a b c d e]]]

	;; vectors support
	v: make vector! [1 2 3 4 5]
	[1 2 3 4 5              ] = collect [for-each  x    v [keep x]]                
	[[1 2] [3 4] [5 #[none]]] = collect [for-each [x y] v [keep/only reduce [x y]]]

	;; any-block support
	[[1 2] [3 4] [5 #[none]]] = collect [for-each [x y] make hash!   [1 2 3 4 5] [keep/only reduce [x y]]]
	[[1 2] [3 4] [5 #[none]]] = collect [for-each [x y] as paren!    [1 2 3 4 5] [keep/only reduce [x y]]]
	; [[1 2] [3 4] [5 #[none]]] = collect [for-each [x y] as path!     [1 2 3 4 5] [keep/only reduce [x y]]]		;@@ uncomment me when #4421 gets fixed
	; [[1 2] [3 4] [5 #[none]]] = collect [for-each [x y] as lit-path! [1 2 3 4 5] [keep/only reduce [x y]]]		;@@ uncomment me when #4421 gets fixed
	; [[1 2] [3 4] [5 #[none]]] = collect [for-each [x y] as set-path! [1 2 3 4 5] [keep/only reduce [x y]]]		;@@ uncomment me when #4421 gets fixed
	; [[1 2] [3 4] [5 #[none]]] = collect [for-each [x y] as get-path! [1 2 3 4 5] [keep/only reduce [x y]]]		;@@ uncomment me when #4421 gets fixed

	;; pattern matching support
	[#"3" 4       ] = collect [v: 4         for-each [x   (v)                  ] [1 2.0 #"3" 4 'e] [keep reduce [x v] ]]
	[#"3" 4       ] = collect [v: #"3" w: 4 for-each [(v) (w)                  ] [1 2.0 #"3" 4 'e] [keep reduce [v w] ]]
	[1 2.0        ] = collect [             for-each [x [integer!]  y          ] [1 2.0 #"3" 4 'e] [keep reduce [x y] ]]
	[1 2.0 #"3" 4 ] = collect [             for-each [x             y [number!]] [1 2.0 #"3" 4 'e] [keep reduce [x y] ]]
	[1 2.0 #"3" 4 ] = collect [             for-each [x [any-type!] y [number!]] [1 2.0 #"3" 4 'e] [keep reduce [x y] ]]
	[#"3" 4       ] = collect [             for-each [x [char!]     y [number!]] [1 2.0 #"3" 4 'e] [keep reduce [x y] ]]
	[#"3" 4       ] = collect [v: #"3"      for-each [(v)           y [number!]] [1 2.0 #"3" 4 'e] [keep reduce [v y] ]]
	; [2 2 2 2      ] = collect [v: 2         for-each [(v)  ]                     [2 2.0 #"^B" 2]   [keep v] ]	;@@ FIXME: affected by #4327
	; [2 2.0 #"^B" 2] = collect [v: 2         for-each [p: (v)]                    [2 2.0 #"^B" 2]   [keep p/1]]	;@@ FIXME: affected by #4327

	;; /same & /case value filters
	[2 2            ] =  collect [v: 2 for-each/case [p: (v)] [2 2.0 #"^B" 2] [keep p/1]]
	[2 2            ] =  collect [v: 2 for-each/same [p: (v)] [2 2.0 #"^B" 2] [keep p/1]]
	r: reduce [v: "v" w: "v" w uppercase copy v]
	["v" "v" "v" "V"] == collect [for-each           [p: (v)] r [keep p/1]]
	["v" "v" "v"    ] == collect [for-each/case      [p: (v)] r [keep p/1]]
	["v" "v"        ] == collect [for-each/same      [p: (w)] r [keep p/1]]
	["v"            ] == collect [for-each/same      [p: (v)] r [keep p/1]]

	;; `advance` support
	; [[2 3] #[none]] = collect [for-each  x    [1 2 3    ] [        keep/only advance]]
	; [[2 3 4] [4]  ] = collect [for-each  x    [1 2 3 4  ] [        keep/only advance]]
	; [[3 4] #[none]] = collect [for-each  x    [1 2 3 4  ] [advance keep/only advance]]
	; [[3 4]        ] = collect [for-each [x y] [1 2 3 4  ] [        keep/only advance]]
	; [[5]          ] = collect [for-each [x y] [1 2 3 4 5] [advance keep/only advance]]
	; [4 #[none]    ] = collect [for-each [x [integer!]] [1 2.0 #"3" 4 'e 6] [set [x] advance keep x]]	;-- jumps to next match
	; [2.0 6        ] = collect [for-each [x [number!] ] [1 2.0 #"3" 4 'e 6] [set [x] advance keep x]]
	; [1 6          ] = collect [for-each [x [integer!]] [1 2.0 #"3" 4 'e 6] [advance keep x]]			;-- does not affect the `x`

	;; confirm that there's no leakage
	(x: 1     for-each x     [2 3 4] [x: x * x]  x = 1)
	(x: y: 1  for-each [x y] [2 3 4] [x: y: 0]   all [x = 1 y = 1])





	;---------------------------- MAP-EACH -----------------------------

	;; spec unfolding tests
	empty?    map-each  x  [     ] [x]
	[1    ] = map-each  x  [1    ] [x]
	[1 2  ] = map-each  x  [1 2  ] [x]
	[1 2 3] = map-each  x  [1 2 3] [x]
	[1    ] = map-each [x] [1    ] [x]
	[1 2  ] = map-each [x] [1 2  ] [x]
	[1 2 3] = map-each [x] [1 2 3] [x]
	[[1 2] [3 #[none]]      ] = map-each/only [x y] [1 2 3    ] [reduce [x y]]
	[[1 2] [3 4]            ] = map-each/only [x y] [1 2 3 4  ] [reduce [x y]]
	[[1 2] [3 4] [5 #[none]]] = map-each/only [x y] [1 2 3 4 5] [reduce [x y]]

	;; decomposition of strings
	[#"a" #"b" #"c"]    = map-each  x    "abc"   [x]
	[#"a" #"c" #"e"]    = map-each [x y] "abcde" [x]
	[#"b" #"d" #[none]] = map-each [x y] "abcde" [y]
	[#"b" #"d"]         = map-each [x y] "abcd"  [y]
	[#"a" #"b" #"c"]    = map-each  x     <abc>  [x]
	[#"a" #"b" #"c"]    = map-each  x     %abc   [x]
	[#"a" #"@" #"b"]    = map-each  x     a@b    [x]
	[#"a" #":" #"b"]    = map-each  x     a:b    [x]

	;; indexes
	[1 2 3    ] = map-each      [/i x]           [x y z]     [i       ]
	[1 2 3    ] = map-each      [p: x]           [x y z]     [index? p]
	[1 2 3    ] = map-each      [/i x y]         [a b c d e] [i       ]
	[1 3 5    ] = map-each      [p: x y]         [a b c d e] [index? p]
	[1 4      ] = map-each/drop [/i x [word!]]   [a 2 3 b 5] [i       ]	;-- iteration number counts even if not matched
	[1 2 3 4 5] = map-each      [/i x [word!]]   [a 2 3 b 5] [i       ]
	[1        ] = map-each/drop [/i x [word!] y] [a 2 3 b 5] [i       ]
	[2        ] = map-each/drop [/i x y [word!]] [a 2 3 b 5] [i       ]	;-- iteration number accounts for step size

	;; image support
	im: make image! [2x2 #{111111 222222 333333 444444}]
	; [17.17.17.0 34.34.34.0 51.51.51.0 78.78.78.0] = map-each c i [c]		;@@ uncomment me when #4421 gets fixed
	; [1x1 2x1 1x2 2x2] = map-each [/i c] im  [i]				;-- special index for images - pair
	[1 2 3 4        ] = map-each [p: c] im  [index? p]

	;; 1D/2D ranges support
	; error?         try [map-each [/i x] 2x2 []]						;-- indexes with ranges forbidden
	error?         try [map-each [p: x] 2x2 []]
	[1x1 2x1 1x2 2x2] = map-each  i    2x2 [i]				;-- unfold size into pixel coordinates
	[1x1 1x2        ] = map-each [i j] 2x2 [i]
	[1 2 3 4        ] = map-each  i    4   [i]
	[1 3 5 7 9      ] = map-each [i j] 10  [i]				;-- unfold length into integers
	[               ] = map-each  i    0   [i]				;-- zero length
	[               ] = map-each  i    -10 [i]				;-- negative length
	[               ] = map-each  i    0x0 [i]				;-- zero length
	[               ] = map-each  i    0x5 [i]				;-- zero length
	[               ] = map-each  i    5x0 [i]				;-- zero length
	[               ] = map-each  i  -5x-5 [i]				;-- negative length

	;; maps support
	error?         try [map-each [p: x] #(1 2 3 4) []]								;-- no indexes for maps allowed
	; error?         try [map-each [/i x] #(1 2 3 4) []]
	[1 2 3 4        ] = map-each [k v]       #(1 2 3 4) [reduce [k v]]		;-- map iteration is very relaxed
	[1 2 3 4        ] = map-each x           #(1 2 3 4) [x]       
	[1 2 3 4 #[none]] = map-each [a b c d e] #(1 2 3 4) [reduce [a b c d e]]

	;; vectors support
	v: make vector! [1 2 3 4 5]
	[1 2 3 4 5               ] = map-each       x    v [x]           
	[[1 2] [3 4] [5 #[none]] ] = map-each/only [x y] v [reduce [x y]]
	[1 2 6 4 5               ] = map-each      [(3)] v [6]			;-- vectors get appended as /only by default - need to ensure it's not the case
	(make vector! [1 2 6 4 5]) = map-each/self [(3)] copy v [6]

	;; any-block support
	[[1 2] [3 4] [5 #[none]]] = map-each/only [x y] make hash!   [1 2 3 4 5] [reduce [x y]]
	[[1 2] [3 4] [5 #[none]]] = map-each/only [x y] as paren!    [1 2 3 4 5] [reduce [x y]]
	; [[1 2] [3 4] [5 #[none]]] = map-each/only [x y] as path!     [1 2 3 4 5] [reduce [x y]]		;@@ uncomment me when #4421 gets fixed
	; [[1 2] [3 4] [5 #[none]]] = map-each/only [x y] as lit-path! [1 2 3 4 5] [reduce [x y]]		;@@ uncomment me when #4421 gets fixed
	; [[1 2] [3 4] [5 #[none]]] = map-each/only [x y] as set-path! [1 2 3 4 5] [reduce [x y]]		;@@ uncomment me when #4421 gets fixed
	; [[1 2] [3 4] [5 #[none]]] = map-each/only [x y] as get-path! [1 2 3 4 5] [reduce [x y]]		;@@ uncomment me when #4421 gets fixed

	;; `continue` & `break` support
	[1 2 3] = map-each       x [1 2 3] [continue x]
	[     ] = map-each/drop  x [1 2 3] [continue x]
	[1 2 3] = map-each       x [1 2 3] [if x > 1 [break] x]
	[1    ] = map-each/drop  x [1 2 3] [if x > 1 [break] x]
	[1 2 3] = map-each       x [1 2 3] [break]
	[     ] = map-each/drop  x [1 2 3] [break]

	;; /eval
	[1 2 3 4]           = map-each/eval      x [1 2 3 4] [x]
	[1 2 3 4]           = map-each/eval      x [1 2 3 4] [[x]]
	[[1] [2] [3] [4]]   = map-each/eval/only x [1 2 3 4] [[x]]
	[(1) (2) (3) (4)]   = map-each/only      x [1 2 3 4] [to paren! x]
	[(1) (2) (3) (4)]   = map-each/eval      x [1 2 3 4] [[to paren! x]]
	[1 [x y] 2 [x y]]   = map-each/eval      x [1 2    ] [[ x map-each x [x y] [x] ]]
	[1 [x y] 2 [x y]]   = map-each           x [1 2    ] [reduce [ x map-each      x [x y]  [x] ]]
	[1 [x y] 2 [x y]]   = map-each           x [1 2    ] [reduce [ x map-each/eval x [x y] [[x]] ]]

	;; filtering (pattern matching)
	[1 2 3 4 5 6]             = map-each            x             [1 "2" "3" 4 5 "6"] [to integer! x]
	["1" "2" "3" "4" "5" "6"] = map-each           [x [integer!]] [1 "2" "3" 4 5 "6"] [form x]       
	[1 2 3 4 5 6]             = map-each           [x [string!]]  [1 "2" "3" 4 5 "6"] [to integer! x]
	[1 [2] [3] 4 5 [6]]       = map-each/only/eval [x [string!]]  [1 "2" "3" 4 5 "6"] [[to integer! x]]
	[[1] "2" "3" [4] [5] "6"] = map-each/only/eval [x [integer!]] [1 "2" "3" 4 5 "6"] [[x]]
	[2 4 6]                   = map-each/drop      [x [integer!]] make vector! [1 2 3] [x * 2]	;-- vectors are no problem for type filter
	[]                        = map-each/drop      [x [float!]]   make vector! [1 2 3] [x * 2]
	[1 4 3]                   = map-each           [(2)]          make vector! [1 2 3] [4]

	;; /same & /case value filters
	[2 2          ] = (v: 2 map-each/case/drop [p: (v)] [2 2.0 #"^B" 2] [p/1])
	[2 2          ] = (v: 2 map-each/same/drop [p: (v)] [2 2.0 #"^B" 2] [p/1])
	[2 2.0 #"^B" 2] = (v: 2 map-each/case      [p: (v)] [2 2.0 #"^B" 2] [p/1])
	[2 2.0 #"^B" 2] = (v: 2 map-each/same      [p: (v)] [2 2.0 #"^B" 2] [p/1])
	r: reduce [v: "v" w: "v" w uppercase copy v]
	["v" "v" "v" "V"] == map-each           [p: (v)] r [p/1]
	["v" "v" "v"    ] == map-each/case/drop [p: (v)] r [p/1]
	["v" "v"        ] == map-each/same/drop [p: (w)] r [p/1]
	["v"            ] == map-each/same/drop [p: (v)] r [p/1]
	["V" "V" "V" "V"] == map-each/case      [p: (v)] r [uppercase copy p/1]
	["v" "V" "V" "V"] == map-each/same      [p: (w)] r [uppercase copy p/1]
	["V" "v" "v" "V"] == map-each/same      [p: (v)] r [uppercase copy p/1]

	;; /self
	error? try     [map-each/self x 4             [x]]                		;-- incompatible with ranges & maps
	error? try     [map-each/self x 2x2           [x]]                
	[1 2 3 4]     = map-each/self x [11 22 33 44] [x / 11]            
	"1234"        = map-each/self x "abcd"        [x - #"a" + #"1"]   		;-- string in, string out
	"a1b2c3d4"    = map-each/self/eval x "abcd"  [[x x - #"a" + #"1"]]
	"c1d2"        = map-each/self/eval [/i x] skip "abcd" 2 [[x i]]			;-- retains original index
	"abc1d2" = head map-each/self/eval [/i x] skip "abcd" 2 [[x i]]			;-- does not affect series before it's index
	"abef"        = map-each/self x "abCDef" [either x < #"a" [][x]]		;-- unset should silently be formed into empty string
	#(1 2 3 4   ) = map-each/self [k v]  #(1 2 3 4) [reduce [k v]]			;-- preserves map type
	#(2 4       ) = map-each/self [k v]  #(1 2 3 4) [v]           

	; ;; `advance` support (NOTE: without /drop - advance makes little sense and hard to think about)
	; [[2 3] #[none]] = map-each/drop/only  x    [1 2 3    ] [        advance]
	; [[2 3 4] [4]  ] = map-each/drop/only  x    [1 2 3 4  ] [        advance]
	; [[3 4] #[none]] = map-each/drop/only  x    [1 2 3 4  ] [advance advance]
	; [[3 4]        ] = map-each/drop/only [x y] [1 2 3 4  ] [        advance]
	; [[5]          ] = map-each/drop/only [x y] [1 2 3 4 5] [advance advance]
	; [4 #[none]    ] = map-each/drop [x [integer!]] [1 2.0 #"3" 4 'e 6] [set [x] advance x]	;-- jumps to next match
	; [2.0 6        ] = map-each/drop [x [number!] ] [1 2.0 #"3" 4 'e 6] [set [x] advance x]
	; [1 6          ] = map-each/drop [x [integer!]] [1 2.0 #"3" 4 'e 6] [advance x]			;-- does not affect the `x`
	; [4 'e #[none] ] = map-each [x [integer!]] [1 2.0 #"3" 4 'e 6] [set [x] advance x]		;-- without /drop includes skipped items
	; [2.0 #"3" 6   ] = map-each [x [number!] ] [1 2.0 #"3" 4 'e 6] [set [x] advance x]
	; [1 'e 6       ] = map-each [x [integer!]] [1 2.0 #"3" 4 'e 6] [advance x]

	;; pipe
	[1 2 3          ] = map-each      [x |]     [1 2 3]   [x]
	[1 2 3          ] = map-each      [/i x |]  [x y z]   [i]
	[x y z          ] = map-each      [/i x |]  [x y z]   [x]
	[1 2 3          ] = map-each      [p: x |]  [x y z]   [index? p]
	[x y z          ] = map-each      [p: x |]  [x y z]   [x]
	[x y z          ] = map-each      [p: | x]  [x y z]   [p: next p x]			;-- zero step, manual advance
	[x y z          ] = map-each/drop [p: | x]  [x y z]   [p: next p x]
	error?         try [map-each [p: |] [x y z] [p: next p]]					;-- no mandatory words
	[[x y]  [y z] z ] = map-each/only/eval      [x | y]   [x y z] [[x y]]
	[[x y]  [y z]   ] = map-each/only/eval/drop [x | y]   [x y z] [[x y]]
	[[x y z] y z    ] = map-each/only/eval      [x | y z] [x y z] [[x y z]]
	[[x y z]        ] = map-each/only/eval/drop [x | y z] [x y z] [[x y z]]
	[x y            ] = map-each/only/eval      [x | y z] [x y]   [[x y z]]		;-- too short to fit in
	empty?              map-each/only/eval/drop [x | y z] [x y]   [[x y z]]		;-- too short to fit in
	[1 2 3 3        ] = map-each/eval           [x y | z] [1 2 3]       [[x y z]]
	[1 2 3          ] = map-each/eval/drop      [x y | z] [1 2 3]       [[x y z]]
	[1 2 3 3 4      ] = map-each/eval           [x y | z] [1 2 3 4]     [[x y z]]
	[1 2 3          ] = map-each/eval/drop      [x y | z] [1 2 3 4]     [[x y z]]
	[1 2 3 3 4 5 5  ] = map-each/eval           [x y | z] [1 2 3 4 5]   [[x y z]]
	[1 2 3 3 4 5    ] = map-each/eval/drop      [x y | z] [1 2 3 4 5]   [[x y z]]
	[1 2 3 3 4 5 5 6] = map-each/eval           [x y | z] [1 2 3 4 5 6] [[x y z]]
	[1 2 3 3 4 5    ] = map-each/eval/drop      [x y | z] [1 2 3 4 5 6] [[x y z]]

	;; confirm that there's no leakage
	(x: 1     map-each x     [2 3 4]   [x: x * x]  x = 1)
	(x: y: 1  map-each [x y] [2 3 4 5] [x: y * x]  all [x = 1 y = 1])

	;; confirm binding is not shared
	depth: 0
	f: does [
		depth: depth + 1
		also map-each/eval [x y] [1 2 3 4] [			;-- shared code block between multiple nesting levels
			if depth < 2 [x: f]
			[x y]
		]
		depth: depth - 1
	]
	[[[1 2 3 4] 2 [1 2 3 4] 4] = f]




	;---------------------------- REMOVE-EACH -----------------------------
	#(a b c d) = remove-each x #(a 1 b 2 c 3 d 4) [integer? x]
	#(1 2 3 4) = remove-each x #(a 1 b 2 c 3 d 4) [word? x]
	[2x1 3x1 1x2 3x2 1x3 2x3] = remove-each p 3x3 [p/x = p/y]
	[1 2 3]    = remove-each x  3 [no]    
	[2]        = remove-each x  3 [odd? x]
	[1]        = remove-each x  1 [no]    
	[]         = remove-each x  0 [no]    
	[]         = remove-each x -1 [no]    
	"ac"       = remove-each x "abc" [#"b" = x]
	["" ""]    = remove-each x ["abc" "def"] [remove-each x x [yes] no]
	["ac" "df"]= remove-each x ["abc" "def"] [remove-each x x [find "be" x] no]
	[2 3 4   ] = remove-each [/i x [word!]] [a 2 3 b 4] [yes]
	"cf"       = remove-each x skip "abcdef" 2 [find "de" x]	;-- retains original index
	"abcf"= head remove-each x skip "abcdef" 2 [find "de" x]

]]


