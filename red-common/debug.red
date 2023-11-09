Red [
	title:   "#debug macros"
	author:  @hiiamboris
	license: 'BSD-3
	usage: {
		#debug off          - ignore all debug statements
		#debug on           - include unnamed debug statements only
		#debug set id       - include unnamed debug statements and those named 'id' (word!)
		#debug [my code]    - `my code` is included when debug is not off
		#debug id [my code] - `my code` is included when debug is set to `id`

		EXAMPLE:
			#debug set my-module
			#debug my-module [...]		;) will be included
			#debug other-module [...]	;) will NOT be included
			#debug [...]				;) will be included
	}
]

#macro [#debug 'on       ] func [s e] [*debug?*: on  []]
#macro [#debug 'off      ] func [s e] [*debug?*: off []]
#macro [#debug 'set word!] func [s e] [
	either block? get/any '*debug?* [
		append *debug?* s/3
	][
		*debug?*: reduce [s/3]
	]
	[]
]
; #macro [#debug not ['on | 'off | 'set] opt word! block!] func [[manual] s e /local code] [	;-- not R2-compatible!
#macro [#debug [['on | 'off | 'set] (c: [end skip]) | (c: [])] c opt word! block!] func [[manual] s e /local code] [
	; if either block? s/2 [:*debug?* <> off][attempt [find *debug?* s/2]] [	;-- not R2-compatible
	if either block? s/2 [all [value? '*debug?*  off <> get/any '*debug?*]][attempt [find *debug?* s/2]] [
		code: e/-1
	]
	remove/part s e
	if code [insert s code]
	s
]

; #debug on		;@@ this prevents setting it to a word value because of double-inclusion #4422
#do [unless value? '*debug?* [*debug?*: on]]			;-- only enable it for the first time
