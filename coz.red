Red [
<<<<<<< HEAD
    Title:   "COZ"
=======
  Title:   "COZ"
>>>>>>> 0.0.3
	Author:  "Abdullah Yiğiterol"
	License: {
		Şuan yok
	}
]

<<<<<<< HEAD
#include %environment/console/input.red
do %anahtarlar.red

either system/options/args [
    gelen: read rejoin[%./ system/options/args/1]
   
    parse gelen [
         any [ SDise | SDyaz | bosluk | satir | SDkapat]
        | skip
    ]
][
    print "  Coz 0.0.1 (24 Mart 2018'de Derlendi)  "
    print ""

    while [0 = 0] [
        prin ">>"        
        gelen: ask ">>"
        parse gelen [  (git: [none])
            any [SDise | SDyaz | SDislem  satir (print ["==" text])| SDkapat | bosluk]
            | skip
        ]
    ]
=======
either system/options/args/1 [
    gelen: read rejoin[%./ system/options/args/1]
    do %yorumlayıcı.red
][
  do %kabuk.red
>>>>>>> 0.0.3
]
