Red [
    title: "Coz"
    author: "Abdullah Yiğiterol"
]

#include %veri.red
#include %malzeme.red
#include %tarama/tara.red
#include %köprü.red
#include %renkler.red

tara read %coz.coz

either system/options/args/1 [
    either system/options/args/1 = "test" [
        prin "Coz " print coz/versiyon print ""
        probe coz
        while [0 = 0] [
            tara ask rejoin [yazırengi/kırmızı ">> " yazırengi/sade]
            probe coz
        ]
    ][
        tara read rejoin[%./ system/options/args/1]
    ]
][
    coz/satır: 0
    prin "Coz " print coz/versiyon print ""
    while [0 = 0] [
        tara ask rejoin [yazırengi/sarı ">> " yazırengi/sade]
    ]
]