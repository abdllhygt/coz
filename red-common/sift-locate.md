# SIFT & LOCATE

`sift` is a high-level filter.\
`locate` is a high-level `find`.

The idea behind these two is to **remove the syntactic noise** from trivial filter expressions and clearly relay the code's intent.

Sift & Locate make great one-liners. If filtering block is huge and complicated, no win here.

To use currently you have to [**`#include %sift-locate.red`**](sift-locate.red). Fastest way to learn is to play ☻

## Usage examples

| Classic Red code | Sift/Locate code | Comment |
|-|-|-|
| <pre><br>forall faces [<br>	all [<br>		faces/1/type = 'base<br>		faces/1/size <> 0x0<br>		faces: head pos: faces<br>		break<br>	]<br>]<br>if pos [do-smth]<br></pre> | `if pos: locate faces [.. /type = 'base /size <> 0x0] [do-smth]` | /refinements are automatically made into paths |
| <pre><br>forall objs [<br>	all [<br>		in objs/1 'data<br>		in objs/1/data 'type<br>		objs/1/data/type = 'container<br>		objs: head pos: objs<br>		break<br>	]<br>]<br>if pos [do-smth]<br></pre> | `if pos: locate/back objs [obj .. obj/data/type = 'container] [do-smth]` | Paths are automatically checked for existence - no error dodging required |
| <pre><br> q: queue<br> while [q: find/same/skip q reactor 4][<br> 	if same? :q/2 :reaction [return yes]<br> 	q: skip q 4<br> ]<br> no<br> </pre> | `to logic! locate/same queue [(reactor) (reaction) - -]` | \*each spec format is fully supported, including fast hash lookups |
| <pre><br>either target [<br>	field: in reactor field<br>	pos: skip relations 3<br>	if pos: find/same/skip pos field 4 [<br>		return pos/-1<br>	]<br>][<br>	pos: relations<br>	while [pos: find/same/skip pos reactor 4][<br>		if pos/2 = field [return pos/3]<br>		pos: skip pos 4<br>	]<br>]<br>none<br></pre> | <pre><br>pos: locate/same relations either target [<br>	[- - - (in reactor field)]<br>][<br>	[(reactor) word - - .. word = field]<br>]<br>if pos [pos/3]<br></pre> | Row format is expressed naturally, leaving off all the index trickery |
| <pre><br>path: back tail path<br>until [<br>    targ: :path/1<br>    if all [<br>        attempt [:targ/feel/over]<br>        targ <> window<br>        any [<br>			changed<br>			previndex <> index<br>			find window/face-flags 'all-over<br>		]<br>    ][<br>        do-smth...<br>        break<br>    ]<br>    <br>    path: back path<br>    head? path<br>]<br></pre> | <pre><br>if locate/back path [<br>	targ .. :targ/feel/over<br>	targ <> window<br>	any [<br>		changed<br>		previndex <> index<br>		find window/face-flags 'all-over<br>	]<br>][<br>	do-smth..<br>]<br></pre> | Non-essential code is kept at minimum |
| <pre><br>while [not tail? faces] [<br>	either all [<br>		object? face: :faces/1<br>		in face 'type<br>		face/type = 'face<br>	][<br>		if not face/show? [face/show?: true]<br>		do-smth...<br>	][<br>		do make error! "Invalid graphics face object"<br>	]<br>	faces: next faces<br>]<br></pre> | <pre><br>foreach face sift faces [<br>	.. object! /type = 'face<br>	[/show? \| /show?: true]<br>  \|	(do make error! "Invalid graphics face object")<br>][<br>	do-smth...<br>]<br></pre> | Filter code is kept separate from main action code, cleanly expressing the intent |
| <pre><br>while [base: find/skip base name 2] [<br>    append result :base/2<br>    base: skip base 2<br>]<br></pre> | `append result sift base [(name) x]` | Unnamed columns are skipped by `sift` |
| <pre>extract remove-each [role value] any [roles []] [value <> "yes"] 2</pre> | `sift any [roles []] [role ("yes")]` | Extract is thus unnecessary |
| <pre><br>remove-each item src-data [<br>    any [<br>        item/1 = "Commodity"<br>        item/2 = "Practice"<br>    ]<br>]<br></pre> | `sift src-data [.. /1 <> "Commodity" /2 <> "Practice"]` | Refinements become paths |
| `remove-each row face/data [not value? 'row]` | `sift face/data [.. default!]` | Type(set) tests can shorten even one-liners |



## Syntax


See [https://github.com/greggirwin/red-hof/tree/master/code-analysis#siftlocate](here) for background. But those were just early ideas. Some weren't good at all. Some were ambiguous or contradictory. Some were unnecessary. And as @greggirwin said, filters are only a tiny part of code and we don't want to switch our mind into a totally differernt dialect every time we see or write one. This redesign is based on a minimal set of simple rules.

Both `sift` & `locate` accept a **pattern** argument written in the same dialect:
- **pattern**: `[spec opt ['.. tests]]` - **`..`** acts as a delimiter, visually separaring row format from filter
- **spec**: [format used by \*each functions](foreach-design.md) is fully supported, including value and type filters (in fact, `locate` translates into `foreach`, while `sift` - into `map-each`)
- **tests**: `[test-chain any ['| test-chain]]` - like in Parse, **`|`** declares an alternative logical path (used to construct `any` clause)
- **test-chain**: `[any expression]` - a chain of Red expressions that is used to construct an `all` clause (with some special cases allowed, see below)

`locate` returns position in the series *before* a row that matched the pattern (or none if not found):
```
>> locate [1 2 3 4 5 6 7 8 9] [- x - .. x = 5]
== [4 5 6 7 8 9]
>> locate/back [1 2 3 4 5 6 7 8 9] [- x - .. x = 5]
== [4 5 6 7 8 9]
```

`sift` returns selected (named) columns from rows that matched the pattern (preserves series type):
```
>> sift [1 2 3 4 5 6 7 8 9] [- x - .. x = 5]
== [5]
>> sift [1 2 3 4 5 6 7 8 9] [- x -]
== [2 5 8]
>> sift [1 2 3 4 5 6 7 8 9] [x .. odd? x]
== [1 3 5 7 9]
```

### Spec

Is used to specify **row format** in the data being inspected.

\*each spec format here is extended with:
- **`-`** marker that denotes unused columns, e.g. `[one - - four]`
- empty spec is allowed and gets transformed into a single anonymous word (i.e. step = 1), e.g. `[.. pair! /x > 0]` is the same as `[p .. pair? p p/x > 0]`

Named columns (e.g. `one` and `four` in `[one - - four]`) both declare the meaning of data and can be used in tests. They also appear in `sift` output.

Unnamed columns (skipped by `-` or using value filters `(value)`) can still be checked using positional index:\
`[p: x - - .. p/2 = p/3]` will select first column from rows where 2nd and 3rd columns are equal. `p:` is not a column here, but `x` is.

### Tests

Similar to Parse DSL, `sift` & `locate` use blocks of expressions delimited by **`|`** marker instead of nested any/all clauses. The point of it is to enhance readability.

Each **test must return a truthy value** to proceed further. If it returns `false` or `none`, next alternate test chain is evaluated, or if this was the last chain, iteration immediately continues. For `sift` this means that row is skipped in output, for `locate` - that this is not the row we're looking for.

Empty set of tests `[x ..]` always succeeds \(similar to how `[]` rule in Parse does, see also [REP 85](https://github.com/red/REP/issues/85)\)

Tests are normal Red expressions, with the following special cases made:

1. Refinements get **converted into paths**\
e.g. `[obj .. /item = 0]` -> `[obj .. obj/item = 0]`.

   That works when only a single named column is present in the spec: `obj` or `- x - -`. Empty spec is also allowed, because it gets transformed into a single named anonymous column. Value filters are not named: `- (value)` spec forbids refinement syntax.

   Note that refinements don't stick to each other, so `/a/b` is lexed as `/a /b`, resulting in two paths tested one after the other: `[obj .. /a/b = 0]` will be rewritten as `[obj .. obj/a obj/b = 0]` and will likely be a mistake. So, remember to fully qualify deep paths: `[obj .. obj/a/b = 0]`

2. **Single-word** expression that has a **value of datatype or typeset** is used as a type check\
e.g. `[x .. integer!]` -> `[x .. integer? x]`.

   Function calls don't get this special treatment of their result.

   As above, this only works for specs containing a single named column. 

3. **Paths** (including those produced by refinements) are **tested for validity** first\
e.g. `[p .. /x = 0]` -> `[p .. path-exists? p/x p/x = 0]` - validity test is inserted before the expression that uses path.

   This is done to avoid unnecessary error handling. Non-existing paths just fail the tests and search/filtering continues.\
   If you want to receive an error from invalid path, wrap it in parens: `(p/x) = 0`.

4. **Parens are not processed** at all.

   Use them to escape the dialect: `(my-func /ref-arg path/that/throws/errors)` etc.

5. Single **literal blocks** are used to construct inner `any [all [...]]` subtrees (similar to Parse)\
e.g. `[x y .. x > 0 [y < 5 | z > 10]]` -> `[x y .. all [x > 0 any [y < 5 z > 10]]]`.

   Such literal blocks can in turn contain other literal blocks, allowing any logical nesting level to be reached.\
   Blocks used as arguments are unaffected. And blocks returned as evaluation results.



**Note**: some of these cases require use of the **preprocessor** to determine expression bounds, so avoid overly tricky dynamic code (e.g. construction of functions used in tests as a side effect of tests evaluation).

