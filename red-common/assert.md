# [ASSERT](assert.red)

## Use cases

1. **Unit testing**

   ```
   my-func: func [x][...]		;) declared a function
   
   #assert [					;) a set of tests to ensure it's correct
   	"1" = my-func 1
   	"2" = my-func 2
   	"x" = my-func 10
   	...
   ]
   ```
   This feature requires set-words to be hidden, which is achieved by [`#localize` macro](localize-macro.red). 

2. **Run-time state validity checking**

   ```
   my-func: func [...][
   	x: my-func2 ...
   	y: my-func3 ...
   	#assert [x > y]			;) ensure state is correct to limit error propagation
   ]
   ```
   This must work as fast as possible and have minimal memory footprint, or people will tend to avoid assertions where they could have them.

3. **Function argument verification**

   A common variant of (2), where instead of cryptic errors pointing to some logic inside the function we want to declare that it's simply improperly used.
   ```
   my-func: func [x [integer!] "0 to 10 !!"] [
   	#assert [all [0 <= x x <= 10]]
   	... code that uses x ...
   ]
   ```
   Apart from speed, this may require a human-friendly error message or it may be hard to get what exactly failed, even for code's author. Real example: 
   ```
   #assert [not all [def/flags/compiled find [not-compiled compiling] def/status] "Issue has not been compiled!"]
   ```

## Usage

**Syntax** is simple, 2 forms are supported:
```
#assert [expression]
#assert [expression "message on failure"]
```
Multiple expressions can be included into single `#assert` block:
```
#assert [
	expression1
	expression2 "message on failure"
	expression3
	...
]
```

Note:
- multiple expressions per line are not allowed
- single expression can span as many lines as required

### Example

```
diagonal?: function [
	"Measure diagonal size of a box"
	box [block!] "2 pairs"
][
	#assert [							;) argument checks
		2 = length? box
		pair? :box/1
		pair? :box/2
	]
	size: box/2 - box/1
	sqrt (size/x ** 2) + (size/y ** 2)
]

#assert [								;) unit test
	0 = diagonal? [ 0x0  0x0]			;) extremum
	1 = diagonal? [ 0x0  0x1]			;) single axis tests
	1 = diagonal? [ 0x0  1x0]
	1 = diagonal? [ 0x1  0x0]
	1 = diagonal? [ 1x0  0x0]
	1 = diagonal? [ 0x0 -1x0]
	1 = diagonal? [ 0x0 0x-1]
	3 = diagonal? [ 0x0 5x4 ]			;) to produce a failure example
	4 = diagonal? [ 0x0 5x4 ] "But of course this will fail"
	1 = diagonal? [-1x0 0x0]
	1 = diagonal? [0x-1 0x0]
	5 = diagonal? [-4x0 0x3]			;) 2 axis combined
]
```
When included this file prints:
```
ASSERTION FAILED!
  Check [3 = diagonal? [0x0 5x4]] failed with false
  Reduction log:
    diagonal? [0x0 5x4]              => 6.4031242374328485
    3 = 6.4031242374328485           => false
ASSERTION FAILED! But of course this will fail
  Check [4 = diagonal? [0x0 5x4]] failed with false
  Reduction log:
    diagonal? [0x0 5x4]              => 6.4031242374328485
    4 = 6.4031242374328485           => false
```
Full reduction log helps you see what happened. Notice the error message I provided. Evaluation continues despite the errors.

More real world uses can be found in my [mezz-warehouse repo](https://gitlab.com/search?search=%23assert&group_id=&project_id=18539768&scope=&search_code=true&snippets=false&repository_ref=master&nav_source=navbar) to help you get more confident with `#assert`.

### Guidelines

1. **Do write** unit tests and parameter assertions, especially for functions without side effects and those you share with the others.

   Often when developing a solution we make assumptions about how our code works and how our data looks (e.g. `x` will be positive, and `f` should only return a `string`). If we don't write down these assumptions right away while our mind is deep in the problem, we'll forget them and when they will fail we'll have to fully reconstruct the logic of that code in our head to recall what assumptions we made while writing it and why. Writing them down saves a lot of time later.

   If your function requires I/O, isolate I/O from algorithms used and write tests for those algorithms.
   
2. **Keep** tests for every function **right after** it's definition. This way:
   - you will always immediately know what code is *covered* by tests and what isn't
   - your tests will be *kept in sync* with changes in the function
   - tests will automatically run every time you include the function, so you will know it's *not regressed*
   - this practice *allows you* to *trust* this code and when you hit a bug you will *know it's not here*, and will look at other possibilities<br><br>

   Of course, this will also work in separate test files, which have their use cases as well.
   
3. In complex programs after you modify some shared state, and you expect this state to honor some constraints, do **test those constraints** after the change. This may save your time spent on debugging.

4. Know that they assertions may fail to work at all due to preprocessor bugs. In that case try re-including `assert.red` within that particular source file.      

5. Keep test expressions **side-effect free** if possible. See Repeatability clause below for more info.

   To be as non-intrusive as possible, it makes no copies of the assertions block, so as with functions you have to explicitly copy any global (literal) series within before you modify them.

6. Use `assert` function directly (not as a macro) if you want to **test unconditionally** (even in release code).

## Design

**What's in `#assert block!` form**

`#assert` part:
- has `#` shard in it to denote a macro, hinting that it will disappear if assertions are turned off
- gets loaded as an issue and gets silently ignored in case `assert.red` fails to include (e.g. due to preprocessor bugs), not breaking your code
- gets transformed on load into `assert` word referring to the test function

`block!` part:
- clearly denotes assertion code start and end, making it possible to remove it on load (where meaning of many words may be unknown, so is arity)
- gets silently ignored in case `assert.red` fails to include, works almost as if assertions were disabled: issue and block get skipped, leaving only a tiny performance impact

**Why a macro and not a function?**

- Each Red token takes some time (e.g. \~80ns on my laptop) to evaluate and sets interpreter's baseline speed. If we can remove assertions during load phase, we can speed the code up. Effectively this means users will more readily use it, extending tests coverage.
- Reduced compiled binary size.
- Ability to have both mandatory and optional assertions: `#assert` can be switched on/off, `assert` is always evaluated.

**Words leakage**

I do not want to make every assertion `#localize` it's words automatically because this will be a performance hit and memory creep during evaluation of *every* assertion (the cost is creation of a new function for every expression).

**Failure behavior**

It's not enough to show that assertion failed. If we did, one would have to litter assertion with `probe`s to find out what exactly went wrong. Not a desirable workflow.

Instead, we want to evaluate assertion code step by step and show full backtrace in case of failure.

We also do not want to throw an error and stop the program. Assertion may be wrong itself (too strict, or temporarily fails due to some work going on). Or most code parts may work just fine even if some unused feature fails the tests. Most annoying is when an assertion fails inside a piece of code in a complex program and whole program aborts because of it, losing all state and any ability to debug it while it's hot. By continuing after failure we can get bigger overview of failing parts before we dive into fixes.

A message should always be displayed however. Failure indication, backtrace and possibly a user-provided message. Ideally we want the line number as well, but that's not yet possible AFAIK.

**New line alignment**

It may so happen that during code refactoring we change the arity and our assertions will magically succeed but won't actually do any useful work. To avoid this, we should ensure that each assertion is aligned at new-line markers. Basically, no two assertions may be written on a single line, and any leftover tokens (except the error message) are error indicators.

Some assertions may span multiple lines however, so we should allow it.

This also enforces readable unittest layout.

**Repeatability**

Normally, whole unittest code should be repeatable any number of times, so it's best to avoid modifying global data (e.g. literal blocks are global unless explicitly copied).

To be light `assert` doesn't copy expressions given to it, and doesn't turn on tracing until assertion fails. So upon failure it evaluates the failed assertion *again*, this time tracing it. Consider the following example:
```
#assert [
	b: []
	[1] = append b 2
]
```
It's wrong because `b` is assigned a global empty block `[]` that is created during file's `load`. After that `[1] = append b 2` will fail with `[2]` result, and when evaluated second time, `b` will still be `[2]` and assertion will change it to `[2 2]`, making the error report somewhat surprising.

It also can't be fixed by `b: copy []`, because this initialization line will not be re-evaluated (as it doesn't fail), but only `[1] = append b 2` will be.

Proper way to write this is:
```
#assert [(b: copy []  [1] = append b 2)]
```
In this case both `copy` and `append` will be re-evaluated, producing an expected failure report.

Of course, `#assert [[1] = append copy [] 2]` will do as well for this particular example.
