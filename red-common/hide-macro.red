Red [
	title:   "#HIDE macro"								;-- #local is already used by the preprocessor, #localize is l10n-related
	purpose: "Collect and hide set-words and loop counters"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		This is most useful when working in the global context, esp. for unit tests.
		Use WITH when you want minimum overhead. #HIDE is slower, but fully automated collector.

		Usage:
			a: 321
			#hide [print [a: 123]]						;-- prints 123
			?? a										;-- still 321

		Limitations:
			traps return, exit
	}
]

#macro [#hide block!] func [[manual] s e] [				;-- allow macros within local block!
	remove/part insert s compose/deep/only [do reduce [function [] (s/2)]] 2
	s													;-- reprocess
]

