Red [
    title: "Coz"
    author: "Abdullah Yiğiterol"
    version: 0.4.0
]

#include %red-common/search.red


COZ: context [
    VERSIYON: "0.4.test8"

    DEGISKEN: [
        ["z"]
        ["coz"]
    ]

    ORTAC: []

    DURAK: []

    SONBELLEK: []

    SATIR: 0

    LIMIT: 5
]



BLOK_AYIR: function [blok [block!] /local b] [
    b: copy blok
    either (length? b) > 0 [
        forall b [if not last? b [b: next b insert b '|]]
        return b
    ][
        return false
    ]
]

SIRA_BUL: function [a [block!] i] [
    return (length? a) - (length? find a i) + 1
]

SONBELLEKLE: function[d] [
    insert coz/sonbellek d
    if (length? coz/sonbellek) > (coz/limit) [
        coz/sonbellek: reverse (remove reverse coz/sonbellek)
    ]
]




_SATIR: [
    [newline | end | "^M" | "^/"] (
        coz/SATIR: coz/SATIR + 1
    )
]


_harf: complement charset {"}
_metin: [any _harf]

_dizgi: [
    copy c_m [{"} thru {"}] ( 
        SONBELLEKLE (do c_m) ;append
        if (length? coz/durak) > 0 [
            durak_: copy coz/durak/1
            clear coz/durak
            tara reverse remove (reverse(remove mold coz/degisken/2/(SIRA_BUL coz/degisken/1 durak_)))
            durak_: copy ""
        ]    
        
    ) 
]


_harf: complement charset {"[]}
_fume: ["[" any [_harf | {"} thru {"} | _fume] "]"]

_kume: [
    copy c_k [
        "[" 
            any [
                _fume
                ;"[" any [ _harf | {"} thru {"} | "[" any [_harf | {"} thru {"} | "[" thru "]"] "]"] "]"
                | [{"} thru {"}]
                | _harf
            ]
        "]"
    ] (
        kume_: copy do c_k
        insert/only coz/sonbellek kume_
        if (length? coz/sonbellek) > (coz/limit) [
            coz/sonbellek: reverse (remove reverse coz/sonbellek)
        ]
        if (length? coz/durak) > 0 [
            durak_: copy coz/durak/1
            clear coz/durak
            tara reverse remove (reverse(remove mold coz/degisken/2/(SIRA_BUL coz/degisken/1 durak_)))
            durak_: copy ""
        ]    
    )
]


_SAYI19: charset "123456789"
_SAYI09: charset "0123456789"

_SAYI: [
    copy c_s [["0" | _SAYI19 any _SAYI09] "." any _SAYI09 | "0" | [_SAYI19 any _SAYI09]] (
        SONBELLEKLE to float! c_s
        if (length? coz/durak) > 0 [
            durak_: copy coz/durak/1
            clear coz/durak
            tara reverse remove (reverse(remove mold coz/degisken/2/(SIRA_BUL coz/degisken/1 durak_)))
            durak_: copy ""
        ]    
    )
]


_bosluk: [some space]


_olsun: ["olsun" (
    either find coz/degisken/1 coz/sonbellek/2 [
        degisken_uzunluk: length? coz/degisken/1
        degisken_sira: degisken_uzunluk - ((length? find coz/degisken/1 coz/sonbellek/2) - 1)
        coz/degisken/2/(degisken_sira): coz/sonbellek/1
    ][
        either (length? coz/degisken/1) < 2 [ ;false
            either (length? coz/degisken/1) = 0 [
                insert/only coz/degisken/1 coz/sonbellek/2
                insert/only coz/degisken/2 coz/sonbellek/1
            ][
                either (length? coz/sonbellek/2) > (length? coz/degisken/1/1)[
                    insert/only coz/degisken/1 coz/sonbellek/2
                    insert/only coz/degisken/2 coz/sonbellek/1
                ][
                    append/only coz/degisken/1 coz/sonbellek/2
                    append/only coz/degisken/2 coz/sonbellek/1
                ]
            ]
        ][
            set [i1: len1: i2: len2:]
            search/for i: 1 length? coz/degisken/1 [length? coz/degisken/1/:i] length? coz/sonbellek/2
            insert/only at coz/degisken/1 i2 coz/sonbellek/2
            insert/only at coz/degisken/2 i2 coz/sonbellek/1
            ;coz/degisken/1: copy coz/degisken/1
            ;coz/degisken/2: copy coz/degisken/2
            comment {
                yeni_degisken_uzunluk: length? coz/sonbellek/2
                yeni_sira: 0
                yeni_degisken: copy [
                    []
                    []
                ]
                eklenmedi: true
                foreach i coz/degisken/1 [
                    either (length? i) > yeni_degisken_uzunluk [
                        append yeni_degisken/1 i
                        append yeni_degisken/2 coz/degisken/2/(SIRA_BUL yeni_degisken/1 i)
                    ][
                        either eklenmedi [
                            append yeni_degisken/1 coz/sonbellek/2
                            append yeni_degisken/2 coz/sonbellek/1
                        ][
                            append yeni_degisken/1 i
                            append yeni_degisken/2 coz/degisken/2/(SIRA_BUL yeni_degisken/1 i)
                        ]
                        eklenmedi: false
                    ]
                ]
                probe yeni_degisken
                coz/degisken: copy yeni_degisken
            }
        ]
    ]
)]


_degisken: [ 
    (_AYRI_DEGISKEN: BLOK_AYIR coz/degisken/1) 
    copy c_a _AYRI_DEGISKEN
    (
        either (type? coz/degisken/2/(SIRA_BUL coz/degisken/1 c_a)) = block! [
            either find coz/ortac c_a [
                ;either find coz/durak c_a [
                ;    tara reverse remove (reverse(remove mold coz/degisken/2/(SIRA_BUL coz/degisken/1 c_a)))
                ;    clear coz/durak
                ;][
                    insert coz/durak c_a
                ;]
            ][
                tara reverse remove (reverse(remove mold coz/degisken/2/(SIRA_BUL coz/degisken/1 c_a)))
            ]
        ][
            SONBELLEKLE coz/degisken/2/(SIRA_BUL coz/degisken/1 c_a)
            if (length? coz/durak) > 0 [
                durak_: copy coz/durak/1
                clear coz/durak
                tara reverse remove (reverse(remove mold coz/degisken/2/(SIRA_BUL coz/degisken/1 durak_)))
                durak_: copy ""
            ]
        ]
    )
]


_ilintile: [
    "ilintile" (
        ilinti_: coz/sonbellek/1
        remove coz/sonbellek
        do ilinti_
    )
]


_ata: ["ata" (
    either find coz/degisken/1 coz/sonbellek/2 [
        degisken_uzunluk: length? coz/degisken/1
        degisken_sira: degisken_uzunluk - ((length? find coz/degisken/1 coz/sonbellek/2) - 1)
        coz/degisken/2/(degisken_sira): coz/sonbellek/1
    ][
        either (length? coz/degisken/1) < 2 [ ;false
            either (length? coz/degisken/1) = 0 [
                insert/only coz/degisken/1 coz/sonbellek/2
                insert/only coz/degisken/2 coz/sonbellek/1
            ][
                either (length? coz/sonbellek/2) > (length? coz/degisken/1/1)[
                    insert/only coz/degisken/1 coz/sonbellek/2
                    insert/only coz/degisken/2 coz/sonbellek/1
                ][
                    append/only coz/degisken/1 coz/sonbellek/2
                    append/only coz/degisken/2 coz/sonbellek/1
                ]
            ]
        ][  
            set [i1: len1: i2: len2:]
            search/for i: 1 length? coz/degisken/1 [length? coz/degisken/1/:i] length? coz/sonbellek/2
            insert/only at coz/degisken/1 i2 coz/sonbellek/1
            insert/only at coz/degisken/2 i2 coz/sonbellek/2
        ]
    ]
)]

tara: function[t [string!]][
    parse t [
        any [
            _SATIR
            | _kume
            | _olsun
            | _ata
            | _dizgi
            | _SAYI
            | _ilintile
            | _degisken
            | _bosluk
            | "kapat" (quit)
            | "!" (coz/sonbellek: copy reverse (remove reverse coz/sonbellek))
            | skip
        ]
    ]
]

tara read %coz.coz

either system/options/args/1 [
    dosya: read/lines rejoin[%./ system/options/args/1]
    foreach d dosya [
        tara d
    ]
][
    prin " Coz " print coz/versiyon print "^[[0;34m   2018-2023" print ""
    coz/SATIR: 0
    print "dosya ismi yazın"
]