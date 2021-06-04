Red []

!isim: [
    (
        ayrıİsimler: blokAyır coz/isimler/1
    )
    copy _isim ayrıİsimler 
    (
        _sıra: sıraBul _isim coz/isimler/1
        insert coz/sonbellek coz/isimler/1/(_sıra)
        insert coz/sonbellek coz/isimler/2/(_sıra)
    )
]