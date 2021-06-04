Red []

!isim: [
    (
        ayrıİsimler: blokAyır coz/isimler/1
    )
    copy _isim ayrıİsimler 
    (
        _sıra: sıraBul _isim coz/isimler/1

        dönen: copy []
        insert dönen coz/isimler/2/(_sıra)
        insert dönen coz/isimler/1/(_sıra)

        insert/only coz/sonbellek dönen
    )
]