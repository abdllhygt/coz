Red [
	title: "glob func test script"
	author: @hiiamboris
]

#include %glob.red

unless value? 'input [input: none]

root: %globtest-temp-dir.$$$
if exists? root [print ["please remove the" root "from" what-dir "first"] input quit]

change-dir make-dir root

files: compose [
	%123
	%234
	%345
	%456
	%file.ext
	%file.ex2
	%file2.ex3
	%.file3
	%dir1/dir2/dir3/
	%dir1/dir4/
	%dir1/file5
	; trailing period:
	(either 'Windows = system/platform
		[ to-file rejoin ["\\?\" to-local-file what-dir %file4.] ]
		[ %file4. ]
	)
	; 100 items:
	%0/1/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/0/1/2/3/4/5/6/7/8/9/
]

foreach f files [
	either dir? f [make-dir/deep f][write f ""]
]

ntotal: nsucc: 0
=>: make op! func [code rslt /local r] [
	ntotal: ntotal + 1
	prin ["testing" pad mold/flat code 40 "... "]
	r: try code
	either error? r [
		print ["^/" mold r]
		print "FAILED^/"
	][
		either r <> rslt
			[	print ["^/  exp" mold/flat rslt]
				print ["  got" mold/flat r]
				print "FAILED^/"	]
			[	print "OK" nsucc: nsucc + 1	]
	]
]

big-tree: collect [foreach x split last files #"/" [unless empty? x [keep copy append %"" dirize x]]]

[sort glob/limit 0] => sort [%123 %234 %345 %456 %file.ext %file.ex2 %file2.ex3 %.file3 %file4. %dir1/ %0/]
[sort glob/limit 1] => sort [%123 %234 %345 %456 %file.ext %file.ex2 %file2.ex3 %.file3 %file4. %dir1/ %dir1/dir2/ %dir1/dir4/ %dir1/file5 %0/ %0/1/]
[sort glob/limit 2] => sort [%123 %234 %345 %456 %file.ext %file.ex2 %file2.ex3 %.file3 %file4. %dir1/ %dir1/dir2/ %dir1/dir2/dir3/ %dir1/dir4/ %dir1/file5 %0/ %0/1/ %0/1/2/]
[sort glob/limit 3] => sort [%123 %234 %345 %456 %file.ext %file.ex2 %file2.ex3 %.file3 %file4. %dir1/ %dir1/dir2/ %dir1/dir2/dir3/ %dir1/dir4/ %dir1/file5 %0/ %0/1/ %0/1/2/ %0/1/2/3/]
[sort glob] => sort compose [
	%123 %234 %345 %456 %file.ext %file.ex2 %file2.ex3 %.file3 %file4. %dir1/ %dir1/dir2/ %dir1/dir2/dir3/ %dir1/dir4/ %dir1/file5
	(big-tree)
]
[sort glob/only "123"] => [%123]
[sort glob/only ["123" "234" "345"]] => [%123 %234 %345]
[sort glob/only "*23*"] => [%123 %234]
[sort glob/only "*23"] => [%123]
[sort glob/only "23*"] => [%234]
[sort glob/only "*2*3*"] => sort [%123 %234 %file2.ex3]
[sort glob/only "*il*ex*"] => sort [%file.ext %file.ex2 %file2.ex3]
[sort glob/only "*il*ex?"] => sort [%file.ext %file.ex2 %file2.ex3]
[sort glob/only "**123"] => [%123]
[sort glob/only "**123**"] => [%123]
[sort glob/only "123**"] => [%123]
[sort glob/only "???"] => [%123 %234 %345 %456]
[sort glob/only "??"] => []
[sort glob/only "?*?"] => sort [%123 %234 %345 %456 %file.ext %file.ex2 %file2.ex3 %.file3 %file4. %dir1/ %dir1/dir2/ %dir1/dir2/dir3/ %dir1/dir4/ %dir1/file5]
[sort glob/only "?"] => sort big-tree
[sort glob/only "5"] => sort collect [foreach f big-tree [if #"5" = pick tail f -2 [keep f]]]
[sort glob/only ["*0" "5*"]] => sort collect [foreach f big-tree [if find "05" pick tail f -2 [keep f]]]
[sort glob/only "*."] => [%file4.]

[sort glob/only/omit "?" "?"] => []
[sort glob/only/omit "?" "5"] => sort collect [foreach f big-tree [if #"5" <> pick tail f -2 [keep f]]]
[sort glob/only/omit "?" ["*0" "5*"]] => sort collect [foreach f big-tree [unless find "05" pick tail f -2 [keep f]]]
[sort glob/omit "?"] => sort [%123 %234 %345 %456 %file.ext %file.ex2 %file2.ex3 %.file3 %file4. %dir1/ %dir1/dir2/ %dir1/dir2/dir3/ %dir1/dir4/ %dir1/file5]
[sort glob/omit "*"] => []
[sort glob/omit ["*.?*" "???" "????" "?"]] => sort [%file4. %dir1/file5]
[sort glob/only/omit "*il*ex?" "*t"] => sort [%file.ex2 %file2.ex3]

[sort glob/files] => sort [%123 %234 %345 %456 %file.ext %file.ex2 %file2.ex3 %.file3 %file4. %dir1/file5]
[sort glob/files/only "*.*"] => sort [%file.ext %file.ex2 %file2.ex3 %.file3 %file4.]
[sort glob/files/omit "*.*"] => sort [%123 %234 %345 %456 %dir1/file5]

[sort glob/from copy/part last files skip tail last files -9] => sort [%6/ %6/7/ %6/7/8/ %6/7/8/9/]
[sort glob/from copy/part last files skip tail last files -4] => sort [%8/ %8/9/]
[sort glob/from last files] => []
[sort glob/files/from %0/] => []


print ["--- total" nsucc "of" ntotal "test succeeded ---"]
change-dir %..

input 

if nsucc > 0 [
	call either 'Windows = system/platform
		[ rejoin [{rmdir /q /s "} to-local-file root {"}] ]
		[ rejoin [{rm -rf "} to-local-file root {"}] ]
]

quit