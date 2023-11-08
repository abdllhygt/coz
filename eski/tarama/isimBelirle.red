Red []

isimKarakteri: complement charset {"{}<>[]}

!isimBelirle: [
    !yaboşluk copy _isim [some isimKarakteri] to [!satır | !isim | !an | !işaret | !işlev | !yaboşluk !satır]
    (
        if coz/durum = "doğru" [
            insert coz/isimler/1 (trim _isim)
            insert coz/isimler/2 (trim _isim)

            dönen: copy []

            insert dönen _isim
            insert dönen _isim

            insert/only coz/sonbellek dönen
        ]

        
    )
]