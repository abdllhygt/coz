Red [
	title:   "Mezz hub"
	purpose: "Include every script in the repo"
	author:  @hiiamboris
]

#include %include-once.red
#include %assert.red									;-- including it first will expand embedded assertions in the other scripts
; #assert off												;-- optionally uncomment this to disable assertions 
#include %debug.red

#include %with.red										;-- included by split.red
#include %without-gc.red
#include %setters.red									;-- included by parsee.red
#include %catchers.red									;-- included by parsee.red
#include %step.red	
#include %clip.red	
#include %extrema.red
#include %prettify.red
#include %split.red
#include %reshape.red
#include %match.red										;-- included by glob.red
#include %morph.red
#include %leak-check.red

#include %count.red
#include %collect-set-words.red
#include %keep-type.red
#include %typecheck.red

#include %selective-catch.red							;-- included by forparse.red
#include %forparse.red
#include %mapparse.red
#include %composite.red								;-- included by error-macro.red
#include %error-macro.red								;-- included by for-each.red
#include %bind-only.red								;-- included by for-each.red
#include %for-each.red								;-- included by map-each.red
#include %map-each.red								;-- included by sift-locate.red
#include %sift-locate.red
#include %xyloop.red									;-- included by explore.red
#include %relativity.red								;-- included by explore.red and tabbing.red
#include %tabbing.red
#include %explore.red
#include %bulk.red	

#include %clock.red
#include %shallow-trace.red							;-- included by clock-each.red & show-trace.red & stepwise-func.red
#include %clock-each.red
#include %show-trace.red								;-- unlikely needed given now available trace mezz
#include %stepwise-func.red

#include %trace-deep.red								;-- included by expect.red & show-deep-trace.red
#include %expect.red
#include %show-deep-trace.red							;-- unlikely needed given now available trace mezz

#include %exponent-of.red								;-- included by format-number.red & format-readable.red
#include %format-number.red								;-- included by timestamp.red
#include %format-readable.red
#include %stepwise-macro.red							;-- included by timestamp.red
#include %timestamp.red									;-- included by parsee.red
#include %tabs.red
#include %modulo.red
#include %print-macro.red
#include %hide-macro.red
#include %profiling.red

#include %glob.red

#include %do-atomic.red
#include %do-queued-events.red
#include %color-models.red								;-- included by contrast-with.red
#include %contrast-with.red
#include %is-face.red

#include %classy-object.red
#include %advanced-function.red							;-- included by search.red
#include %search.red
#include %quantize.red
#include %parsee.red


