Red [
    needs: 'view
]

 _save-cfg: ""

testiMi?: true

#include %../red-master/environment/console/CLI/input.red
#include %veri.red
#include %malzeme.red
#include %tarama/tara.red
#include %köprü.red
#include %renkler.red

sergile: [
    prin [yazırengi/kırmızı "isimler: " yazıRengi/sade]
    foreach i coz/isimler/1[
        prin [yazırengi/pembe i yazırengi/sade "|"]
    ] print ""
    
    prin [yazırengi/kırmızı "işlevler: " yazıRengi/sade]
    foreach i coz/işlevler/1[
        prin [yazırengi/pembe i yazırengi/sade "|"]
    ] print ""

    prin [yazırengi/kırmızı "işaretler: " yazıRengi/sade]
    foreach i coz/işaretler/1[
        prin [yazırengi/pembe i yazırengi/sade "|"]
    ] print ""

    prin [yazırengi/kırmızı "sonbellek: " yazıRengi/sade]
    foreach i coz/sonbellek[
        prin [yazırengi/pembe i yazırengi/sade "|"]
    ] print ""

    prin [yazırengi/kırmızı "durum: " yazıRengi/sade]
    print [yazırengi/pembe coz/durum yazırengi/sade]

    prin [yazırengi/kırmızı "satır: " yazıRengi/sade]
    print [yazırengi/pembe coz/satır yazırengi/sade]
]

tara read %coz.coz

coz/satır: 0
prin "Coz " print coz/versiyon print " (Test Aracı)"
do sergile
while [0 = 0] [
    prin rejoin [yazırengi/kırmızı ">> " yazırengi/sade]
    tara ask ""
    do sergile
]
