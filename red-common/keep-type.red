Red [
	title:   "KEEP-TYPE mezzanine"
	purpose: "Filter list using accepted type or typeset"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		Examples:
	        msgs: keep-type message-log string!
	        objs: keep-type message-log object!		
	}
]


;@@ TODO: more general keep-thing function that can filter on charsets - opposite of trim/all/with
keep-type: function [
	"Make a list including only values of type TYPE from the original LIST"
	list [any-block!]
	type [datatype! typeset!] "Typesets are accepted"
][
	r: clear copy list
	parse list [collect into r any thru keep type]				;-- can use FORPARSE here, but this is faster
	r
]

comment {

	;; this version is 10% slower and is only working in the fast-lexer branch (commit 54a0db76)
	keep-type: function [
		"Make a list including only values of type TYPE from the original LIST"
		list [any-block!]
		type [datatype! typeset!] "Typesets are accepted"
	][
		r: make type? list 10
		while [list: find/tail list type] [append/only r :list/-1]
		r
	]

	;; this version is 2x (or more, depending on the length) times slower
	keep-type: function [
		"Make a list including only values of type TYPE from the original LIST"
		list [any-block!]
		type [datatype! typeset!] "Typesets are accepted"
	][
		remove-each x list: copy list
			either datatype? type
				[[ type <> type? :x ]]
				[[ not find type type? :x ]]
		list
	]
}

#assert [[]                      = keep-type [1 1.0 "ab" "cd" [blk] %file] none!]
#assert [[1 1.0]                 = keep-type [1 1.0 "ab" "cd" [blk] %file] number!]
#assert [[1.0]                   = keep-type [1 1.0 "ab" "cd" [blk] %file] float!]
#assert [[[blk]]                 = keep-type [1 1.0 "ab" "cd" [blk] %file] block!]
#assert [["ab" "cd"]             = keep-type [1 1.0 "ab" "cd" [blk] %file] string!]
#assert [["ab" "cd" [blk] %file] = keep-type [1 1.0 "ab" "cd" [blk] %file] series!]

