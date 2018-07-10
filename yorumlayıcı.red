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
      !kapatma (çöz -paketdön)
      | !hepsi (çöz -paketdön)
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
      | !değişken !son
      | !metin !son
      | !sayı !son
    ]
  ]
]

tara gelen
