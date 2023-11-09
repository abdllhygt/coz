Red [
	title:   "STEPWISE (macro variant)"
	purpose: "Allows you write long compound expressions as a sequence of steps"
	author:  @hiiamboris
	license: 'BSD-3
	usage: {
		#stepwise [
			2							;== 2
			. * 3						;== 6
			. + .						;== 12
			append/dup "" "x" . / 3		;== "xxxx"
			clear next .				;== tail "x"
			head .						;== "x"
		]
	}
	limitations: {
		- not for recursive invocation! (unless you're sure the `.` word is made local by the `function`)
		- won't work from the REPL (as any macro)
		- overrides `.` word; if you're using it - back it up
	}
]

#macro [#stepwise set code block!] func [[manual] s e] [
	while [not empty? code] [
		code: preprocessor/fetch-next insert code [.:]
	]
	remove/part s e
	insert s head code
]
