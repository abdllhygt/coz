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
    either (find değer {`~}) [
      değer: replace değer {`~} ""
      değişkendeğer/(-sayı): (math load değer)
      -atan2: (math load değer)
    ][
      değişkendeğer/(-sayı): (do değer)
    ]
  ][
    append/only değişkenisim isim
    either (find değer {`~}) [
      değer: replace değer {`~} ""
      append/only değişkendeğer (math load değer)
      -atan2: (math load değer)
    ][
      append/only değişkendeğer (do değer)
    ]
  ]
]

işlev: func [isim değer /local -sayı][
  switch isim [
    "yaz" [
      either (type? değer) = word![
        -sayı: index? (find değişkenisim (to string! değer))
        print değişkendeğer/(-sayı)
      ][
        either (find değer {`~})[
          değer: replace değer {`~} ""
          print (math load değer)
        ][
          print değer
        ]
      ]
    ]
    "yaz#dosya" [
      either (type? değer/1) = word![
        -sayı: index? (find değişkenisim (to string! değer/1))
        save rejoin[%./ değer/2] değişkendeğer/(-sayı)
      ][
        either (find değer/1 {`~})[
          değer: replace değer {`~} ""
          save rejoin[%./ değer/2] (math load değer)
        ][
          save rejoin[%./ değer/2] değer/1
        ]
      ]
    ]
    "yaz#pencere" [
      either (type? değer) = word![
        -sayı: index? (find değişkenisim (to string! değer))
        değer: to string! değişkendeğer/(-sayı)
      ][
        either (find değer {`~})[
          değer: replace değer {`~} ""
          değer: to string! (math load değer)
        ][
          değer: to string! değer
        ]
      ]
      either system/platform = 'Linux [
        wsize 300x100 zenity/title "Coz" zenity/info değer
      ][
        view [ title "Coz" size 350x100
          text değer
        ]
      ]
    ]
    "oku" [
      -dön: copy {""}
      -dön: rejoin[{"} (ask "") {"}]
    ]
    "oku#dosya" [
      -dön: copy {""}
      -dön: rejoin["{" (read (to file! değer)) "}"]
    ]
    "oku#pencere" [
      -dön: copy {""}
      either system/platform = 'Linux [
        wsize 300x100 zenity/title "Coz" -dön: zenity/entry
        -dön: rejoin[{"} -dön {"}]
      ][
        view [ title "Coz" size 350x100
          fyazı: field button "gönder" [
            -dön: fyazı/text
            unview
          ]
        ]
        -dön: rejoin[{"} -dön {"}]
      ]
    ]
    "@" [
      foreach i değişkenisim [
        print rejoin[i ": " (değişkendön i)]
      ]
      probe değişkenisim
      probe değişkendeğer
    ]
    "kapat" [quit]
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

değişkenkon: func[isim /local -sayı][
  either (değişkenvarmı isim) [
    -sayı: index? (find değişkenisim isim)
    if (type? değişkendeğer/(-sayı)) = string! [
      return rejoin[{"} değişkendeğer/(-sayı) {"}]
    ]
    return değişkendeğer/(-sayı)
  ][
    return "yok"
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
