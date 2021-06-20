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