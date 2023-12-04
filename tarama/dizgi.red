Red []

_harf: complement charset {"}
_metin: [any _harf]

_dizgi: [
    {"} copy c_m _metin {"} ( 
        SONBELLEKLE c_m ;append
        if (length? coz/durak) > 0 [
            tara reverse remove (reverse(remove mold coz/degisken/2/(SIRA_BUL coz/degisken/1 coz/durak/1)))
            clear coz/durak
        ]    
        
    ) 
]