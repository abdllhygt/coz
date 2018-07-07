Red [
  Title:   "COZ"
	Author:  "Abdullah Yiğiterol"
	License: {
		Şuan yok
	}
]

!boş: [opt space]
!yaboş: [any space]
!son: [any space [newline | end ]]
küçükharf: charset "abcçdefgğhıijklmnoöprsştuüvyzwxqé"
büyükharf: charset "ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZWXQÉ"
harf: union küçükharf büyükharf
hepsi: complement charset {"}
rakam: charset "0123456789"
numara: charset "123456789"
nokta: "."
!sayı: [numara any rakam any[nokta rakam]]
!metin: [{"} any hepsi {"}]
!liste: ["[" !yaboş [!metin | !sayı] !yaboş any ["," !yaboş [!metin | !sayı] ] !yaboş "]"]
!değişken: [harf any [harf | !sayı]]

!işlem: [
    copy -işlem [
      !işl: [
        !sayı !yaboş [
          "+"
          | "-"
          | "*"
          | "/"
        ]
        !yaboş !sayı
        any [
          !yaboş [
            "+"
            | "-"
            | "*"
            | "/"
          ]
          !yaboş [!sayı | !işl]
        ]
      ]
    ]
    (
      -işlem: copy replace/all -işlem "+" " + "
      -işlem: copy replace/all -işlem "-" " - "
      -işlem: copy replace/all -işlem "*" " * "
      -işlem: copy replace/all -işlem "/" " / "
      -dön: math load -işlem
    )
]

!değişkenatama: [copy -atan1 !değişken !yaboş ":" !yaboş
  [
    copy -atan2 !değişken (
      either (değişkenvarmı -atan2)[
        -değeri: değişkendön -atan2
        değişkenata -atan1 -değeri
        -atan2: -değeri
      ][
        hataver/değişkenyok -atan2
      ]
    )
    | copy -atan2 !liste (
      -atan2: replace/all -atan2 "," " "
      değişkenata -atan1 -atan2
    )
    | copy -atan2 !metin (
      değişkenata -atan1 -atan2
    )
    | !işlem (
      değişkenata -atan1 -dön
      -atan2: -dön
    )
    | copy -atan2 !sayı (
      değişkenata -atan1 -atan2
    )
  ] !yaboş
  !son
  (-dön: -atan2)
]

!yaz: [
  [
    copy -değişken !değişken (
      either (değişkenvarmı -değişken)[
        -dön: değişkendön -değişken
      ][
        hataver/değişkenyok -değişken
      ]
    )
    | copy -dön !metin (-dön: do -dön)
    | !işlem
    | copy -dön !sayı
  ] !yaboş
  "yaz" (-paketdön: (paketle/işlev "yaz" -dön)) !yaboş
  !son
]

!değişkenler: [
  "@"
  !son
  (
    -paketdön: (paketle/işlev "@" [])
  )
]
!işlev: [
  !yaz | !değişkenler
]

do %karşılaştırma.red
!karşılaştırma: [
  !eşitmi
  | !eşitdeğilmi
  | !büyükmü
  | !küçükmü
]

!isetek: [
  !karşılaştırma !boş "ise" !boş [if (-dön = "doğru") !işlev | ] !son
]

!saytek: [
  copy -sayı !sayı !boş "say" !boş !işlev !son
  (
    repeat i (to integer! -sayı)[
      print "hey"
    ]
  )
]

!kapatma: ["kapat" !yaboş !son (quit)]
