Red []

BLOK_AYIR: function [blok [block!] /local b] [
    b: copy blok
    either (length? b) > 0 [
        forall b [if not last? b [b: next b insert b '|]]
        return b
    ][
        return false
    ]
]

SIRA_BUL: function [i a [block!]] [
    return (length? a) - (length? find a i) + 1
]
