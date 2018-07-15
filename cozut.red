Red [
  Title:   "COZ"
	Author:  "Abdullah Yiğiterol"
	License: {
		Şuan yok
	}
]

hataver: context[
  değişkenyok: func[isim][
    print ""
    print "COZUTTU!"
    print rejoin[isim " isminde bir değişken yok!"]
    print ""
    unless kabukAktifMi [
      quit
    ]
  ]

  değişkensayıdeğil: func [isim][
    print ""
    print "COZUTTU!"
    print rejoin[isim " değişkeni sayı değil!"]
    print ""
    unless kabukAktifMi [
      quit
    ]
  ]

  büyükküçüksayıolmalı: func [][
    print ""
    print "COZUTTU!"
    print rejoin["Büyük/küçük karşılaştırmaları sayı üzerinden yapılır!"]
    print ""
    unless kabukAktifMi [
      quit
    ]
  ]

  sözdizimi: func [][
    print ""
    print "COZUTTU!"
    print rejoin["Söz dizimi hatası"]
    print ""
    unless kabukAktifMi [
      quit
    ]
  ]
]
