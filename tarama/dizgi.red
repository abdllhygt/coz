Red []

_harf: complement charset {"}
_metin: [any _harf]

_dizgi: [
    {"} copy c_m  thru {"} ( ;problemli
        c_m: reverse remove reverse copy c_m
        SONBELLEKLE c_m ;append
        if (length? coz/durak) > 0 [
            durak_: copy coz/durak/1
            clear coz/durak
            tara reverse remove (reverse(remove mold coz/degisken/2/(SIRA_BUL coz/degisken/1 durak_)))
            durak_: copy ""
        ]    
        
    ) 
]