Red [
  Title:   "COZ"
	Author:  "Abdullah Yiğiterol"
	License: {
		Şuan yok
	}
]

print {
  Coz Programlama Dili
  0.0.8

}

#include %dynamic-ask.red

tara: func [gelen][
  parse gelen [
    !kapatma (çöz -paketdön)
    | !hepsi (çöz -paketdön)
    | !komut (çöz -paketdön)
    | copy -değer !değişken !son (print rejoin["^[[35;1;1m==^[[0m ^[[36;1;3m" değişkenkon -değer "^[[0m"])
    | copy -dön !metin !son (print rejoin["^[[35;1;1m==^[[0m ^[[36;1;3m" -dön "^[[0m"])
    | !metinbirleştirme !son (print rejoin["^[[35;1;1m==^[[0m ^[[36;1;3m" -dön "^[[0m"])
    | copy -dön !sayı !son (print rejoin["^[[35;1;1m==^[[0m ^[[36;1;3m" -dön "^[[0m"])
    | !değişkenatama (
        çöz -paketdön print rejoin["^[[35;1;1m==^[[0m ^[[36;1;3m" -atan2 "^[[0m"]
      )
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
