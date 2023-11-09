Red [
	title:   "DO-ATOMIC mezzanine"
	purpose: "Atomically execute a piece of code that triggers reactions"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		Usually the code you evaluate triggers reactions instantly.
		Let's call it "sync" code.

		Reaction code, however, schedules more reactions but does not interrupt itself (it can't do otherwise).
		Set values will be updated immediately, but everything that depends on those values will be scheduled to update later.
		Let's call it "async" code.

		Sometimes it is useful to prevent reactions from kicking in in the sync code:
		1) you want reactions to trigger once after the code finishes, rather than after every step
		   e.g. you're adding some values to a deeply reactive block in a loop
		2) if otherwise it would leave some objects in a logically wrong state
		   e.g. you set one thing but will set another thing later, but those things are dependent
		   e.g. you take some parts of deep list to reinsert them into other place inside it

		This is where DO-ATOMIC comes into play. Just wrap your code with it:
			do-atomic [
				update/reactive/source1: value1
				update/reactive/source2: value2
				for-each [pos: x] reactive/source3 [
					if x = y [remove pos]
				]
				...
			]
		Reactions fire upon leaving the scope.

		When do-atomic is used from within "async" code, it's the same as DO.

		This only applies to %reactivity.red and not View subsystem's auto-sync.
		Should DO-ATOMIC also delay View changes?
		If so, how to do that? Or rather, how to flush the events that weren't synced?
		Usually I do that by `show window` or something, but that's very specific.
	}
]

do-atomic: none
make reactor! [
    react/later job: [do self/job]						;-- `do`es itself when changed

    ; set 'hold-horses									;@@ what name is better?
    ; set 'do-async
    set 'do-atomic func [
    	"Execute CODE as an atomic (from reactivity's POV) operation"
    	code [block!] "Will not be interrupted by reactions; reactive targets remain unchanged"
    ][
        either empty? system/reactivity/queue [job: code][do code]
    ]
]
