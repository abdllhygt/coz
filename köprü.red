Red []

yaz: function [][
    remove coz/sonbellek
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
    remove coz/sonbellek
    if (type? coz/sonbellek/2) = block! [
        sıra: sıraBul coz/sonbellek/2/1 coz/isimler/1 print sıra
        either (type? coz/sonbellek/1) = block! [
            coz/isimler/2/(sıra): coz/sonbellek/1/2
        ][
            coz/isimler/2/(sıra): coz/sonbellek/1
        ]
    ]
]