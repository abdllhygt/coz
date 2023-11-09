Red [
	title:   "DETAB & ENTAB mezzanines"
	purpose: "Tabs to spaces conversion and back"
	author:  @hiiamboris
	license: 'BSD-3
	notes:   {Supports multi-line text}
]

; #include %clock.red
; #include %assert.red


detab: entab: none
context [
	spaces: insert/dup "" #"^(20)" 32					;-- 32 spaces max are supported per tab
	set 'detab function [
		"Expand tabs in string STR"
		str       [string! binary!]
		/into buf [string! binary!]  "Speficy an out buffer (allocated otherwise)"
		/size tab [integer!]         "Specify Tab size (default: 8)"
	][
		buf: any [buf  make str length? str]
		tab: any [tab 8]
		#assert [
			tab > 0
			tail? spaces
		]
		ok: parse/case s1: str [
			collect into buf [
				any [
					keep any [#"^/" s1: | not #"^-" skip]
					any [
						s2: #"^-" 
						keep (skip spaces (offset? s1 s2) % tab - tab)
						s1:
					]
				]
			]
		]
		#assert [ok]
		buf
	]

	nonspace: charset [not #"^(20)"]
	set 'entab function [
		"Convert leading spaces in STR into tabs"
		str       [string! binary!]
		/into buf [string! binary!]  "Speficy an out buffer (allocated otherwise)"
		/size tab [integer!]         "Specify Tab size (default: 8)"
	][
		buf: any [buf  make str length? str]
		tab: any [tab 8]  tab-1: tab - 1
		#assert [
			tab > 0
			tail? spaces
		]
		ok: parse/case str [
			collect into buf [
				any [
					s1: #" " [
						s2: tab-1 [#" " s2:] keep (#"^-")
					|	:s1 keep :s2
					]
				|	keep #"^-"
				|	keep thru [#"^/" | end]
				]
			]
		]
		#assert [ok]
		buf
	]
]

comment [
	; slower versions:

	detab2: func [s [string!] /into buf [string!] /size tab /local s1 s2] [
		spaces: tail "                                "	;-- 32 spaces
		append buf: any [buf  copy ""] s
		parse/case buf [any [
			p: change #"^-" (
				i: index? p
				skip spaces -1 + i - round/to/ceiling i tab
			)
		|	skip
		]]
		buf
	]

	detab1: func [s [string!] /into buf [string!] /size tab /local s1 s2] [
		spaces: tail "                                "	;-- 32 spaces
		buf: any [buf  copy ""]
		parse/case s [
			any [
				s1: to #"^-" s2: skip
				(append/part buf s1 s2
				 append/dup buf #"^(20)" (tab - ((length? buf) % tab)) )
			]
			(append buf s1)
		]
		buf
	]


	detab3: func [s [string!] /into buf [string!] /size tab /local s2] [
		buf: any [buf  copy ""]
		while [not tail? s] [
			either s2: find/case s #"^-" [
				append/part buf s s2
				append/dup buf #"^(20)" (tab - ((length? buf) % tab))
			][ append buf s  break ]
			s: next s2
		]
		buf
	]
]

; tests
; s: "^-1 2 3  4^-1^-2 3 4 5^-|abcdefgh^-abcdefgh"

; buf: ""
; recycle/off
; probe "|-------|-------|-------|-------|-------|-------|-------|-------|"
; probe detab s
; probe entab detab s
; ; probe detab1 s clear buf
; ; probe detab2 s clear buf
	
; clock/times [detab/into  s clear buf] 10000
; s: detab s
; clock/times [entab/into  s clear buf] 10000

; clock/times [entab1/into s clear buf] 10000
; clock/times [entab2/into s clear buf] 10000
; clock/times [entab3/into s clear buf] 10000

#assert [
	""                 = detab ""           
	"        "         = detab "^-"         
	"                " = detab "^-^-"       
	"1               " = detab "1^-^-"      
	"1       1       " = detab "1^-1^-"     
	"        1       " = detab "^-1^-"      
	"1234567         " = detab "1234567^-^-"
	"12345678        " = detab "12345678^-" 
	"123456789       " = detab "123456789^-"
	"123456789012345 " = detab "123456789012345^-"
	"        1234567 " = detab "^-1234567^-"
	"1   ^/    2   ^/    ^/" = detab/size "1^-^/^-2^-^/^-^/" 4

	""                 = entab ""                
	"1"                = entab "1"               
	"^-"               = entab "        "        
	"^-^-"             = entab "                "
	"       1"         = entab "       1"        
	"       1        " = entab "       1        "
	"^-1       "       = entab "        1       "
	"1               " = entab "1               "
	"^-       1"       = entab "               1"
	"^-      12"       = entab "              12"
	"^- 1234567"       = entab "         1234567"
	"^-12345678"       = entab "        12345678"
	"       123456789" = entab "       123456789"
	"1234567890123456" = entab "1234567890123456"
	"^-^-  1^/^-2"     = entab/size "^-      1^/    2" 4			;-- allows mixing tabs and spaces; resets at newlines


	""                 = to "" detab to #{} ""           
	"        "         = to "" detab to #{} "^-"         
	"                " = to "" detab to #{} "^-^-"       
	"1               " = to "" detab to #{} "1^-^-"      
	"1       1       " = to "" detab to #{} "1^-1^-"     
	"        1       " = to "" detab to #{} "^-1^-"      
	"1234567         " = to "" detab to #{} "1234567^-^-"
	"12345678        " = to "" detab to #{} "12345678^-" 
	"123456789       " = to "" detab to #{} "123456789^-"
	"123456789012345 " = to "" detab to #{} "123456789012345^-"
	"        1234567 " = to "" detab to #{} "^-1234567^-"
	"1   ^/    2   ^/    ^/" = to "" detab/size to #{} "1^-^/^-2^-^/^-^/" 4

	""                 = to "" entab to #{} ""                
	"1"                = to "" entab to #{} "1"               
	"^-"               = to "" entab to #{} "        "        
	"^-^-"             = to "" entab to #{} "                "
	"       1"         = to "" entab to #{} "       1"        
	"       1        " = to "" entab to #{} "       1        "
	"^-1       "       = to "" entab to #{} "        1       "
	"1               " = to "" entab to #{} "1               "
	"^-       1"       = to "" entab to #{} "               1"
	"^-      12"       = to "" entab to #{} "              12"
	"^- 1234567"       = to "" entab to #{} "         1234567"
	"^-12345678"       = to "" entab to #{} "        12345678"
	"       123456789" = to "" entab to #{} "       123456789"
	"1234567890123456" = to "" entab to #{} "1234567890123456"
	"^-^-  1^/^-2"     = to "" entab/size to #{} "^-      1^/    2" 4			;-- allows mixing tabs and spaces; resets at newlines
]