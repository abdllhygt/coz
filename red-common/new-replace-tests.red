Red [
	Title:   "Red replace test script"
	Author:  "Nenad Rakocevic & Peter W A Wood & Toomas Vooglaid & hiiamboris"
	File: 	 %replace-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2023 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../red-src/red/quick-test/quick-test.red
qt-verbose: yes
#include %include-once.red
#include %new-replace.red
#include %mapparse.red

~~~start-file~~~ "replace"

===start-group=== "replace"

	--test-- "replace-1"	--assert [1 4 3 4 5]       = replace [1 2 3 2 5] 2 4
	--test-- "replace-2"	--assert [1 4 5 3 4 5]     = replace [1 2 3 2] 2 [4 5]
	--test-- "replace-3"	--assert [1 8 9 8 9]       = replace [1 2 3 2 3] [2 3] [8 9]
	--test-- "replace-4"	--assert [1 2 3 2 3]       = replace/only [1 2 3 2 3] [2 3] [8 9]
	--test-- "replace-5"	--assert [1 [[2 3]] [8 9]] = replace/only [1 [[2 3]] [2 3]] [2 3] [8 9]
	--test-- "replace-6"	--assert [1 8 8]           = replace [1 2 3 2 3] [2 3] 8
	--test-- "replace-7"	--assert 'a/b/g/d/g        = replace 'a/b/c/d/c 'c 'g
	--test-- "replace-8"	--assert 'a/b/g/h/d/g/h    = replace 'a/b/c/d/c 'c 'g/h
	--test-- "replace-9"	--assert #{640164}         = replace #{000100} #{00} #{64}
	--test-- "replace-10"	--assert %file.sub.ext     = replace %file!sub!ext #"!" #"."
	--test-- "replace-11"	--assert <tag body end>    = replace <tag_body_end> "_" " "
	--test-- "replace-12"	--assert [x: 123]          = replace [a: 123] quote a: quote x:
	--test-- "replace-13"	--assert "XbXdXf"          = replace "abcdef" charset "ace" "X"
	--test-- "replace-14"	--assert "XbcdXf"          = replace/case "AbcdEf" charset "ACE" "X"

===end-group===

===start-group=== "replace/deep"

	--test-- "replace/deep-1"	--assert [1 8 3 [4 8]]               = replace/deep [1 2 3 [4 2]] [2] 8
	--test-- "replace/deep-2"	--assert [x: 123 [x: 123]]           = replace/deep [a: 123 [a: 123]] quote a: quote x:
	--test-- "replace/deep-3"	--assert [1 [1] 1 [1 [1] 1] 1 [1] 1] = replace/deep [1 [1] 1] 1 [1 [1] 1]
	--test-- "replace/deep-4"	--assert [1 [1 [1] 1] 1]             = replace/deep/only [1 [1] 1] [1] [1 [1] 1]

===end-group===

===start-group=== "replace/once"

	--test-- "replace/once-1"	--assert [4 5]                = replace/once [1 2 3 4 5] 3 8
	--test-- "replace/once-1a"	--assert [1 2 8 4 5]     = head replace/once [1 2 3 4 5] 3 8
	--test-- "replace/once-2"	--assert [4 5]                = replace/once [1 2 3 4 5] 3 [8 9]
	--test-- "replace/once-2a"	--assert [1 2 8 9 4 5]   = head replace/once [1 2 3 4 5] 3 [8 9]
	--test-- "replace/once-3"	--assert [4 5]                = replace/once/only [1 2 3 4 5] 3 [8 9]
	--test-- "replace/once-3a"	--assert [1 2 [8 9] 4 5] = head replace/once/only [1 2 3 4 5] 3 [8 9]
	--test-- "replace/once-4"	--assert [5]             =      replace/once [1 2 3 4 5] [3 4] [8 9]
	--test-- "replace/once-5"	--assert [1 2 8 5]       = head replace/once [1 2 3 4 5] [3 4] 8
	--test-- "replace/once-6"	--assert [1 2 a 5]       = head replace/once [1 2 3 4 5] [3 4] 'a
	--test-- "replace/once-7"	--assert tail?                  replace/once [a b c d] 'not-there 'g
	--test-- "replace/once-7a"	--assert [a g c d]       = head replace/once [a b c d] 'b 'g
	--test-- "replace/once-8"	--assert 'a/b/g/d/e      = head replace/once 'a/b/c/d/e 'c 'g
	--test-- "replace/once-9"	--assert 'a/b/g/h/i/d/e  = head replace/once 'a/b/c/d/e 'c 'g/h/i
	--test-- "replace/once-10"	--assert 'a/b/c/d/e      = head replace/once 'a/b/g/h/i/d/e 'g/h/i 'c
	--test-- "replace/once-11"	--assert #{006400}       = head replace/once #{000100} #{01} 100
	--test-- "replace/once-12"	--assert %file.ext       = head replace/once %file.sub.ext ".sub." #"."
	--test-- "replace/once-13"	--assert "abra-abra"     = head replace/once "abracadabra" "cad" #"-"
	--test-- "replace/once-14"	--assert "abra-c-adabra" = head replace/once "abracadabra" #"c" "-c-"
	--test-- "replace/once-15"	--assert "x23"           = head replace/once "123" 1 "x"
	--test-- "replace/once-16"	--assert "xbc"           = head replace/once "abc" quote a: "x"
	--test-- "replace/once-17"	--assert [a x c 4 e]     = head replace/once [a 2 c 4 e] integer! 'x
	--test-- "replace/once-18"	--assert [a 2 c 4 e]     = head replace/once/only [a 2 c 4 e] integer! 'x
	--test-- "replace/once-19"	--assert [a 2 c x e]     = head replace/once/only reduce ['a 2 'c integer! 'e] integer! 'x
	--test-- "replace/once-20"	--assert [a c [x] [[c]]] = head replace/once/only [a c [c] [[c]]] [c] [x]
	--test-- "replace/once-21"	--assert [a c  x  [[c]]] = head replace/once/only [a c [c] [[c]]] [c] 'x

===end-group===

===start-group=== "replace/deep"

	--test-- "replace/deep-1"	--assert [1 2 3 [8 5]]     = replace/deep      [1 2 3 [4 5]] 4 8
	--test-- "replace/deep-2"	--assert [1 2 3 [4 8 9]]   = replace/deep      [1 2 3 [4 5]] 5 [8 9]
	--test-- "replace/deep-3"	--assert [1 2 3 [4 [8 9]]] = replace/deep/only [1 2 3 [4 5]] 5 [8 9]
	--test-- "replace/deep-4"	--assert [1 2 3 [8 9]]     = replace/deep      [1 2 3 [4 5]] [4 5] [8 9]
	--test-- "replace/deep-5"	--assert [1 2 3 [8 9]]     = replace/deep/only [1 2 3 [4 5]] [4 5] [8 9]
	--test-- "replace/deep-6"	--assert [1 2 3 [8]]       = replace/deep      [1 2 3 [4 5]] [4 5] 8
	--test-- "replace/deep-7"	--assert [1 2 3 8]         = replace/deep/only [1 2 3 [4 5]] [4 5] 8
	--test-- "replace/deep-8"	--assert [x: 1 2 3]        = replace/deep      [a: 1 2 3] quote a: quote x:
	--test-- "replace/deep-9"	--assert [x: 1 2 3]        = replace/deep      [a  1 2 3] quote a: quote x:
	--test-- "replace/deep-10"	--assert [x: 1 2 3]        = replace/deep/case [a: 1 2 3] quote a: quote x:
	--test-- "replace/deep-11"	--assert [a  1 2 3]        = replace/deep/case [a  1 2 3] quote a: quote x:
	--test-- "replace/deep-12"	--assert [1 [[8 9]] [8 9]] = replace/deep/only [1 [[2 3]] [2 3]] [2 3] [8 9]

===end-group===

===start-group=== "replace/case"

	--test-- "replace/case-1"	--assert "axbAab"   = head replace/case/once "aAbAab" "A" "x"
	--test-- "replace/case-2"	--assert "axbxab"   =      replace/case      "aAbAab" "A" "x"
	--test-- "replace/case-3"	--assert %file.txt  = head replace/case/once %file.TXT.txt %.TXT ""
	--test-- "replace/case-4"	--assert %file.txt  =      replace/case %file.TXT.txt.TXT %.TXT ""
	--test-- "replace/case-5"	--assert <tag xyXx> = head replace/case/once <tag xXXx> "X" "y"
	--test-- "replace/case-6"	--assert <tag xyyx> =      replace/case <tag xXXx> "X" "y"
	--test-- "replace/case-7"	--assert 'a/X/o/X   = head replace/case/once 'a/X/x/X 'x 'o
	--test-- "replace/case-8"	--assert 'a/o/x/o   =      replace/case 'a/X/x/X 'X 'o
	--test-- "replace/case-9"	--assert ["a" "B" "x"]     replace/case ["a" "B" "a" "b"] ["a" "b"] "x"
	--test-- "replace/case-10"	--assert (make hash! [x a b [a B]]) = head replace/case/once make hash! [a B a b [a B]] [a B] 'x
	--test-- "replace/case-11"	--assert (quote :x/b/A/x/B) = replace/case quote :a/b/A/a/B [a] 'x
	--test-- "replace/case-12"	--assert (quote (x A x))  = replace/case quote (a A a) 'a 'x

===end-group===


===start-group=== "mapparse/once"

	--test-- "mapparse/once-1"	--assert       [4 5]   =      mapparse/once [quote 8 | quote 4 | quote 3] [1 2 3 4 5] ['a]
	--test-- "mapparse/once-2"	--assert [1 2 a 4 5]   = head mapparse/once [quote 8 | quote 4 | quote 3] [1 2 3 4 5] ['a]
	--test-- "mapparse/once-3"	--assert [c d]         =      mapparse/once ['b | 'd] [a b c d] [[g h]]
	--test-- "mapparse/once-4"	--assert [a g h c d]   = head mapparse/once ['b | 'd] [a b c d] [[g h]]
	--test-- "mapparse-1"	--assert [a g h c g h] = mapparse      ['b | 'd] [a b c d] [[g h]]

===end-group===

===start-group=== "mapparse/deep"

	--test-- "mapparse/deep-1"	--assert [1 8 9 3 [4 8 9]]           = mapparse/deep [quote 5 | quote 2] [1 2 3 [4 5]] [[8 9]]
	--test-- "mapparse/deep-2"	--assert [1 3 3 [4 6]]               = mapparse/deep [set i [quote 5 | quote 2]] [1 2 3 [4 5]] [i + 1]
	--test-- "mapparse/deep-3"	--assert [i j c [i j]]               = mapparse/deep ['d 'e | 'a 'b] [a b c [d e]] [[i j]]
	--test-- "mapparse/deep-4"	--assert [a [<tag> [<tag>]]]         = mapparse/deep ['d 'b | 'b 'c] [a [b c [d b]]] [<tag>]
	--test-- "mapparse/deep-5"	--assert [x [x] x [x [x] x] x [x] x] = mapparse/deep ['x] [x [x] x] [[x [x] x]]

===end-group===

===start-group=== "mapparse in string with rule"

	--test-- "mapparse-str-rule1"	--assert "racadabra"   =      mapparse/once ["ra" | "ab"] "abracadabra" [#"!"]
	--test-- "mapparse-str-rule2"	--assert "!racadabra"  = head mapparse/once ["ra" | "ab"] "abracadabra" [#"!"]
	--test-- "mapparse-str-rule3"	--assert "!!cad!!"     =      mapparse      ["ra" | "ab"] "abracadabra" [#"!"]
	--test-- "mapparse-str-rule4"	--assert "!!cad!!"     =      mapparse      ["ra" | "ab"] "abracadabra" [["!"]]
	--test-- "mapparse-str-rule5"	--assert "AbrACAdAbrA" ==     mapparse      [s: ["a" | "c"]] "abracadabra" [uppercase s/1]

===end-group===

===start-group=== "mapparse/case"

	--test-- "mapparse/case-1"	--assert "a-babAA-"    = mapparse/case ["Ab" | "Aa"] "aAbbabAAAa" ["-"]
	--test-- "mapparse/case-2"	--assert "axbAab" = head mapparse/case/once "A" "aAbAab" [["x"]]
	--test-- "mapparse/case-3"	--assert "axbxab"      = mapparse/case      "A" "aAbAab" [["x"]]

===end-group===

===start-group=== "mapparse/case/deep"

	--test-- "mapparse/case/deep-1"	--assert [x A x B [x A x B]] = mapparse/case/deep ['a | 'b] [a A b B [a A b B]] ['x]
	--test-- "mapparse/case/deep-2"	--assert (quote (x A x B (x A x B))) = mapparse/case/deep ['a | 'b] quote (a A b B (a A b B)) ['x]

===end-group===

~~~end-file~~~
