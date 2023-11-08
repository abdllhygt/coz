Red []

#include %satir.red
#include %dizgi.red
#include %kume.red
#include %sayi.red
#include %bosluk.red
#include %olsun.red
#include %degisken.red

tara: function[t [string!]][
    parse t [
        any [
            _SATIR
            | _dizgi
            | _kume
            | _SAYI
            | _degisken
            | _olsun
            | _bosluk
        ]
    ]
]