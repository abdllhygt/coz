Red []

_ata: ["ata" (
    either find coz/degisken/1 coz/sonbellek/2 [
        degisken_uzunluk: length? coz/degisken/1
        degisken_sira: degisken_uzunluk - ((length? find coz/degisken/1 coz/sonbellek/2) - 1)
        coz/degisken/2/(degisken_sira): coz/sonbellek/1
    ][
        either (length? coz/degisken/1) < 2 [ ;false
            either (length? coz/degisken/1) = 0 [
                insert/only coz/degisken/1 coz/sonbellek/2
                insert/only coz/degisken/2 coz/sonbellek/1
            ][
                either (length? coz/sonbellek/2) > (length? coz/degisken/1/1)[
                    insert/only coz/degisken/1 coz/sonbellek/2
                    insert/only coz/degisken/2 coz/sonbellek/1
                ][
                    append/only coz/degisken/1 coz/sonbellek/2
                    append/only coz/degisken/2 coz/sonbellek/1
                ]
            ]
        ][  
            set [i1: len1: i2: len2:]
            search/for i: 1 length? coz/degisken/1 [length? coz/degisken/1/:i] length? coz/sonbellek/2
            insert/only at coz/degisken/1 i2 coz/sonbellek/1
            insert/only at coz/degisken/2 i2 coz/sonbellek/2
        ]
    ]
)]