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

print {
  Coz Programlama Dili
  0.0.3

}

tara: func [gelen][
  parse gelen [
    !kapatma
    | !hepsi (çöz -paketdön)
    | copy -değer !değişken end (print rejoin["^[[35;1;1m==^[[0m ^[[36;1;3m" değişkenkon -değer "^[[0m"])
    | copy -dön !metin end (print rejoin["^[[35;1;1m==^[[0m ^[[36;1;3m" -dön "^[[0m"])
    | copy -dön !sayı end (print rejoin["^[[35;1;1m==^[[0m ^[[36;1;3m" -dön "^[[0m"])
    | !değişkenatama (çöz -paketdön print rejoin["^[[35;1;1m==^[[0m ^[[36;1;3m" -dön "^[[0m"])
    | !işlev (çöz -paketdön)
    | !isetek
    | !saytek
    | !karşılaştırma !son (print rejoin["^[[35;1;1m==^[[0m ^[[36;1;3m" -dön "^[[0m"])
    | !işlem !son (print rejoin["^[[35;1;1m==^[[0m ^[[36;1;3m" -dön "^[[0m"])
    | !son
    | (hataver/sözdizimi)
  ]
]
while [true][
  gelen: ask "^[[33;1;1m>>^[[0m "

  tara gelen
]
