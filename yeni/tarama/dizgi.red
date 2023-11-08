Red []

_harf: complement charset {"}
_metin: [any _harf]

_dizgi: [
    {"} copy c_m _metin {"} ( 
        insert coz/sonbellek c_m ;append
    ) 
]