Red [
	title:   "Smarter LOAD experiment"
	purpose: "Report possible bracket mismatches in loaded data"
	author:  @hiiamboris
	license: 'BSD-3
]

#include %bmatch.red
; #include https://gitlab.com/hiiamboris/red-mezz-warehouse/-/raw/master/bmatch.red

context [
	smart-load: func [{Returns a value or block of values by reading and evaluating a source} 
		source [file! url! string! binary!] 
		/header "TBD" 
		/all {Load all values, returns a block. TBD: Don't evaluate Red header} 
		/trap {Load all values, returns [[values] position error]} 
		/next {Load the next value only, updates source series word} 
		position [word!] "Word updated with new series position" 
		/part "Limit to a length or position" 
		length [integer! string!] 
		/into {Put results in out block, instead of creating a new block} 
		out [block!] "Target block for results" 
		/as {Specify the type of data; use NONE to load as code} 
		type [word! none!] "E.g. bmp, gif, jpeg, png" 
		/local codec suffix name mime pre-load
	][
		if as [
			if word? type [
				either codec: select system/codecs type [
					if url? source [source: read/binary source] 
					return do [codec/decode source]
				] [
					cause-error 'script 'invalid-refine-arg [/as type]
				]
			]
		] 
		if part [
			case [
				zero? length [return make block! 1] 
				string? length [
					if (index? length) = index? source [
						return make block! 1
					]
				]
			]
		]
		unless out [out: make block! 10] 
		switch type?/word origin: source [
			file! [
				suffix: suffix? source 
				foreach [name codec] system/codecs [
					if find codec/suffixes suffix [
						return do [codec/decode source]
					]
				] 
				source: read/binary source
			] 
			url! [
				source: read/info/binary source
				either source/1 = 200 [
					foreach [name codec] system/codecs [
						foreach mime codec/mime-type [
							if find source/2/Content-Type mold mime [
								return do [codec/decode source/3]
							]
						]
					]
				] [return none] 
				source: source/3
			]
		] 
		if pre-load: :system/lexer/pre-load [do [pre-load source length]] 
		out: case [
			part [smart-xcode/part origin source length] 
			next [
				set position second out: transcode/next source 
				return either :all [reduce [out/1]] [out/1]
			] 
			'else [smart-xcode origin source]
		] 
		either trap [out] [
			unless :all [if 1 = length? out [out: out/1]] 
			out
		]
	]

	smart-xcode: function [origin source /part length] [
		e: try [r: either part [transcode/part source length][transcode source]]
		if error? e [
			if all [
				any [									;-- sources worth analyzing
					file? origin
					url? origin
					1000 < length? origin				;-- long strings are likely a result of `read`
				]
				any [
					all [								;-- curly brace errors
						e/code = 200
						e/type = 'syntax
						e/id = 'invalid
						e/arg2 = string!
						find e/arg3 #"{"				;-- not a "single-line" string
					]
					all [								;-- paren/block errors
						e/code = 201
						e/type = 'syntax
						e/id = 'missing
						find "])" e/arg2
					]
				]
			][											;-- inject analysis report into the message
				if origin =? source [origin: "string"]
				bmatch/origin/into source origin report: clear ""
				unless empty? report [insert insert e/arg1 "^/" report]
			]
			do e
		]
		:r
	]

	unless (spec-of :smart-load) = spec-of :load [print "WARNING! LOAD must have changed!"]

	set 'load :smart-load
]

