Red [
	title:   "PRETTIFY mezzanine"
	purpose: "Automatically fill some (possibly flat) code/data with new-line markers for readability"
	author:  @hiiamboris
	license: 'BSD-3
	usage: {
		Example (flatten prettify's own code then restore it):
		
		>> probe prettify load mold/flat :prettify
		func [
			"Reformat BLOCK with new-lines to look readable"
			block [block! paren!] "Modified in place, deeply"
			/data "Treat block as data (default: as code)"
			/spec "Treat block as function spec"
			/parse "Treat block as Parse rule"
			/local w body orig limit inner code-hints! p part
		] [
			new-line/all orig: block no
			if empty? orig [
				return orig
			]
			limit: 80
			case [
				data [
					while [
						block: find/tail block block!
					] [
						prettify/data inner: block/-1
					]
					if any [
						inner
						limit <= length? mold/part orig limit
					] [
						new-line/skip orig yes 2
					]
				]
		... and so on
	}
]


;@@ TODO: VID support
prettify: function [
	"Reformat BLOCK with new-lines to look readable"
	block [block! paren! map!] "Modified in place, deeply"
	/data  "Treat block as data (default: as code)"
	/draw  "Treat block as Draw dialect"
	/spec  "Treat block as function spec"
	/parse "Treat block as Parse rule"
	/local body word
][
	unless map? block [new-line/all orig: block no]		;-- start flat
	if empty? orig [return orig]
	limit: 80											;-- expansion margin
	
	; attempt [											;-- trap in case it recurses into itself ;)
	; print [case [data ["DATA"] spec ["SPEC"] parse ["PARSE"] 'else ["CODE"]] mold block lf]
	case [
		map? block [
			block: values-of block
			while [block: find/tail block block!] [
				prettify/data block
			]
		]
		data [													;-- format data as key/value pairs, not expressions
			while [block: find/tail block block!] [
				prettify/data inner: block/-1					;-- descend recursively
			]
			if any [
				inner											;-- has inner blocks?
				limit <= length? mold/part orig limit			;-- longer than limit?
			][
				new-line/skip orig yes 2						;-- expand as key/value pairs
			]
		]
		spec [
			if limit > length? mold/part orig limit [return orig]
			new-line orig yes
			forall block [
				if all-word? :block/1 [new-line block yes]		;-- new-lines before argument/refinement names
				if /local == :block/1 [break]
			]
		]
		parse [
			if limit > length? mold/part orig limit [return orig]
			new-line orig yes
			forall block [
				case [
					'| == :block/1 [new-line block yes]			;-- new-lines before alt-rule
					block? :block/1 [prettify/parse block/1]
					paren? :block/1 [prettify block/1]
				]
			]
		]
		draw [
			if limit > length? mold/part orig limit [return orig]
			draw-commands: make hash! [
				line curve box triangle polygon circle ellipse text arc spline image
				matrix reset-matrix invert-matrix push clip rotate scale translate skew transform
				pen fill-pen font line-width line-join line-cap anti-alias
			]
			shape-commands: make hash! [
				move hline vline line curv curve qcurv qcurve arc
			]
			split: [p: (new-line back p yes)]
			system/words/parse orig rule: [any [
				ahead block! p: (new-line/all p/1 off) into rule
			|	set word word! [
					'shape any [
						set word word! if (find shape-commands word) split
					|	skip
					]
				|	if (find draw-commands word) split
				]
			|	skip
			]]
		]
		'code [
			code-hints!: make typeset! [any-word! any-path!]
			until [
				new-line block yes								;-- add newline before each independent expression
				tail? block: preprocessor/fetch-next block
			]
			system/words/parse orig [any [p:
				ahead word! ['function | 'func | 'has]			;-- do not mistake words for lit-/get-words
				set spec block! (prettify/spec spec)
				set body block! (prettify body)
			|	ahead word! 'draw pair! set block block! (prettify/draw block)
			|	set block block! (
					unless empty? block [
						part: min 50 length? block				;@@ workaround for #5003
						case [
							not find/part block code-hints! part [	;-- heuristic: data if no words nearby
								prettify/data block
							]
							find/case/part block '| part [		;-- heuristic: parse rule if has alternatives
								prettify/parse block
							]
							'else [prettify block]
						]
						if new-line? block [new-line p no]		;-- no newline before expanded block
					]
				)
			|	set block paren! (prettify block)
			|	skip
			]]
		]
	]
	orig
]

; probe prettify load mold/flat :prettify
