Red[]

!eşitmi: [
  [
    !işlem (-karşın1: -dön)
    | copy -değişken !değişken (
      either (değişkenvarmı -değişken)[
        -karşın1: (değişkendön -değişken)
      ][
        hataver/değişkenyok -değişken
      ]
    )
    | copy -karşın1 !metin (-karşın1: do -karşın1)
    | copy -karşın1 !sayı (-karşın1: to float! -karşın1)
  ]
  !yaboş "=" !yaboş
  [
    !işlem (-karşın2: -dön)
    | copy -değişken !değişken (
      either (değişkenvarmı -değişken)[
        -karşın2: (değişkendön -değişken)
      ][
        hataver/değişkenyok -değişken
      ]
    )
    | copy -karşın2 !metin (-karşın2: do -karşın2)
    | copy -karşın2 !sayı (-karşın2: to float! -karşın2)
  ]
  (
    either -karşın1 = -karşın2 [
      -dön: copy "doğru"
    ][
      -dön: copy "yanlış"
    ]
  )
]

!eşitdeğilmi: [
  [
    !işlem (-karşın1: -dön)
    | copy -değişken !değişken (
      either (değişkenvarmı -değişken)[
        -karşın1: (değişkendön -değişken)
      ][
        hataver/değişkenyok -değişken
      ]
    )
    | copy -karşın1 !metin (-karşın1: do -karşın1)
    | copy -karşın1 !sayı (-karşın1: to float! -karşın1)
  ]
  !yaboş "!=" !yaboş
  [
    !işlem (-karşın2: -dön)
    | copy -değişken !değişken (
      either (değişkenvarmı -değişken)[
        -karşın2: (değişkendön -değişken)
      ][
        hataver/değişkenyok -değişken
      ]
    )
    | copy -karşın2 !metin (-karşın2: do -karşın2)
    | copy -karşın2 !sayı (-karşın2: to float! -karşın2)
  ]
  (
    either -karşın1 = -karşın2 [
      -dön: copy "yanlış"
    ][
      -dön: copy "doğru"
    ]
  )
]

!büyükmü: [
  [
    !işlem (-karşın1: -dön)
    | copy -değişken !değişken (
      either (değişkenvarmı -değişken)[
        -karşın1: (değişkendön -değişken)
        unless değişkensayımı -değişken[
          print değişkentipi -değişken
          hataver/değişkensayıdeğil -değişken
        ]
      ][
        hataver/değişkenyok -değişken
      ]
    )
    | copy -karşın1 !metin (hataver/büyükküçüksayıolmalı)
    | copy -karşın1 !sayı (-karşın1: to float! -karşın1)
  ]
  !yaboş ">" !yaboş
  [
    !işlem (-karşın2: -dön)
    | copy -değişken !değişken (
      either (değişkenvarmı -değişken)[
        -karşın2: (değişkendön -değişken)
        unless (değişkentipi -değişken) = "sayı"[
          hataver/değişkensayıdeğil -değişken
        ]
      ][
        hataver/değişkenyok -değişken
      ]
    )
    | copy -karşın2 !metin (hataver/büyükküçüksayıolmalı)
    | copy -karşın2 !sayı (-karşın2: to float! -karşın2)
  ]
  (
    either -karşın1 > -karşın2 [
      -dön: copy "doğru"
    ][
      -dön: copy "yanlış"
    ]
  )
]

!küçükmü: [
  [
    !işlem (-karşın1: -dön)
    | copy -değişken !değişken (
      either (değişkenvarmı -değişken)[
        -karşın1: (değişkendön -değişken)
        unless değişkensayımı -değişken[
          print değişkentipi -değişken
          hataver/değişkensayıdeğil -değişken
        ]
      ][
        hataver/değişkenyok -değişken
      ]
    )
    | copy -karşın1 !metin (hataver/büyükküçüksayıolmalı)
    | copy -karşın1 !sayı (-karşın1: to float! -karşın1)
  ]
  !yaboş "<" !yaboş
  [
    !işlem (-karşın2: -dön)
    | copy -değişken !değişken (
      either (değişkenvarmı -değişken)[
        -karşın2: (değişkendön -değişken)
        unless (değişkentipi -değişken) = "sayı"[
          hataver/değişkensayıdeğil -değişken
        ]
      ][
        hataver/değişkenyok -değişken
      ]
    )
    | copy -karşın2 !metin (hataver/büyükküçüksayıolmalı)
    | copy -karşın2 !sayı (-karşın2: to float! -karşın2)
  ]
  (
    either -karşın1 < -karşın2 [
      -dön: copy "doğru"
    ][
      -dön: copy "yanlış"
    ]
  )
]
