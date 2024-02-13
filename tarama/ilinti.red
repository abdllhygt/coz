Red []

_ilinti: [
    "(" copy c_i thru ");" ( ;son işareti bellekte yorum olarak algılıyor
        ilinti_: replace c_i ");" ""
        do ilinti_
        ilinti_: copy ""
    )
]