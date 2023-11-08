Red []

etiketHariç: complement charset "<>"

!işaretBelirle: [
    "<" copy _içi [some etiketHariç] ">"
    (
        if coz/durum = "doğru" [
            insert coz/işaretler/1 coz/sonbellek/1
            insert coz/işaretler/2 _içi
        ]
    )
]