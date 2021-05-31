Red []

süslüHariç: complement charset "{}"

!işlevBelirle: [
    !yaboşluk "{" copy _içi [some süslüHariç]  "}" any !satır
    (
        insert coz/işlevler/1 coz/sonbellek/1
        insert coz/işlevler/2 _içi
    )
]