Red [
  Title:   "COZ"
	Author:  "Abdullah Yiğiterol"
	License: {
		Şuan yok
	}
  Needs: 'View
]

;#include %environment/console/CLI/input.red
;#include %dynamic-ask.red

#include %zenity.red
#include %parcalar.red
#include %cozut.red

;do %zenity.red

;do %paketle.red
;do %coez.red
;do %bellek.red
;do %parcalar.red
;do %cozut.red

kabukAktifMi: false
either system/options/args/1 [
    gelen: read rejoin[%./ system/options/args/1]
    #include %yorumlayici.red
    ;do %yorumlayici.red
][
  kabukAktifMi: true
  #include %kabuk.red
  ;do %kabuk.red
]
