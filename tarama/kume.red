Red []

;_harf: complement charset {"[]}
_anahtar: ["ata" | "olsun" | "ilintile"]
_isaret: charset "{}()[];.,_-+*/'!?&%$#"
_dizgi: [{"} thru {"}]
_ilinti: ["(" thru ");"]

_SAYI19: charset "123456789"
_SAYI09: charset "0123456789"
_sayi: [["0" | _SAYI19 any _SAYI09] "." any _SAYI09 | "0" | [_SAYI19 any _SAYI09]]

_degisken: [(_AYRI_DEGISKEN: BLOK_AYIR coz/degisken/1) _AYRI_DEGISKEN]

_bosluk: [some space]
_satir: [newline | end | "^M" | "^/"]

_fume: ["kü" any [_anahtar | _isaret | _dizgi | _ilinti | _sayi | _degisken | _bosluk | _satir | _fume ] "me"]

_kume: [
    [
        "kü"
            copy c_k [ 
                any [
                    _anahtar | _isaret | _dizgi | _ilinti | _sayi | _degisken | _bosluk | _satir | _fume
                ]
            ]
        "me"
    ] (
        c_k_: rejoin ["[" c_k "]"]
        kume_: copy do c_k_ ;
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