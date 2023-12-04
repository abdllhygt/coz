Red []

_degisken: [ 
    (_AYRI_DEGISKEN: BLOK_AYIR coz/degisken/1) 
    copy c_a _AYRI_DEGISKEN
    (
        either (type? coz/degisken/2/(SIRA_BUL coz/degisken/1 c_a)) = block! [
            either find coz/ortac c_a [
                ;either find coz/durak c_a [
                ;    tara reverse remove (reverse(remove mold coz/degisken/2/(SIRA_BUL coz/degisken/1 c_a)))
                ;    clear coz/durak
                ;][
                    insert coz/durak c_a
                ;]
            ][
                tara reverse remove (reverse(remove mold coz/degisken/2/(SIRA_BUL coz/degisken/1 c_a)))
            ]
        ][
            SONBELLEKLE coz/degisken/2/(SIRA_BUL coz/degisken/1 c_a)
            if (length? coz/durak) > 0 [
                durak_: copy coz/durak/1
                clear coz/durak
                tara reverse remove (reverse(remove mold coz/degisken/2/(SIRA_BUL coz/degisken/1 durak_)))
                durak_: copy ""
            ]
        ]
    )
]