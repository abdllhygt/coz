Red []

tirnak: charset {"'}
hepsi: complement tirnak

numara: charset [#"0" - #"9"]
sayi: [some numara]
matOp: charset "+-*/"
karOp: ["=" | "!=" | "<" | ">"]

bosluk: [some [space | tab]]
yabosluk: [any [space | tab]]
satır: [newline | end]

bHarf: charset "ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZXWQ"
kHarf: charset "abcçdefgğhıijklmnoöprsştuüvyzxwq"
harf: charset rejoin[bHarf kHarf]
metin: [tirnak any hepsi tirnak]

SDyaz: [
    [ copy text metin (take text take/last text)
    | SDislem
    | copy text sayi ]
    bosluk "yaz" (print text)
]

SDislem: [
    copy text [sayi yabosluk matOp yabosluk sayi]  (
        parse text [
            any [
                change copy textEs matOp (rejoin [space textEs space])
            | skip
            ]
        ]
        text: math load text
    )
]

SDkarsilastirma: [
    copy text [[SDislem | sayi] yabosluk karOp yabosluk [SDislem | sayi]] (
        parse text [
            any [
                change copy textEs matOp (rejoin [space textEs space])
            | skip
            ]
        ]
        parse text [
            any [
                change copy textEs karOp (rejoin [space textEs space])
            | skip
            ]
        ]
        text: do load text
    )
]

SDise: [ (git: [none])
    SDkarsilastirma bosluk "ise" [if (text = yes) bosluk SDyaz satır | to satır]
]

SDkapat: [
    "kapat" (print "== KAPANDI" quit)
]
