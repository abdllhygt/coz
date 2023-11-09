Red [
	title:   "BIND-ONLY mezzanine"
	purpose: "Selectively bind a word or a few only (until we have a native)"
	author:  @hiiamboris
	license: 'BSD-3
	usage: {
		Bind single word in a block:
			>> bind-only code 'my-word  
			Binds all instances of [my-word 'my-word :my-word my-word:]
			inside CODE to the context of given MY-WORD.

		Bind multiple words at once:
			>> c1: context [x: 1]
			>> c2: context [y: 2]
			>> z: 3
			>> print bind-only [x y z] reduce [in c1 'x  in c2 'y]  ;-- binds x and y to c1 and c2
			1 2 3
			In this case the targets block is likely already provided to the function and is bound accordingly.

		It's similar to native bind. Compare:
			>> bind code 'my-word`
			binds whole code to `context? 'my-word`
			>> bind-only code 'my-word`
			binds only 'my-word to `context? 'my-word`
		The only differences are:
		- it accepts a block as it's second argument
		- it does not accept a word as it's first argument, as it makes no sense:
			>> `bind-only 'word 'word`
			word here is already bound, no point in spawning another

		With this compatibility in mind, it could be made into an /only refinement for the bind native.
		And it should, as speed is it's major limitation
	}
]

;; non-strict by default: rebinds any word type
bind-only: function [
	"Selective bind"
	where	[block!] "Block to bind"
	what	[any-word! block!] "Bound word or a block of, to replace to, in the where-block"
	/strict "Compare words strictly - not taking set-words for words, etc."
	/local w
][
	found?: does either block? what [
		finder: pick [find/same find] strict
		compose/deep [all [p: (finder) what w  ctx: p/1]]	;-- use found word's context
	][
		ctx: what										;-- use (static) context of 'what
		pick [ [w =? what] [w = what] ] strict
	]
	parse where rule: [any [
		ahead any-block! into rule						;-- into blocks, parens, paths, hash
	|	change [set w any-word! if (found?)] (bind w ctx)
	|	skip
	]]
	where
]
