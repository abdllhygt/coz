Red [
    title: "Coz"
    author: "Abdullah Yiğiterol"
]

#include %veri.red
#include %malzeme.red
#include %tarama/tara.red
#include %köprü.red

tara read %coz.coz

either system/options/args/1 [
    either system/options/args/1 = "test" [
        prin "Coz " print coz/versiyon 
        probe coz
        while [0 = 0] [
            tara ask ">> "
            probe coz
        ]
    ][
        tara read rejoin[%./ system/options/args/1]
    ]
][
    coz/satır: 0
    print coz/versiyon 
    while [0 = 0] [
        tara ask ">> "
    ]
]