Red [
	title:   "TABLE style"
	purpose: "Renders data as a table, until such style is available out of the box"
	author:  @hiiamboris
	license: 'BSD-3
	notes: {
		This is work in progress, and mainly an experiment!
		Requires fixes from PR #4529 to work!

		DESIGN

		Goal of this implementation is not speed, it's flexibility and reuse of `face!` functionality.
		50 rows - easy, 50000 - madness.

		Should table consist of columns or rows?
		Columns give natural resize of them, natural definition in VID (e.g. giving names to columns).
		Rows give natural row height balancing and also possibility to resize rows, simpler sorting.
		I chose columns; rows are auto-sized.
		Rows are also unnamed, so table is CSV-like, fit for listing objects, blocks, etc.

		Be careful when making cells editable and mapping them to global words: `data: 'none` will change global `none`!
	}
	todo: {
		* make an update func for elastic UI -> get rid of shares
		* use spacing between rows
		* columns manual resize and dragging around (too many bugs in View to attempt this now)
		* reverse sorting
		* how to decouple sort handler (right now it's a cell event that accesses the table sorter)
	  	* user-defined actors
		* provide a block renderer that would arrange multiple values in a cell (e.g. image + text)
		* provide a block of (identical) objects renderer that uses objects words as header names
		* ability to overload 'cell' style to implement the whole table in draw?
	  	  it will be a virtual deep reactor that reflects everything on a canvas
	  	  not sure how View will handle panes with fake faces...
		* how to support multi-row/multi-column spanning faces?
		  I have no need of that though, and that will rule out panels usage as they clip content
		* short vs full formatters (e.g. for numbers)
		* should cells be sorted by their Red value or displayed (formatted) text?
		* resizeable columns once #4479 gets fixed
	}
]

; recycle/off

#include %assert.red
#include %setters.red
#include %keep-type.red
#include %map-each.red
#include %extrema.red
#include %clock.red
#include %clock-each.red
#include %do-unseen.red
#include %show-trace.red
#include %reshape.red
#include %relativity.red

; #include %"/d/devel/red/red-src/red/environment/reactivity.red"

; do-unseen: :do
by: make op! :as-pair

{
	Geometry event flow:

	canvas/size <= cell/size : depends on the renderer (text only considers width, image - both)

	cell/size/y : result of row balancing - uses height constraints given by the renderers
	cell/size/x <= column/size/x : text cells adapt to column width, image cells will try to fit

	column/extent : auto determined (during arrange) sum of all cells arranged vertically with spacing accounted for
	column/size/y <= column/extent/y : after row balancing is done
	column/size/x <= controlled by the table (mappers and shares), TBD manual resize
		column/size/x has a #fill anchor by default so will stretch when resized => cell/size/x => canvas/size/x

	table/extent : auto determined (during arrange) sum of all columns arranged horizontally with spacing accounted for
	table/size <= table/extent : after arranging columns
		add an #anchor to table declaration to control how it scales with the window => column/size/x => cell/size/x => canvas/size/x
	TIP: put table into a scrollable panel to contain it if it's big!

	sorting: triggered by column click, but makes no sense in a separate column (?)
}

{
	so suppose there's a picker func:
	'min-size
	'max-size
	'data
	'render size flags (e.g. read-only, even/odd) - returns draw commands block

	addresses?
	1 - address in the original data set (XxY for table, X otherwise)
	2 - address in the virtual data set (e.g. item number, type...)
	3 - address on a sorted layout

	1->2 needs a transform function
	2->3 needs ideally a rule that would given 2 return 3, but that's too slow so: just a table of correspondence

	how would refresh work? how does it know what to update?
	if 1->2 and 2->3 are light, it can recalculate the whole thing, but `render` is not light, neither is draw
	...need to think...
}

; system/reactivity/debug?: 'full
; system/view/debug?: yes
table: context [
	~table: self

	profile?: yes
	debug?:   no
	~colors: system/view/metrics/colors

	clock-each: either profile? [:system/words/clock-each][:do]
	clock:      either profile? [:system/words/clock]     [:do]
	report:     either debug? [:print] [:comment]

	use-font: func [font] [either object? :font [copy font][:font]]

	;; `compose` readability helper
	when: make op! func [value test] [either :test [:value][[]]]

	~cell: cell: context [
		default-image-height: 40

		zoom-factor?: function [
			"Determine the maximum zoom factor that allows to fit SRC-SIZE within DST-SIZE"
			src-size [pair!] dst-size [pair!]
		][
			min 1.0 * dst-size/x / max 1 src-size/x			;-- use the narrowest dimension
				1.0 * dst-size/y / max 1 src-size/y
		]

		get-formatter: function [cell [object!]] [
			any [
				select cell/formatters type?/word cell/value
				:cell/formatters/default
			]
		]

		get-renderer: function [cell [object!]] [
			any [
				select cell/renderers type?/word cell/value
				:cell/renderers/default
			]
		]

		format-value: function [cell [object!] canvas [object!] value [any-type!]] [
			fmt: get-formatter cell
			fmt cell canvas :value
		]

		render-value: function [cell [object!] canvas [object!] value [any-type!]] [
			rdr: get-renderer cell
			rdr cell canvas :value
		]

		heights?: function [cell [object!]] [
			rdr: get-renderer cell
			rdr/size cell cell cell/value				;-- canvas is not used, so just passing cell twice
		]

		default-renderer: func [cell [object!] canvas [object!] value [any-type!] /size] [
			if size [return 25x25]
			maybe canvas/image: none
			maybe canvas/text:  format-value cell canvas :value
			maybe canvas/size:  cell/size ;cell/size/x by 25
		]
		
		image-renderer: func [cell [object!] canvas [object!] image [image!] /size] [
			if size [return 40 by image/size/y]
			maybe canvas/text:  form image/size
			maybe canvas/image: image
			maybe canvas/size:  image/size * zoom-factor? image/size max 40x40 cell/size
		]
		

		default-formatter: function [cell [object!] canvas [object!] value [any-type!]] [
			mold/flat/part :value to integer! cell/size/x / 4		;-- 4 pixels per char limit
		]
		
		string-formatter: function [cell [object!] canvas [object!] string [string!]] [
			either 'base = canvas/type [
				copy/part string to integer! cell/size/x / 4		;-- 4 pixels per char limit
			][	string												;-- expose string directly into field
			]
		]
		
		number-formatter: function [cell [object!] canvas [object!] number [number!]] [
			mold number
		]
		
		spec-formatter: function [cell [object!] canvas [object!] fun [any-function!]] [
			mold/flat keep-type spec-of :fun any-word!
		]

		keys-formatter: function [cell [object!] canvas [object!] obj [any-object! map!]] [
			mold/flat/part words-of obj to integer! cell/size/x / 4		;-- 4 pixels per char limit
		]

		renderers: make map! reduce [
			'default   :default-renderer
			'image!    :image-renderer
		]

		formatters: make map! reduce [
			'default   :default-formatter
			'string!   :string-formatter
			'integer!  :number-formatter
			'float!    :number-formatter
			'percent!  :number-formatter
			'function! :spec-formatter
			'native!   :spec-formatter
			'action!   :spec-formatter
			'op!       :spec-formatter
			'object!   :keys-formatter
			'error!    :keys-formatter
			'port!     :keys-formatter
			'map!      :keys-formatter
		]

		editable!: make typeset! [string! number!]
		
		default-canvas-provider: function [cell [object!]] [
			value: get-value :cell/data
			read-only?: to logic! any [
				cell/read-only?
				not find editable! type? :value
			]
			
			type: pick [base field] read-only?
			either any [
				empty? cell/pane
				cell/pane/1/type <> type
			][
				canvas: make face! compose/deep [
					(system/view/VID/styles/:type/template)
					offset: 0x0
					color: (any [cell/color ~colors/panel white])
					size:  (cell/size)
					font:  (use-font cell/font)
					para:  (any [cell/para  make para! [align: 'left]])
				]
				if type = 'field [
					canvas/actors: make object! [
						on-change: func [fa ev] [push-value fa/parent fa/text]
					]
				]
				cell/pane: reduce [canvas]
			][
				canvas: cell/pane/1
			]

			render-value cell canvas :value
			canvas
		]

		renew-canvas: func [cell [object!]] [
			cell/canvas-provider cell
		]

		;; force redraw of cell content when the data changed
		;;  e.g. if we bind to a word and it's value changes, or we map to a block and it's first value changes
		;;  otherwise we have no way to know
		;;  maybe in addition to it, some tracking mechanism can be invented?
		update: func [cell [object!]] [
			cell/data: cell/data
		]

		;@@ BUG: when changing cell size it's required to call renew-canvas manually or call `update` (see REP #77)
		change-hook: function [cell word old [any-type!] new [any-type!]] [
			; print ["change-hook" word :old :new]
			unless action: select/skip [				;-- these are ordered in predicted update frequency order
				size [] data [] read-only? []			;-- these warrant a canvas check & re-render  @@ TODO: don't react to size/y - how?
				text  [set-to cell :new  exit]			;-- exit because it will re-enter with `data` facet changed
				color [maybe canvas/color: :new]
				font  [maybe canvas/font:  use-font :new]
				;@@ any other facets to transfer?
				; font [print ["change-hook" word :old :new]]
			] word 2 [exit]
			canvas: renew-canvas cell
			do action
		]
		
		deep-change-hook: function [cell word target action new [any-type!] index part] [
			; print ["deep-change-hook" word target :new :action :index :part]
			change-hook cell word none :new
		]

		;@@ TODO: also an evaluating version??
		get-value: func [data [any-type!]] [
			switch/default type?/word :data [
				block! paren! [:data/1]
				word! path! get-word! [get/any data]
				get-path! [get/any as path! data]				;@@ workaround for #4448
			][	:data
			]
		]

		push-value: func [cell [object!] value [any-type!] /local data] [
			set/any 'data cell/data
			switch type?/word :data [
				block! [change/only data to :data/1 :value]
				word! path! get-word! get-path! [
					if get-path? data [data: as path! data]		;@@ workaround for #4448
					attempt [set data to get/any data :value]	;-- attempt for validation
				]
			]
		]

		bind-to: func [cell [object!] target [word! path! get-word! get-path!]] [
			unless :cell/data =? target [cell/data: target]
		]

		map-to: func [cell [object!] target [block!]] [
			unless :cell/data =? target [cell/data: target]
		]

		;; has to guarantee that the value, when changed, will not have repercussions outside
		;; that's why it's using parens - to distinguish from blocks used by map-to
		set-to: func [cell [object!] value [any-type!]] [
			;; this check is hard, as what if value is a huge block?
			;; and same huge block is already in cell/data?
			;; need to tread with care...
			;; still it's worth doing to avoid triggering reactivity
			;@@ TODO: maybe use non-block values as is, without `reduce`?
			unless all [
				yes = try [:value =? :cell/data/1]
				paren? :cell/data
			] [cell/data: as paren! reduce [:value]]
		]

		;; optimization - this is even faster than inlining the whole thing into template (why? makes template shorter?)
		on-change-template: compose [
			change-hook self word :old :new
			(body-of :face!/on-change*)
		]

		extend system/view/VID/styles compose/deep [
			cell: [
				default-actor: on-down					;-- e.g. for actions, highlighting
				template: [
					type:  'panel
					size:  100x25
					color: (any [~colors/panel white])

					value:            does [get-value :data]		;-- needed for sort
					read-only?:       yes
					canvas-provider: :default-canvas-provider
					renderers:       :cell/renderers
					formatters:      :cell/formatters

					;; reactivity is unbelievably slow (at least for now), so have to use hooks:
					on-change*:      function spec-of :face!/on-change* [(on-change-template)]
					                          ; bind/copy on-change-template self		;@@ faster but BUGGY: see #4500
					on-deep-change*: function spec-of :face!/on-deep-change* [
						deep-change-hook     owner word target action :new index part
						on-face-deep-change* owner word target action :new index part state no
					]
				]
			]
		]
	];; ~cell: cell: context [


	~column: column: context [
		;; used to preallocate a bulk of cells for mapping them later
		;; length = 0 includes header, length = 1 is header + cell, etc.
		set-length: func [column [object!] len [integer!]] [
			set-pane-size column 1 + len 'cell					;-- `1` for the header
		]

		rename: function [column [object!] title [any-type!]] [
			unless empty? column/pane [~cell/set-to column/header :title]
		]

		;@@ TODO: update it in one go, else too many events
		assign: function [method [word!] column [object!] data [block!]] [
		do-atomic [;do-unseen [						;@@ do-unseen bugs View and crashes here!
			; set-length column len: length? data	;-- done by the table! otherwise block map + /skip won't work
			len: length? data
			pane: next column/pane
			action: select/skip [
				set  [~cell/set-to  pane/:i :data/:i]
				bind [~cell/bind-to pane/:i :data/:i]
				map  [~cell/map-to  pane/:i at data i]
			] method 2
			repeat i len [if pane/:i [do action]]
			arrange column
		];]
		]

		;; creates a 2-way binding between words and column
		bind-to: function [column [object!] words [block!]] [
			assign 'bind column words
		]

		;; creates a 2-way binding between data block and column
		map-to: function [column [object!] data [block!]] [
			assign 'map column data
		]

		;; fills column with values from the data block
		set-to: function [column [object!] data [block!]] [
			assign 'set column data
		]

		;; call it after changing the mapped-to/bound-to data, to force redraw
		update: function [column [object!]] [
			do-atomic [foreach cell column/pane [~cell/update cell]]
		]

		arrange: function [column [object!]] [
			report "ARRANGING CELLS"
			; do-unseen [								;@@ THIS DOESN'T WORK (even when do-unseen = do) - SEE #4549
				pos: 0x2									;-- 2px upper margin
				pane: column/pane
				foreach cell pane [
					maybe cell/offset: pos * 0x1
					;; cell sets it's width automatically from column width (or doesn't, depends on renderer)
					maybe cell/size/x: column/size/x
					pos/x: max pos/x cell/size/x
					pos/y: pos/y + cell/size/y + 1			;-- 1 for spacing
				]
				maybe column/extent: pos
				; maybe column/size/y: pos/y					;-- auto adjust height only -- done by the table!
			; ]
		]

		on-header-down: function [fa ev] [
			if all [
				column: fa/parent
				table: column/parent
				function? sort: select table 'sort-by
			][
				sort column
				show table
			]
		]

		extend system/view/VID/styles reshape [
			;@@ TODO: add resizing of columns into the table
			column: [
				template: [
					type:   'panel
					pane:   []
					; color:  !(any [~colors/panel black])
					color:  !(any [~colors/text black])
					size:   100x400
					text:   "Header"
					anchors: [scale ignore]

					extent: 0x0
					header: make-face/spec 'cell compose [
						bold with [read-only?: yes]									;-- bold font for the header and always readonly
						(color * 0.3 + !(0.7 * any [~colors/panel white]))			;-- give it's background a slight tint of the text color
						on-down :on-header-down
					]
					insert pane header												;-- insert preserves user-defined (in VID) pane
					
					react [rename self self/text]									;-- text facet controls the header title
					react [if block? data [set-to self self/data]]		;@@ TODO: use on-deep-change? otherwise a single deep change triggers full column reset
					react/later [[self/pane self/size/x] arrange self]
					; arrange self
				]
			]
		]
	];; ~column: column: context [

	set-pane-size: function [face [object!] size [integer!] child-style [word!]] [
		more: size - length? pane: face/pane
		case [
			more < 0 [clear skip pane size]
			more > 0 [loop more [append pane make-face child-style]]
		]
	]

	set-width: func [table [object!] width [integer!]] [
		set-pane-size table width 'column
		update-read-only table				;-- force new items to obey table r/o state
		;@@ TODO: should columns have control over read-only too?
	]

	resize: function [table [object!] size [pair!]] [
		; clock [		;@@ BUG: make-face allocates a lot of stuff, GC slows it all down by ~25%
		; recycle/off
		do-unseen [clock-each [
			set-width table size/x
			foreach column table/pane [~column/set-length column size/y]
		; attempt [show table]
		]]
		; recycle/on
		; recycle
		; ]
	]

	;; to be called on column resize only
	arrange: function [table [object!]] [
		report "SETTING UP COLUMNS & RESIZING TABLE"
		do-unseen [clock [
			pos: 1x0 * table/spacing
			if table/balance-rows? [balance-rows table]	;-- adjust cell heights
			foreach column table/pane [
				~column/arrange column					;-- recalculate column's extent (height only)
				maybe column/offset: pos * 1x0
				maybe column/size: column/extent
				report ["COLUMN" index? find/same table/pane column "AT" column/offset]
				pos/x: pos/x + column/size/x + table/spacing/x
				pos/y: max pos/y column/size/y
			]
			maybe table/extent: pos
			report ["NEW SIZE" pos]
			maybe table/size: pos
			; attempt [show table]
		]]
	]

	;@@ TODO: probably inefficient to do by-column updates; make a by-row algorithm
	update: function [
		"Update table contents with the data it maps to"
		table [object!]
	][
		report "TABLE UPDATE"
		foreach column table/pane [~column/update column]
	]

	get-row: function [table [object!] row [integer!] into [block!]] [
		clear into
		foreach column table/pane [append into any [column/pane/:row []]]
		into
	]

	balance-rows: function [table [object!]] [
	do-unseen [clock [
		report ["BALANCING ROWS"]
		columns: table/pane
		rows: maximum-of map-each c columns [length? c/pane]
		repeat y rows [
			height: 0
			row: get-row table y []
			foreach cell row [							;-- collect sizes first
				constraints: ~cell/heights? cell
				height: max height constraints/1
			]
			foreach cell row [							;-- resize now
				report ["RESIZING CELL AT ROW" y "TO" height]
				; cell/size: cell/size/x by height
				maybe cell/size/y: height
				; ?? cell/size
			]
		]
	]]
	]

	set-shares: function [
		table [object!]
		shares [block!]
		/local s i column
	][
		ncol: length? table/pane
		used: 1.0 * (w: table/size/x) - (ncol + 1 * table/spacing/x) / w		;-- x space occupied by columns, [0..1]
		total: sum shares
		shares: map-each s shares [s / total * used]
		; shares: table/shares: map-each s shares [s / total * used]
		for-each [/i column] table/pane [
			maybe column/size: (w * shares/:i) by table/size/y
		]
	]

	set-headers: function [table [object!] headers [block!] /local i title] [
		for-each [/i title] headers [table/pane/:i/text: title]
	]

	map-object-to-table: function [
		"Prepare TABLE layout and create a mapping between TABLE and OBJ"
		table [object!] obj [object!]
		/index "Add index column"
		/types "Add type column"
		/names "Override column headers"
			headers [block!]
		/local i w
	][
		report ["MAPPING to" mold/part obj 100]
		clock-each [do-unseen [
			ncol: pick pick [[4 3] [3 2]] index = on types = on			;-- how many columns will we have
			clear columns: table/pane									;-- destroy old columns so Elastic remembers new geometry
			resize table ncol by len: length? words: words-of obj
			show table
			
			;; resize columns before changing cells data! (cells will adapt to columns)
			set-shares table compose [(10% when index) 20% (20% when types) 50%]

			;; fill with data
			set-headers table any [headers  compose [("#" when index) "Field" ("Type" when types) "Value"]]
			if index [
				~column/map-to columns/1 map-each i len [i]
				columns: next columns
			]
			~column/map-to columns/1 words
			if types [~column/map-to columns/2 map-each w words [type?/word get/any w]]
			~column/bind-to last columns words
			; arrange table
		]]
	]

	map-block-to-table: function [
		"Prepare TABLE layout and create a mapping between TABLE and BLOCK"
		table [object!] block [block!]
		/skip  "Put more than one item per row"
			period [integer!] "Block period (default: 1)"
		/index "Add index column(s)"
		/types "Add type column(s)"
		/names "Override column headers"
			headers [block!]
		/local i v title share i-col t-col v-col
	][
		period: any [period 1]
		#assert [period >= 1]
		report ["MAPPING to" mold/part block 100]
		clock-each [
			group: pick pick [[3 2] [2 1]] index = on types = on		;-- how many columns will we have per skip
			ncol: group * period										;-- total columns
			len: length? block
			height: round/to/ceiling len / period 1
			clear columns: table/pane									;-- destroy old columns so Elastic remembers new geometry
			resize table ncol by height

			shares: compose [(15% when index) (30% when types) 55%]
			set-shares  table append/dup clear [] shares period

			headers: any [headers  compose [("#" when index) ("Type" when types) "Value"]]
			set-headers table append/dup clear [] headers period

			spec: compose [/i ('i-col when index) ('t-col when types) v-col]
			if index [indexes: map-each i len [i]]
			if types [types:   map-each v block [type?/word :v]]
			for-each (spec) columns [
				offset: (to integer! i - 1 / group) * height + 1
				if index [~column/map-to i-col at indexes offset]
				if types [~column/map-to t-col at types   offset]
				~column/map-to v-col at block offset
			]
			; autosize table
		]
	]

	default-mapper: function [table [object!] data [default!]] [
		switch type?/word :data [
			block!  [map-block-to-table/index/types  table data]
			object! [map-object-to-table/index/types table data]
			;@@ can more types be mapped?
		]
	]

	mappers: make map! reduce [
		'default   :default-mapper
		'block!    :default-mapper
		'object!   :default-mapper
	]

	map-to: function [table [object!] data [default!]] [
		if mapper: any [
			select table/mappers type?/word :data
			:table/mappers/default
		][
			mapper table data
			; balance-rows table
		]
	]

	image-cmp: func [a b] [				;@@ workaround for #4502
		any [
			a/size < b/size
			all [
				a/size == b/size
				a/argb <= b/argb
			]
		]
	]

	;@@ TODO: reverse sorting
	sort-by: function [table [object!] column [object! integer!] /local i c v1 v2] [
		report "SORTING TABLE"
		columns: table/pane
		either integer? icol: column [
			column: columns/:column
		][	icol: index? find/same columns column
		]
		cells: next column/pane							;-- `next` to exclude the header
		indexes: map-each i length? cells [i]
		values: map-each c cells [c/value]

		buf: [- -]
		;@@ BUG: THIS CRASHES; use it when #4489 gets fixed
		; sort/stable/compare indexes func [a b] [
		; 	buf1/1: :values/:a  buf2/1: :values/:b		;-- we're sorting generic unknown data, so `<` doesn't work here
		; 	buf1 <= buf2
		; ]
		; clear buf1

		;@@ temporary bubble sort workaround
		len: -1 + length? cells
		until [
			sorted?: yes
			s: next indexes
			forall s [
				change/only change/only buf	
					set/any 'v1 pick values s/-1
					set/any 'v2 pick values s/1
				either all [image? :v1 image? :v2] [
					;@@ workaround for #4502
					sort/compare buf :image-cmp
				][
					sort buf							;-- we're sorting generic unknown data, so `<` doesn't work here
				]
				unless :buf/1 =? :v1 [
					sorted?: no
					swap back s s
				]
			]
			sorted?
		]

		;; rearrange all columns
		do-unseen [do-atomic [
			foreach col columns [
				cells: head clear next copy col/pane

				; foreach i indexes [append cells pick col/pane i + 1]
				append cells map-each i indexes [pick col/pane i + 1]
				; change col/pane cells		;@@ too slow - recreates every OS window
				for-each [/i cell] cells [		;@@ BUG: this is O(n^2), doesn't scale
					pos: find/same col/pane cell
					move pos at col/pane i
				]
				~column/arrange col
				; clock [show col]
			]
			; clock [attempt [show table]]
		]]
	]

	update-read-only: function [table [object!]] [
	do-atomic [do-unseen [clock-each [
		foreach column table/pane [
			foreach cell next column/pane [				;-- `next` to skip the header!
				cell/read-only?: table/read-only?
			]
		]
		; attempt [show table]
	]]]
	]

	; table?: function [face [object!]] [
	; 	all [select face 'mappers  select face 'shares  panel = select face 'type]
	; ]

	extend system/view/VID/styles [
		table: [
			default-actor: on-down		;???
			template: [
				type:   'panel
				size:   400x400
				color:  ~colors/text
				pane:   []
				actors: [								;@@ TODO: allows user-defined actors & combine these with those
					on-created: func [fa] [
						context [
							table: fa
							react [map-to table table/data]		;@@ TODO: block of blocks too ;@@ also see #4471
							react [[table/pane] arrange table]
							; react [[table/size] arrange table]
							react [[table/read-only?] update-read-only table]
						]
					]
				]

				read-only?:    no
				balance-rows?: yes		;-- indicates that table handles cell resize, not columns
				extent:  0x0			;-- auto inferred size of the content, for the user to hook to
				spacing: 5x10		;-- inter-column band width x inter-row band height  ;@@ TODO: inter-row band is unused yet
				;@@ this is required in absense of floating point pairs, as otherwise each minor resize would distort column widths:
				; shares: []				;-- percentage of width occupied by each column, set by arrange

				mappers: ~table/mappers
				sort-by: func [column [object! integer!]] [table/sort-by self column]

				; insert-column ?
				; remove-column ?
				; insert-row ?
				; remove-row ?
			]
		]
	]

	;; TAB navigation support
	focusables: [field area button toggle check radio slider text-list drop-list drop-down]		;@@ calendar? tab-panel?
	tab-handler: function [fa ev] [
		unless all [
			ev/type = 'key-down
			ev/key = #"^-"
			attempt [fa =? fa/parent/selected]
		] [return none]

		look-forward: [
			case [
				fa =? face [found: yes]
				logic? found [found: face  break]		;@@ break doesn't work (see REP #78)
			]
		]
		look-back: [
			if fa =? face [found: last-face  break]		;@@ break doesn't work (see REP #78)
			last-face: face
		]
		foreach-face/with window-of fa 
			either ev/shift? [look-back][look-forward]
			[	;; filter:
				all [
					find focusables face/type
					face/enabled?
					face/visible?
				]
			]

		if object? found [set-focus found]
		'done
	]

	unless find/same system/view/handlers :tab-handler [
		insert-event-func :tab-handler
	]
];; table: context [


