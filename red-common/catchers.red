Red [
	title:   "TRAP, FCATCH & PCATCH mezzanines"
	purpose: "Reimagined TRY & CATCH design variants, fixed ATTEMPT"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		TRAP - Enhances native TRY with /CATCH refinement

			Backward-compatible with native TRY, ideally should replace it.
			But we cannot override it (yet) because it traps RETURN & EXIT.

			In addition to native TRY, supports:
				/catch handler [function! block!]
			HANDLER is called whenever TRAP successfully catches an error.
				If it's a block, it should use THROWN to get the error.
				If it's a function, it should accept the error as it's argument.

			Returns:
			- on error: return of HANDLER if provided, error itself otherwise
			- normally: result of CODE evaluation

			Common code pattern:
				error: try/all [set/any 'result do code  'ok]
				unless error == 'ok [print error  result: 'default]
				:result
			Becomes much cleaner:
				trap/all/catch code [print thrown  'default]

			NOTE: R3 uses the similar design: `try/except [code][print "error"]`
			and similarly accepts a function of one argument for /except.


		PCATCH - Pattern-matched CATCH

			Evaluates CASES block after catching a throw (similar to native CASE).
			Rethrows values for which there is no matching pattern in CASES.
			Returns:
			- on throw: `CASE CASES` result if any pattern matched
			- normally: result of CODE evaluation

			Automatic rethrow works as if `true [throw thrown]` line was appended to CASES.
			However you can do always the same manually, e.g.:
				pcatch [
					thrown = my-value [
						print "found it!"
						if 1 = random 2 [throw thrown]		;) coin toss :D
					]
				][
					do code
				]

			`pcatch [true [thrown]] [...]` is equivalent to `catch [...]`

		
		FCATCH - Filtered CATCH

			Catches only values for which FILTER returns a truthy value (and also calls HANDLER if provided).
			Rethrows values for which FILTER returns a falsey value.
			Returns:
			- on throw: HANDLER's result (if provided) or thrown value otherwise
			- normally: result of CODE evaluation

				fcatch/handler [thrown = my-value] [
					do code
				][
					print "found it!"
				]

			`fcatch [] [...]` is equivalent to `catch [...]` (because result of [] is unset - a truthy value)

		
		THROWN

			Returns the thrown value inside:
			- CASES block of PCATCH
			- FILTER and HANDLER of FCATCH
			- HANDLER of TRY
			Inside CODE it will be = none.
			Undefined outside the scopes of TRY, FCATCH & PCATCH.


		ATTEMPT
			Fixed of #3755 issue.
			
			
		FOLLOWING - Analogue of `try .. finally ..` clause in C-like languages
		
			Ensures evaluation of finalization code while not disrupting non-local control flow.
			Due to #4416 the only way to achieve this is by leveraging `do/trace`, so:
			- it may slow down the code by 20-25%
			- it traps `return` and `exit`, though `continue`, `break` and `throw` work as expected
			- it only works at the top level, i.e. `following` won't work from within other `following` 
			
			Example:
				following [
					some code that can use break or throw exceptions 
				][
					do some resource cleanup
				]


		Notes

			Both trap RETURN & EXIT due to Red limitations.
			Due to #4416 issue, `throw/name` loses it's `name` during rethrow. Nothing can be done about it.

			See https://gitlab.com/-/snippets/1995436
			and https://github.com/red/red/issues/3755
			for full background on these designs and flaws of native catch
	}
]

#include %hide-macro.red
#include %assert.red

thrown: pcatch: fcatch: trap: following: none
context [
	with-thrown: func [code [block!] /thrown] [			;-- needed to be able to get thrown from both *catch funcs
		do code
	]

	;-- this design allows to avoid runtime binding of filters
	;@@ should it be just :thrown or attempt [:thrown] (to avoid context not available error, but slower)?
	set 'thrown func ["Value of the last THROW from FCATCH or PCATCH"] bind [:thrown] :with-thrown

	set 'pcatch function [
		"Eval CODE and forward thrown value into CASES as 'THROWN'"
		cases [block!] "CASE block to evaluate after throw (normally not evaluated)"
		code  [block!] "Code to evaluate"
	] bind [
		with-thrown [
			set/any 'thrown catch [return do code]
			;-- the rest mimicks `case append cases [true [throw thrown]]` behavior but without allocations
			forall cases [if do/next cases 'cases [break]]	;-- will reset cases to head if no conditions succeed
			if head? cases [throw :thrown]					;-- outside of `catch` for `throw thrown` to work
			do cases/1										;-- evaluates the block after true condition
		]
	] :with-thrown
	;-- bind above binds `thrown` and `code` but latter is rebound on func construction
	;-- as a bonus, `thrown` points to a value, not to a function, so a bit faster

	set 'fcatch function [
		"Eval CODE and catch a throw from it when FILTER returns a truthy value"
		filter [block!] "Filter block with word THROWN set to the thrown value"
		code   [block!] "Code to evaluate"
		/handler        "Specify a handler to be called on successful catch"
			on-throw [block!] "Has word THROWN set to the thrown value"
	] bind [
		with-thrown [
			set/any 'thrown catch [return do code]
			unless do filter [throw :thrown]
			either handler [do on-throw][:thrown]
		]
	] :with-thrown

	set 'trap function [					;-- backward-compatible with native try, but traps return & exit, so can't override
		"Try to DO a block and return its value or an error"
		code [block!]
		/all   "Catch also BREAK, CONTINUE, RETURN, EXIT and THROW exceptions"
		/keep  "Capture and save the call stack in the error object"
		/catch "If provided, called upon exceptiontion and handler's value is returned"
			handler [block! function!] "func [error][] or block that uses THROWN"
			;@@ maybe also none! to mark a default handler that just prints the error?
		/local result
	] bind [
		with-thrown [
			plan: [set/any 'result do code  'ok]
			set 'thrown try/:all/:keep plan				;-- returns 'ok or error object
			case [
				thrown == 'ok   [:result]
				block? :handler [do handler]
				'else           [handler thrown]		;-- if no handler is provided - this returns the error
			]
		]
	] :with-thrown
	
	;@@ of course this traps `return` because of #4416
	set 'following function [
		"Guarantee evaluation of CLEANUP after leaving CODE"
		code    [block!] "Code that can use break, continue, throw"
		cleanup [block!] "Finalization code"
	][
		do/trace code :cleaning-tracer
	]
	cleaning-tracer: func [[no-trace]] bind [[end] do cleanup] :following	;-- [end] filter minimizes interpreted slowdown
]


#hide [#assert [
	1 =    catch [fcatch         [            ] [1      ]  ]	;-- normal result
	unset? catch [fcatch         [            ] [       ]  ]
	unset? catch [fcatch         [true        ] [       ]  ]
	2 =    catch [fcatch         [            ] [throw 1] 2]	;-- unset is truthy, always catches
	1 =    catch [fcatch         [no          ] [throw 1] 2]
	1 =    catch [fcatch         [no          ] [throw/name 1 'abc] 2]
	2 =    catch [fcatch         [yes         ] [throw 1] 2]
	1 =    catch [fcatch         [even? thrown] [throw 1] 2]
	2 =    catch [fcatch         [even? thrown] [throw 4] 2]
	3 =    catch [fcatch/handler [even? thrown] [throw 3] [thrown * 2]]
	8 =    catch [fcatch/handler [even? thrown] [throw 4] [thrown * 2]]
	9 =    catch [loop 3 [fcatch/handler [] [throw 4] [break/return 9]]]			;-- break test
	8 =    catch [loop 3 [fcatch/handler [continue] [throw 4] [break/return 9]] 8]	;-- continue test

	1 =    catch [pcatch [              ] [throw 1] 2]			;-- no patterns matched, should rethrow
	3 =    catch [pcatch [true [3]      ] [throw 1]  ]			;-- catch-all
	3 =    catch [pcatch [true [throw 3]] [throw 1] 2]			;-- catch-all with custom throw
	1 =    catch [pcatch [even? thrown [thrown * 2]] [throw 1]]
	4 =    catch [pcatch [even? thrown [thrown * 2]] [throw 2]]
	4 =    catch [pcatch [even? thrown [thrown * 2] thrown < 5 [0]] [throw 2]]
	0 =    catch [pcatch [even? thrown [thrown * 2] thrown < 5 [0]] [throw 3]]
	5 =    catch [pcatch [even? thrown [thrown * 2] thrown < 5 [0]] [throw 5]]
	9 =    catch [repeat i 4 [pcatch [thrown < 3 [] 'else [break/return 9]] [throw i]]]		;-- break test
	9 =    catch [repeat i 4 [pcatch [thrown < 3 [continue] 'else [break/return 9]] [throw i]]]

	unset?    trap []									;-- native try compatibility tests
	1       = trap [1]
	3       = trap [1 + 2]
	error?    trap [1 + none]
	error?    trap/all [throw 3 1]
	error?    trap/all [continue 1]
	10      = trap/catch [1 + none] [10]				;-- /catch tests
	'script = trap/catch [1 + none] [select thrown 'type]
	6       = trap/all/catch [throw 3 1] [2 * select thrown 'arg1]
	
	i: 0
	1 = following [1] [2]
	1 = following [i: i + 1] [2]
	error? try/all [following [continue] [i: i + 1]]
	2 = i
	error? try/all [following [break] [i: i + 1]]
	3 = i
	0 =      catch [following [throw 0] [i: i + 1]]
	4 = i
	error? try     [following [0 / 0] [i: i + 1]]
	5 = i
	;@@ add return test if #4416 gets fixed
]]

{
	;-- this version is simpler but requires explicit `true [throw thrown]` to rethrow values that fail all case tests
	;-- and that I consider a bad thing

	set 'pcatch function [
		"Eval CODE and forward thrown value into CASES as 'THROWN'"
		cases [block!] "CASE block to evaluate after throw (normally not evaluated)"
		code  [block!] "Code to evaluate"
	] bind [
		with-thrown [
			set/any 'thrown catch [return do code]
			case cases									;-- case is outside of catch for `throw thrown` to work
		]
	] :with-thrown
}
