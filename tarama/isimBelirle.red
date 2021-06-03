Red []

isimKarakteri: complement charset {"{}<>[]}

!isimBelirle: [
    !yaboşluk copy _isim [some isimKarakteri] to [!satır | !boşluk !isim | !işaret | !boşluk !işlev | !yaboşluk !satır]
    (
        insert coz/isimler/1 _isim
        insert coz/isimler/2 _isim
        insert coz/sonbellek _isim
    )
]