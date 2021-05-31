Red []

#include %boşluk.red
#include %isim.red
#include %işaret.red
#include %işlev.red
#include %an.red
#include %satır.red
#include %kırmızı.red
#include %isimBelirle.red
#include %işlevBelirle.red
#include %işaretBelirle.red

tara: function [t [string!]][
    sonuç: parse t [
        senaryo: any [
            "x" (quit)
            | !satır
            | !işaret
            | !işlev
            | !an
            | !kırmızı
            | !işlevBelirle
            | !işaretBelirle
            | !isim
            | !isimBelirle
            | !boşluk
            | senaryo
        ] ;any
    ] ;parse
    print sonuç
]