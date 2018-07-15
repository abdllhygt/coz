Red [
  Title:   "COZ"
	Author:  "Abdullah Yiğiterol"
	License: {
		Şuan yok
	}
  Needs: 'View
]

#include %zenity.red

#include %paketle.red
#include %coez.red
#include %bellek.red
#include %parcalar.red
#include %cozut.red

kabukAktifMi: false
either system/options/args [
    gelen: read rejoin[%./ system/options/args/1]
    #include %yorumlayici.red
][
  kabukAktifMi: true
  #include %kabuk.red
]
