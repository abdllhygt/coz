Red [
	title:   "#ASSERT macro and ASSERT mezzanine"
	purpose: "Allow embedding sanity checks into the code, to limit error propagation and simplify debugging"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		Usage:
			#assert [expression]
			#assert [expression "message"]
			#assert [
				expression1
				expression2 "message"
				expression3
				...
			]

		See assert.md for details.
	}
]


#macro [#assert 'on]  func [s e] [assertions: on  []]
#macro [#assert 'off] func [s e] [assertions: off []]
#do [unless value? 'assertions [assertions: on]]		;-- only reset it on first include

#macro [#assert block!] func [[manual] s e] [			;-- allow macros within assert block!
	nl: new-line? s										;-- preserve newline marker state before #assert
	either assertions [change s 'assert][remove/part s e]
	new-line s nl
]

assert: none
context [
	next-newline?: function [b [block!]] [
		forall b [if new-line? b [return b]]
		tail b
	]

	set 'assert function [
		[no-trace]
		"Evaluate a set of test expressions, showing a backtrace if any of them fail"
		tests [block!] "Delimited by new-line, optionally followed by an error message"
		/local result
	][
		while [not tail? tests] [
			set/any 'result do/next bgn: tests 'tests
			all [
				:result
				any [
					new-line? tests
					tail? tests
					all [string? :tests/1 new-line? next tests]
				]
				continue								;-- total success, skip to the next test
			]

			end: next-newline? tests
			if 0 <> left: offset? tests end [			;-- check assertion alignment
				if any [
					left > 1							;-- more than one free token before the newline
					not string? :tests/1				;-- not a message between code and newline
				][
					do make error! form reduce [
						"Assertion is not new-line-aligned at:"
						mold/part bgn 100				;-- mold the original code
					]
				]
				tests: end								;-- skip the message
			]

			unless :result [							;-- test fails, need to repeat it step by step
				msg:     either left = 1 [first end: back end][""]
				print ["ASSERTION FAILED!" msg]
				expr:    copy/part bgn end
				full:    any [attempt [to integer! system/console/size/x] 80]
				half:    to integer! full - 22 / 2		;-- 22 is 1 + length? "  Check  failed with "
				result': mold/flat/part :result half
				expr':   mold/flat/part :expr   half
				print ["  Check" expr' "failed with" result' "^/  Reduction log:"]
				trace/all expr
				;; no error thrown, to run other assertions
			]
		]
		exit											;-- no return value
	]
]

; #include %hide-macro.red
; #hide [#assert [
	; a: 123
	; not none? find/only [1 [1] 1] [1]
	; 1 = 1
	; 100
	; 1 = 2
	; ;3 = 2 4
	; 2 = (2 + 1) "Message"
	; 3 + 0 = 3

	; 2													;-- valid multiline assertion
	; -
	; 1
	; =
	; 1
	
	; #assert [1 + 1 > 3]									;-- reentry should be supported, as some assertions use funcs with assertions
; ]]
