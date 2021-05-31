Red []

blokAyır: function [b [block!]] [
    either (length? b) > 0 [
        forall b [if not last? b [b: next b insert b '|]]
        return b
    ][
        return false
    ]
]

sıraBul: function [i a [block!]] [
    return (length? a) - (length? find a i) + 1
]
