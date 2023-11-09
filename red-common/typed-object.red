Red [
	title:       "TYPED-OBJECT! prototype"
	description: "A per-object implementation of object field's type checking"
	author:      @hiiamboris
	license:     'BSD-3
	usage: {
		my-object: make typed-object! [
			x: "normal unrestricted object field"
			constant y: 1000							;) block Y from any further change
			restrict [integer! float!] z: exp 10		;) only allow integer & float values for Z
		]
		
		>> my-object/z: my-object/y
		== 1000
		
		>> my-object/z: 'wrong-type
		*** User Error: {Word z only accepts type(s) [integer! float!] not wrong-type of type word!}
		*** Where: do
		*** Near : :new
		*** Stack: type-check  
		
		>> my-object/y: exp 1
		*** User Error: {Word y is marked constant and cannot be set to 2.718281828459045}
		*** Where: do
		*** Near : new'
		*** Stack: type-check  
		
		>> ?? my-object
		my-object: make object! [
		    x: "normal unrestricted object field"
		    y: 1000
		    z: 1000
		]
	}
	notes: {
		Type data is kept within the object's on-change* function!
		So, any object built upon another typed-object will inherit type restrictions along with the data.
		
		Why on-change*?
		- If it was kept in a named field, e.g. `type-matrix*`, it would have been the first thing visible on every MOLD!
		  Since usually we see the result of `mold/part`, type-matrix would be the only thing you see,
		  and all objects would look similarly non-descriptive.
		- If it was kept outside of the object, in some hashtable perhaps, GC would be unable to release these objects!
		  Hash would keep growing since there's no way to know on Red level when object is not useful anymore.
		  Plus, that would involve extra hash lookup on every `set`, not slow per se, but 4-5 extra values to be interpreted have a price.
		
		Type data is a block! So lookups are linear and over 10-20 type-checked words will have a footprint.
		Why a block?
		  It's the only type that is copied within a function body by `make obj [...]` and `copy obj`.
		  Maps within data are not copied at all, ignored by copy/deep.
		  Hashes are not copied within function bodies.
		  We need a copy of the type data on every `copy` or `make`, otherwise changes to copied object will affect the prototype.
		  
		See also %classy-object.red which is a different (and incompatible) approach 
	}		
]


allow-types: function [
	"Change the types WORD can accept"
	word  [any-word!] "Must be bound to a typed-object!"
	types [block!]    "Allowed types"
][
	obj:   context? word
	body:  body-of :obj/on-change*
	types: complement make typeset! types				;-- complement here simplifies on-change using none-propagation
	put body/type-check word types
]

restrict: function [									;@@ or restricted? typed?
	"Allow object's WORD to only accept values of given TYPES and initialize it"
	types [block!]
	'word [set-word!] "Must be bound to a typed-object!"
	value [any-type!] "Initial value for the WORD"
][
	allow-types word types
	set word :value
]

constant: function [									;@@ or const? guard? fixed? fix?
	"Initialize object's WORD and guard it from any subsequent change"
	'word [set-word!] "Must be bound to a typed-object!"
	value [any-type!] "Initial value for the WORD"
][
	set word :value
	allow-types word []
]

type-check: function [
	"Verify the type of NEW value assigned to WORD"
	map  [block! hash! map!] "Map of word->typeset to check in"
	word [any-word!]         "Must be bound to a typed-object!"
	old  [any-type!]         "Used to restore the value if NEW is unsupported"
	new  [any-type!]         "Newly assigned value"
][
	if find select/skip map word 2 type? :new [			;-- select/skip supports maps
		set-quiet word :old								;-- in case of type error, word must have the old value
		word:  to word! word
		new':  mold/flat/part :new 40
		types: to block! complement map/:word
		message: pick [
			["Word" word "is marked constant and cannot be set to" new']
			["Word" word "only accepts type(s)" mold types "not" new' "of type" mold type? :new]
		] empty? types
		do make error! form reduce message
	]
]
	
typed-object!: object [
	on-change*: function [word [any-word!] old [any-type!] new [any-type!]] [
		type-check [] bind word self :old :new			;@@ bind required for `set obj value` case
	]
]

comment {
	;; test code
	obj: make typed-object! [
		restrict [integer!]      x: 1
		restrict [number!]       n: 2.0
		restrict [none! string!] t: "abc"
		restrict [function!]     f: does [print "F called"]
		v: none
		constant z: 3
	]
	
	obj2: make obj [
		restrict [integer!] z: 1 
	]
	
	?? obj
	
	obj/x: 2
	print try [obj/x: 2.0]
	obj/n: obj/n * 2
	print try [obj/n: 'word]
	obj/t: none
	obj/t: "xyz"
	print try [obj/t: 10]
	obj/f: does [print "new F called"]
	print try [obj/f: 20] 
	obj/f
	obj/v: 1 + 2
	; try [obj/x: none]
	print try [set obj none]
	print try [obj/z: 4]
	?? obj
	
	?? obj2
	obj2/z: 1000
	?? obj2
	; print mold/all obj
	
	; obj2: typed-object [
		; x: 1
		; restrict [integer!] y: 2
	; ]
	; ?? obj2 
	; set obj2 [3 4]
	; ?? obj2 
}
