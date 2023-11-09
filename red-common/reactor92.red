Red [
	title:   "Reactor 92"
	purpose: "Experimental implementation of REP#92's reduced deep-reactor model"
	author:  @hiiamboris
	license: 'BSD-3
	usage: {
		!! BEWARE ON-DEEP-CHANGE IS FULL OF BUGS !! (see #4788)
		so this should not be relied upon and used only for experimentation
	
		; base your reactor on `deep-reactor-92!`:
		r: make deep-reactor-92! [
			; ...your code here... e.g.:
			x: "abcd"
			
			; use this function to track changes and raise validation errors
			on-deep-change-92*: func [
				word        [word!]    "name of the field value of which is being changed"
				target      [series!]  "series at removal or insertion point"
				part        [integer!] "length of removal or insertion"
				insert?     [logic!]   "true = just inserted, false = about to remove"
				reordering? [logic!]   "removed items won't leave the series, inserted items came from the same series"
			][
				; ...your code to handle changes... e.g.:
				print [
					word ":"
					either insert? ["inserted"]["removing"]
					"at" mold/flat target
					part "items"
					either reordering? ["(reordering)"][""]
					either all [not insert? part = 0] ["(done)"][""]
				]
			]
		]
		
		; do smth with inner series of the reactor and watch the changes: 
		>> insert/part next r/x [1 0 1] 2
		x : inserted at "10bcd" 2 items 
		== "bcd"
		>> reverse/part next r/x 2
		x : removing at "10bcd" 2 items (reordering)
		x : inserted at "01bcd" 2 items (reordering)
		== "01bcd"
	}
	notes: {
		there are 3 types of actions:
		1. only inserting items
		   these only require a single event: after insertion 
		2. only removing items
		   these require 2 events:
		   - before removal - so we can evaluate the size and maybe contents of the removed part
		   - after removal - so we can work with the actual result of the change
		   these stages are currently distinguished by `part` argument:
		   if part is zero, then it's "after removal" event
		   I considered adding another `done?` argument but it seems excessive, because `part` is enough
		3. removing some, inserting some other
		   these always require 2 events:
		   - before removal
		   - after insertion
		   this type of event can have `reordering? = true` (reverse, random, sort actions, move on the same buffer)
		consequently, `done?: any [insert? part = 0]` is enough to check if series is in it's final state
	}
]

deep-reactor-92!: none
context [
	reduce-deep-change-92: function [owner word target action new index part] [
		f: :owner/on-deep-change-92*
		switch/default action [
			insert     []								;-- no removal phase
			inserted   [f word target part yes no]
			
			;; append's bug is: `append "abc" 123` will have part=1,
			;; and in `append/part` part is related to the appended value
			;; so have to use `length?` to obtain the size of change
			append     []								;-- no removal phase
			appended   [f word (p: skip head target index) length? p yes no]
			
			;; change is buggy: 'change' event never happens
			change     [f word (skip head target index) part no  no]	;-- so this won't fire at all
			changed    [f word (skip head target index) part yes no]	;-- target for some reason is at change's tail
			
			clear      [if part > 0 [f word target part no  no]]	;-- user code should remember 'part' given (if needed)
			cleared    [f word target part no  no]					;-- here part argument is invalid (zero)
			
			;; move is buggy: into another series it does not report anything at all
			;; so we have to assume it's the same series
			;; tried `same? head new head target` but 'moved' reports new=none so won't work
			move       [f word new    part no  yes]		;-- new is used here as source for some reason
			moved      [f word target part yes yes]
			
			;; poke has a bug: `poke "abc" 1 123` will report removal of "b" but will throw an error before insertion
			;; so it's not 100% reliable and I don't have a workaround
			poke       [f word (skip head target index) part no  no]
			poked      [f word (skip head target index) part yes no]
			
			put [
				unless tail? next target [  			;-- put reports found item as target, not the one being changed
					f word next target part no  no		;-- but removed item is not present at tail, so we don't have to report it
				]
			]
			put-ed [f word next target part yes no]
			
			random     [f word target part no  yes]
			randomized [f word target part yes yes]
			
			remove     [if part > 0 [f word target part no  no]]	;-- user code should remember 'part' given (if needed)
			removed    [f word target part no  no]					;-- here part argument is invalid (zero)
			
			reverse    [f word target part no  yes]
			reversed   [f word target part yes yes]
			
			;; sort is buggy in that it reports part=0 regardless of the /part argument
			;; so we have to assume the worst case
			sort       [f word target (length? target) no  yes]
			sorted     [f word target (length? target) yes yes]
			
			swap       [f word target part no  no]	;-- swap may be used on the same buffer, but we have no way of telling
			swaped     [f word target part yes no]
			
			take       [f word target part no  no]	;-- user code should remember 'part' given (if needed)
			taken      [f word target part no  no]	;-- part argument is invalid (zero)
	
			;; trim does not provide enough info to precisely pinpoint changes
			;; so we should consider it as global change from current index
			trim       [f word target (length? target) no  no]	;-- about to remove everything
			trimmed    [f word target (length? target) yes no]	;-- already filled with new stuff
		][
			do make error! "Unsupported action in on-deep-change*!"
		] 
	] 
	
	set 'deep-reactor-92! make deep-reactor! [
		on-deep-change-92*: func [
			word        [word!]    "name of the field value of which is being changed"
			target      [series!]  "series at removal or insertion point"
			part        [integer!] "length of removal or insertion"
			insert?     [logic!]   "true = just inserted, false = about to remove"
			reordering? [logic!]   "removed/inserted items belong to the same series"
			; done?       [logic!]   "signifies that series is in it's final state (after removal/insertion)"
		][
			;; placeholder to override
		]
		
		on-deep-change**: :on-deep-change*
		on-deep-change*: function [owner word target action new index part] [
			reduce-deep-change-92 owner to word! word target action :new index part
			on-deep-change**      owner word target action :new index part
		]
		
		; shouldn't be tampered with
		; on-change**: :on-change*
		; on-change*: function [word [any-word!] old [any-type!] new [any-type!]] [
		; ]
	]
]

comment {
	; test code
	r: make deep-reactor-92! [
		x: "abcd"
		
		on-deep-change-92*: func [
			word        [word!]    "name of the field value of which is being changed"
			target      [series!]  "series at removal or insertion point"
			part        [integer!] "length of removal or insertion"
			insert?     [logic!]   "true = just inserted, false = about to remove"
			reordering? [logic!]   "removed items won't leave the series, inserted items came from the same series"
			; done?       [logic!]   "signifies that series is in it's final state (after removal/insertion)"
		][
			; ...your code to handle changes... e.g.:
			print [
				word ":"
				either insert? ["inserted"]["removing"]
				"at" mold/flat target
				part "items"
				either reordering? ["(reordering)"][""]
				either part = 0 ["(done)"][""]
				; either done? ["(done)"][""]
			]
		]
	]
	
	?? r/x
	insert/part next r/x [1 0 1] 2
	reverse/part next r/x 2
	remove/part next next next r/x 3
	?? r/x
}
