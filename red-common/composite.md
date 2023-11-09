# `#composite` macro & `composite` mezz

[`composite`](composite.red) is an implementation of [string interpolation](https://en.wikipedia.org/wiki/String_interpolation). It's main **advantage** over `rejoin` is **readability**. Compare:
```
cmd: #composite {red(flags) -o "(to-local-file exe-file)" "(to-local-file src-file)"}
cmd: rejoin ["red" flags { -o "} to-local-file exe-file {" "} to-local-file src-file {"}]
```

Like `compose`, `composite` expects expressions to be in parens. 

It supports **all string types**, e.g. it's useful for file names, thanks to the double quoted file syntax:
`#composite %"(key)-code.exe"` - the result is of `file!` type

It should also be useful for **tag** composition, but be careful that tags with double quotes inside may become unloadable.

To compose **urls**, we need different syntax than parens, as urls do not support non-encoded parens. So just use `as url! #composite "https://..."` trick.

## Syntax

\(See also [@greggirwin's sad emoji DSL](https://github.com/greggirwin/red-formatting/blob/master/formatting-functions.adoc#composite), which informed this design.\)

Any paren inside string gets treated like a Red expression. Result of this paren's evaluation gets `form`ed (using `rejoin`).

Opening paren can be escaped: `(\` (slash after paren).\
E.g. `log-info #composite "Started worker (name) (\PID:(pid))"`

<details>
	<summary>On choice of escape format...</summary>

Sometimes we want literal parens. After ~2 years of using `composite` and writing hundreds of composite-expressions, I've encountered a need to:
- put some comment into the string in parens (2-3 times), which can be done as `"... ("(comment)") ..."`
- put Red expression inside literal parens (2 times), e.g. `"... ("(")PID: (pid)(")")"`

Needless to say this is unreadable, esp. the latter case that looks like 2 ugly parrots `("(")`.

Question is: should we complicate the substituted parens, like `:(expr):` in the sad emoji dialect? or should we complicate literal parens by using an escape pattern?\
My own statistics (4-5 cases of literal parens versus many hundreds of substituted expressions) tells me that latter is preferred. So the question boils down to the choice of escape sigil.

It seems that most [widely used interpolation syntaxes](https://en.wikipedia.org/wiki/String_interpolation) are: `$var`, `$(var)` and `${var}`, leaving `"(normal parens)"` as is. This goes against the above conclusion, but it's explainable: many languages do not require a `#composite` prefix before the interpolated string, they have interpolation always built in, so for those languages literal parens is a much more likely case to deal with.

With the above said, I considered the following:
- `$var text` - `$var` doesn't stand out, making it harder to visually tell apart evaluated expressions from literal text, requires escaping every `$` and possibly every `\`, and has [other problems](https://stackoverflow.com/questions/17622106/variable-interpolation-in-the-shell)
- `!(var) (text)`/`@(var) (text)`/`$(var) (text)` - [reshape](reshape.md)-like or bash-like syntax - OK, but I'd like to avoid the overhead of extra sigil prefix
- `(var) \(text)` - requires to escape every backslash, because makes it impossible to write a Red expression after the backslash (without making the backslash ugly `("\")`) - doubling is very bad
- `(var) (\text)` - although escaping is sort of backwards here, it should just work because `\` in Red is a forbidden char (reserved? what if gets used later?)
- `(var) (;text)` - future-proof, however `;...` could be a comment in a composed multiline string, and this syntax disables it (but it's easy to fix by adding a whitespace: `( ;`); biggest issue is that `(;` is not an unlikely emoji
- `(var) (\text\)` - longer, I see no point in preferring this over the `(\text)` variant
- `(var) ((text))`/`(var) ([text])`/`(var) ("text")`/`(var) (:text:)` - can hurt perfectly valid exprs like `((a + b) / (c + d))`, or `([a] op [b])`, or `("a" op "b")`, or `(:a op b:)`
- `(var) (]text[)`/`(var) (>text<)` - reads as some error
- `[var] ^(text)` - impossible: `^(XX)` is a char syntax in Red
- `{var} ^{text}` - impossible: `^` gets lost during load
- `[var] ^[text]` - should just work, since `^[` is an ESC (27) char, however I'd like to avoid using square brackets for parens are more natural way to write expressions
- `(var) (^text)` - bad: on load converts first char of text into a control char, esp. `^t` into tab; we could convert them back, but only if we expect control chars to never follow an opening paren - surely that's dangerous to assume about linefeed `^/`
- `\var\ ^\text^\` - should just work, since `^\` is a char 28 (file separator)

To me `(var) (\text)` seems like the best tradeoff, followed by `[var] ^[text]` then `\var\ ^\text^\` (in former 2 expressions are also easy to load, while latter requires manual parsing that will slow it down).

</details>

## Macro version

I'm using it in the [Red View Test System repo](https://gitlab.com/hiiamboris/red-view-test-system) and other places and I'm satisfied with it.
During macro expansion phase `#composite` macro simply **transforms** a given string **into a rejoin-expression**. 

**Benefits** of macro approach over a function implementation are:
- Huge benefit is that used expressions are **automatically bound** as expected, because macro expansion happens before any `bind` can be executed upon it. This makes it easy and natural to use, contrary to the function version that would have to receive a context (or multiple contexts) to bind it's words to and becomes so ugly that's it's not worth the effort using it.
- Another is runtime **performance**: expression is expanded only once, so any subsequent evaluations do not pay the expansion cost. And if you compile it, you pay the cost at compile time only.
- Expands macros within parens.

**Drawbacks** compared to function implementation are:
- You cannot **pass around or build** the template strings at runtime. E.g. if you want to write a simple wrapper around `#composite` call, you have to make it a macro wrapper, not function wrapper. So, formatting a dataset using a template won't work with a macro.
- Macros **loading is unreliable** right now \(see the [numerous issues on the tracker](https://github.com/red/red/issues?q=is%3Aissue+is%3Aopen+preprocessor)\) - often you just move your included file somewhere else and it stops working.
- If you have a lot of `composite` expressions, most of which are not going to ever be used by the program (like, composite error messages), then it's **only slower** than the function version (unless you're compiling your code).

### Shorter format

Since `#composite` is a long thing to type and as a result I found myself writing macro wrappers around it: `#print` for `print #composite`, `ERROR` for `do make error! #composite` and so on, it is reasonable to provide a shorter universal syntax.

Below's a comparison of short macro formats as currently possible to lex. As can be seen some tokens are more sticky than the others, but that can be fixed of course.

|string|alt string|raw string|tag|file|note|
|-|-|-|-|-|-|
| `` `"value=(v)"` ``  | `` `{value=(v)}` ``  | `` ` %{value=(v)}% ` ``  | `` `<value=(v)>` `` | `` ` %"value=(v)" ` ``  | |
| `` #`"value=(v)"` `` | `` #`{value=(v)}` `` | `` #`%{value=(v)}%` `` | `` #` <value=(v)> ` `` | `` #`%"value=(v)"` ``  | |
| `@"value=(v)"`  | `@{value=(v)}`  | `@%{value=(v)}%` | `@<value=(v)>`    | `@%"value=(v)"`    | 1 |
| `&"value=(v)"`  | `&{value=(v)}`  | `& %{value=(v)}%` | `&<value=(v)>`    | `& %"value=(v)"`   | 2 |
| `/"value=(v)"/` | `/{value=(v)}/` | `/%{value=(v)}%/` | `/ <value=(v)> /` | `/%"value=(v)"/`   | |
| `="value=(v)"=` | `={value=(v)}=` | `= %{value=(v)}% =` | `=<value=(v)>=`   | `= %"value=(v)" =` | |
| `^"value=(v)"^` | `^{value=(v)}^` | `^ %{value=(v)}% ^` | `^<value=(v)>^`   | `^ %"value=(v)" ^` | |

1. similar to [reshape](https://gitlab.com/hiiamboris/red-mezz-warehouse/-/blob/master/reshape.md), but disables possible future `@".."` format for refs
2. `&` can't be an operator then

We could modify lexer to transform `` `value=(v)` `` patterns *on load* into blocks or rejoin-expressions, but:
- this will harm localization as we won't have the string form anymore, and will have to invent some kludges to extract it
- macros can be disabled by user, but lexer behavior is hardcoded, so there'll be no way around it

### Examples:
```
stdout: #composite %"(working-dir)stdout-(index).txt"
pid: call/shell #composite {console-view.exe (to-local-file name) 1>(to-local-file stdout)}
log-info #composite {Started worker (name) (\PID:(pid))}
#composite "Worker build date: (var/date) commit: (var2)^/OS: (system/platform)"
write/append cfg-file #composite "config: (mold config)"
```
Bigger example:
```
stdin:  #composite %"(working-dir)stdin-(wi).txt"
name:   #composite %"(working-dir)worker-(wi).red"
write name #composite {
	Red [needs: view]
	context [
		ofs: 0
		bin: none
		pos: none
		forever [
			wait 1e-2
			unless empty? system/view/screens/1/pane [
				loop 5 [do-events/no-wait]
			]
			bin: read/binary/seek (mold stdin) ofs			;<-- filename goes here
			if pos: find/tail bin #"^^/" [
				ofs: ofs + offset? bin pos
				str: to string! copy/part bin pos
				print ["=== BUSY:" str]
				task: load/all str
				if error? e: try/all [do next task 'ok] [print e]
				print ["=== IDLE:" :task/1 "@" now/precise]
			]
		]
	]
}
```

## Mezz version

**Benefits**:
- Much **simpler** code.
- Can be used on **dynamically** generated or passed around strings, like any other function.
- No tripping on macro issues.
- Supports `/trap` refinement to handle evaluation errors (I don't think it's of any use for macro version, so not implemented there)

**Drawbacks**:
- Requires explicit binding info. See [`with` header](https://gitlab.com/hiiamboris/red-mezz-warehouse/-/blob/master/with.red) - usage is the same, and resembles usage of `bind`.
- Slower at runtime due to extra processing.
- Does not expand macros within parens (by design, because preprocessor would slow down it's operation a lot for some dubious edge case).

<details>
	<summary>Why do we even need binding info?</summary>

\
Usually Red code is bound:
- to global context during `load` phase
- to other contexts during their creation at evaluation time

But since `composite` accepts a string, when it's wrapping context was created there were no words to bind. Just a string. Words that it will extract from that string will always be bound to the global namespace. This makes using `composite` inside functions a bag of gotchas:
```
o: object [
	x: 1 y: 2
	tell: function [z] [
		composite[] "Result of `x + y * z` is: (x + y * z)"
	]
]

>> o/tell 3
*** Script Error: z has no value
*** Where: =
*** Stack: tell composite rejoin empty?  
```
I was lucky `z` wasn't defined globally and I got an error. But `x` and `y` were `= 1` (probably some leaking assertions), and if `z` was also globally known it would have likely led to a nastiest bug hunt session. Moreso, *I wouldn't be able to use any words from function or from any contexts except global one, if I could not provide the context info to `composite`.*

Tiny scripts where all data is global do not require it. But they also do not require a mezz version and will be perfectly fine with a macro.

Where we build something more complex, there's no way around it that I can see. And if `composite` was only good for global words, imagine how many times that would bite programmers, and especially beginners (and they are always a majority statistically).

So, proper way to write the above is:
```
o: object [
	x: 1 y: 2
	tell: function [z] [
		composite['z 'x] "Result of `x + y * z` is: (x + y * z)"
	]
]

>> o/tell 3
== "Result of `x + y * z` is: 9"
```
Since `z` and `x` refer to values and not contexts, they are quoted as `'z` so reduction results in a word and word carries the context info for the [`with`](with.red) call. See `with` syntax, it's used here as is.

Macro version does not require this, as macros get expanded *before* any evaluation happens, and the result of #composite expansion - a rejoin call with a block - gets bound when it's wrapping context is built.
</details>

- Why `with` cannot be used separately from `composite`?\
Because `composite` mezz takes and returns a string. The only thing that can be bound - a block of expressions - lives solely within `composite` and never leaves it.

- Why binding info is not a refinement?\
Main reason is readability: refinement implies that block goes after the string, which is not quite readable.\
Another reason is to help the user not forget to specify it (and thus prevent bughunt sessions). E.g. I do forget it myself when I switch from `#composite` to `composite`, and I immediately get a type error that I'm passing a string as first argument.

### Examples:
```
prints: func [b [block!] s [string!]] [print composite b s]
prints['msg] "error reading the config file: (mold msg)"			;) often requires duplication of variable name
composite[] "system/words size = (length? words-of system/words)"	;) automatically bound to global context
```
Bigger example:
```
avcmd: {"(player)" "(vfile)" --audio-file "(afile)"}
vcmd:  {"(player)" "(vfile)"}
play: function [player root vfile afile] [
	...
	cmd: composite['root] either afile [avcmd][vcmd]
	...
]
```


## ERROR macro

- is based on the `#composite` *macro* (because error strings are almost always immediate values)

`ERROR "my composite (string)"` is simply a shortcut for: `do make error! #composite "my composite (string)"`, which I'm using a lot.

As all macros it is **case-sensitive!** (`error` and `Error` won't be affected).

Why `ERROR` and not `#error`?\
Because the preprocessor has a lot of issues and may easily fail to expand the macro. In this case `#error` will just be skipped silently, propagating errors further, while `ERROR` will likely tell that the word is undefined.

### Examples:
```
ERROR "Unexpected spec format (mold spc)"
ERROR "command (mold-part/flat code 30) failed with:^/(form/part output 100)"
ERROR "Images are expected to be of equal size, got (im1/size) and (im2/size)"
```

## Localization

In my opinion, `#composite` will have a **big role to play when localization** work starts. Suppose we write a macro that replaces every string in the script with a local version. It's a piece of cake when `#composite` is used:
`#composite "A (type) message with (this value) and (another value) and more"` can get replaced by the translator as:
`#composite "Localized (another value) and (this value) and more (type) message"` - the order of things depends on the language/culture.

And imagine translator's dizziness when he sees:
```
"A "
" message with "
" and "
" and more"
```
coming from `rejoin ["A " type " message with " this value " and " another value " and more"]`

Not only `rejoin` leaves no option to reword the phrase properly, it also blocks any attempt to get the meaning of the message.

That's why I believe **`#composite` (macro and function) should be a part of Red runtime** and should be used for formatting values in error messages.

