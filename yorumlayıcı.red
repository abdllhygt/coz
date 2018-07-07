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
      !işlev (çöz -paketdön)
      | !değişkenatama (çöz -paketdön)
      | !isetek
      | !saytek
      | !son
    ]
  ]
]

tara gelen
