Red []

_olsun: ["olsun" (
    either find coz/degisken/1 coz/sonbellek/2 [
        degisken_uzunluk: length? coz/degisken/1
        degisken_sira: degisken_uzunluk - ((length? find coz/degisken/1 coz/sonbellek/2) - 1)
        coz/degisken/2/(degisken_sira): coz/sonbellek/1
    ][
        insert coz/degisken/1 coz/sonbellek/2
        insert coz/degisken/2 coz/sonbellek/1
    ]
)]