# [MORPH DSL - A dialect for efficient local series conversion](morph.red)

## Status

- Syntax may undergo some changes in the future. It's not yet cast in stone.
- Scanner and emitter are working and are able to backtrack properly, though went through only basic testing. 
- Partial change propagation designed but not fully implemented.
- Performance considerations were put into design, but no optimization was done whatsoever. Once finished, this project will closely compete with Parse's performance.
- Macros design is unfinished.
- No test suite yet.

## Goals

Are two:
1. Be able to define a **persistent mapping** from one series into another, so that output gets updated automatically when the input changes.\
   This requires the ability to reflect partial changes in the input into partial changes to the output, and should open **new ways of expression**, of thinking and of modeling of our software.
2. Have a flexible declarative **user-mode parser and emitter**.\
   This should simplify common data processing tasks (from grouping to codecs) and make them more **declarative**.

An expected side effect of this work should eventually be the ability to **parallelize data processing** tasks, based on the ability to do partial updates (1) and on encouraging of locally defined rules. Long as rules only rely on a limited number of adjacent items, such rules can be safely adapted for parallel computation with little work.

Picture this project as a parser-emitter constructor. Lego of dataflows ;)

## Origins

Initally the idea was born from the following use case.

Imagine a simple text editor, but with 2 requirements:
- real-time syncing of edits back to disk (a must have not to lose one's work in case of outage/crash/etc)
- ability to edit files of unlimited size (think gigabytes) with constant UI response time
 
We can't even enumerate lines from 1 in such case, because this will take way too long. We can only choose some anchor line as `0` and go up as `-1`, `-2` etc and down as `1` `2` ...

This editor would have the following layers of data representation:
1. `binary!` data on disk
2. `string!` representation of a fragment we're working on
3. `block!` of `string!` - lines of text
4. `block!` of `block!`s of rendered char sizes in each line as `pair!`s (from 3)
   main point is to not be forced to do a full render when we add/remove characters
5. `block!` of rendered line sizes as `pair!`s (from 3, considering line wrapping)\
   main point is to not be forced to do a full render when we join/split lines
6. a draw `block!` that's composed also from (4), and maybe also (5)

To meet our simple requirements we need the following functionality:
- user clicks on the screen somewhere, we translate that into coordinates in (4) with a few operations, now we know where our caret is in text (3))
- from where the caret is in (3) we can make edits and reflect those on (1) propagating layer by layer, and on (6) rendering the changes only
- when we "move" our loaded text fragment (2) inside (1), like when we scroll up or down, we want all layers up to (6) to be updated, *partially*, not recomputing everything on every keypress

The issue here is if done naively this code may spread to thousands of lines of code in the best case. And it's far from trivial to write in the first place.

There's also the fact that every change is local to some scope. Example: `[one [two] three]` - if I remove the `]` after `two`, editor should know that `three` and `one` were not affected. Nor it should affect any outer scopes. In reality, 
I do not know a single editor that follows these principles. It can be seen that very long block comments do not get highlighted properly and the overall lagginess of modern editors suggests they rescan everything after every keystroke.

Thus when I say that such a task is *accessible only* to most skilled and dedicated developers, the world around us acts as a confirmation.

Obviously this is a complex example, but it's good as an illustration. Most of the time we'll be dealing with simpler tasks, where the dialect should stay useful. 

## Examples

> `morph` function takes 3 arguments: `input`, `scan-rule` and `emit-rule`.

**Reordering** of items:
```
>> morph [1 2 3 4] ['x 'y ...] ['y 'x ...]
== [2 1 4 3]
```
Here, each `x` and `y` get set to next item, then get emitted in reverse order.\
`...` denotes a loop (similar to `any` Parse rule).

---

**Filtering**:
```
>> morph [1 2 3 4] ['x ? even? x | skip ...] ['x ...]
== [2 4]
```
Here, `? even? x` evaluates `even? x` expression and fails if it returns `none` or `false`.

---

**Delimiting**:
```
>> morph "1 2 3 4" context [
[    		token: [not #" " skip ...]
[    		return [token (#" " token ...)]
[    	] ['token ...]
== ["1" "2" "3" "4"]
```
Here, we define `token` rule and an unnamed scan rule that uses `token`.

Rules above are all similar to Parse, except `()` is equivalent to Parse's `[]` and just groups a few rules together into a single one, in this particular case to denote loop start and end points.

---

**Joining**:
```  
>> morph/into [1 2 3 4] ['x ...] ['x (not 'x | " ") ...] ""
== "1 2 3 4"
```
Since intermediate data model is not a sequence, but a tree of named branches (explained below), we cannot check for tail of input during emission. So we use `not 'x` rule to see if there are more `x`s or not, so we don't get close the output with space.

`/into` lets us emit directly into a new string.

---

Emission of values **literally** when those value
```
>> morph [] [] ["str" 123 quote x: lit [y: z:]]
== ["str" 123 x: y: z:]
```
`"str"` and `123` are not recognized as rules, so they are treated literally, while set-words demonstrate the work of `quote` and `lit` rules.

---

**Object** creation:
```
>> morph ["x" "y" 10 20] [name: string! | value: integer! ...] [to object! [to set-word! 'name 'value] ...]
== [make object! [
    x: 10
] make object! [
    y: 20
]]
>> morph ["x" "y" 10 20] [name: string! | value: integer! ...] [to object! [to set-word! 'name 'value ...]]
== [make object! [
    x: 10
    y: 20
]]
```
Note the subtle difference in the loop scope ;)

And of course more trivial:
```
>> object morph ["x" "y" 10 20] [name: string! | value: integer! ...] [to set-word! 'name 'value ...]
== make object! [
    x: 10
    y: 20
]
```

---

Simple **CSV-like codec**.

First we define a few rules.

```
csv-src: context [
	value-char: negate charset "^/,"
	value: [value-char ...]
	line:  [value (#"," value ...)]
	return [line (lf line ...)]
]
```
The above ruleset defines how to **interpret** the textual structure of a CSV file.

```
csv-blk: [line: [load 'value ...] ...]
csv-txt: [line: ['value (#"," 'value ...)] :lf ...]
```
The above two rules define how to **emit** CSV as block and as text back.\
`load` rule, well, `load`s the result of the next rule, so we get `10` instead of `"10"` and so on.

Note that because `morph` **tracks** each value by it's rule's **name**, these rules have to be put into different contexts (objects). That's what you can see above: same word `line` is linked to various rules for scanning and emission.

Now we can transform text CSV into a block or back into itself: 
```
>> text: {a,b,c^/10,20,30}
>> morph/into text csv-src csv-txt ""
== "a,b,c^/10,20,30^/"
>> morph text csv-src csv-blk
== [[a b c] [10 20 30]]
```
Look closely at the rules again.
- They are purely **declarative**: there is **zero bookkeeping, index-juggling, imperatives to do this'n'that, only the data layout**.
- They are also **refined**: there is not a single thing that can be omitted, as otherwise we would not have enough info about the data.
- There's clear **distinction** between input and output, so we can look at a ruleset and imagine the data model. No need to visually scan the rules for `keep` or `append` anymore to figure out what comes from where.

> Note I didn't write a rule to read CSV from a block produced by `csv-blk`: the exercise of converting CSV block into text is left to the reader. Clone the repository, do `morph.red` and play ;)

### Learn by example

Here's more examples, illustrating the basics. Try to compare the result with your expectations.
```
>> morph [1 2 3 4] ['x ...] ['x ...]
== [1 2 3 4]
>> morph [1 2 3 4] ['x ...] ['x]
== [1]
>> morph [1 2 3 4] ['x] ['x]
== [1]
>> morph [1 2 3 4] ['x] ['x ...]
== [1]
>> morph [1 2 3 4] ['x ...] [any 'x]
== [1 2 3 4]
>> morph [1 2 3 4] [any 'x] ['x ...]
== [1 2 3 4]
>> morph [1 2 3 4] [any 'x] [any 'x]
== [1 2 3 4]
>> morph [1 2 3 4] ['x 'y 'z 'w] ['x 'y 'z 'w]
== [1 2 3 4]
>> morph [1 2 3 4] ['x 'y 'z 'w] [] print [x y z w]
1 2 3 4
>> morph [1 2 3 4] ['x skip ...] ['x ...]
== [1 3]
>> morph [1 2 3 4] ['x 'y ...] ['x ...]
== [1 3]
>> morph [1 2 3 4] ['x 'y ...] ['y ...]
== [2 4]
>> morph [1 2 3 4] ['x ? x <= 2 | skip ...] ['x ...]
== [1 2]
>> morph [1 2 3 4] ['x ? x <= 3 | skip ...] ['x ...]
== [1 2 3]
>> morph [1 2 3 4] ['x ? any [x = 1 x = 4] | skip ...] ['x ...]
== [1 4]
>> morph [1 2 3 4] ['x 'y ? x = 3 | skip ...] ['x 'y ...]
== [3 4]
>> morph [1 2 3 4] ['x 'y ...] ['x 'y ...]
== [1 2 3 4]
>> morph [1 2 3 4] [any ('x 'y)] ['x 'y ...]
== [1 2 3 4]
>> morph [1 2 3 4] [any ('x 'y)] [any ('x 'y)]
== [1 2 3 4]
>> morph [1 2 3 4] [any ('x 'y)] [any ['x 'y]]
== [[1 2] [3 4]]
>> morph [1 2 3 4] [any ('x 'y)] [['x 'y] ...]
== [[1 2] [3 4]]
>> morph [1 2 3 4] [any ('x 'y)] [[['x] ['y]] ...]
== [[[1] [2]] [[3] [4]]]
>> morph [1 2 3 4] [any ('x 'y)] [(['x] ['y]) ...]
== [[1] [2] [3] [4]]
>> morph [1 2 3 4] [any ('x 'y)] [(('x) ('y)) ...]
== [1 2 3 4]
>> morph [1 2 3 4] [any [any 'x]] [any 'x]
== [1 2 3 4]
>> morph [[1 2] [3 4]] [any any 'x] [any 'x]
== [[1 2] [3 4]]
>> morph [[1 2] [3 4]] [any (any 'x)] [any 'x]
== [[1 2] [3 4]]
>> morph [[1 2] [3 4]] [any [any 'x]] [any 'x]
== [1 2 3 4]
>> morph "1234" [x: ('y 'y) ...] [x: ('y 'y) ...]
== ["1" "2" "3" "4"]
>> morph "1234" [x: ('y 'y) ...] [x: ['y 'y] ...]
== [["1" "2"] ["3" "4"]]
>> morph "1234" [x: ('y 'y) ...] ['x ...]
== ["12" "34"]
```

## Data model

To be able to use `morph` DSL, it's important to get the idea how it structures the data.

Picture below illustrates it for the following modified CSV-like ruleset (as in the examples section, but with delimiters kept):
```
csv-src: context [
	value-char: negate charset "^/,"
	d: [#","]		;) delimiter
	value: [value-char ...]
	line:  [value (d value ...)]
	return [line (lf line ...)]
]
``` 
<img src=https://i.gyazo.com/28ecb51fc94775b5b79dd34c849c3873.png width=700></img>

During scanning phase, a data tree is built with **unordered named branches** containing **ordered sets of values**. This makes it possible to reorder or omit any branches during emission, but keep the order of values in them.

This data tree acts as *output* for the scanner and as *input* for the emitter. Tree also contains scanning and emission history, like rule positions of each match, so this tree will eventually provide enough info to perform partial updates on the data. Tree can be of any depth.

## How it works

The **hardcoded** syntax:
- At the heart of data model is a **ruleset** (like `csv-src` above) and **rule dictionary** (where all the common rules are stored).
  - Rulesets are simply a way to have the same words have different meaning for scanner and emitter. Nothing more. You can create any kind of contextual structure, inheriting rules from outer contexts. Only the word's resolved value matters to `morph`.
  - Rule dictionaries however are only two. Default ones are named [`scan-rules` and `emit-rules`](#default-rule-dictionaries) and can be overridden with `/custom` refinement. When resolving a word, dictionaries take priority over rulesets.
- Ruleset consists of named rule groups (like `value: [value-char ...]`).
- **Groups** are denoted by `()` and `[]` markers (see block and paren in [type rules](#scanner-type-rules)).
- Groups can define **single rules** (default) or **loops** (denoted by `...` before the closing brace).\
  Loops never fail, i.e. they evaluate zero or more times, similar to Parse's `any`
- Groups can contain **alternatives** (denoted by `|` as in Parse).\
  They serve as positions for backtracking. Backtracking mechanics should undo any changes to the output and any advances of the input made since the previous group start (unlike Parse where there's no backtracking of side effects).

Everything else is handled by a set of **datatype dispatchers**. These functions decide what to do when they meet a token of certain type in the rule. Type dispatchers can be extended or replaced by replacing `morph-ctx/scanner/type-rules` and `morph-ctx/emitter/type-rules` objects, though normally you wouldn't need that.

Type dispatcher that handles `function!` and `routine!` datatypes calls the corresponding function and returns it's result.\
Type dispatcher that handles `word!` datatype fetches word's value and dispatches based on the type of it's value.

Together `word!` and `function!` dispatchers allow one to fully define one's own processing rules. `word!` is first looked up in a rule dictionary, and only if it's not found, then it's value is fetched from the context where it's bound.

**Rule function** is a function (or routine) of the following interface:
```
function [
	input   [series!]
	args    [block! paren!]
	output  [series!]
	data    [object!]
	return: [pair!]
]
```
All arguments are optional, i.e. `func [input args]` is a valid rule function. No need to include what you are not going to use.

**Arguments** meaning:
- `input`:\
  for scan rules: input series at next unprocessed token's offset\
  for emit rules: subtree of the data tree (contains named branches with other subtrees)
- `args` rule after the current token (which is the name of the function)\
  rule function can read it's arguments from `args`; to treat arguments as another rule, use `morph-ctx/scanner/eval-next-rule` and `morph-ctx/emitter/eval-next-rule` functions
- `output`:\
  for scan rules: subtree of the data tree\
  for emit rules: current sub-block of the output, or output itself if it's shallow
- `data`: object of unspecified format, needed only to pass it to `eval-next-rule`

Rule functions should **return** a pair value in `ATExUSED` format, where:
- `ATE`:\
  for scan rules: length of the `input` consumed, or -1 if rule fails\
  for emit rules: -1 to fail, 0 to succeed but discard any modifications of the output (for look-ahead rules), >= 1 to succeed and keep any modifications
- `USED`: length of the `args` used by the rule (zero if rule does not take any arguments)\
  it should be set regardless of failure state (e.g. `not` rule requires this info to continue processing after the failed rule)
  

## Scanner type rules

| datatype | function |
|-|-|
| word! | Polymorphic. Looks it up in the scan dictionary, if not found - gets it's value. Then redispatches it by value type. The only exception is `any-word!` values, which are fed to `any-type!` sink, thus forbidding function and rule aliasing |
| get-word! | Literally matches the value referred to by the word |
| lit-word! | `'x` acts as a shortcut to `x: skip`, defining a named rule that eats a single token, but also sets the word so it can be inspected e.g. using `?? x` rule |
| set-word! | Defines a named rule: rule that follows the set-word will be included into the output tree. Loosely similar to `copy word! rule` in Parse | 
| paren! | Matches paren value as a single rule group (with alternatives and looping possibility). Used for flow control. | 
| block! | If it meets `any-list!` in the input, it matches itself against contents of that list. Otherwise, same as `paren!`. Used to scan input of any nesting level |
| function! and routine! | Call rule functions (explained above) |
| bitset! | Matches next item in the input against given bitset (string input only) |
| datatype! | Matches type of next item in the input against given one (block input only) |
| any-type! | Used as a fallback if no other type dispatcher can handle it. Literally matches the value against the input | 

## Emitter type rules

| datatype | function |
|-|-|
| word! | Polymorphic. Looks it up in the emit dictionary, if not found - gets it's value. Then redispatches it by value type. If value is a block or paren, chooses a named branch of the tree before entering the group. The only exception is `any-word!` values, which are fed to `any-type!` sink, thus forbidding function and rule aliasing |
| get-word! | Literally emits the word's value |
| lit-word! | Emits next item from the branch by that name, or fails if branch is exhausted |
| set-word! | Has to be followed by block or paren, for now at least. Declares a named rule group and enters it |
| paren! | Enters the rule group (with alternatives and looping possibility). Used for flow control | 
| block! | Pushes a new block on the output and enters the rule group to emit into that block. Used to create output of any nesting level |
| function! and routine! | Call rule functions (explained above) |
| any-type! | Used as a fallback if no other type dispatcher can handle it. Emits the value as is | 

## Default rule dictionaries

It's possible to inspect the rules in console:
```
>> ? scan-rules
SCAN-RULES is a map! with the following words and values:
     ?      function!     Evaluate next expression, succeed if it's not n...
     ??     function!     Display value of next token.
     show   function!     Display current input location.
     opt    function!     Try to match next rule, but succeed anyway, sim...
     ahead  function!     Look ahead if next rule succeeds.
     not    function!     Look ahead if next rule fails.
     some   function!     Match next rule one or more times.
     any    function!     Match next rule zero or more times (always succ...
     quote  function!     Match next token literally vs the input.
     lit    function!     Match contents of next block/paren (or word ref...
     skip   function!     Match any single value.
     head   function!     Match head of input only.
     tail   function!     Match tail of input only.

>> ? emit-rules
EMIT-RULES is a map! with the following words and values:
     quote  function!     Emit next token as is.
     lit    function!     Emit contents of next block/paren (or word refe...
     opt    function!     Try to match next rule, but succeed anyway, sim...
     ahead  function!     Look ahead if next rule succeeds.
     not    function!     Look ahead if next rule fails.
     to     function!     [to datatype! rule...] Convert result of rule m...
     load   function!     [load rule...] Load result of next rule match.
```

Play in console to get a feel of it ;) Though most of it is similar to Parse. `? expr` is similar to Parse's `if (expr)`, `lit` can be used to match multiple items, e.g. `lit [1 2 3]` would be equivalent to Parse's `quote 1 quote 2 quote 3`, and also supports words. The rest should be obvious. 

These are not final, but seemed like a good starting point and showcase.

To override these use `morph/custom` call. Compose your own rule dictionaries that fit perfectly your taste and your task at hand!


## Partial update logic

Scanner and emitter keep track of each named match start and end, both in input/output, in the data tree, and in the scan/emit rules themselves. Thus given a changed range in the input, it should be possible to:
- clear the tree of all named matches affected by the change
- find previous named match unaffected by the change
- roll back the state back to the point where that match happened
- continue scanning until whole changed range is processed
- continue scanning to a point where a newly added named match fully repeats another one present in the tree
- knowing starting and ending unchanged named matches, we remove part of output corresponding to them and
- repeat emission from the state of starting match to the state of ending match
- then insert emitted chunk into the output
- call it a day

But this is a lot of work, so only sketched so far...  

## Further considerations

These features weren't designed but were considered for later:
- Functions to work with the data tree, so user-defined rules could call them too.  
- Inline declaration of named rules, e.g. `[x: rule1 x x y: rule2 y y]`. Should be possible to define all rules on the go, without prior context creation.
- Multiple sources/targets could be combined later in the single `morph` call using likely `from source ...` and `into target ...` rules.
- Support of automatic propagation of changes from a single series into many will require on-deep-change to use a dispatcher of sorts. We should be able to add/remove new targets.
- Macros to rewrite rules in place. E.g. `opt rule` -> `[rule |]`, or `some rule` -> `rule any rule`.\
  Problem with these is that arity of each rule is only known at the moment of it's evaluation, but macros cannot evaluate anything, so they are limited by their knowledge and need extra clues. And then there's a question of how to spell them. If with issues, e.g. `#opt rule`, then is this better than using Red preprocessor? And won't we be conflicting with the preprocessor?
- Natives and actions could be used as rule functions of simpler form. They would take the series and possibly single argument and return series at a new offset (or none). Thus `find` could be used as `to`, `next` as `skip`, maybe something else. I'm not sure how much use this idea is.
- How to track partial updates to integral transformations, e.g. if we transform each item in a series into a sum of it and all previous items?
- Write some example codec, like JSON, to test and evaluate the model and the rules used. Maybe add more rules to the table.
- Think how to simplify parallel evaluation, try to find common ground. 

**Abandoned ideas**:

- Automatic rules reversal (i.e. given only source and target formats, be able to produce mappings in both directions). Would limit the possibilities too much, totally not worth it.
- Parsing and emitting in a single rule, e.g. `[x y -> y x]`. Does not scale, loses readability fast. Does not provide a clear answer to what input and output should look like without extra thinking. 






