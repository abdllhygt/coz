Red []

etiketHariç: complement charset "<>"

!işaretBelirle: [
    !yaboşluk "<" copy _içi [some etiketHariç] ">" any !satır
    (
        insert coz/işaretler/1 coz/sonbellek/1
        insert coz/işaretler/2 _içi
    )
]