Red [
  Title:   "COZ"
	Author:  "Abdullah Yiğiterol"
	License: {
		Şuan yok
	}
]

!boş: [some [space | tab]]
!yaboş: [any [space | tab]]
!tab: [tab]
!son: [any space [newline | end ]]
küçükharf: charset "abcçdefgğhıijklmnoöprsştuüvyzwxqé"
büyükharf: charset "ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZWXQÉ"
harf: union küçükharf büyükharf
hepsi: complement charset {"}
rakam: charset "0123456789"
numara: charset "123456789"
nokta: "."
!sayı: [ "0" | [numara any rakam any[nokta rakam]] ]
!metin: [{"} any hepsi {"}]
!liste: ["[" !yaboş [!metin | !sayı] !yaboş any ["," !yaboş [!metin | !sayı] ] !yaboş "]"]
!değişken: [harf any [harf | !sayı]]
!nsdeğişken: [harf any [harf | !sayı]]


#include %karşılaştırma.red
#include %işlem.red

!değişkenatama: [copy -atan1 !nsdeğişken !yaboş ":" !yaboş
  (-atan1: rejoin[-atan1] -paketdön: copy [])
  [
    !işlem (
      -paketdön: (paketle/değişkenata -atan1 -dön)
      -atan2: -dön
    )
    | copy -atan2 !değişken (
      either (değişkenvarmı -atan2)[
        -değeri: değişkendön -atan2
        -paketdön: (paketle/değişkenata -atan1 -değeri)
        -atan2: -değeri
      ][
        hataver/değişkenyok -atan2
      ]
    )
    | copy -atan2 !liste (
      -atan2: replace/all -atan2 "," " "
      -paketdön: (paketle/değişkenata -atan1 -atan2)
    )
    | copy -atan2 !metin (
      -paketdön: (paketle/değişkenata -atan1 -atan2)
      -atan2: -atan2
    )
    | copy -atan2 !sayı (
      -paketdön: (paketle/değişkenata -atan1 -atan2)
      -atan2: -atan2
    )
  ] !yaboş
  !son
]

!yaz: [
  [ (-paketdön: copy [])
    copy -dön !metin (-dön: do -dön)
    | copy -dön !sayı
    | !işlem
    | copy -değişken !değişken (
      either (değişkenvarmı -değişken)[
        -dön: to word! -değişken
      ][
        hataver/değişkenyok -değişken
      ]
    )
  ]  !yaboş
  "yaz" (-paketdön: (paketle/işlev "yaz" -dön))
]

!hepsi: [
  "@"
  !son
  (
    -paketdön: (paketle/işlev "@" [])
  )
]

!işlev: [
    !yaz
]

!karşılaştırma: [
  !eşitmi
  | !eşitdeğilmi
  | !büyükmü
  | !küçükmü
]

!isetek: [
  !karşılaştırma !boş "ise" !boş
  [if (-dön = "yanlış") thru end | [ !kapatma | !işlev | !değişkenatama] ]
  !son
  (
    çöz -paketdön
  )
]

!ise: [
  !karşılaştırma !boş "ise" !yaboş "{"
  [if (-dön = "yanlış")
    thru "}"
    | any [
        !kapatma (çöz -paketdön)
        | !hepsi (çöz -paketdön)
        | !değişkenatama (çöz -paketdön)
        | !işlev (çöz -paketdön)
        | !isetek
        | !keretek
        | !tab
        | !son
        | !boş
    ] "}"
  ]
]

!keretek: [
  [
    copy -miktar !sayı
    | copy -miktar !değişken (
      either (değişkensayımı -miktar)[
        -miktar: değişkendön -miktar
      ][
        -miktar: 0
      ]
    )
  ]
  !boş "kere" !boş [!kapatma | !hepsi | !işlev | !değişkenatama] !son
  (
    repeat i (to integer! -miktar)[
      çöz -paketdön
    ]
  )
]

!kere: [
  [
    copy -miktar !sayı
    | copy -miktar !değişken (
      either (değişkensayımı -miktar)[
        -miktar: değişkendön -miktar
      ][
        -miktar: 0
      ]
    )
  ]
  !boş "kere" !yaboş "{"
  (-paketler: copy [])
  any [
    !kapatma (append/only -paketler -paketdön)
    | !hepsi (append/only -paketler -paketdön)
    | !değişkenatama (append/only -paketler -paketdön)
    | !işlev (append/only -paketler -paketdön)
    | !tab
    | !son
    | !boş
  ]
  "}"
  (
    repeat i (to integer! -miktar)[
      foreach p -paketler [
        çöz p
      ]
    ]
  )
]

!kapatma: ["kapat" (-paketdön: (paketle/işlev "kapat" []))]
