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
        any senaryo: [
            "x" (quit)
            | !satır
            | !işaret
            | !işlev
            | !isim
            | !an
            | !kırmızı
            | !isimBelirle
            | !işlevBelirle
            | !işaretBelirle
            | !boşluk
        ] ;any
    ] ;parse
    print sonuç
]