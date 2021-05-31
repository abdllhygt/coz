Red [
    title: "Coz"
    version: "0.3.0"
    author: "Abdullah Yiğiterol"
]

#include %veri.red
#include %malzeme.red
#include %tarama/tara.red

either system/options/args/1 [
    tara read rejoin[%./ system/options/args/1]
][
    print "Coz 0.3.0" print 
    while [0 = 0] [
        tara ask ">> "
        probe coz
    ]
]