# Generalized \*EACH loops

Describes usage & design of extended FOREACH, MAP-EACH & REMOVE-EACH loops design for possible inclusion into Red runtime.

Design is based on examination of code patterns statistics described [here](https://github.com/greggirwin/red-hof/tree/master/code-analysis), with some improvements made after a period of my own usage of the prototype. Every feature implemented here is backed by real world needs.

The goal is to provide high-level loop constructs to improve the declarativity of Red code.

[2nd table here](https://github.com/greggirwin/red-hof/tree/master/code-analysis#loopmeaning-matrix) shows what we use loops for.

FOREACH, MAP-EACH and REMOVE-EACH aim to cover three of those use cases:
- `foreach`: general purpose iteration
- `map-each`: map of one series into another, 1 or more source items are mapped into 0 or more target items
- `remove-each`: series filter

Remaining use cases (lookup & fold) should be separate designs.

This design is backward-compatible with the existing one used in Red.

Impelementation can be found in [`new-each.red`](new-each.red), along with the tests. It intentionally follows imperative style to ease eventual transition of it's code into Red/System.


## Spec

All \*each functions share the same format of their spec.

Spec can include the following elements:

| Type | Example | Meaning |
|-|-|-|
| word! | `foreach [x y z] srs` | Gives a name (and meaning) to a value fetched from the series |
| `set-word!` | `foreach [p: x y] srs` | *Series offset*. Sets `p` to series `srs` at index referring to the first fetched item `x`. Should be the 1st item in the spec. |
| `refinement!` | `foreach [/i x y] srs` | *Iteration number*. Sets `i` to iteration number, counting from `1` and up, regardless of traversal direction. Skipped (not matched by spec) iterations are also counted. Should be the 1st item in the spec, so mutually exclusive with set-word. |
| `block!` | `foreach [x [integer!]] [a 1 2 b]` | *Type filter*. Skips iterations where fetched value `x` does not belong to given type, typeset or a mix of. Has to follow a `word!`. |
| `paren!` | `foreach [p: ('_)] [1 _ 3 4 _]` | *Value filter*. Skips iterations where fetched value (unnamed) does not equal to the result of a paren evaluation (evaluated with `do` before entering the loop). `/same` and `/case` refinements are provided to control the comparison operator. Leverages fast lookups of hashes and maps. |
| `|` (pipe - reserved word) | `foreach [x | y] [1 2 3]` | Splits spec into 2 parts: words before `|` are counted in step size, words after are not. Switches loop into "no leftovers" mode: enters only those iterations where all words can be filled from the series (i.e. no filling with `none` from past-the-tail area). Contrary to normal iteration which enters if at least first word can be filled. Used to loop with intersections, which is useful even outside DSP area. |

Spec can also be a `word!`, used as a shortcut. E.g. `foreach x ..` is fully equivalent to `foreach [x] ..`.

Note: `/i` and `p:` cannot be mixed together because then behavior becomes undefined. E.g. user modifies `p` and it's not aligned with step anymore and may even go backwards, then what should `i` become?

## Series

Apart from iteration over series, this version supports:

| Subject | Example | Meaning |
|-|-|-|
| integer! | `foreach [x y] 10` | `repeat` generalization that can unfold integer range in groups |
| pair! | `foreach xy 10x10` | `repeat` generalization on pairs (can also fill multiple items at once, though unlikely ever needed) |
| map! | `foreach [/i k v] #(a b)` | map is treated as series of key-value pairs |

Note: `map-each/self` does not support integer & pair ranges, because `map-each` is enough, and `/self` is simply not needed.\
`remove-each` supports ranges, but creates a new block as a result:
```
>> remove-each x 54 [any [x % 2 = 0  x % 3 = 0  x % 5 = 0]]
== [1 7 11 13 17 19 23 29 31 37 41 43 47 49 53]
```

## Refinements

### `/same`

Tells *value filter* to compare for sameness (for all values if more than one is provided)
```
>> b: [] for-each/same [p: (b)] reduce [[] b []] [? p]
P is a block! value.  length: 2 index: 2 [[] []]
```

### `/case`

Tells *value filter* to compare for strict equality (for all values if more than one is provided)
```
>> for-each/case [p: (1.0)] [1 1.0 100%] [? p]
P is a block! value.  length: 2 index: 2 [1.0 100%]
```

### `/reverse` (foreach only)

Reverses the iteration direction - from tail to current index.\
Consider:
```
>> for-each [/i x y] "abcde" [print [i x y]]
1 a b
2 c d
3 e none

>> for-each/reverse [/i x y] "abcde" [print [i x y]]
1 e none
2 c d
3 a b
```
As you can see, `/reverse` does not affect alignment of it's spec towards initial offset: item after `e` is still `none`. It can be seen as time reversal, though iteration number is still counted forward.

### `/eval` (map-each only)

`reduce`s blocks returned by iteration code automatically, saving user from extra `reduce` call. If `/only` is not also provided, reduction is done in place to avoid extra allocations (and that is the main this refinement exists).

Compare:
```
>> map-each [x y] [a 1 b 2 c 3] [reduce/into [y x] clear []]
== [1 a 2 b 3 c]

>> map-each/eval [x y] [a 1 b 2 c 3] [[y x]]
== [1 a 2 b 3 c]
```

### `/only` (map-each only)

Any-blocks returned by iteration code are treated as single values.

It's possible to do away without `/only` and it only serves as a shortcut that expresses the meaning:\
`map-each/only x .. [:x]` <=> `map-each x .. [reduce [:x]]` <=> `map-each/eval x .. [[:x]]`

Without `/only` it gets messy at times:
```
>> map-each/eval/only x [a b c] [[x]]
== [[a] [b] [c]]
```
becomes one of:
```
>> map-each/eval x [a b c] [[reduce [x]]]
== [[a] [b] [c]]

>> map-each x [a b c] [compose/deep/only [[(x)]]]
== [[a] [b] [c]]
```
I consider readability to be well worth the cost of supporting `/only`.

### `/self` (map-each only)

Instead of returning a newly allocated block, commits the changes into original series or map.

```
>> map-each/self x s: "cypher" [x - #"a" + 13 % 26 + #"a"]		;) rot13
== "plcure"
>> s
== "plcure"
```
Can be used like `remove-each`:
```
>> map-each/self x s: "cyPHer" [either x < #"a" [][x]]		;) unset is formed into empty string
== "cyer"
>> map-each/self x s: [1 4 3 2] [either x < 3 [[]][x]]		;) empty block w/o /only counts for nothing
== [4 3]
```

### `/drop` (map-each and remove-each)

Discards regions not matched by spec's value and type filters (which are included in output by default).\
Also discards regions where iteration code did not return any result (`continue` or `break` was called).

Compare:
```
>> map-each [x [word!]] [a 2 c 4] [form x]
== ["a" 2 "c" 4]

>> map-each/drop [x [word!]] [a 2 c 4] [form x]
== ["a" "c"]
```

## Ownership & events

To avoid O(n^2) time complexity of in-place series modification, `map-each/self` and `remove-each` use an internal buffer for their operation. Upon leaving, temporary result gets copied into the original series buffer. As a result only a single `on-deep-change*` event gets generated, covering the whole changed region.


## Returned values

FOREACH:
- unset when never entered iteration code
- unset if last evaluated iteration calls `continue` or `break` without `/return`
- result of `break/return` if it's evaluated
- result of last evaluated iteration otherwise (that is, filtered out regions do not affect the result)

MAP-EACH:
- result of `break/return` if it's evaluated
- resulting series otherwise (which can be empty if never entered iteration code): without `/self` it's always a block, with `/self` the original index is retained

REMOVE-EACH:
- result of `break/return` if it's evaluated
- modified original series otherwise; original index is retained

## Usage scenarios

### Series index

Often used for in-place modification of the series, like this:
```
forall srs [
	set [a: b: c:] srs
	srs/2: a + c / b
	srs: skip srs 2
]
```
Which is a lot of micromanagement for such simple thing.\
Other times it can be used to access another parallel series at the same index, or for other purposes.

Inclusion of series index into spec allows one to use it also in `map-each` and `remove-each`, as well as write readable code:
```
foreach [p: a b c] srs [p/2: a + c / b]
```
or
```
map-each/self/eval [a b c] srs [[a a + c / b c]]
```

### Iteration number

Used to avoid this sort of code:
```
repeat i length? srs [
	x: srs/:i
	...
]
```
or
```
i: 0
foreach x srs [
	i: i + 1
]
```
Instead, counter is provided for free in all \*each loops:
```
>> for-each/reverse [/i x y] "abcde" [print [i x y]]
1 e none
2 c d
3 a b
>> map-each/eval [/i w] [a b c] [[i w]]
== [1 a 2 b 3 c]
>> remove-each [/i x] "abcde" [even? i]
== "ace"
```

### Value filters

Are there to replace common (but low-level) while-find or until-find idiom.

Consider this code from R2:
```
while [not none? base: find/skip base name 2][
    insert tail result pick base 2
    base: skip base 2
]
```
It can be reduced in Red to:
```
while [base: find/skip base name 2][
    append result :base/2
    base: skip base 2
]
```
With foreach it becomes just:
```
foreach [(name) y] base [append result :y]
```
Or:
```
map-each/drop [(name) y] base [:y]
```

And this simplified example from `reactivity.red`:
```
while [pos: find/skip pos field 3] [
	set [word: reaction: target:] pos
	...
	pos: skip pos 3
]
```
Becomes obvious:
```
foreach [(field) reaction target] pos [
	...
]
```

### Type filters

Same as value filters, let us express while-find idiom in a human readable manner.

Consider (do you find it easy to read what this code does?):
```
while [tmp: find tmp block!] [
    change tmp func [new args] first tmp
]
```
Now it be rewritten as:
```
map-each/self [blk [block!]] tmp [func [new args] blk]
```
Which obviously just turns blocks into functions.


### Iteration with intersections

Usually it's simple DSP-like cases, where iteration step is less than count of items we want to inspect at each iteration.\
E.g. treatment of profiling results:
```
>> t: now/precise
>> time-data: reduce [t [code1] t + 0:0:0.1 [code2] t + 0:0:0.2 [code3] t + 0:0:0.3]	;) t+ are some timestamps
>> for-each [t1 code | t2] time-data [print [code "took" difference t2 t1]]
code1 took 0:00:00.1
code2 took 0:00:00.1
code3 took 0:00:00.1
```
Or averaging coordinates of pointer moves:
```
>> map-each/drop [xy1 | xy2] [1x1 20x10 30x10 25x20 40x22] [xy1 + xy2 / 2]
== [10x5 25x10 27x15 32x21]					;) note that 5 pairs produce 4 centers
```

Pipe `|` ensures all words of the spec are always filled, so you need not slow your code down with `none?` checks.\
As a side effect, it can be used to iterate over full multiples of spec length only:
```
>> for-each [a b c] [1 2 3 4 5 6 7 8] [print [a b c]]
1 2 3
4 5 6
7 8 none
>> for-each [a b c |] [1 2 3 4 5 6 7 8] [print [a b c]]
1 2 3
4 5 6
```

### Iteration over pair ranges

This is often useful on 2D data or images.

Current implementation accepts a pair *limit* and walks from 1x1 up to that limit:
```
>> for-each xy 3x2 [prin [xy ""]]
1x1 2x1 3x1 1x2 2x2 3x2 
>> remove-each xy 3x3 [xy/x = xy/y]
== [2x1 3x1 1x2 3x2 1x3 2x3]
```
It is also a common need to have a starting point not at 1x1, which is currently achieved with addition:
```
>> map-each xy 2x2 [10x10 + xy]
== [11x11 12x11 11x12 12x12]
```
However I expect eventually Red to be enriched with a range! datatype that \*each loops will accept as subject argument, and it will work like this out of the box:
```
>> map-each xy 11x11..12x12 [xy]
== [11x11 12x11 11x12 12x12]
```

### Iteration over integer ranges

`repeat` already provides this functionality. However \*each version generalizes that to multiple words at a time:
```
>> for-each [i j | k] 10 [print [i j k]]
1 2 3
3 4 5
5 6 7
7 8 9
```
What \*each functions do not provide is choice of step: it's always equal to `1`. This is where more specialized loops like `for`/`loop` from [REP#0101](https://github.com/red/REP/blob/master/REPs/rep-0101.adoc) will shine eventually.


## Design edge cases

### Source modification on the fly

Is allowed:
```
>> for-each [a b] s: [1 2 3 4 5] [print [a b] append s 1 + length? s]
1 2
3 4
5 6
7 8
9 none
== [1 2 3 4 5 6 7 8 9 10]
```

### Reverse iteration not from head

As /reverse behaves as time reversal, it stops at the original index if it's not at head:
```
>> for-each x skip "abcdef" 2 [prin x]
cdef
>> for-each/reverse x skip "abcdef" 2 [prin x]
fedc
```

### Zero step

Pipe position is not restricted, so it can be used to set step to zero:
```
foreach [| x] ...
```
Current implementation does not forbid it, but requires series index to be in the spec, using which iteration can be manually advanced:
```
>> for-each [p: | x] "abcdef" [print x p: skip p (random 7) - 4]
a
a
a
c
d
b
a
d
== ""					;) eventually it reached tail
```
End condition for zero step is the same as for positive step: reach the tail, and `/reverse` doesn't have any effect.

Absence of any words or value filters is forbidden though, so `foreach [p:]`, `foreach []`, `foreach [|]` are all errors.

### Two indexes at the same time

Current implementation does not allow to use both iteration number `/i` and series index `p:` in the spec.

Should it be allowed? Nothing is preventing us from allowing it later, if it's proven useful.

### Iteration on maps not aligned to even number of words

`foreach [k v] map` should be the most common case, however current implementation does not enforce it.

`foreach [k1 v1 k2 v2]` or `foreach [k1 v1 k2]` likes seem devoid of sense. However single word can have meaning:\
`map-each/self x map [form x]` instead of `map-each/self/eval [k v] map [[form k form v]]`

Should we forbid 3+ items per spec on maps? or 1 item? If so, should we also restrict the usage of pipe `|`?\
I'm no fan of arbitrary restrictions that serve zero purpose, however it may make sense if we expect some future map implementations to complicate such unrestricted access (currently it's just `hash!` in disguise and there's no problem).

### /eval and non-block results

Current version of `map-each/eval` only calls `reduce` on block results.\
Should it call it on other result types?

### Index when iterating over images

Current implementation defines iteration index as number, totally unrelated to index in the series.\
However when iterating over images, a pair coordinate is more useful.\
No special case is made in the code for this. But pair index can be obtained by iterating over image/size:
```
>> i: make image! 3x2
>> for-each xy i/size [print [xy i/:xy]]
1x1 255.255.255.0
2x1 255.255.255.0
3x1 255.255.255.0
1x2 255.255.255.0
2x2 255.255.255.0
3x2 255.255.255.0
```

### Type filters on vector series

`find vector type!` doesn't work in Red even if vector is all of that type, so don't try type filters on vector input - that won't work.

Should however \*each loops check this case and throw an error?


### On-demand advancement

Sometimes there's a need to advance the loop position based on data read, esp. when parsing data.\
An `advance` func is proposed [here](https://github.com/greggirwin/red-hof/tree/master/code-analysis#on-demand-advancement), but current implementation does not provide it, as I'm not yet convinced it's worth it:
- If we decide to provide it, user may expect it to work in all other loops (repeat, forall..), but it doesn't make a lot of sense there
- It interplay with filters, ranges, /drop, /reverse, pipe, while well-definable, still not easy to think about. And if it doesn't make the code easier to understand, what's the point of it?
- If it's a native like `break` and `continue`, that means new type of exception has to be considered by all R/S code

Current way of manual advancement is modifying the series offset:
```
>> for-each [p: x n] [a 0  b 1 x  c 2 y z] [print [x ":" copy/part at p 3 n] p: skip p n]
a : 
b : x
c : y z
== [y z]
```
In `map-each` and `remove-each` such "skipped" regions are considered consumed and handled by the iteration code. It's up to user to make it appear in output, as otherwise it'll be lost:
```
>> map-each [p: x n] [a 0  b 1 x  c 2 y z] [p: skip p n n]
== [0 1 2]        ;) 'x' and 'y z' were skipped, but weren't provided by the final result `n`
```

### Separation

`/sep` refinement was considered for `map-each` to insert a separator between results. However this separator would come after the code block, which is bad style. And it also would complicate insertion of filtered out regions.

For now, alternate approaches on separation can be used:
```
>> next map-each/eval [/i x] [a b c] [['| i x]]
== [1 a | 2 b | 3 c]
>> map-each/eval [x | _] [a b c] [[x '|]]
== [a | b | c]			;) without /drop it just copied the `c` part, though never iterated over it
```

Eventually, maybe a wrapper around `map-each` with different order of arguments (and maybe `/self` by default) can be made, e.g.:
```
>> delimit-each/eval '| [/i x] [a b c] [[i x]]
== [1 a | 2 b | 3 c]
```
And a dumber version is also valuable (a standard mezz, and [REP94](https://github.com/red/REP/issues/94) is applicable here):
```
>> delimit/skip [1 a 2 b 3 c] '| 2
== [1 a | 2 b | 3 c]
```

### Compilability

These loops are not low-level. Implementing them at R2 side is expected to be a big effort with near zero performance gain.

### Scope of words

Current implementation keeps spec words local to loops's body. However, R/S version will collect those words and put them into `function` spec, to avoid binding cost at each loop startup.


