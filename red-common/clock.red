Red [
	title:   "Simple CLOCK mezz for benchmarking"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		On units:
		No nanoseconds here, as it takes a lot of execution time to reach 1 ns precision.
		No seconds either as it makes sense to make long times as stand out, e.g. `10000 ms` vs `10 ms`.
		Microseconds seem better looking than `0.01 ms` or `0.00 ms`, esp. since I limited formatting to 3 digits, so they are supported.
	}
]

unless function? get/any 'clock [						;-- defined in recent Red builds
	clock: function [
		"Display execution time of CODE, returning result of it's evaluation"
		code [block!]
		/times n [integer! float!] "Repeat N times (default: once); displayed time is per iteration"
		/delta "Don't print the result, return time delta (ms)"
		/local r
	][
		n: max 1 any [n 1]
		text: mold/flat/part code 70					;-- mold the code before it mutates
		t1: now/precise/utc
		set/any 'r loop to integer! n code				;-- float is useful for eg. `1e6` instead of `1'000'000`
		t2: now/precise/utc
		dt: 1e3 / n * to float! difference t2 t1
		either delta [
			dt
		][
			unit: either dt < 1 [dt: dt * 1e3 "μs^-"]["ms^-"]
			parse form dt [								;-- save 3 significant digits max
				0 3 [opt #"." skip] opt [to #"."] dt: (dt: head clear dt)
			]
			print [dt unit text]
			:r
		]
	]
]
