Red [
    title: "Coz"
    version: "0.3.0"
    author: "Abdullah Yiğiterol"
]

#include %veri.red
#include %malzeme.red
#include %tarama/tara.red

while [0 = 0] [
    tara ask ">> "
    probe coz
]

comment [either system/options/args/1 [
    gelen: read rejoin[%./ system/options/args/1]
    #include %yorumlayici.red
    ;do %yorumlayici.red
][
  kabukAktifMi: true
  #include %kabuk.red
  ;do %kabuk.red
]]