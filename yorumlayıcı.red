Red [
  Title:   "COZ"
	Author:  "Abdullah Yiğiterol"
	License: {
		Şuan yok
	}
]

do %paketle.red
do %çöz.red
do %bellek.red
do %parçalar.red
do %cozut.red

tara: func [gelen][
  parse gelen [
    any [
      !kapatma
      | !hepsi (çöz -paketdön)
      | !değişken !son
      | !metin !son
      | !sayı !son
      | !değişkenatama (çöz -paketdön)
      | !işlev (çöz -paketdön)
      | !ise
      | !isetek
      | !kere
      | !keretek
      | !karşılaştırma !son
      | !işlem !son
      | !son
      | !boş
    ]
  ]
]

tara gelen
