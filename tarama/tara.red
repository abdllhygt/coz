Red []

#include %satir.red
#include %dizgi.red
#include %kume.red
#include %sayi.red
#include %bosluk.red
#include %olsun.red
#include %degisken.red
#include %ilinti.red
#include %ata.red

kural_tablosu: [
    any [
        _SATIR
        | _kume
        | _olsun
        | _ata
        | _dizgi
        | _SAYI
        | _ilinti
        | _degisken
        | _bosluk
        | "kapat" (quit)
        | "!" (coz/sonbellek: copy reverse (remove reverse coz/sonbellek))
        | skip
    ]        
]

test_tablosu: [
    any [ (probe coz/sonbellek) ;buradayım
        _SATIR
        | _bosluk
        | _olsun
        | _kume
        | _dizgi
        | _degisken
        | skip
    ]
]

tara: function[t [string!]][
    parse t kural_tablosu
]

tara_test: function[t [string!]][
    parse
    ;parse-trace
    t test_tablosu
]