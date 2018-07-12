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
    !oku (
      -okunan: çöz -paketdön
      -paketdön: (değişkenata -atan1 -okunan)
      -atan2: rejoin[{"} (do -okunan) {"}]
    )
    | !işlem (
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
  [ (-paketdön: copy [] -hata: copy "")
    copy -dön !metin (-dön: do -dön)
    | !işlem
    | copy -dön !sayı
    | copy -değişken !değişken (
      either (değişkenvarmı -değişken)[
        -dön: to word! -değişken
      ][
        -hata: "var"
      ]
    )
  ]  !yaboş
  "yaz" !yaboş [ (if -hata = "var" [hataver/değişkenyok -değişken])
    "#dosya:" !yaboş {"} copy -hepsi [any hepsi] {"} ( -dönküme: copy []
        append/only -dönküme -dön
        append/only -dönküme -hepsi
        -paketdön: (paketle/işlev "yaz#dosya" -dönküme)
      )
    | "#pencere" (-paketdön: (paketle/işlev "yaz#pencere" -dön))
    | opt "#konsol" (-paketdön: (paketle/işlev "yaz" -dön))
  ]
]

!oku: [ (-paketdön: copy [] )
  "oku" !yaboş [
    "#dosya:" !yaboş {"} copy -hepsi [any hepsi] {"} (
        -paketdön: (paketle/işlev "oku#dosya" -hepsi)
      )
    | "#pencere" (-paketdön: (paketle/işlev "oku#pencere" ""))
    | opt "#konsol" (-paketdön: (paketle/işlev "oku" ""))
  ]
]

!hepsi: [
  "@"
  !son
  (
    -paketdön: (paketle/işlev "@" [])
  )
]

!komut: [
    !oku | !yaz
]

!karşılaştırma: [
  !eşitmi
  | !eşitdeğilmi
  | !büyükmü
  | !küçükmü
]

!isetek: [
  !karşılaştırma !boş "ise" !boş
  [if (-dön = "yanlış") thru end | [ !kapatma | !komut | !değişkenatama] ]
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
        | !komut (çöz -paketdön)
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
  !boş "kere" !boş [!kapatma | !hepsi | !komut | !değişkenatama] !son
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
    | !komut (append/only -paketler -paketdön)
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
