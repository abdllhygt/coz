Red [
    title: "Coz"
    author: "Abdullah Yiğiterol"
    version: 0.4.0
]

#include %red-common/search.red
#include %veri.red
#include %malzeme.red
#include %tarama/tara.red

tara read %coz.coz

either system/options/args/1 [
    dosya: read/lines rejoin[%./ system/options/args/1]
    foreach d dosya [
        tara d
    ]
][
    prin " Coz " print coz/versiyon print "^[[0;34m   2018-2023" print ""
    coz/SATIR: 0
    while [0 = 0] [
        either (to string! system/build/config/os) = "Linux" [
            tara ask rejoin ["^[[0;33m" ">> " "^[[0m"]
        ][
            prin rejoin ["^[[0;33m" ">> " "^[[0m"]
            tara ask ""
        ]
        prin "^[[0;36mson bellek: ^[[0m" probe coz/sonbellek
        prin "^[[0;36msatır: ^[[0m" print coz/SATIR
        prin "^[[0;36mlimit: ^[[0m" print coz/limit
    ]
]