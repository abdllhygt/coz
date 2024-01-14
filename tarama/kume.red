Red []

_harf: complement charset {"[]}
_fume: ["kü" any [_harf | {"} thru {"} | _fume] "me"]

_kume: [
    copy c_k [
        "kü" 
            any [
                _fume
                ;"[" any [ _harf | {"} thru {"} | "[" any [_harf | {"} thru {"} | "[" thru "]"] "]"] "]"
                | [{"} thru {"}]
                | _harf
            ]
        "me"
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