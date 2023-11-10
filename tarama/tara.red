Red []

#include %satir.red
#include %dizgi.red
#include %kume.red
#include %sayi.red
#include %bosluk.red
#include %olsun.red
#include %degisken.red
#include %ilinti.red

tara: function[t [string!]][
    parse t [
        any [
            _SATIR
            | _kume
            | _olsun
            | _dizgi
            | _SAYI
            | _ilintile
            | _degisken
            | _bosluk
            | "kapat" (quit)
            | "!" (coz/sonbellek: copy reverse (remove reverse coz/sonbellek))
            | skip
        ]
    ]
]