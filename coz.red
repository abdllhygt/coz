Red [
    title: "Coz"
    author: "Abdullah Yiğiterol"
    version: 0.4.0
]

#include %red-common/search.red
#include %veri.red
#include %malzeme.red
#include %tarama/tara.red
#include %kopru.red

tara read %coz.coz

either system/options/args/1 [
    dosya: read/lines rejoin[%./ system/options/args/1]
    foreach d dosya [
        tara d
    ]
][
    prin "Coz " print coz/versiyon print "^[[0;34m2018-2023"
    while [0 = 0] [
        either (to string! system/build/config/os) = "Linux" [
            tara ask rejoin ["^[[0;33m" ">> " "^[[0m"]
            print coz
        ][
            prin rejoin ["^[[0;33m" ">> " "^[[0m"]
            tara ask ""
        ]
    ]
]