Red [
	title:   "#print macro"
	purpose: "Shortcut for print #composite"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		More readable than the usual print:

		#print "Created cache in (iter: n - n0 + 1) iterations: (mold r)"
		#print "^/Building cache for (name), with spec: (mold/flat spec)..."
		#print {invoking: (cmd)^/from: "(to-local-file what-dir)"}
	}
]


#include %composite.red									;-- doesn't make sense to include this file without #composite also

#macro [#print skip] func [[manual] s e] [
	unless string? s/2 [
		print form make error! "#print macro expects a string! argument"
	]
	insert remove s [print #composite]
	s		;-- reprocess it again so it expands #composite
]
