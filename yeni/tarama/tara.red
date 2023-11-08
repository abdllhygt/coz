Red []

#include %satir.red
#include %dizgi.red
#include %kume.red
#include %sayi.red
#include %bosluk.red
#include %olsun.red

tara: function[t [string!]][
    parse t [
        any [
            _SATIR
            | _dizgi
            | _kume
            | _SAYI
            | _olsun
            | _bosluk
        ]
    ]
]