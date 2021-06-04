Red []

!işlev: [
    (
        ayrıİşlevler: blokAyır coz/işlevler/1
    )
    copy _işlev ayrıİşlevler 
    (    
        if coz/durum = "doğru" [
            _sıra: sıraBul _işlev coz/işlevler/1
            tara coz/işlevler/2/(_sıra)
        ]
    )
]