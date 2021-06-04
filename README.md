# Coz
Türkçe sözdizimli programlama dili

İlk program:
```
"merhaba" yaz
```


Örnek program:
```
    Kedinin Adı

Köpeğin adı "kedinin adı" olsun. Köpeğin adı kedinin adı ise kedinin adı "başka bir şey" olsun.

    "şimdi nedir?" {yaz}

Kedinin adı şimdi nedir?
```

Örnek programın açıklaması:

İlk satırda `kedinin adı` diye bir isim (değişken) oluşturduk. İsim oluşturmak için yazmak yeterli; işaret veya başka bir şeye gerek yok. Her ismin ilk değeri kendisidir, yani `kedinin adı` yazdığımızda değeri de aynısı oluyor. Daha sonra `köpeğin adı` diye bir isim (değişken) oluşturduk, bunun için yorumlayıcı tırnak işaretine kadar devam edip durdu. `"kedinin adı"` diye anlık bir metin döndürdük. `"Köpeğin adı"` ve `"kedinin adı"` metinleri geçici hafızaya kaydedildi. `coz.coz` dosyasında bulunan `olsun` işlevi geçici hafızadaki değeri isme atadı. Diğer cümlede `köpeğin adı` ve `kedinin adı` isimleri değerlerini döndürdü, `köpeğin adı` isminin değeri `"kedinin adı"` idi, yine `kedinin adı` ismi kendi ismiyle oluşturulmuştu. (`coz.coz`'daki) `ise` geçiçi hafızadaki son iki değeri karşılaştırdı ve aynı oldukları için durumu `doğru` yaptı. Durum yanlış olsaydı cümle bitene kadar(nokta koyana kadar)ki (çoğu) komutlar çalışmayacaktı. `ise`'den sonraki `isim`, metin(`an`) ve `işlev` çalıştı. Daha sonra "şimdi nedir?" isminde bir `işlev` tanımladık, içerisine `coz.coz`'daki `yaz` işlevini koyduk. `kedinin adı` ismi ve `şimdi nedir?` işlevi beraber `kedinin adı`nın değeri olan "başka bir şey" yazdırdı.

Diğer örnek programlara örnekler klasöründen bakabilirsiniz.

Programı çalıştırmak için 32bit curl gerekli olabilir:
```
dpkg --add-architecture i386
apt-get update
apt-get install libc6:i386 libcurl4:i386 \
libgtk-3-0:i386 libgdk-pixbuf2.0-0:i386
```
(ubuntu 18.04 üstü)

Programlarınızı şu şekilde çalıştırabilirsiniz:

```
coz programım.coz
```

Veya direkt `coz` şeklinde başlatıp denemeler yapın. Testi programı yazdığımız programdaki hafızayı takip ediyor, öğrenmek ve hata tespit etmek için daha kullanışlıdır.

# Nasıl derlerim?

Red dili `ask` işlevini derlerken sorun çıkardığı için Red'in kaynak kodundaki input.red'e ihtiyacımız olacak. Klasör konumunu `coz.red`'deki `#include ....input.red` yoluna göre ayarlayın. Komutu girerek derleyin:

```
./red -r coz.red
```