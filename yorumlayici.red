Red [
  Title:   "COZ"
	Author:  "Abdullah Yiğiterol"
	License: {
		Şuan yok
	}
]

tara: func [gelen][
  parse gelen [
    any [
      !kapat
      | !değişkenata (do -kaynak)
      | !komut (do -kaynak)
      | !ise (do -kaynak)
      | !kere (do -kaynak)
      | !keretek (do -kaynak)
      | !isetek (do -kaynak)
      | [!büyükmü | !küçükmü | !eşitmi | !eşitdeğilmi] !son
      | !işlem !son
      | !son
      | !boş
      | !metinbirleştirme !son
      | !değişken !son
      | !metin !son
      | !sayı !son
      ;| (hataver/sözdizimi)
    ]
  ]
]

tara gelen
