Red[]

!işlem: [ (hata: copy [] -şey: copy "")
    [
      copy -şey !sayı
      | copy -değişken !değişken (
        unless değişkenvarmı -değişken [
          append hata "var"
          append hata -değişken
        ]
        either değişkensayımı -değişken [
          -şey: to string! (değişkendön -değişken)
        ][
          append hata "var"
          append hata -değişken
        ]
      )
    ]
    !yaboş (-işlem: copy -şey)[
      copy -şey "+"
      | copy -şey "-"
      | copy -şey "*"
      | copy -şey "/"
    ] (
      append -işlem -şey
    )
    !yaboş
    [
      copy -şey !sayı
      | copy -değişken !değişken (
        unless değişkenvarmı -değişken [
          hataver/değişkenyok -değişken
        ]
        either değişkensayımı -değişken [
          -şey: (değişkendön -değişken)
        ][
          hataver/değişkensayıdeğil -değişken
        ]
      )
    ]
    (append -işlem -şey)
    any [
      !yaboş [
        copy -şey "+"
        | copy -şey "-"
        | copy -şey "*"
        | copy -şey "/"
      ] (append -işlem -şey)
      !yaboş
      [
        copy -şey !sayı
        | copy -değişken !değişken (
          unless değişkenvarmı -değişken [
            hataver/değişkenyok -değişken
          ]
          either değişkensayımı -değişken [
            -şey: (değişkendön -değişken)
          ][
            hataver/değişkensayıdeğil -değişken
          ]
        )
      ]
      (append -işlem -şey)
    ]
    (
      if (length? hata) > 1 [hataver/değişkensayıdeğil hata/2]
      -işlem: copy replace/all -işlem "+" " + "
      -işlem: copy replace/all -işlem "-" " - "
      -işlem: copy replace/all -işlem "*" " * "
      -işlem: copy replace/all -işlem "/" " / "
      -dön: math load -işlem
    )
]
