Red []

yaz: function [][
    either (type? coz/sonbellek/1) = block! [
        print coz/sonbellek/1/2
    ][
        print coz/sonbellek/1
    ]
]

kapat: function [][
    quit
]

olsun: function[/local sıra][
    if (type? coz/sonbellek/2) = block! [
        sıra: sıraBul coz/sonbellek/2/1 coz/isimler/1
        either (type? coz/sonbellek/1) = block! [
            coz/isimler/2/(sıra): coz/sonbellek/1/2
        ][
            coz/isimler/2/(sıra): coz/sonbellek/1
        ]
    ]
]

ise: function[/local birinci ikinci][
    either (type? coz/sonbellek/1) = block! [
        ikinci: coz/sonbellek/1/2
    ][
        ikinci: coz/sonbellek/1
    ]
    either (type? coz/sonbellek/2) = block! [
        birinci:  coz/sonbellek/2/2
    ][
        birinci:  coz/sonbellek/2
    ]
    either birinci = ikinci [
        coz/durum: "doğru"
    ][
        coz/durum: "yanlış"
    ]
]

sonbelleğiTemizle: function [][
    coz/döngü: 1
    coz/durum: "doğru" 
    clear coz/sonbellek
]

kaçEder: function [/local işlem][
    either (type? coz/sonbellek/1) = block! [
        işlem: coz/sonbellek/1/2
    ][
        işlem: coz/sonbellek/1
    ]
    işlem: replace/all işlem "+" " + "
    işlem: replace/all işlem "-" " - "
    işlem: replace/all işlem "*" " * "
    işlem: replace/all işlem "/" " / "
    işlem: do işlem
    sonbelleğeEkle işlem
    yaz
]

sıfırla: function [][
    clear coz/isimler/1
    clear coz/isimler/2

    clear coz/işaretler/1
    clear coz/işaretler/2

    clear coz/işlevler/1
    clear coz/işlevler/2

    coz/durum: "doğru"

    tara read %coz.coz

    clear coz/sonbellek
    
    coz/satır: 0
]

kere: function[][
    coz/döngü: to integer! coz/sonbellek
]