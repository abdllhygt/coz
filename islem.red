Red[]

!işlem: [ (hata: copy [] -şey: copy "")
    copy -şey !sayı
    !yaboş (-işlem: copy -şey)[
      "+" (-şey: copy " + ")
      | "-" (-şey: copy " - ")
      | "*" (-şey: copy " * ")
      | "/" (-şey: copy " / ")
    ] (
      append -işlem -şey
    )
    !yaboş
    [
      copy -şey !sayı
      | copy -şey !değişken (
        either (do rejoin["type? " -şey]) = integer! [

        ][
          either (do rejoin["type? " -şey]) = float![
          ][
            append hata "var"
            append hata -şey
          ]
        ]
      )
    ]
    (append -işlem -şey)
    any [
      !yaboş [
        "+" (-şey: copy " + ")
        | "-" (-şey: copy " - ")
        | "*" (-şey: copy " * ")
        | "/" (-şey: copy " / ")
      ] (append -işlem -şey)
      !yaboş
      [
        copy -şey !sayı
        | copy -şey !değişken (
          either (do rejoin["type? " -şey]) = integer! [
          ][
            either (do rejoin["type? " -şey]) = float![
            ][
              append hata "var"
              append hata -şey
            ]
          ]
        )
      ]
      (append -işlem -şey)
    ]
    (
      either (length? hata) > 1 [
        hataver/değişkensayıdeğil hata/2
        -kaynak: "0"
        -dön: 0
      ][
        -kaynak: rejoin["(math ["-işlem "])"]
        -dön: do -işlem
      ]
    )
]
