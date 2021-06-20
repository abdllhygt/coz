Red [
    title: "Coz"
    author: "Abdullah Yiğiterol"
    needs: 'view
]

 _save-cfg: ""

testiMi?: false

;#include %../red-master/environment/console/CLI/input.red
#include %veri.red
#include %malzeme.red
#include %tarama/tara.red
#include %kopru.red
#include %renkler.red

tara read %coz.coz

either system/options/args/1 [
    dosya: read/lines rejoin[%./ system/options/args/1]
    foreach d dosya [
        tara d
    ]
][
    coz/satır: 0
    prin "Coz " print coz/versiyon print ""
    while [0 = 0] [
        prin rejoin [yazırengi/sarı ">> " yazırengi/sade]
        tara ask ""
    ]
]