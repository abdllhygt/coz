Red [title: "Standalone version of the ParSEE backend"]

;; keep includes from spilling out
set [parsee: parse-dump: inspect-dump:]
	reduce bind [:parsee :parse-dump :inspect-dump]
	context [#include %parsee.red]
	