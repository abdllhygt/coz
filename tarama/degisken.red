Red []

_degisken: [ 
    (_AYRI_DEGISKEN: BLOK_AYIR coz/degisken/1) 
    copy c_a _AYRI_DEGISKEN
    (
        either (type? coz/degisken/2/(SIRA_BUL coz/degisken/1 c_a)) = block! [
            ;to string! coz/degisken/2/(SIRA_BUL coz/degisken/1 c_a)
        ][
            SONBELLEKLE coz/degisken/2/(SIRA_BUL coz/degisken/1 c_a)
        ]
    )
] 