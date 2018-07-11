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

print {
  Coz Programlama Dili
  0.0.6

}

#include %dynamic-ask.red

tara: func [gelen][
  parse gelen [
    !kapatma (çöz -paketdön)
    | !hepsi (çöz -paketdön)
    | copy -değer !değişken end (print rejoin["^[[35;1;1m==^[[0m ^[[36;1;3m" değişkenkon -değer "^[[0m"])
    | copy -dön !metin end (print rejoin["^[[35;1;1m==^[[0m ^[[36;1;3m" -dön "^[[0m"])
    | copy -dön !sayı end (print rejoin["^[[35;1;1m==^[[0m ^[[36;1;3m" -dön "^[[0m"])
    | !değişkenatama (
        çöz -paketdön print rejoin["^[[35;1;1m==^[[0m ^[[36;1;3m" -atan2 "^[[0m"]
      )
    | !işlev (çöz -paketdön)
    | !isetek
    | !keretek
    | !karşılaştırma !son (print rejoin["^[[35;1;1m==^[[0m ^[[36;1;3m" -dön "^[[0m"])
    | !işlem !son (
      -dön: replace -dön {`~} ""
      print rejoin["^[[35;1;1m==^[[0m ^[[36;1;3m" (math load -dön) "^[[0m"]
    )
    | !son
    | (hataver/sözdizimi)
  ]
]

while [true][
  gelen: ask "^[[33;1;1m>>^[[0m "

  tara gelen
]
