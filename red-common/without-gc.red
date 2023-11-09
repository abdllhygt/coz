Red [
	title:       "WITHOUT-GC function"
	description: {Evaluate code with GC temporarily turned off, but restore GC's original state upon exit}
	author:      @hiiamboris
	license:     'BSD-3
	notes: {
		Relies on internals of sort at the moment.
		To be revised once we have a way to read GC state - REP #130.
	}
]

without-GC: function [
	"Evaluate CODE with GC temporarily turned off"
	code [block!]
][
	sort/compare [1 1] func [a b] code
]

