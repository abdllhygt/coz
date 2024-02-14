Red []

;_harf: complement charset {"[]}
_anahtar_: ["ata" | "olsun"]
_isaret_: charset "{}[];.,_-+*/'!?&%$#"
_dizgi_: [{"} thru {"}]
_ilinti_: ["((" thru "))"] ;hata burada olabilir

_SAYI19_: charset "123456789"
_SAYI09_: charset "0123456789"
_sayi_: [["0" | _SAYI19 any _SAYI09] "." any _SAYI09 | "0" | [_SAYI19 any _SAYI09]]

_degisken_: [(_AYRI_DEGISKEN: BLOK_AYIR coz/degisken/1) _AYRI_DEGISKEN]

_bosluk_: [some space]
_satir_: [newline | end | "^M" | "^/"]

_fume: ["kü" any [_satir_ | _bosluk_ | _ilinti_ | _dizgi_ | _sayi_ | _degisken_ | _fume | _anahtar_ | _isaret_] "me"]

_kume: [
    copy c_k _fume (
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