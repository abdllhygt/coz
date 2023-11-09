Red [
	title:   "GLOB mezzanine"
	purpose: "Recursively list all files"
	author:  @hiiamboris
	version: 0.3.3
	license: 'BSD-3
]

;@@ an option not to follow symlinks, somehow?
;@@ allow time! as /limit ? like, abort if takes too long..
;@@ asynchronous/concurrent listing (esp. of different physical devices)

;; BUG: in Windows some masks have special meaning (8.3 filenames legacy)
;;      these special cases are not replicated in `glob`:
;;  "*.*" is an equivalent of "*" 
;;     use "*" instead or better leave out the /only refinement
;;  "*." historically meant any name with no extension, but now also matches filenames ending in a period
;;     use `/omit "*.?*"` instead of it
;;  "name?" matches "name1", "name2" ... but also "name"
;;     use ["name" "name?"] set instead

#include %match.red

glob: none
context [
	~only: func [value [any-type!]] [any [:value []]]

	set 'glob function [
		"Recursively list all files"
		/from "starting from a given path"
			root [file!] "CWD by default"
		/limit "recursion depth (otherwise limited by the maximum path size)"
			sublevels [integer!] "0 = root directory only"
		/only "include only files matching the mask or block of masks"
			imask [string! block!] "* and ? wildcards are supported"
		/omit "exclude files matching the mask or block of masks"
			xmask [string! block!] "* and ? wildcards are supported"
		/files "list only files, not directories"
		/dirs  "list only directories, not files"
	][
		;; ^ tip: by binding the func to a context I can use a set of helper funcs
		;; without recreating them on each `glob` invocation
		
		prefx: tail root: either from [clean-path dirize to-red-file root][copy %./]
		if string? imask [imask: reduce [imask]]
		if string? xmask [xmask: reduce [xmask]]
		
		;; lessen the number of conditions to check by defaulting sublevels to 1e9
		;; with maximum path length about 2**15 it is guaranteed to work
		unless sublevels [sublevels: 1 << 30]
		
		;; requested file exclusion conditions:
		;; tip: any [] = none, works even if no condition is provided
		excl-conds: compose [
			(~only if files [[dir? f]])						;-- it's a dir but only files are requested?
			(~only if dirs  [[not dir? f]])					;-- it's a file but only dirs are requested?
			(~only if only  [[not match-any f imask]])		;-- doesn't match the provided imask?
			(~only if omit  [[match-any f xmask]])			;-- matches the provided xmask?
		]

		r: copy []
		;@@ unsafe to use these static blocks in the face of IO errors
		subdirs: append [] %"" 		;-- dirs to list right now
		nextdirs: [] 					;-- will be filled with the next level dirs
		until [
			foreach d subdirs [		;-- list every subdir of this level
				;; path structure, in `glob/from /some/path`:
				;; /some/path/some/sub-path/files
				;; ^=root.....^=prefx
				;; `prefx` gets replaced by `d` every time, which is also relative to `root`:
				append clear prefx d
				unless error? fs: try [read root] [		;-- catch I/O (access denied?) errors, ignore silently
					foreach f fs [
						;; `f` is only the last path segment
						;; but excl-conds should be tested before attaching the prefix to it:
						if dir? f [append nextdirs f]
						unless any excl-conds [append r f]
						;; now is able to attach...
						insert f prefx
					]
				]
			]
			;; swap the 2 directory sets, also clearing the used one:
			subdirs: also nextdirs  nextdirs: clear subdirs

			any [
				0 > sublevels: sublevels - 1 		;-- exit upon reaching the limit
				0 = length? subdirs					;-- exit when nothing more to list
			]
		]
		clear subdirs		;-- cleanup
		r
	]

	;; test if file matches a mask (any of)
	match-any: function [file masks [block!]] [
		if dir? file: append clear %"" file [take/last file]	;-- shouldn't try to match against the trailing slash
		forall masks [if match/glob file masks/1 [return yes]]
		no
	]

]

