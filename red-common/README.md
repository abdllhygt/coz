Official URL of this project: [https://codeberg.org/hiiamboris/red-common](https://codeberg.org/hiiamboris/red-common)

# A collection of my Red mezzanines & macros

Some of these are trivial. Some may look simple in code, but are a result long design process. Some are only emerging experiments. See headers of each file for usage, info, design info!

Notes:
- most scripts are standalone, I tried to keep dependencies at minimum
- mostly untested for compileability so far; optimized for the interpreted use
- use `#include %everything.red` to include all the scripts at once and play

**Navigate by category:**
* [General purpose](#general-purpose)
* [Series-related](#series-related)
* [Loops](#loops)
* [Debugging](#debugging)
* [Profiling](#profiling)
* [Formatting](#formatting)
* [String interpolation](#string-interpolation)
* [Filesystem scanning](#filesystem-scanning)
* [Graphics & Reactivity](#graphics-reactivity)


## By category:

### Recent implementations, not yet incorporated into the whole
| Source file                            | Description |
| ---                                    | --- |
| [map, fold, scan, sum, partition (external)](https://github.com/greggirwin/red-hof/tree/master/mapfold) | Fast FP-like HOFs, as alternative to dialected \*each (routines, require compilation) |
| [new apply](new-apply.red)             | Waits for #4854 to be fixed and then I can start porting it to R/S |
| [new for-each, map-each, remove-each](new-each.red) | Waits for Gregg's review then I can start porting it to R/S |
| [new count](new-count.red)             | Based on the new apply, waits for it's R/S implementation |
| [sift & locate](sift-locate.red)       | Based on the new-each and new-apply. [Read more](sift-locate.md) |
| [new replace](new-replace.red)         | Based on the new apply, but awaits team consensus on design |

### General purpose
| Source file                            | Description |
| ---                                    | --- |
| [setters](setters.red)                 | Contains ONCE, DEFAULT, MAYBE, QUIETLY, ANONYMIZE value assignment wrappers, and IMPORT/EXPORT to expose some object's words globally |
| [step](step.red)                       | Increment & decrement function useful for code readability |
| [clip](clip.red)                       | Contain a value within given range |
| [catchers](catchers.red)               | TRAP - enhanced TRY, FCATCH - Filtered catch, PCATCH - Pattern-matched catch, FOLLOWING - guaranteed cleanup |
| [#include macro](include-once.red)     | Smart replacement for #include directive that includes every file only once |
| [with](with.red)                       | A convenient/readable BIND variant |
| [#hide macro](hide-macro.red)          | Automatic set-word and loop counter hiding |
| [bind-only](bind-only.red)             | Selectively bind a word or a few only |
| [apply](apply.red)                     | Call a function with arguments specified as key-value pairs |
| [timestamp](timestamp.red)             | Ready-to-use and simple timestamp formatter for naming files |
| [stepwise-macro](stepwise-macro.red) and [stepwise-func](stepwise-func.red) | Allows you write long compound expressions as a sequence of steps |
| [trace](trace.red)                     | Step-by-step evaluation of a block of expressions with a callback |
| [trace-deep](trace-deep.red)           | Step-by-step evaluation of each sub-expression with a callback |
| [selective-catch](selective-catch.red) | Catch `break`/`continue`/etc. - for use in building custom loops |
| [prettify](prettify.red)               | Automatically fill some (possibly flat) code with new-line markers for readability |
| [reshape](reshape.red)                 | Advanced code construction dialect to replace `compose` and `build`. [Read more](reshape.md) |
| [leak-check](leak-check.red)           | Find words leaking from complex code |
| [modulo](modulo.red)                   | Working modulo implementation with tests |

### Series-related
| Source file                                | Description |
| ---                                        | --- |
| [extremi](extremi.red)                     | Find minimum and maximum points over a series |
| [median](median.red)                       | Find median value of a sample |
| [count](count.red)                         | Count occurences of an item in the series |
| [split](split.red)                         | Generalized series splitter (docs in the header) |
| [keep-type](keep-type.red)                 | Filter list using accepted type or typeset |
| [collect-set-words](collect-set-words.red) | Deeply collect set-words from a block of code |
| [morph](morph.red)                         | Dialect for persistent local series mapping. [Read more](morph.md) |

### Loops
| Source file                                | Description |
| ---                                        | --- |
| [xyloop](xyloop.red)                       | Iterate over 2D area - image or just size |
| [forparse](forparse.red)                   | Leverage parse power to filter series |
| [for-each](for-each.red)                   | Experimental design of an extended FOREACH |
| [map-each](map-each.red)                   | Map one series into another, leveraging FOR-EACH power |
| [bulk](bulk.red)                           | Bulk evaluation syntax support. [Read more](https://github.com/greggirwin/red-hof/tree/master/code-analysis#bulk-syntax)] |
| [search](search.red)                       | Find root of a function with better than linear complexity. Supports [binary / bisection](https://en.wikipedia.org/wiki/Binary_search_algorithm), [interpolation / false position](https://en.wikipedia.org/wiki/Interpolation_search) and [jump](https://en.wikipedia.org/wiki/Jump_search) search. |

Interestingly, `for-each` and `map-each` code showcases how limited `compose` is when building complex nested code with a lot of special cases.
It works, but uglifies it so much that a question constantly arises: can we do something better than `compose`?
These two functions will serve as a great playground for such an experiment.

### Debugging

These functions mainly help one follow design-by-contract guidelines in one's code.

| Source file                            | Description |
| ---                                    | --- |
| [debug](debug.red)                     | Simple macro to include some debug-mode-only code/data |
| [assert](assert.red)                   | Allow embedding sanity checks into the code, to limit error propagation and simplify debugging. [Read more](assert.md) |
| [typecheck](typecheck.red)             | Mini-DSL for type checking and constraint validity insurance |
| [expect](expect.red)                   | Test a condition, showing full backtrace when it fails |
| [show-trace](show-trace.red)           | Example TRACE wrapper that just prints the evaluation log to console |
| [show-deep-trace](show-deep-trace.red) | Example TRACE-DEEP wrapper that just prints the evaluation log to console |
| [parsee](parsee.red)                   | Parse visual debugger. [Read more](https://codeberg.org/hiiamboris/red-spaces/src/branch/master/programs/README.md#parsee-parsing-flow-visual-analysis-tool-parsee-tool-red) |

### Profiling
| Source file                  | Description |
| ---                          | --- |
| [clock](clock.red)           | Simple, even minimal, mezz for timing code execution |
| [clock-each](clock-each.red) | Allows you to profile each expression in a block of code (obsolete) |
| [profiling](profiling.red)   | Inline profiling macros and functions (documented in the header) |

### Formatting
| Source file                        | Description |
| ---                                | --- |
| [entab & detab](tabs.red)          | Tabs to spaces conversion and back |
| [format-number](format-number.red) | Simple number formatter with the ability to control integer & fractional parts size |

### String interpolation
| Source file                        | Description |
| ---                                | --- |
| [composite macro & mezz](composite.red) | String interpolation both at run-time and load-time. [Read more](composite.md) |
| [ERROR macro](error-macro.red)     | Shortcut for raising an error using string interpolation for the message. [Read more](https://gitlab.com/hiiamboris/red-mezz-warehouse/-/blob/master/composite.md#error-macro) |
| [#print macro](print-macro.red)    | Shortcut for `print #composite` |

### Filesystem scanning
| Source file                  | Description |
| ---                          | --- |
| [glob](glob.red)             | Allows you to recursively list files. [Read more](glob.md). [Run tests](glob-test.red) |

### Graphics & Reactivity
| Source file                              | Description |
| ---                                      | --- |
| [relativity](relativity.red)             | Face coordinate systems translation mezzanines |
| [color-models](color-models.red)         | Reliable statistically neutral conversion between common color models |
| [contrast-with](contrast-with.red)       | Pick a color that would contrast with the given one |
| [is-face?](is-face.red)                  | Reliable replacement for FACE? which doesn't work on user-defined faces |
| [do-queued-events](do-queued-events.red) | Flush the View event queue |
| [do-atomic](do-atomic.red)               | Atomically execute a piece of code that triggers reactions |
| [do-unseen](do-unseen.red)               | Disable View redraws from triggering during given code evaluation |
| [embed-image](embed-image.red)           | Macro to compile images into exe |
| [explore & image-explorer style](explore.red) | Show UI to explore an image in detail (TODO: support any Red value) |
| [scrollpanel style](scrollpanel.red)     | Automatic scrolling capability to a panel, until such is available out of the box. [Read more](scrollpanel.md) |
| [table style](table.red)                 | WIP experiment on VID-based table construction |
