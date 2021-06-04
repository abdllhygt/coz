Red []

testiMi?: true

#include %veri.red
#include %malzeme.red
#include %tarama/tara.red
#include %köprü.red
#include %renkler.red

tara read %coz.coz

coz/satır: 0
prin "Coz " print coz/versiyon print " (Test Aracı)"
probe coz
while [0 = 0] [
    tara ask rejoin [yazırengi/kırmızı ">> " yazırengi/sade]
    probe coz
]
