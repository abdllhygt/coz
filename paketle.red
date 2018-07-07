Red [
  Title:   "COZ"
	Author:  "Abdullah Yiğiterol"
	License: {
		Şuan yok
	}
]

paketle: context [

  değişkenata: func[isim değer /local -küme][
    -küme: copy ["değişkenata"]
    append/only -küme isim
    append/only -küme değer
    return -küme
  ]

  işlev: func[isim değer /local -küme][
    -küme: copy ["işlev"]
    append/only -küme isim
    append/only -küme değer
    return -küme
  ]

]
