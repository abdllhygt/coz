Red []

_SAYI19: charset "123456789"
_SAYI09: charset "0123456789"

_SAYI: [
    copy c_s [["0" | _SAYI19 any _SAYI09] "." any _SAYI09 | "0" | [_SAYI19 any _SAYI09]] (
        SONBELLEKLE to float! c_s
        if (length? coz/durak) > 0 [ probe coz/durak/1
            durak_: copy coz/durak/1
            clear coz/durak
            tara reverse remove (reverse(remove mold coz/degisken/2/(SIRA_BUL coz/degisken/1 durak_)))
            durak_: copy ""
        ]    
    )
]