Red [
  Title:   "COZ"
	Author:  "Abdullah Yiğiterol"
	License: {
		Şuan yok
	}
]

print [{
  Coz Programlama Dili
  0.1.2

}]

tara: func [gelen][
  parse gelen [
    !kapat (do -kaynak)
    | !değer !son (print rejoin["^[[35;1;1m==^[[0m ^[[36;1;3m" -dön "^[[0m"])
    | !isetek (do -kaynak)
    | !ikentek (do -kaynak)
    | !keretek (do -kaynak)
    | !pencereYaz (do -kaynak)
    | !dosyaYaz (do -kaynak)
    | !yaz (do -kaynak)
    | !pencereOku (do -kaynak)
    | !dosyaOku (do -kaynak)
    | !oku (do -kaynak)
    | !değişkenAta !son (
      do -kaynak
      print rejoin["^[[35;1;1m==^[[0m ^[[36;1;3m" -dön "^[[0m"]
    )
    | !değişken !son (
      -dön: do -değişkendön
      if (type? -dön) = string! [
        -dön: rejoin[{"} -dön {"}]
      ]
      if (type? -dön) = logic! [
        if -dön [-dön: "doğru"]
        unless -dön [-dön: "yanlış"]
      ]
      print rejoin["^[[35;1;1m==^[[0m ^[[36;1;3m" -dön "^[[0m"]
    )
  ]
]

sistem: to string! system/platform

either sistem = "Linux" [
  while [true][
    gelen: ask "^[[33;1;1m>>^[[0m "
    tara gelen
  ]
][
  while [true][
    prin "^[[33;1;1m>>^[[0m "
    gelen: ask ""
    tara gelen
  ]
]
