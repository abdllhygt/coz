Red []

;_harf: complement charset {"[]}
_anahtar: ["ata" | "olsun"]
_isaret: charset "{}[];.,_-+*/'!?&%$#"
_dizgi: [{"} thru {"}]
_ilinti: ["(" thru ");"] ;hata burada olabilir

_SAYI19: charset "123456789"
_SAYI09: charset "0123456789"
_sayi: [["0" | _SAYI19 any _SAYI09] "." any _SAYI09 | "0" | [_SAYI19 any _SAYI09]]

_degisken: [(_AYRI_DEGISKEN: BLOK_AYIR coz/degisken/1) _AYRI_DEGISKEN]

_bosluk: [some space]
_satir: [newline | end | "^M" | "^/"]

_fume: ["kü" (probe "kü") any [_satir (probe "s")| _bosluk (probe "b") | _ilinti (probe "n") | _dizgi | _sayi | _degisken | _fume | _anahtar | _isaret] "me"]

_kume: [ ;kümeyi düzgün taramıyor
    copy c_k _fume ( probe "oldu"
        c_k: copy remove c_k
        c_k: copy remove c_k
        c_k: copy reverse c_k
        c_k: copy remove c_k
        c_k: copy remove c_k
        c_k: copy reverse c_k
        c_k: copy rejoin ["[" c_k "]"]
        kume_: copy do c_k
        c_k: copy ""
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