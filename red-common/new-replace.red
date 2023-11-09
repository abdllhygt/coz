Red [
	title:   "REPLACE function rewrite"
	purpose: "Simplify and empower it, move parse functionality into mapparse"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {See https://github.com/red/REP/issues/146}
]


; #include %assert.red
#include %hide-macro.red


context [
	string-formed-types!: complement make typeset! [any-string! bitset! binary!]
	binary-formed-types!: complement make typeset! [any-string! bitset! binary! integer!]

	;; block leveraging version
	do [
	set 'replace1 function [
		"Replaces every pattern in series with a given value, in place"
	    series  [any-block! any-string! binary! vector!] "The series to be modified"	;-- series! barring image!
	    pattern [any-type!] "Specific value to look for"
	    value   [any-type!] "New value to replace with"
	    /once "Replace only the first occurrence, return position after replacement"	;-- makes no sense with /deep, returns series unchanged if no match
	    /deep "Replace pattern in all sublists and paths as well"
	    /case "Search for pattern case-sensitively"
	    /same "Search for pattern using `same?` comparator"
	    ;@@ /only applies to both pattern & value, but how else? or we would have /only-pattern & /only-value
	    /only "Treat type/typeset/series pattern, as well as series value, as single item"
	    /part "Limit the lookup region"
	    	limit [integer! series!]
	][
		if all [deep once] [cause-error 'script 'bad-refines []]	;-- incompatible
		unless any-block? series [deep: off]
		
		start: series										;-- starting offset may be adjusted if part is negative
		either limit [
			if integer? limit [limit: skip start limit]		;-- convert limit to series, or will have to update it all the time
			if back?: negative? offset? start limit [		;-- ensure negative limit symmetry
				start: limit
				limit: series
			]
		][
			limit: tail series
		]
		
		if any [any-string? series binary? series] [		;-- if pattern/value needs forming, form it once rather than on each lookup
			formed-types!: either binary? series [binary-formed-types!][string-formed-types!]
			if find formed-types! type? :pattern [pattern: to series form :pattern]
			if find formed-types! type? :value   [value:   to series form :value]
		]
		
		;; pattern size will be found out after first match:
		size: [size: offset? match find/:case/:same/:only/match/tail match :pattern]
		
		next-match: [match: find/:case/:same/:only/:part pos :pattern offset? pos limit]	;@@ offset = workaround for #5319
		shallow-replace: [
			unless pos =? match [append/part result pos match]			;@@ unless = workaround for #5320
			append/:only result :value
			pos: skip match do size
		]
		replace-in-sublists: [
			;; using any-list! makes paths real hard to create dynamically, so any-block! here
			while [list: find/part pos any-block! offset? pos match] [	;@@ offset = workaround for #5319
			; while [list: find/part pos any-block! match] [
				replace1/deep/:case/:same/:only sublist: list/1 :pattern :value
				unless pos =? list [append/part result pos list]		;@@ unless = workaround for #5320
				append/only result sublist
				pos: next list
			]
		]
		
		;; two reasons to use a separate buffer: O(1) performance and ease of tracking of /part which would move otherwise
		result: clear copy/part start limit
		pos: start
		system/words/case [
			once     [either do next-match shallow-replace [return limit]]
			not deep [while next-match shallow-replace]
			deep [
				while next-match [
					do replace-in-sublists
					do shallow-replace
				]
				match: limit
				do replace-in-sublists
			]
		]
	
		;; global replace returns original location: if part < 0 it's end (<> series), otherwise start
		;; /once returns offset after match (or tail if no match, indicating full processing of input)
		end: change/part start result pos
		either any [back? once] [end][start]
	]
	]

	;; compiler-friendly version
	set 'replace2 function [
		"Replaces every pattern in series with a given value, in place"
	    series  [any-block! any-string! binary! vector!] "The series to be modified"	;-- series! barring image!
	    pattern [any-type!] "Specific value to look for (typesets, datatypes, bitsets have special meaning)"
	    value   [any-type!] "New value to replace with"
	    /once "Replace only the first occurrence, return position after replacement"	;-- makes no sense with /deep, returns series unchanged if no match
	    /deep "Replace pattern in all sublists and paths as well"
	    /case "Search for pattern case-sensitively"
	    /same "Search for pattern using `same?` comparator"
	    ;@@ /only applies to both pattern & value, but how else? or we would have /only-pattern & /only-value
	    /only "Treat type/typeset/bitset/series pattern, as well as series value, as single item"
	    /part "Limit the lookup region"
	    	limit [integer! series!]
	][
		if all [deep once] [cause-error 'script 'bad-refines []]	;-- incompatible
		unless any-block? series [deep: off]
		
		start: series										;-- starting offset may be adjusted if part is negative
		either not limit [
			limit: tail series
		][
			if integer? limit [limit: skip start limit]		;-- convert limit to series, or will have to update it all the time
			if back?: negative? offset? start limit [		;-- ensure negative limit symmetry
				start: limit
				limit: series
			]
		]
		
		if any [any-string? series binary? series] [		;-- if pattern/value needs forming, form it once rather than on each lookup
			formed-types!: either binary? series [binary-formed-types!][string-formed-types!]
			if find formed-types! type? :pattern [pattern: to series form :pattern]
			if find formed-types! type? :value   [value:   to series form :value]
		]
		
		;; pattern size will be found out after first match:
		size: [size: offset? match find/:case/:same/:only/match/tail match :pattern]
		
		;; two reasons to use a separate buffer: O(1) performance and ease of tracking of /part which would move otherwise
		result: clear copy/part start limit
		pos: start
		; while [not pos =? limit] [
		while [0 < left: offset? pos limit] [
			; match: find/:case/:same/:only/:part pos :pattern limit
			match: find/:case/:same/:only/:part pos :pattern left			;@@ left = workaround for #5319
			end: any [match limit]
			if deep [										;-- replace in inner lists up to match location
				;; using any-list! makes paths real hard to create dynamically, so any-block! here
				while [list: find/part pos any-block! offset? pos end] [	;@@ offset = workaround for #5319 
				; while [list: find/part pos any-block! end] [
					append/part result pos list
					append/only result replace2/deep/:case/:same/:only list/1 :pattern :value
					pos: next list
				]
			]
			unless pos =? end [append/part result pos pos: end]				;@@ unless = workaround for #5320
			; append/part result pos pos: end
			if match [										;-- replace the pattern
				append/:only result :value
				pos: skip match do size
	 			if once [break]
	 		]
	 	]
	 	
		;; global replace returns original location: if part < 0 it's end (<> series), otherwise start
		;; /once returns offset after match (or tail if no match, indicating full processing of input)
		end: change/part start result pos
		either any [back? once] [end][start]
	]
]

#hide [
	;@@ move these into new-replace-tests
	#assert [
		replace: :replace2
		[[1] 2 [1] 1 [1]]      = head replace/once      [[1] 1 [1] 1 [1]] 1 2
		      [[1] 1 [1]]           = replace/once      [[1] 1 [1] 1 [1]] 1 2
		[[1] 1 [1] 1 [1]]      = head replace/once      [[1] 1 [1] 1 [1]] 3 2
		tail?                         replace/once      [[1] 1 [1] 1 [1]] 3 2	;-- no match - returns tail (processed everything)
		
		[[2] 2 [2] 2 [2]]           = replace/deep      [[1] 1 [1] 1 [1]] 1 2
		[[2] 2 [2] 2 [2] 3]         = replace/deep      [[1] 1 [1] 1 [1] 3] 1 2
		[[2] 2 [2] 2 [2]]           = replace/deep      [[1] 1 [1] 1 [1]] [1] 2
		[2 1 2 1 2]                 = replace/deep/only [[1] 1 [1] 1 [1]] [1] 2
		[2 1 2 1 2]                 = replace/only      [[1] 1 [1] 1 [1]] [1] 2
		[2 1 2 1 2]                 = replace           [[1] 1 [1] 1 [1]] block! 2
		[2 1 2 1 2]                 = replace/deep      [[1] 1 [1] 1 [1]] block! 2
		[2 1 2 1 2]                 = replace/deep      [[1] 1 [[]] 1 [1]] block! 2
		[[1] 2 1 [1] 2 1 [1]]       = replace           [[1] 1 [1] 1 [1]] 1 [2 1]
		[[1] 2 1 [1] 2 1 [1]]       = replace           [[1] 1 [1] 1 [1]] [1] [2 1]
		[[2 1] 2 1 [2 1] 2 1 [2 1]] = replace/deep      [[1] 1 [1] 1 [1]] 1 [2 1]
		[[2 1] 2 1 [2 1] 2 1 [2 1]] = replace/deep      [[1] 1 [1] 1 [1]] [1] [2 1]
		[[[2 1]] [2 1] [[2 1]] [2 1] [[2 1]]] = replace/deep/only [[1] 1 [1] 1 [1]] 1 [2 1]
		[[2 1] 1 [2 1] 1 [2 1]]     = replace/deep/only [[1] 1 [1] 1 [1]] [1] [2 1]		;-- should not try to match the insertion
		[2 1 2 1 1]                 = replace           [1 1 1 1 1] [1 1] [2 1]
		[1 2 2 1 1]            = head replace/part skip [1 1 1 1 1] 3 1 2 -2		;-- negative /part
		[1 1]                       = replace/part skip [1 1 1 1 1] 3 1 2 -2
		[2 2 2 1 1]            = head replace/part skip [1 1 1 1 1] 3 1 2 -4
		[1 1]                       = replace/part skip [1 1 1 1 1] 3 1 2 -4
		[2 3 2 3 2 3 1 1]      = head replace/part skip [1 1 1 1 1] 3 1 [2 3] -4
		[1 1]                       = replace/part skip [1 1 1 1 1] 3 1 [2 3] -4		;-- should be smart enough to return after the change here
		; "<b> <b> <b>"                         = replace           "a a a" "a" <b>	;@@ #5321 - tags are broken, too hard to work around
		; (as tag! "<b> <b> <b>")               = replace           <a a a> "a" <b>
		; <a a a>                               = replace           <a a a> <a> <b>
	]
]

#hide [
	benchmarks: [
		print "^/in place, big buffer"
		block: append/dup make [] n: 100'000 0 n
		clock [replace1    block 0 1]
		clock [replace2    block 1 2]
		clock [replace/all block 2 0]
		
		print "^/length change, big buffer"
		block: append/dup make [] n 0 n  clock [replace1    block 0 [1 2]]
		block: append/dup make [] n 0 n  clock [replace2    block 0 [1 2]]
		block: append/dup make [] n 0 n  clock [replace/all block 0 [1 2]]
		block: none recycle
		
		print "^/length change, mid buffer"
		block: append/dup [] 0 1000  clock [loop 100 [replace1    block 0 [1 2] replace1    block [1 2] 0]]
		block: append/dup [] 0 1000  clock [loop 100 [replace2    block 0 [1 2] replace2    block [1 2] 0]]
		block: append/dup [] 0 1000  clock [loop 100 [replace/all block 0 [1 2] replace/all block [1 2] 0]]
		
		print "^/length change, small buffer"
		block: append/dup [] 0 10  clock [loop 10000 [replace1    block 0 [1 2] replace1    block [1 2] 0]]
		block: append/dup [] 0 10  clock [loop 10000 [replace2    block 0 [1 2] replace2    block [1 2] 0]]
		block: append/dup [] 0 10  clock [loop 10000 [replace/all block 0 [1 2] replace/all block [1 2] 0]]
		
		print "^/length change, mid buffer (hash)"
		hash: make hash! append/dup [] 0 1000  clock [loop 100 [replace1    hash 0 [1 2] replace1    hash [1 2] 0]]
		hash: make hash! append/dup [] 0 1000  clock [loop 100 [replace2    hash 0 [1 2] replace2    hash [1 2] 0]]
		hash: make hash! append/dup [] 0 1000  clock [loop 100 [replace/all hash 0 [1 2] replace/all hash [1 2] 0]]
		
		print "^/length change, small buffer (hash)"
		hash: make hash! append/dup [] 0 10  clock [loop 10000 [replace1    hash 0 [1 2] replace1    hash [1 2] 0]]
		hash: make hash! append/dup [] 0 10  clock [loop 10000 [replace2    hash 0 [1 2] replace2    hash [1 2] 0]]
		hash: make hash! append/dup [] 0 10  clock [loop 10000 [replace/all hash 0 [1 2] replace/all hash [1 2] 0]]
		
		print "^/init time"
		block: [0] clock [repeat i 100'000 [replace1    block i - 1 i]]
		block: [0] clock [repeat i 100'000 [replace2    block i - 1 i]]
		block: [0] clock [repeat i 100'000 [replace/all block i - 1 i]]
	]
	do benchmarks
]
