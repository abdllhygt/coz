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
      !kapatma (çöz -paketdön)
      | !hepsi (çöz -paketdön)
      | !değişkenatama !son (çöz -paketdön)
      | !komut !son (çöz -paketdön)
      | !ise
      | !isetek
      | !kere
      | !keretek
      | !karşılaştırma !son
      | !işlem !son
      | !son
      | !boş
      | !metinbirleştirme !son
      | !değişken !son
      | !metin !son
      | !sayı !son
      | (hataver/sözdizimi)
    ]
  ]
]

tara gelen
