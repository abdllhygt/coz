Red [
    title: "Coz"
    author: "Abdullah Yiğiterol"
    version: 0.4.0
]

#include %red-common/search.red
#include %veri.red
#include %malzeme.red
#include %tarama/tara.red

ilk_g: system/options/args/1

either ilk_g [
    either ilk_g = "test" [
        tara_test read %test.coz
    ][
        tara read %coz.coz
        dosya: read/lines rejoin[%./ system/options/args/1]
        foreach d dosya [
            tara d
        ]
    ]
][
    tara read %coz.coz false
    prin " Coz " print coz/versiyon print "^[[0;34m   2018-2023" print ""
    coz/SATIR: 0
    while [0 = 0] [
        either (to string! system/build/config/os) = "Linux" [
            tara ask rejoin ["^[[0;33m" ">> " "^[[0m"]
        ][
            prin rejoin ["^[[0;33m" ">> " "^[[0m"]
            tara ask ""
        ]
        prin "^[[3;36m^[[2m= " probe coz/sonbellek/1
        ;probe coz/sonbellek
        ;probe coz/ortac
        ;probe coz/durak
        ;prin "^[[0;36msatır: ^[[0m" print coz/SATIR
        ;prin "^[[0;36mlimit: ^[[0m" print coz/limit
    ]
]