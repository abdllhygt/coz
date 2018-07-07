Red [
  Title:   "COZ"
	Author:  "Abdullah Yiğiterol"
	License: {
		Şuan yok
	}
]

değişkenisim: []
değişkendeğer: []

değişkenvarmı: func[isim][
  if (find değişkenisim isim) [
    return true
  ]
  return false
]

değişkenata: func[isim değer /local -sayı][
  either (değişkenvarmı isim) [
    -sayı: index? (find değişkenisim isim)
    değişkendeğer/(-sayı): (do değer)
  ][
    append/only değişkenisim isim
    append/only değişkendeğer (do değer)
  ]
]

işlev: func [isim değer][
  switch isim [
    "yaz" [print değer]
    "@" [
      foreach i değişkenisim [
        print rejoin[i ": " (değişkendön i)]
      ]
      probe değişkenisim
      probe değişkendeğer
    ]
  ]
]

değişkendön: func[isim /local -sayı][
  either (değişkenvarmı isim) [
    -sayı: index? (find değişkenisim isim)
    return değişkendeğer/(-sayı)
  ][
    return false
  ]
]

değişkensayımı: func [isim /local -sayı][
  either (değişkenvarmı isim) [
    -sayı: index? (find değişkenisim isim)
    if ((type? değişkendeğer/(-sayı)) = integer!) [
      return true
    ]
    if ((type? değişkendeğer/(-sayı)) = float!) [
      return true
    ]
    return false
  ][
    return false
  ]
]

değişkenmetinmi: func [isim /local -sayı][
  either (değişkenvarmı isim) [
    -sayı: index? (find değişkenisim isim)
    return ((type? değişkendeğer/(-sayı)) = string!)
  ][
    return false
  ]
]

değişkenlistemi: func [isim /local -sayı][
  either (değişkenvarmı isim) [
    -sayı: index? (find değişkenisim isim)
    return ((type? değişkendeğer/(-sayı)) = block!)
  ][
    return false
  ]
]

değişkentipi: func [isim /local -sayı][
  either (değişkenvarmı isim) [
    if değişkensayımı isim [
      return "sayı"
    ]
    if değişkenmetinmi isim [
      return "metin"
    ]
    if değişkenlistemi isim [
      return "liste"
    ]
  ][
    return false
  ]
]
