Red [
  Title:   "COZ"
	Author:  "Abdullah Yiğiterol"
	License: {
		Şuan yok
	}
]

#include %paketle.red
#include %çöz.red
#include %bellek.red
#include %parçalar.red
#include %cozut.red

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
