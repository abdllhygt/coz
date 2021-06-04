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
        any [
            !satır
            | !işaret
            | !işlev
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