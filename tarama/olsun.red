Red []

_olsun: ["olsun" (
    either find coz/degisken/1 coz/sonbellek/2 [
        degisken_uzunluk: length? coz/degisken/1
        degisken_sira: degisken_uzunluk - ((length? find coz/degisken/1 coz/sonbellek/2) - 1)
        coz/degisken/2/(degisken_sira): coz/sonbellek/1
    ][
        either (length? coz/degisken/1) = 0 [
            insert coz/degisken/1 coz/sonbellek/2
            insert coz/degisken/2 coz/sonbellek/1
        ][
            yeni_degisken_uzunluk: length? coz/sonbellek/2
            yeni_sira: 0
            yeni_degisken: copy [
                []
                []
            ]
            eklenmedi: true
            foreach i coz/degisken/1 [
                either (length? i) > yeni_degisken_uzunluk [
                    append yeni_degisken/1 i
                    append yeni_degisken/2 coz/degisken/2/(SIRA_BUL yeni_degisken/1 i)
                ][
                    either eklenmedi [
                        append yeni_degisken/1 coz/sonbellek/2
                        append yeni_degisken/2 coz/sonbellek/1
                    ][
                        append yeni_degisken/1 i
                        append yeni_degisken/2 coz/degisken/2/(SIRA_BUL yeni_degisken/1 i)
                    ]
                    eklenmedi: false
                ]
            ]
            probe yeni_degisken
            coz/degisken: copy yeni_degisken
        ]
    ]
)]