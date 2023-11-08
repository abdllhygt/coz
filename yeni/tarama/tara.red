Red []

#include %satir.red
#include %dizgi.red
#include %kume.red
#include %sayi.red
#include %bosluk.red

tara: function[t [string!]][
    parse t [
        any [
            _SATIR
            | _dizgi
            | _kume
            | _SAYI
            | _bosluk
        ]
    ]
]