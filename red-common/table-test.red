Red [
	title:   "TABLE style test"
	purpose: "Play with the table style, evaluate, look for bugs"
	author:  @hiiamboris
	license: 'BSD-3
]


#include %include-once.red
#include %table.red
#include %../red-view-test/elasticity.red
; do https://gitlab.com/hiiamboris/red-elastic-ui/-/raw/master/elasticity.red
#include %scrollpanel.red

test-object: object [		;@@ reactor doesn't work - ownership limitation
	a: b: c: d: e: f: g: h: i: j: k: l: m: none
	a1: b1: c1: d1: e1: f1: g1: h1: i1: j1: k1: l1: m1: none
	a2: b2: c2: d2: e2: f2: g2: h2: i2: j2: k2: l2: m2: none
	a3: b3: c3: d3: e3: f3: g3: h3: i3: j3: k3: l3: m3: none
	a4: b4: c4: d4: e4: f4: g4: h4: i4: j4: k4: l4: m4: none
	a5: b5: c5: d5: e5: f5: g5: h5: i5: j5: k5: l5: m5: none
	a6: b6: c6: d6: e6: f6: g6: h6: i6: j6: k6: l6: m6: none
	a7: b7: c7: d7: e7: f7: g7: h7: i7: j7: k7: l7: m7: none
	a8: b8: c8: d8: e8: f8: g8: h8: i8: j8: k8: l8: m8: none
	a9: b9: c9: d9: e9: f9: g9: h9: i9: j9: k9: l9: m9: none
	a0: b0: c0: d0: e0: f0: g0: h0: i0: j0: k0: l0: m0: none
	
	; a11: b11: c11: d11: e11: f11: g11: h11: i11: j11: k11: l11: m11: none
	; a12: b12: c12: d12: e12: f12: g12: h12: i12: j12: k12: l12: m12: none
	; a13: b13: c13: d13: e13: f13: g13: h13: i13: j13: k13: l13: m13: none
	; a14: b14: c14: d14: e14: f14: g14: h14: i14: j14: k14: l14: m14: none
	; a15: b15: c15: d15: e15: f15: g15: h15: i15: j15: k15: l15: m15: none
	; a16: b16: c16: d16: e16: f16: g16: h16: i16: j16: k16: l16: m16: none
	; a17: b17: c17: d17: e17: f17: g17: h17: i17: j17: k17: l17: m17: none
	; a18: b18: c18: d18: e18: f18: g18: h18: i18: j18: k18: l18: m18: none
	; a19: b19: c19: d19: e19: f19: g19: h19: i19: j19: k19: l19: m19: none
	; a10: b10: c10: d10: e10: f10: g10: h10: i10: j10: k10: l10: m10: none

	; a21: b21: c21: d21: e21: f21: g21: h21: i21: j21: k21: l21: m21: none
	; a22: b22: c22: d22: e22: f22: g22: h22: i22: j22: k22: l22: m22: none
	; a23: b23: c23: d23: e23: f23: g23: h23: i23: j23: k23: l23: m23: none
	; a24: b24: c24: d24: e24: f24: g24: h24: i24: j24: k24: l24: m24: none
	; a25: b25: c25: d25: e25: f25: g25: h25: i25: j25: k25: l25: m25: none
	; a26: b26: c26: d26: e26: f26: g26: h26: i26: j26: k26: l26: m26: none
	; a27: b27: c27: d27: e27: f27: g27: h27: i27: j27: k27: l27: m27: none
	; a28: b28: c28: d28: e28: f28: g28: h28: i28: j28: k28: l28: m28: none
	; a29: b29: c29: d29: e29: f29: g29: h29: i29: j29: k29: l29: m29: none
	; a20: b20: c20: d20: e20: f20: g20: h20: i20: j20: k20: l20: m20: none

	on-change*: func [word old new] [
		poke types index? find words-of self word type?/word :new
	]
]
types: append/dup [] none length? words-of test-object
update-types: does [
	repeat i length? types [types/:i: type?/word get pick words-of test-object i]
]
; for-each [/i w] words-of test-object [
; 	react probe compose [poke types (i) type?/word (as get-path! reduce ['test-object w])]
; ]
random-value: does [
	do random/only [
		[as get random/only exclude to block! any-string! [ref!] copy random "string"]
		[to get random/only to block! number! random 100.0]
		[random white]
		[draw 50x50 + random 200x200 reduce [
			'fill-pen random white
			random/only [ellipse box]
			-20x-20 + random 50x50
			50x50 + random 100x100
		]]
	]
]
words: exclude words-of test-object [on-change* on-deep-change*]
foreach w words [set w random-value]
update-types

print "FINISHED CREATING THE OBJECT"
view/no-wait/options elastic [
	s: scrollpanel [
		; at 0x0 t: table data system/catalog/errors/script #fill-x
		; t: table data words-of test-object #fill-x
		t: table data test-object #fill-x
		on-down [
			c: event/face
			unless c/type = 'panel [c: c/parent]
			addr/data: (index? find/same t/pane col: c/parent)
			        by (-1 + index? find/same col/pane c)
		]
	] #fill
	return
	panel #fix [
		text "Cell:" addr: field on-change [attempt [cell: t/pane/(addr/data/x)/pane/(addr/data/y + 1)]] button "Random cell" [addr/data: (random 4) by (random -1 + length? t/pane/1/pane)]
		return
		button "Random color" [cell/color: random white]
		button "Random font" [cell/font: make font! compose [color: (random white) size: (5 + random 10) name: (random/only ["Times New Roman" "Courier New" "Verdana"])]]
		return
		button "Randomize an object's field" [set random/only words random-value  update-types  table/update t]
		; text rate 10 on-time [t: reverse form stats parse t [any [3 skip insert " "] to end] face/text: reverse t]
		; text rate 10 on-time [face/data: 1e-6 * (stats - first-stat) / to float! difference now/precise first-time]
	]
] [flags: [resize]]


first-stat: stats
first-time: now/precise
addr/data: 1x1
table/~column/map-to t/pane/3 types
do-events
