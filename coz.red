Red [
    Title:   "COZ"
	Author:  "Abdullah Yiğiterol"
	License: {
		Şuan yok
	}
]

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
]
