Red []

#include %bosluk.red
#include %isim.red
#include %isaret.red
#include %islev.red
#include %an.red
#include %satir.red
#include %kirmizi.red
#include %isimBelirle.red
#include %islevBelirle.red
#include %isaretBelirle.red
#include %kopru.red

tara: function [t [string!]][
    sonuç: parse t [
        any [
            !satır
            | !işaret
            | !işlev
            | !köprü
            | !an
            | !kırmızı
            | !işlevBelirle
            | !işaretBelirle
            | !isim
            | !boşluk
            | !isimBelirle
        ] ;any
    ] ;parse
    if testiMi? [
        either sonuç [
            print [yazırengi/yeşil "doğru" yazıRengi/sade]
        ][
            print [yazırengi/kırmızı "yanlış" yazıRengi/sade]
        ]
    ]
]