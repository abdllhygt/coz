Red[]

!eşitmi: [
  [
    !işlem (-karşın1: -kaynak)
    | copy -karşın1 !değişken
    | copy -karşın1 !metin
    | copy -karşın1 !sayı (-karşın1: to float! -karşın1)
  ]
  !yaboş "=" !yaboş
  [
    !işlem (-karşın2: -kaynak)
    | copy -karşın2 !değişken
    | copy -karşın2 !metin
    | copy -karşın2 !sayı (-karşın2: to float! -karşın2)
  ]
  (
    -kaynak: rejoin[-karşın1 " = " -karşın2]
    either (do -kaynak)[
      -dön: "doğru"
    ][
      -dön: "yanlış"
    ]
  )
]

!eşitdeğilmi: [
  [
    !işlem (-karşın1: -kaynak)
    | copy -karşın1 !değişken
    | copy -karşın1 !metin
    | copy -karşın1 !sayı (-karşın1: to float! -karşın1)
  ]
  !yaboş "!=" !yaboş
  [
    !işlem (-karşın2: -kaynak)
    | copy -karşın2 !değişken
    | copy -karşın2 !metin
    | copy -karşın2 !sayı (-karşın2: to float! -karşın2)
  ]
  (
    -kaynak: rejoin[-karşın1 " = " -karşın2]
    either (do -kaynak)[
      -dön: "doğru"
    ][
      -dön: "yanlış"
    ]
  )
]

!büyükmü: [
  [
    !işlem (-karşın1: -kaynak)
    | copy -karşın1 !değişken
    | !metin (-karşın1: -metindön)
    | copy -karşın1 !sayı (-karşın1: to float! -karşın1)
  ]
  !yaboş ">" !yaboş
  [
    !işlem (-karşın2: -kaynak)
    | copy -karşın2 !değişken
    | !metin (-karşın2: -metindön)
    | copy -karşın2 !sayı (-karşın2: to float! -karşın2)
  ]
  (
    -kaynak: rejoin[-karşın1 " > " -karşın2]
    either (do -kaynak)[
      -dön: "doğru"
    ][
      -dön: "yanlış"
    ]
  )
]

!küçükmü: [
    [
      !işlem (-karşın1: -kaynak)
      | copy -karşın1 !değişken
      | !metin (-karşın1: -metindön)
      | copy -karşın1 !sayı (-karşın1: to float! -karşın1)
    ]
    !yaboş "<" !yaboş
    [
      !işlem (-karşın2: -kaynak)
      | copy -karşın2 !değişken
      | !metin (-karşın2: -metindön)
      | copy -karşın2 !sayı (-karşın2: to float! -karşın2)
    ]
    (
      -kaynak: rejoin[-karşın1 " < " -karşın2]
      either (do -kaynak)[
        -dön: "doğru"
      ][
        -dön: "yanlış"
      ]
    )
]
