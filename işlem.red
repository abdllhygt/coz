Red[]

!işlem: [
    [
      copy -şey !sayı
      | copy -değişken !değişken (
        unless değişkenvarmı -değişken [
          hataver/değişkenyok -değişken
        ]
        either değişkensayımı -değişken [
          -şey: to string! (değişkendön -değişken)
        ][
          hataver/değişkensayıdeğil -değişken
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
      -işlem: copy replace/all -işlem "+" " + "
      -işlem: copy replace/all -işlem "-" " - "
      -işlem: copy replace/all -işlem "*" " * "
      -işlem: copy replace/all -işlem "/" " / "
      -dön: math load -işlem
    )
]
