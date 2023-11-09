# [RESHAPE](reshape.red)

This mezz was made to counter the limitations of COMPOSE.<br>
Inspired also by [Ladislav Mecir's BUILD](https://gist.github.com/rebolek/edb7ba63bbaddde099cb3b1fd95c2d2c)

**Examples**

The following 3 snippets create a string for program identification, e.g. `"Program-name 1.2.3 long description by Author"`, omitting Description and Author parts when those are not specified:
```
form reshape [
	!(pname) !(ver)	@(desc)
	"by"	/if author
	@(author) #"^/"
]
```
```
form compose [  ;-- uses ability of FORM to skip unset values
	(pname) (ver)
	(any [desc ()])
	(either author [rejoin ["by "author]][()])
	#"^/"
]
```
```
form build/with [
	!pname !ver ?desc ?author #"^/"
][
	!pname: pname
	!ver: ver
	?desc: any [any [desc ()]
	?author: either author [rejoin ["by "author]][()]
]
```

And these snippets build a test function used in [FOR-EACH](for-each.red) that checks if values ahead conform to the constraints in the spec. <br>Spec may have type & value constraints, or none of these. <br> Result will look like `unless ..checks.. [continue]` if checks are required, and empty `[]` otherwise.
```
test: reshape [                                         /if filtered?
    /do test: reshape [
        types-match?  old types                             /if use-types?
        values-match? old values values-mask :val-cmp-op    /if use-values?
    ]
    unless
        all !(test)                                         /if all [use-types? use-values?]
        @(test)                                             /else
    [continue]
]
```
```
test: []
if filtered? [
    type-check:   [types-match?  old types]
    values-check: [values-match? old values values-mask :val-cmp-op]
    test: compose [
        (pick [type-check   []] use-types?)
        (pick [values-check []] use-values?)
    ]
    if all [use-types? use-values?] [
        test: compose/deep [all [(test)]]
    ]
    test: compose [unless (test) [continue]]
]
```
```
test: []
if filtered? [
    test: build/with [
        unless :!test [continue]
    ][
        !test: build/with [
            :!type-check :!values-check
        ][
            !type-check: pick [
                [types-match?  old types]
                []
            ] use-types?
            !values-check: pick [
                [values-match? old values values-mask :val-cmp-op]
                []
            ] use-values?
        ]
        if all [use-types? use-values?] [
            !test: build [all only !test]
        ]
    ]
]
```

As can be seen, RESHAPE shows the intent behind the code more clearly in complex scenarios.

## An overview of the previous designs

**Let's start with COMPOSE limitations:**
- **Expressions** used in it are often **long** and they make the code very messy. It becomes **hard to tell** how the result will **look like**.<br>
  E.g. `compose [x (either flag? [[+ y]][]) + z]` -- go figure it will look like `[x + z]` or `[x + y + z]` in the end<br>
  This can be circumvented by making preparations, although the number of words grows fast:
  ```
    ?+y: either flag? [[+ y]][[]]
    compose [x (?+y) + z]
  ```
- It uses parens, so if one wants to also **use parens** in the code, code gets **uglified**.<br>
  E.g. `parse compose [skip p: if ([((index? p) = i)])]` -- seeing this immediately induces headache ;)<br>
  Plus it's a **source of bugs** when one forgets to uglify a paren, especially in big code nested with blocks.
- There's no way to **conditionally include/exclude** whole blocks of code without an inner COMPOSE call<br>
  E.g. `compose [some code (either flag? [compose [include (this code) too]][])]` -- `compose/deep` won't help here<br>
  Also sometimes when one conditionally includes the code, one may want to prepare some values for it:<br>
  E.g. `compose [some code (either flag? [my-val: prepare a block  compose [include (my-val) too]][])]` -- this totally destroys readability (and not always can be taken out of `compose` expression easily, when there's a lot of conditions depending one on the other)
- Sometimes there's a need to **compose** the code used in **conditions** (not the included code itself!) before evaluating them.<br>
  E.g. `compose [some code (do compose [either (this) (or that) [..][..]])]` -- top-level `compose/deep` won't help again

**What I like about COMPOSE is:**
- Parens visually outline both **start and end points** of substitution: very are **easy to tell apart** from the unchanging code.
- Parens are very **minimalistic**, which also helps **readability** in easy cases. And it's also easy to implement.

**Ladislav's BUILD has some advantages over it:**
- One can **freely use parens** as they have no special meaning, and their content will be **deeply expanded** as well.
- With preparation code moved into the /with block, **expression** itself can be **even cleaner** than it's COMPOSE variant:<br>
    `build/with [x :?+y + z] [?+y: either flag? [[+ y]][]]`
- One can not only substitute values, but also **declare own substitution functions** (like `ins` and `only`).
- Conditional inclusion of inner blocks can be shortened by making a dedicated function for that. Then in order to not include it into every /with block again and again, it should be built in. To also expand inner blocks, this function can call BUILD on those blocks on it's own.<br>
  E.g. something like:
  ```
    build/with [some code ~if~ (in this) [only that] ...] withblk: [
        ~if~: func [cond code] [either do build/with cond [build code][[]] withblk]
    ]
  ```
- As the above shows, it's **extensible**, although how to extend it *globally* remains an open question

**But it also has it's drawbacks:**
- **/with block** in practice becomes **bigger** than it's COMPOSE variant's preparation code. This happens because /with builds an object out of the block, and object constructor does **not collect words deeply**, so they have to be declared at top level first:
  ```
    build/with [...][
        x: y: none
        either flag? [x: 1 y: 2][x: 2 y: 3]
    ]
  ```
  Another reason for the bloat, is because BUILD **can't substitute words not declared** in the object without `ins` or `only` (which are way less readable).<br>
  E.g. one has to **duplicate** already set values in the object:
  ```
    x: my-value
    build/with [... !x ...] [!x: :x]
  ```
  So while it keeps the build-expression readable, it does not reduce the overall complexity. It just **moves complexity from the expression into the /with block**.
- Apart from simple words, there's **no visual hint** where each substitution **starts or ends**.<br>
  E.g. `build [ins copy/part find block value back tail series then some code]` -- tip: `ins` eats it up to `then`, but you have to count arity in your mind to know that ;)
- `ins` and `only` (or any other user-defined transformation functions) are **incompatible with operators**<br>
  E.g. `build [x + ins pick [y y'] flag? + z]` -- will try to evaluate `flag? + z` and will fail. One can write `build [x + (ins pick [y y'] flag?) + z]` instead, but when building tight loops code, or frequently used function bodies, an extra paren matters. Besides that will only work for inserting a single value, not whole slices of code.

---
*The purpose of RESHAPE is to address all these limitations.*

## Key design principles of RESHAPE:

- It's code consists of **2 columns:** *expressions* to the left and *conditions* to the right. This separation helps keep track of both the expression under construction, and conditions, and be able to connect both easily. For that to work without extra separators tokens, I had to make it **new-line aware**.<br>
  E.g.:
  ```
    this code is always included
    this code is included          /if this condition succeeds
    this is an alternate code      /else    ;) included if the last condition failed
  ```
- Unlikely coding patterns are used to **minimize the need to escape** anything:
  `!(...)` `@(...)` `/if ...` `/else` `/do ...` `/use (...)` `/mixin (...)` -- fat chance you will encounter these in normal Red.
- Expressions to be substituted are wrapped in parens so their **limits are clearly visible** and contrast with the rest.<br>
  E.g. `@(copy/part find block value back tail series) then some code` -- can be used pretty much like `compose` and stay readable.
- `/if` and `/else` conditionals control what lines to include or not, **eliminating the need for preparation code**, at least in straighforward scenarios.
- There's **block-level** and **line-level** conditionals so one can control inclusion on both levels.<br>
  E.g. `/if flag?` is block-level and affects the rest of the block, while `anything-here /if flag?` is line-level and controls inclusion of `anything-here` line only.
- There's **2 kinds** of pattern **replacement**: insertion of **value**, and insertion of **code**. <br>These are different in meaning, and are usually handled by `/only` refinement (in `compose`) or by `ins` & `only` funcs (in `build`).<br>
  I'm going further, by leveraging this meaning:<br>
    &nbsp;&nbsp;a) insertion of **code** will insert **nothing** in place of **`none` and `unset`** (to eliminate the need to pass empty blocks), and will **unwrap** both **blocks and parens** and insert their contents only<br>
    &nbsp;&nbsp;b) insertion of **values** works **like /only** - it inserts each **value as is**, so there's no risk of bugs when you forget to specify /only somewhere and the value turns out to be a block
- **Readability** is the most important **goal**; that's why there are both **short and long variants** of insertion:<br>
  `!(...)` and `@(...)` are meant for short code filled with insertions<br>
  `/use (...)` and `/mixin (...)` equivalents are meant for big code with little insertions, where those insertions should stand out.
- **Deep processing** of input, so that no extra calls to RESHAPE are needed to expand nested blocks/parens.
- Input that does not contain any patterns does not get copied, so one can use static blocks. This applies to all nested blocks/parens.

## Syntax of RESHAPE

**Columns are delimited** as follows: `/if`, `/else`, and `/do` start the 2nd column, which extends **until the line break**. Everything on the same line that comes before that is the 1st column:
```
this is the 1st column /do this is the 2nd column
/do this code contains only 2nd column (1st is empty)
```

**1st column syntax:**

- `@(expr)` and it's equivalent `/mixin (expr)`: expands `(expr)` paren deeply, then `do`es it, then if it's not `none` or `unset`, inserts the result into the output. If result is a block or paren, only it's contents are inserted (like `insert` action does). `mixin` name tells that one wants to *mix* the code block *in* to the output.
- `!(expr)` and it's equivalent `/use (expr)`: expands `(expr)` paren deeply, then `do`es it, then inserts the resulting values as is into the output (like `insert/only`). `use` name tells that one wants to *use the value* obtained from the expression.
- **Blocks** and undecorated parens are expanded and inserted as blocks/parens.
- Any **other**, undecorated values are inserted as they are.

**2nd column syntax:**
- `/do expr...` does `do/next` on the `expr...`, and *discards* the result. This contrasts it with `/use`, that *uses* the result.<br>
  Expression is evaluated *before* the expansion of patterns in 1st column of the same line, so `/do` can be used to prepare values to insert, thus helping to keep the 1st column clean.<br>
  `/do` may precede or follow `/if`s or `/else`s freely, but keep in mind that those `/do`s coming after a condition will not be evaluated if condition fails.
- `/if expr...` does `do/next` on the `expr...`, and if the result is falsey, it skips the current line immediately. If it's truthy, 1st column is expanded and inserted into the output. Result itself is saved for subsequent `/else`s.
- `/else` negates the last condition evaluated by an `/if` and if that condition was truthy, it skips the current line immediately. If it was falsey, the 1st column of this line is expanded and inserted into the output. `/else` does not affect the condition, so many `/else` lines may follow each other and will apply the same inclusion criterion.
- There's currently no limit on `/if`s and `/else`s in a line, but I would advise not to use more than one, as if it's followed by an `/else` it becomes hard to predict under which conditions this `/else` line will be included. It will negate only the last evaluated `/if`, but which one will be the last - it depends ;) Maybe there's a better meaning we can give to `/else`? I haven't found it yet.
- When the 1st column is empty, `/if`s and `/else`s on that column affect not the line inclusion, but the rest of the block until another `/if` or `/else` line with an empty 1st column:
```
                    /if true       ;) affects everything up to /else
    this will be included
    and this too        /if true
    but not this        /if false  ;) because line-condition fails
                    /else          ;) /else corresponds to the block-level /if at the beginning
    this will not be included      ;) because `/else` after `/if true` is false
    so the rest gets discarded...
```
Both block-level and line-level **`/if`s remember their result** for their corresponding `/else`s, but *each level does not affect the other* (e.g. line-level `/if` does not affect block-level `/else` and vice versa).

**Possible alternate names I have considered:**
- `/when` instead of `/if` - less readable.
- `/where` instead of `/do` - longer. Implies that expression is evaluated before the line expansion (good), but also implies that the results apply only to this line (which isn't true).
- `?(...)` instead of `@(...)` - more likely to clash with the `?` debug mezz. Kinda hints that it may insert nothing though, but doesn't hint about block unwrapping.
- `&(...)` instead of `@(...)` - less readable in my opinion.
- I was thinking on `/also` or `/too` that would work as `/else` but reversed: it would include the code if the last `/if` condition succeeded. But with the block-level `/if`s, I'm not sure there's need in this. And I think multiple `/else`s are also not that great and indicate that perhaps there's a better way to express that part of code ;) Besides, there is a workaround for that using `@([ global flags here then code ])` pattern, which if it turns out to be useful, can be shortened to `@[...]` (parens omitted).

**Drawback of current implementation**: 50 times slower than `compose`, being a `parse`-based mezz ;) Not for the time critical code, until I move it to R/S in some distant future.

I haven't decided whether I should expand expressions after `/if`, `/else` and `/do` before evaluation or not - but it's doable with `preprocessor/fetch-next` in case the need becomes clear.

Also, no extensibility is planned. Rather it should be a one-size-fits-all solution. Is there a need to extend it and in which way? I would like to study use cases.
