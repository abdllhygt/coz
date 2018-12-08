Red []

!boş: [some [space | tab]]
!yaboş: [any [space | tab]]
!tab: [tab]
!son: [any space [newline | end | "^M"]]
!küçükharf: charset "abcçdefgğhıijklmnoöprsştuüvyzwxqé"
!büyükharf: charset "ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZWXQÉ"
!harf: union !küçükharf !büyükharf
!hepsi: complement charset {"}
!rakam: charset "0123456789"
!numara: charset "123456789"
!nokta: "."
!sayı: [ copy -sayıdön ["0" | [!numara any !rakam any[!nokta !rakam]]] ]
!metin: [ copy -metindön [{"} any !hepsi {"}]]
!liste: ["[" !yaboş [!metin | !sayı] !yaboş any ["," !yaboş [!metin | !sayı] ] !yaboş "]"]
!değişken: [ copy -değişkendön [!harf any [!harf | !sayı]]]


do %karsilastirma.red
do %islem.red

!metinBirleştirme: [ (-metinler: copy "")
  !metin (
    append -metinler rejoin [-metindön " "]
  )
  !yaboş "+" !yaboş
  !metin (
    append -metinler rejoin [-metindön " "]
  ) any [
    !yaboş "+" !yaboş
    !metin (
      append -metinler rejoin [-metindön " "]
    )
  ]
  (
    -dön: copy "rejoin [" -metinler "]"
  )
]

!yaz: [
  [!değer | !değişken (-değer: -değişkendön)]
  !boş
  "yaz" (
    if (mold do -değer) = "true" [-değer: {"doğru"}]
    if (mold do -değer) = "false" [-değer: {"yanlış"}]
    -kaynak: rejoin["print " -değer]
  )
]

!oku: [
  "oku" (-kaynak: copy {ask {^[[31;1;1m>^[[0m ^[[32;1;3m}})
]

!dosyaOku: [
  copy -okunan [!metin | !değişken] !boş opt[["dan"|"den"] !boş]
  "oku" (
    -kaynak: rejoin["read to file! " -okunan]
  )
]

!pencereOku: [
  "pencere" !boş "oku" (
    either sistem = "Linux" [
      -kaynak: copy "zenity/entry"
    ][
      -kaynak: copy {view [ title "Coz"
        -girdi: field -tık: button "gir" [
          -dön: girdi/text
        ]
      ]}
    ]
  )
]

!pencereYaz: [
  "pencere" opt ["ye" | "den"] !boş copy -yazı [!değişken | !değer] !boş
  "yaz" (
    if (mold do -yazı) = "true" [-yazı: {"doğru"}]
    if (mold do -yazı) = "false" [-yazı: {"yanlış"}]
    either sistem = "Linux" [
      -kaynak: rejoin["zenity/info " -yazı] ;sayı yazmıyor
    ][
      -kaynak: rejoin[{view [ title "Coz" text } -yazı {]}]
    ]
  )
]

!dosyaYaz: [
  !metin !boş (-dosya: -metindön) opt[["ye"|"ya"] !boş]
  !değer !boş
  if -dön [-dön: {"doğru"}]
  unless -dön [-dön: {"yanlış"}]
  "yaz" (
    -kaynak: rejoin ["write %" -dosya " " -değer]
  )
]


!doğyan: [
  "doğru" (-kaynak: copy "true" -dön: copy "doğru")
  | "yanlış" (-kaynak: copy "false" -dön: copy "yanlış")
]

!değer: [ (-değer: copy "")
  !pencereOku (-değer: copy -kaynak)
  | !dosyaOku (-değer: copy -kaynak)
  | !oku (-değer: copy -kaynak)
  | !doğyan (-değer: copy -kaynak)
  | !metinBirleştirme (-değer: copy -dön)
  | !büyükmü (-değer: copy -kaynak)
  | !küçükmü (-değer: copy -kaynak)
  | !eşitmi (-değer: copy -kaynak)
  | !eşitdeğilmi (-değer: copy -kaynak)
  | !işlem (-değer: copy -kaynak)
  |
  copy -değer [
    !metin (-dön: copy -metindön)
    | !sayı (-dön: copy -sayıdön)
  ]
]

!değişkenAta: [
  copy -değişken !değişken ":"
  !yaboş
  [!değer (
    -kaynak: rejoin[-değişken ": " -değer]
    ;-dön: copy -değer
    parse mold -dön [
      [!yaboş [!işlem | !sayı | !metin] !boş ["="|"<"|">"] !boş [!işlem | !sayı | !metin] !yaboş
      (either (do -dön)[-dön: copy "doğru"][-dön: copy "yanlış"])
      ]
      | ["true" | "false"]
      (either (do -dön)[-dön: copy "doğru"][-dön: copy "yanlış"] )
    ]
  )
  |
    !değişken (
      -kaynak: rejoin[-değişken ": " -değişkendön]
      -dön: copy do -değişkendön
    )
  ]
]

!komut: [
  [
    !değişkenAta
    | !pencereYaz
    | !dosyaYaz
    | !yaz
    | !oku
    | !kapat
  ] !son
]

!kapat: [
  "kapat" (-kaynak: "quit")
]

!ise: [
  [
    !eşitmi (-koşulkaynak: copy -kaynak) !boş "ise"
    | !eşitdeğilmi (-koşulkaynak: copy -kaynak) !boş "ise"
    | !büyükmü (-koşulkaynak: copy -kaynak) !boş "ise"
    | !küçükmü (-koşulkaynak: copy -kaynak) !boş "ise"
  ] !yaboş "{"
  !komut (-komut: copy -kaynak
    -kaynak: copy rejoin ["if " -koşulkaynak " [" -komut "]"]
  )
  !yaboş "}"
]

!kere: [
  copy -sayı [!sayı | !değişken] !boş
  "kere" !yaboş "{" any !son !boş !komut (
    -kaynak: rejoin ["repeat i " -sayı "[" -kaynak "]"]
  )
  "}"
]

!isetek: [
  [
    !eşitmi (-koşulkaynak: copy -kaynak) !boş "ise"
    | !eşitdeğilmi (-koşulkaynak: copy -kaynak) !boş "ise"
    | !büyükmü (-koşulkaynak: copy -kaynak) !boş "ise"
    | !küçükmü (-koşulkaynak: copy -kaynak) !boş "ise"
  ] !boş
  !komut (-komut: copy -kaynak
    -kaynak: copy rejoin ["if " -koşulkaynak " [" -komut "]"]
  )
]

!keretek: [
  copy -sayı [!sayı | !değişken] !boş
  "kere" !boş !komut (
    -kaynak: rejoin ["repeat i " -sayı "[" -kaynak "]"]
  )
]

!ikentek: [
  [
    !eşitmi (-koşulkaynak: copy -kaynak) !boş "iken" !boş !komut (
        -kaynak: rejoin ["while [" -koşulkaynak "] [" -kaynak "]"]
      )
    | !büyükmü (-koşulkaynak: copy -kaynak) !boş "iken" !boş !komut (
        -kaynak: rejoin ["while [" -koşulkaynak "] [" -kaynak "]"]
      )
    | !küçükmü (-koşulkaynak: copy -kaynak) !boş "iken" !boş !komut (
        -kaynak: rejoin ["while [" -koşulkaynak "] [" -kaynak "]"]
      )
  ]
]
