Red [
  Title:   "COZ"
	Author:  "Abdullah Yiğiterol"
	License: {
		Şuan yok
	}
]

#include %zenity.red

#include %paketle.red
#include %çöz.red
#include %bellek.red
#include %parçalar.red
#include %cozut.red

either system/options/args/1 [
    gelen: read rejoin[%./ system/options/args/1]
    #include %yorumlayıcı.red
][
  #include %kabuk.red
]
