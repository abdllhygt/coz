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
      | !değişkenatama (çöz -paketdön)
      | !komut (çöz -paketdön)
      | !ise
      | !isetek
      | !kere
      | !keretek
      | !karşılaştırma !son
      | !işlem !son
      | !son
      | !boş
      | !değişken !son
      | !metin !son
      | !sayı !son
    ]
  ]
]

tara gelen
