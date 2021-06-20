Red []

hariç: complement charset {"[]}

!köprü: [
    {[} copy _içi some [hariç | !boşluk] {]}
    (
        do replace/all _içi " " ""
    )
]