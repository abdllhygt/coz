Red []

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
    )
]