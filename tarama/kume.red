Red []

_harf: complement charset {"[]}

_kume: [
    copy c_k [
        "[" 
            any [
                ["[" thru "]"]
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