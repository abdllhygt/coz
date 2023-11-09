Red [
	title:   "DO-QUEUED-EVENTS mezzanine"
	purpose: "Flush the View event queue"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		Sometimes there's a need to force View subsystem to process all events that may be pending.
		One use is in event loops: process user input, then sleep a bit, then again...
		Another use I had is when simulating some input: I needed that input to be reflected on faces' state.

		DO-QUEUED-EVENTS comes to help: it processes up to 100 events at once.
		Capped at 100, because if event actor produces another event, the event queue may never empty.
	}
]

do-queued-events: does [
	loop 100 [unless do-events/no-wait [break]]		;-- capped at 100 in case of a deadlock
]
