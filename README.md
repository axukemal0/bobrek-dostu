# Böbrek Dostu

Kronik böbrek hastalığı olan **tek bir kişi için**, tamamen telefonda
çalışan **Android + iOS** takip uygulaması. Giriş/üyelik yok, sunucu yok,
mağazada değil. Tüm veriler cihazda **şifreli** (SQLCipher) tutulur.

> **Bu uygulama tıbbi tavsiye değildir, klinik karar kullanıcıya aittir.**

Kullanıcı hekim olduğu için uygulamanın tüm klinik eşikleri ve hedefleri
**serbestçe düzenlenebilir**; uygulama hiçbir alt/üst sınır dayatmaz.
Varsayılanlar kılavuz referanslarıdır ve her değerin yanında kaynağı,
yılı ve **doğrulama durumu** yazar.

---

## 1. Hızlı başlangıç

### 1.1 Android: derlenmiş APK'yı telefona atmak

Mimariye göre ayrı APK'lar üretilir (`--split-per-abi`). 2017 sonrası
tüm telefonlar **arm64**'tür.

| Dosya | Boyut | Ne zaman |
|---|---|---|
| `app-arm64-v8a-release.apk` | **31 MB** | **Önerilen.** Günlük kullanım. |
| `app-arm64-v8a-debug.apk` | 117 MB | Geliştirme/hata ayıklama. |
| `app-armeabi-v7a-release.apk` | 28 MB | 2017 öncesi 32-bit cihaz. |
| `app-x86_64-release.apk` | 33 MB | Emülatör. |

```bash
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

ADB yoksa APK dosyasını telefona kopyalayıp dosya yöneticisinden
açmak da yeterli (telefonda "bilinmeyen kaynaklara izin ver" gerekir).

> Release APK kendi kendini imzalar (debug anahtarı). Mağazaya
> yüklenmeyeceği için ayrı bir imza anahtarı tanımlanmadı.

**Doğrulanan APK özellikleri:**

- Paket: `com.bobrekdostu.bobrek_dostu`, sürüm 1.0.0 (1)
- Uygulama adı: **Böbrek Dostu** (Türkçe karakterlerle)
- minSdk 26, targetSdk 36, compileSdk 36
- 21 izin manifest'te (konum, kamera, mikrofon, bildirim, tam alarm,
  SMS, aktivite tanıma, 7 Health Connect OKUMA izni)
- Uyarlanabilir (adaptive) launcher ikonu + Material You tek renk katmanı

31 MB'ın dağılımı (arm64 release):

| Parça | Boyut | Not |
|---|---|---|
| `libflutter.so` | 10,8 MB | Flutter motoru — sabit maliyet |
| `libapp.so` | 12,2 MB | Derlenmiş Dart kodu |
| `libsqlcipher.so` | 4,9 MB | Şifreli veritabanı — vazgeçilmez |
| `classes.dex` | 4,4 MB | Java/Kotlin katmanı |
| varlıklar | 0,4 MB | yazı tipleri + besin verisi |

### 1.1b iOS: iPhone'a kurmak ve OTOMATİK GÜNCELLEME

Apple, App Store dışından kurulan uygulamaların kendi kendini
güncellemesine izin vermez. iPhone'da gerçek otomatik güncellemenin tek
yolu **TestFlight**'tır. İki seçenek var:

#### A) TestFlight — otomatik güncelleme (önerilen)

Gereken: **Apple Developer Program üyeliği** (yılda 99 USD). Bu olmadan
otomatik güncelleme mümkün değil; Apple'ın kuralı, aşılamıyor.

Kurulum bir kez yapılır:

1. [developer.apple.com](https://developer.apple.com/programs/) üzerinden
   üye ol.
2. App Store Connect'te **App Store Connect API anahtarı** oluştur
   (Users and Access → Integrations → App Store Connect API → `+`).
   Rol: **App Manager**. İnen `.p8` dosyası bir kez indirilir, sakla.
3. App Store Connect'te `com.bobrekdostu.bobrekDostu` kimliğiyle yeni bir
   uygulama kaydı aç.
4. GitHub deposunda **Settings → Secrets and variables → Actions** altına
   dört gizli değer ekle:

   | Ad | Nereden |
   |---|---|
   | `ASC_KEY_ID` | Anahtarın kimliği (10 karakter) |
   | `ASC_ISSUER_ID` | Aynı sayfadaki "Issuer ID" |
   | `ASC_PRIVATE_KEY` | `.p8` dosyasının İÇERİĞİ (tamamı, satır sonlarıyla) |
   | `ASC_TEAM_ID` | Membership sayfasındaki "Team ID" |

5. iPhone'a **TestFlight** uygulamasını kur, Apple kimliğinle gir,
   kendini test kullanıcısı olarak ekle.
6. TestFlight → Böbrek Dostu → **Automatic Updates: On**.

Bundan sonra yeni sürüm yayınlamak tek komut:

```bash
git tag v1.0.1 && git push origin v1.0.1
```

GitHub Actions derler, TestFlight'a yükler, iPhone güncellemeyi
kendiliğinden indirir. Android APK'ları da aynı çalışmada üretilip
GitHub Release'e eklenir.

> Gizli değerler tanımlı değilse iOS işi sessizce atlanır, Android
> tarafı çalışmaya devam eder.

#### B) Ücretsiz Apple kimliğiyle yan yükleme (otomatik güncelleme YOK)

Ücretsiz bir Apple kimliğiyle de kurulabilir ama imza **7 günde bir
dolar** ve uygulama açılmaz olur; her hafta Xcode'a takıp yeniden
yüklemek gerekir. Otomatik güncelleme olmaz.

1. Xcode'da `ios/Runner.xcworkspace` açılır.
2. Runner hedefi → **Signing & Capabilities** → Team olarak kendi Apple
   kimliğin seçilir.
3. iPhone USB ile bağlanır, hedef olarak seçilir, çalıştırılır.
4. iPhone'da **Ayarlar → Genel → VPN ve Cihaz Yönetimi** altından
   geliştiriciye güven verilir.

> HealthKit'in gerçek cihazda çalışması için de bu adımda bir Apple
> hesabı seçilmiş olması gerekir.

#### Simülatörde denemek (hesap gerekmez)

```bash
flutter build ios --debug --simulator
```

```bash
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
```

iOS tarafında kurulu olanlar:

- Dağıtım hedefi **iOS 15.5**
- Tüm izin açıklamaları **Türkçe** (`ios/Runner/Info.plist`)
- `Runner.entitlements`: Keychain erişimi (şifreleme anahtarı burada
  durur) ve HealthKit **okuma**
- Uygulama ikonu açık/karanlık/tinted üç varyantıyla
- Soldan kaydırarak geri gitme jesti çalışır

### 1.1c Android: uygulama içi güncelleme

Android'de uygulama yeni sürümü kendi görür: Ayarlar → **Güncelleme**
kartı GitHub Release'leri denetler, APK'yı indirir ve sistemin kurulum
ekranını açar. Kurulumu sistem yapar, onayı kullanıcı verir.

İlk kurulumda telefon "bilinmeyen kaynaklardan uygulama yükleme" izni
ister; uygulama kullanıcıyı doğrudan ilgili ayar ekranına götürür.

---

## 1.5 İkinci turda yapılanlar (amblem, arayüz, iOS, barkod/etiket/fotoğraf)

### Amblem — tek logo, tek kaynak

Yeni amblem **"ölçülü kap"**: bir böbrek silueti aynı zamanda ölçekli bir
kaptır. İçindeki yeşil sıvı günün kalan bütçesi, üstündeki ince altın
çizgi ise kullanıcının kendi belirlediği sınır — yani uygulamanın
çekirdek fikri. Malzemesi uygulamanın kendi dili: yumuşak kabartma
gölgesi, cam parıltısı, tek altın vurgu.

Farklı yerlerde farklı logo **olamaz**, çünkü hepsi tek bir boyayıcıdan
çıkıyor: `lib/core/brand/brand_mark.dart`. Android launcher ikonu,
iOS AppIcon, bildirim ikonu, açılış ekranı ve uygulama içindeki işaret
`tools/gen_icons.dart` ile **aynı `BrandMarkPainter`'dan** üretilir:

```bash
flutter test tools/gen_icons.dart
```

Boyuta göre ayrıntı düşer (16 px'te yalnız siluet, 64 px üstünde sıvı +
altın çizgi + parıltı) ama biçim aynı kalır — aynı logonun küçük ölçek
sürümüdür, başka bir logo değil.

Açılış animasyonu da aynı geometriyi kullanır: siluet yerine oturur,
kap dolar, sınır çizgisi soldan sağa çizilir.

### Tasarım dili — üç kademeli derinlik

Önceden her kart hem kabartmalı hem buzlu camdı; hiçbir şey öne çıkmıyordu
ve düz krem zemin üzerinde **görünmeyen** bir bulanıklık için her karede
GPU harcanıyordu. Artık üç kademe var, her birinin bir işi var
(`lib/core/theme/neumorphic.dart`, `enum Surface`):

| Kademe | Ne zaman | Nasıl |
|---|---|---|
| `flat` | İçerik kartları | Tonlu dolgu, saç teli kenar, gölge yok |
| `raised` | Basılabilen yüzeyler | Yumuşak çift gölge |
| `floating` | Üstte duran kabuk | **Gerçek** bulanıklık (`GlassBar`) |

Buzlu cam artık yalnız **tek yerde**: alt gezinme çubuğu. Orada anlamlı,
çünkü içerik gerçekten arkasından akıyor (`extendBody: true`).

Tipografi kuralı tekleşti: **serif yalnız başlıklarda**. Ölçüm değerleri
artık tablo rakamlı Nunito ile yazılıyor — başlık yüzü veride hem
okunurluğu düşürüyor hem sütunlarda hizalanmıyordu.

### Akıcılık

Kullanıcı "yeterince akıcı değil" dedi; yapısal sebepler şunlardı:

1. **Açılış 2,4 saniye bekletiyordu.** Animasyon bitmeden veritabanına
   gidilmiyordu. Artık hazırlık animasyonla **paralel** yürür ve animasyon
   1,1 saniye: toplam süre `max(animasyon, hazırlık)`.
2. **Her kart ayrı animasyonla içeri kayıyordu.** Sayfa başına N adet
   `AnimationController` + `Opacity` katmanı. Kaldırıldı; içerik anında
   gelir.
3. **13 kart `BackdropFilter` kullanıyordu.** Her biri tam bir GPU
   geçişi. Biri hariç hepsi kaldırıldı.
4. **Amblem her karede `Path.computeMetrics()` çağırıyordu.** Artık yol
   bir kez hesaplanıp saklanıyor.
5. Dokunma geri bildirimi `setState` yerine denetleyiciyle sürülüyor.
6. Grafik ve halkalar `RepaintBoundary` içinde.
7. Geçiş süreleri 320 ms → 210 ms.

### Boyut

| Değişiklik | Kazanç |
|---|---|
| Barkod modeli APK'dan çıkarıldı (ayrık ML Kit) | ~5,5 MB |
| `google_mlkit_text_recognition` kaldırıldı (yerine yerel OCR) | ML Kit pod/AAR yükü |
| Yazı tipleri Latin+Türkçe kümesine indirgendi | 972 KB → 252 KB |
| Kullanılmayan Playfair ağırlıkları silindi | 390 KB |
| `--split-per-abi` | Tek mimari başına ~60% |

arm64 release APK **31 MB**, debug 132 MB → **117 MB**.

### Barkod / etiket / yemek fotoğrafı — yeniden kuruldu

**Barkod: fotoğraf değil, canlı tarama.** Eskiden fotoğraf çekilip o tek
kare taranıyordu; barkod net çıkmazsa okunmuyordu. Artık kamera akışı
sürekli taranır (`lib/features/nutrition/barcode_scanner_view.dart`):
hedef çerçevesi, fener düğmesi, dokunarak odak, okunduğunda titreşim.
Okunmazsa kodu elle yazma ve galerideki fotoğraftan okuma yolları var.

**Etiket okuma: gerçek bir besin tablosu çözümleyicisi.** Eski kod
`anahtar[^0-9]{0,20}(sayı)` kalıbıyla sayı arıyordu ve böbrek hastası
için **en kritik üç alanda sessizce yanlış** sonuç veriyordu:

1. **Tuz.** Türkiye'deki etiketler "Sodyum" değil **"Tuz"** yazar. Eski
   kalıp "sodyum" arıyor, bulamıyor, sodyum alanını **boş** bırakıyordu —
   yani günün en önemli kısıtı hiç okunmuyordu.
   Yeni: Tuz (g) × 400 = sodyum (mg), türetme ekranda yazılı.
2. **Enerji.** Etiket "1850 kJ / 442 kcal" yazar; eski kalıp **1850**'yi
   kcal diye kaydediyordu (~4,2 kat fazla). Yeni: kcal tercih edilir,
   yoksa kJ ÷ 4,184 ve bu belirtilir.
3. **Sütun.** AB/TR etiketlerinde "100 g'da" ve "porsiyonda" diye iki
   sütun vardır. Eski kalıp hangisi önce geldiyse onu alıyor, 100 g
   sanıp porsiyona göre ölçekliyordu — sonuç iki katına çıkabiliyor ya
   da yarıya inebiliyordu. Yeni: sütun tanınır, gerekirse 100 g'a
   çevrilir, hangi sütundan okunduğu ekranda yazar.

Her alan için **birim, sütun ve güven** ayrı ayrı raporlanır; potasyum
ve fosfor Türkiye'de genelde etikete yazılmadığı için "okunamadı" diye
açıkça belirtilir (sıfır sayılmaz).
Çözümleyici saf Dart: `lib/features/nutrition/nutrition_label_parser.dart`,
18 testle doğrulanmış.

**Yemek fotoğrafı: kalem kalem.** Bir tabakta genelde tek yemek olmaz
(pilav + tavuk + salata + ekmek). Tek toplamda birleştirmek kullanıcıyı
çaresiz bırakıyordu — "pilavın yarısını yedim" diyemiyordu. Artık model
JSON ile kalem kalem yanıt verir; her kalem ayrı düzenlenir, porsiyonu
değişince o kalemin tüm değerleri orantılı güncellenir, yenmeyen kalem
listeden çıkarılır, her kalem veritabanına **ayrı** kaydedilir.
Eski düz metin biçimi yedek olarak korundu.

### OCR: ML Kit yerine yerel çerçeveler

`google_mlkit_text_recognition` kaldırıldı. Sebebi hem işlevsel hem boyut:

- Paket iOS'ta GoogleMLKit pod'unu getiriyor, GoogleMLKit ise simülatör
  için **arm64 dilimi yayınlamıyor**. Apple Silicon'da iOS 26+
  simülatörleri arm64 zorunlu kıldığından uygulama x86_64'e düşüyordu ve
  **simülatörde hiç çalıştırılamıyordu**.
- Android'de modeli APK'ya gömüyordu.

Yerine yerel kod:

- **iOS** → Apple Vision (`ios/Runner/TextRecognition.swift`)
- **Android** → ayrık ML Kit, Play hizmetleri üzerinden
  (`MainActivity.kt`)
- Ortak Dart arayüzü: `lib/core/services/text_recognition.dart`

Görseller her iki platformda da cihazdan **çıkmaz**.

### iOS'ta çalışmayan tek şey: otomatik SMS

iOS, bir uygulamanın kullanıcı onayı olmadan SMS göndermesine işletim
sistemi düzeyinde izin **vermez**. Bu bir eksik değil, Apple'ın kuralı ve
aşılamaz. iPhone'da eşik aşımında ve acil düğmesinde mesaj hazır hâlde
Mesajlar'da açılır; gönder tuşuna kullanıcı basar. Ayarlardaki
"otomatik SMS" anahtarı iPhone'da gösterilmez, yerine bu durum yazılır.
Android'de davranış değişmedi.

---

## 1.6 Üçüncü turda yapılanlar (tema hatası, bildirimler, renk, güncelleme)

### Tema hatası — düzeltildi

Karanlıktan aydınlığa geçince uygulama ancak kapatılıp açılınca
değişiyordu. Sebep: palet, sistem temasını bir `Provider` gövdesinde
**tek seferlik** okuyordu (`PlatformDispatcher.instance.platformBrightness`).
Bu sabit bir okumadır; Riverpod'un onu yeniden hesaplaması için bir sebebi
yoktur. Kök widget'taki `didChangePlatformBrightness` yeniden çizim
tetikliyordu ama provider önbellekten aynı paleti döndürdüğü için hiçbir
şey değişmiyordu.

Artık sistem teması `systemBrightnessProvider` ile **dinleniyor**
(`WidgetsBindingObserver`), palet de onu izliyor. Cihazda doğrulandı:
uygulama açıkken sistem temasını değiştirince anında dönüyor.
`test/theme_reactivity_test.dart` bunu üç testle koruyor.

### Bildirimler — dört gerçek hata

1. **iOS'ta bildirim HİÇ çalışmıyordu.** `initialize` çağrısına yalnız
   `android:` ayarı veriliyordu; `DarwinInitializationSettings` olmadan
   eklenti iOS'ta hiç başlatılmıyor. Eklendi.
2. **Uygulama açıkken bildirim yutuluyordu (iOS).** `AppDelegate` içinde
   `UNUserNotificationCenter.current().delegate` atanmamıştı. Eklendi.
3. **Android ikonu beyaz lekeydi.** Bildirim ikonu olarak renkli
   `@mipmap/ic_launcher` veriliyordu; Android bildirim ikonunu maskeler ve
   renkli bir görsel tanınmaz hâle gelir. Amblemden üretilen tek renk
   `@drawable/ic_notification` kullanılıyor artık (zaten üretiliyordu ama
   hiç bağlanmamıştı).
4. **Tam zamanlı alarm izni yoksa planlama ÇÖKÜYORDU.** Koddaki yorum
   "Android daha gevşek bir modla karşılar" diyordu; gerçekte
   `zonedSchedule` `exact_alarms_not_permitted` ile **fırlatıyor** ve
   hatırlatma hiç kurulmuyordu. Artık yakalanıp `inexactAllowWhileIdle`
   moduna düşülüyor ve İlaçlar ekranında "hatırlatmalar birkaç dakika
   kayabilir" uyarısı gösteriliyor.

Ayrıca iOS'ta ilaç ve randevu bildirimleri **Time Sensitive** olarak
işaretleniyor (odak modlarını delebilsin diye).

### Renk — "aşırı renksiz" eleştirisine karşılık

Önceki turda sadeleştirirken renk fazla kaçmıştı. Ama çözüm rastgele renk
serpmek değil: uygulama **beş ayrı besin bütçesi** tutuyor ve hepsi tek
yeşille çizildiğinde ekranı tarayan biri potasyumu fosfordan ayırt
edemiyordu. Yani renksizlik aynı zamanda işlevsel bir kayıptı.

Her takip alanına kendi rengi verildi (`AppAccents`): enerji kehribar,
protein kiremit, sodyum çivit, potasyum erik, fosfor zeytin, sıvı
deniz mavisi, ilaç yeşil, tahlil indigo, kilo bronz, hareket gül,
randevu mor.

Kurallar:

- **Ana eylem rengi renk paletinin dışında.** Buton rengi süse
  harcanmaz; birincil eylem her zaman aynı yeşille bulunur.
- Kırmızı/kehribar anlamlarına dokunulmadı: hedef aşılınca ölçek
  kırmızıya, eşiğe yaklaşınca kehribara döner — kategori rengi geri
  çekilir.
- **Renk tek başına bilgi taşımaz**: her satırda adı ve sayısı yazar.
- Boş kanallar bile besinin soluk rengiyle çizilir, böylece veri
  sıfırken de satırın neye ait olduğu görünür.
- Alt sekmeler gittikleri bölümün rengiyle yanar (yön bulma).

Tüm renkler **WCAG AA** (metin için ≥4,5:1) hesaplanarak seçildi; yüksek
kontrast temalarında ≥7:1'e çekildi. Koyu tema mekanik ters çevirme
değil, ayrı hesaplandı.

### Güncelleme sistemi

- `.github/workflows/release.yml` — `v*` etiketi itince Android APK'ları
  GitHub Release'e, iOS yapısı TestFlight'a gider.
- `lib/core/services/update_service.dart` — uygulama GitHub
  Release'lerini denetler, Android'de APK'yı indirip kurulumu başlatır,
  iOS'ta TestFlight'a yönlendirir.
- Sürüm karşılaştırması sayısal (`1.10.0 > 1.9.0`), 9 testle korunuyor.

---

## 2. Ortam kurulumu (bu makinede yapılanlar)

Hiçbir araç kurulu değildi; aşağıdakiler `~/development` altına kuruldu.
**Sistem dizinlerine veya Homebrew'a dokunulmadı**, sudo kullanılmadı.

| Araç | Sürüm | Konum |
|---|---|---|
| Flutter SDK (stable) | 3.50.1 (Dart 3.14.0) | `~/development/flutter` |
| JDK (Temurin) | 17.0.21.1 | `~/development/jdk17` |
| Android cmdline-tools | 13114758 | `~/development/android-sdk/cmdline-tools/latest` |
| Android platform | android-36 | `~/development/android-sdk/platforms` |
| Android build-tools | 36.1.0 | `~/development/android-sdk/build-tools` |

`flutter doctor` çıktısı:

```
[✓] Flutter (Channel stable, 3.50.1, on macOS 27.2.1, darwin-arm64)
[✓] Android toolchain - develop for Android devices (Android SDK 36.1.0)
    • All Android licenses accepted.
[!] Connected device — No devices available
[✓] Network resources
```

Tek "sorun" bağlı cihaz olmaması; bu bir araç eksiği değil. Emülatör veya
telefon bağlanınca yeşile döner.

### 2.1 Kabuk ortamı

Hazır betik:

```bash
source tools/env.sh
```

Tam doğrulama (pub get + kod üretimi + analiz + testler + APK):

```bash
./tools/check.sh
```

Kalıcı hâle getirmek için `~/.zshrc`'ye ekle:

```bash
export JAVA_HOME="$HOME/development/jdk17"; export ANDROID_HOME="$HOME/development/android-sdk"; export ANDROID_SDK_ROOT="$ANDROID_HOME"; export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$HOME/development/flutter/bin:$PATH"
```

Flutter yapılandırması (bir kez yapıldı, tekrar gerekmez):

```bash
flutter config --android-sdk "$HOME/development/android-sdk" --jdk-dir "$HOME/development/jdk17"
```

### 2.2 Sıfırdan kurmak isteyen için

```bash
curl -fL -o flutter.zip "https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.50.1-stable.zip" && unzip -q flutter.zip -d ~/development
```

```bash
curl -fL -o jdk17.tar.gz "https://api.adoptium.net/v3/binary/latest/17/ga/mac/aarch64/jdk/hotspot/normal/eclipse" && mkdir -p /tmp/jdkx && tar xzf jdk17.tar.gz -C /tmp/jdkx && mv /tmp/jdkx/*/Contents/Home ~/development/jdk17
```

```bash
curl -fL -o clt.zip "https://dl.google.com/android/repository/commandlinetools-mac-13114758_latest.zip" && mkdir -p ~/development/android-sdk/cmdline-tools && unzip -q clt.zip -d /tmp/cltx && mv /tmp/cltx/cmdline-tools ~/development/android-sdk/cmdline-tools/latest
```

```bash
yes | sdkmanager --sdk_root="$HOME/development/android-sdk" --licenses && sdkmanager --sdk_root="$HOME/development/android-sdk" "platform-tools" "platforms;android-36" "build-tools;36.1.0"
```

---

## 3. Yapılan kararlar (ve nedenleri)

### 3.1 Mimari

| Karar | Neden |
|---|---|
| **Flutter 3.50.1 stable, Android hedefli** | İstenen yığın. iOS/web/masaüstü kapatıldı. |
| **`material_ui` paketi** | Flutter 3.47'den sonra `package:flutter/material.dart` **kullanımdan kaldırıldı**; Material widget'ları `material_ui` paketine taşındı. `flutter create` şablonu da bunu kullanıyor. Tüm kod `package:material_ui/material_ui.dart` ile yazıldı. |
| **Riverpod 3** | İstenen. Kod üretimi (riverpod_generator) kullanılmadı — derleme bağımlılığını azaltmak için elle yazılmış `Provider`/`Notifier`/`AsyncNotifier`. |
| **go_router + ShellRoute** | Alt navigasyon (tek elle kullanım) kabuk rotasıyla; diğer ekranlar tam ekran `push`. |
| **Drift + SQLCipher** | "Drift/SQLite veya Isar" seçeneğinden Drift. Şifreleme SQLCipher ile; anahtar 32 bayt rastgele, `flutter_secure_storage` (Android Keystore destekli) içinde. |
| **Şifreleme açılamazsa uygulama ÇALIŞMAZ** | `main.dart` içinde SQLCipher kurulamazsa şifresiz veritabanına sessizce düşmek yerine açıklayıcı bir hata ekranı gösterilir. Sağlık verisi korumasız yazılmaz. |
| **Feature-first klasör yapısı** | `lib/features/<özellik>/`, paylaşılan kod `lib/core/`, klinik mantık `lib/clinical/`. |
| **Gradle `-bin` dağıtımı** | `gradle-wrapper.properties` varsayılan olarak `-all` (241 MB, kaynak + dokümantasyon dahil) indiriyordu. Derleme için `-bin` (140 MB) yeterli; ilk kurulumu belirgin biçimde hızlandırır. |
| **workmanager KALDIRILDI** | `workmanager 0.9.3` eski Kotlin Gradle Plugin'ini uygular ve **Flutter 3.50 ile Kotlin kaynakları derlenmiyor**: ürettiği AAR'ın `classes.jar`'ı BOŞ kalıyor, `GeneratedPluginRegistrant` "cannot find symbol: WorkmanagerPlugin" ile derlemeyi kırıyor. Bunu derleme sırasında tespit edip eklentiyi çıkardım. |
| **Akıllı bildirimler arka plan görevi olmadan** | Hava/UV/hava kalitesi uyarısı uygulama açıldığında ve öne geldiğinde hesaplanır. Günlük özet ise **içeriği o an hesaplanıp akşam 20:00'ye zamanlanır** (`flutter_local_notifications`), yani uygulama kapalı olsa da bildirim gelir. İlaç ve randevu hatırlatmaları zaten bağımsız olarak zamanlanmıştır ve arka plan görevine hiç ihtiyaç duymaz. (`lib/core/services/smart_notifications.dart`) |
| **Klinik mantık Flutter'dan bağımsız** | `lib/clinical/` içindeki her şey saf Dart. Bu yüzden eşik/alarm/besin/sıvı kuralları hızlı ve kırılgan olmayan birim testlerle kapsanabiliyor. |

### 3.2 Tasarım

- Sıcak krem/bej zemin (`#F6F1E7`), yumuşak yeşil (`#3C6B54`) ve altın
  (`#8A6A20`) vurgu.
- **Üç kademeli derinlik** (`enum Surface`): `flat` içerik kartları
  (tonlu dolgu + saç teli kenar), `raised` basılabilen yüzeyler (çift
  yönlü yumuşak gölge), `floating` üstte duran kabuk. Buzlu cam
  (`GlassBar`, gerçek `BackdropFilter`) yalnız alt gezinme çubuğunda —
  orada içerik gerçekten arkasından aktığı için anlamlı. Ayrıntı için
  bkz. **1.5 İkinci turda yapılanlar**.
- **Fontlar assets'e gömüldü**: Playfair Display (başlık, serif) ve
  Nunito (gövde, sans). Google Fonts'un değişken sürümleri indirilip
  `fontTools` ile statik örneklere dönüştürüldü, sonra **Latin + Türkçe
  kümesine indirgendi** (`tools/subset_fonts.sh`): 972 KB → 252 KB.
  Kullanılmayan Playfair ağırlıkları (400/700) silindi — serif tek
  ağırlıkta (600) kullanılıyor. Türkçe karakterler (ı, İ, ş, ğ, ü, ö, ç)
  cihazda doğrulandı.
- **Kural: serif yalnız başlıklarda.** Etiketler, butonlar, gövde ve
  özellikle **sayılar** Nunito ile, tablo rakamlarıyla yazılır. Başlık
  yüzü veride hem okunurluğu düşürüyor hem sütunlarda hizalanmıyordu.
- **Responsive**: hiçbir yerde sabit piksel yok. Tüm ölçüler
  `Responsive` sınıfından geçiyor (referans 390 dp, 0.88–1.22 arası
  sınırlı ölçek). Telefonda tek sütun, ≥600 dp iki, ≥980 dp üç sütun;
  içerik sütunu 720 dp ile sınırlı (tablette satırlar aşırı uzamasın).
- **Hareketi azalt**: uygulama ayarı **veya** sistem ayarı
  (`MediaQuery.disableAnimations`) açıkken tüm süreler sıfırlanır,
  parallax ve ölçek animasyonları devre dışı kalır, açılış animasyonu
  atlanır.
- **Erişilebilirlik**: 3 kademeli yazı boyutu (sistem ölçeğinin üstüne
  biner, toplam 2.0× ile sınırlanır), yüksek kontrast paleti,
  tüm dokunma hedefleri ≥48 dp, alt navigasyon, her etkileşimli
  öğede `Semantics` etiketi.
- Gece modu da eklendi (sıcaklığı koruyan koyu kahve/antrasit) —
  istenmemişti ama gece ilaç/ölçüm kaydı için işe yarıyor.
  Varsayılan olarak sistem temasını izler.

### 3.3 Gizlilik kararları

- Hiçbir veri otomatik dışarı gitmez.
- Yapay zekaya gönderim **her seferinde** ayrı onay ister ve ne
  gönderildiği birebir gösterilir (sohbette kalkan ikonu).
- **Ad, telefon, doktor bilgisi ve acil kişiler yapay zekaya hiç
  gönderilmez.** Gönderilenler: yaş/boy/kilo, hastalık durumu, ek
  hastalıklar, alerjiler, sevmediği yemekler, klinik ayarlar,
  son 20 tahlil, ilaç listesi — her biri ayrı ayrı kapatılabilir.
- Barkod okuma ve OCR **tamamen cihaz üstünde** (google_mlkit).
- Android bulut yedeği ve cihaz transferi kapatıldı
  (`data_extraction_rules.xml`): şifreli veritabanının anahtarsız
  kopyası işe yaramaz, yedeğe gitmesi gereksiz risk. Kullanıcı kendi
  yedeğini Ayarlar'dan JSON olarak alır.
- JSON yedeği **şifresizdir** ve bu kullanıcıya her seferinde söylenir.
  API anahtarı ve PIN yedeğe **dahil edilmez**.

### 3.4 Sıvı limitine saygı (açık bir tasarım kuralı)

Sıvı limiti olan bir hastaya uygulama **hiçbir yerde** "bol su iç"
demez. Sıcak hava uyarıları bile kalan mL'yi söyler ve susuzluk için
sıvı tüketmeyen alternatifler önerir (buz parçası, şekersiz sakız,
limon dilimi). "Su iç" hatırlatması **varsayılan olarak kapalıdır** ve
limit varken açılmak istenirse ayrı bir onay sorulur.
Bu kural birim testle korunuyor (`test/fluid_budget_test.dart`).

### 3.5 Model adı tek yerde

`lib/core/config/ai_config.dart` → `AiConfig.defaultModel`
(varsayılan `claude-opus-5-5`). Ayarlar ekranından da
Opus 5.5 / Sonnet 5.5 / Haiku 5.5 arasında seçilebilir.
**Kodda ve depoda API anahtarı yok.**

Bağlantı testi `GET /v1/models` kullanır: **token harcamaz**, bu yüzden
istediğin kadar çalıştırılabilir. Anahtarın geçerliliğini ve seçili
modele erişimi doğrular.

---

## 4. Klinik referans değerleri

Varsayılanlar kodlanmadan önce birincil kaynaklardan **internetten
doğrulandı** (23 Kasım 2026). Her değerin yanında dört etiketten biri
görünür:

| Etiket | Anlamı |
|---|---|
| **Kaynaktan doğrulandı** | Birincil kılavuz metninden doğrudan alındı. |
| **Doğrulanmadı** | Sayıyı birincil metinde doğrulayamadık ya da kaynaklar çelişiyor. |
| **Bireyselleştirilir** | Kılavuz açıkça "hastaya göre belirle" diyor; varsayılan **boş** bırakıldı. |
| **Başlangıç değeri** | Kılavuz sayı vermiyor; muhafazakâr bir başlangıç konuldu. |

### 4.1 Doğrulanan değerler

| Değer | Varsayılan | Kaynak |
|---|---|---|
| Protein | 0,8 g/kg/gün (diyalizde 1,0) | KDIGO 2024 (3.3.1.1, 2C); KDOQI 2020 (diyalizsiz diyabetsiz 0,55–0,60; diyabetli 0,6–0,8; HD/PD 1,0–1,2, 1C) |
| Sodyum | 2000 mg/gün | KDIGO 2024 (3.3.2.1, 2C: <2 g Na = <5 g tuz = <90 mmol); KDOQI 2020: <2300 mg |
| Enerji | 25–35 kcal/kg/gün | KDOQI 2020 |
| Sistolik tedavi hedefi | <120 mmHg | KDIGO 2024 (3.4.1, 2B) — **standart ofis ölçümü** ile, tolere edilirse |
| Sistolik/diyastolik üst alarm | 180 / 120 mmHg | ACC/AHA 2017 — hipertansif kriz eşiği |
| Hemoglobin (ESA altında) | 10,0–11,5 g/dL | KDIGO **2026** Anemi (≤11,5 g/dL hedef; HD'de ESA başlama ≤9,0–10,0) |
| Ferritin / TSAT | 100–500 ng/mL / %25–40 | KDIGO 2026 Anemi |
| eGFR referans çizgisi | ≥60 mL/dk/1,73m² | KDIGO 2024 GFR kategorileri |
| uACR | ≤30 mg/g (A1) | KDIGO 2024 albüminüri kategorileri |
| Diyaliz arası kilo artışı | %4,0 (kuru ağırlık) | 2025 derlemesi (PMC11942859): hedef %4,0–4,5'ten az |

### 4.2 Bilerek boş bırakılanlar (bireyselleştirilir)

- **Diyet potasyumu** ve **diyet fosforu**: KDOQI 2020 sabit sayı
  vermez, serum düzeyine göre bireyselleştirilir. Arayüzde
  "serum potasyum/fosfor sonucuna göre doktor belirler" notu ve
  literatürdeki yaygın aralıklar (2000–3000 mg / 800–1000 mg)
  **kılavuz hedefi olmadığı belirtilerek** gösterilir.
- **Serum fosfat / kalsiyum hedef aralığı**: KDIGO 2017 CKD-MBD sayısal
  aralık vermez ("yükselmiş fosfatı normal aralığa doğru düşür", 2C).
  Varsayılan: kullanıcının laboratuvarının referans aralığı.
- **Sıvı limiti**: tüm hastalar için geçerli bir kılavuz sayısı yok.
  "Limit yok" seçeneği var ve varsayılan budur.

### 4.3 Doğrulanamayan / tartışmalı değerler (uygulamada işaretli)

1. **Hiperkalemi kademeleri (5,0 / 5,5 / 6,0 mEq/L)** — "doğrulanmadı".
   KDIGO hiperkalemiyi **potasyum + EKG** ile sınıflar (kesim noktaları
   5,0 / 6,0 / 6,5) ve bunu *uzman görüşü* olarak niteler. Mayo Clinic
   Proceedings kesin eşiklerin kılavuzlar arasında değiştiğini açıkça
   belirtiyor. Uygulamadaki kademeler yaygın bir **alternatif şemadır**
   ve her uyarı metninde bu çekince yazıyor.
2. **PTH hedefi (normalin üst sınırının 2–9 katı)** — "doğrulanmadı".
   Bu sayıyı yalnızca KDIGO'yu özetleyen bir sunumda bulabildik,
   birincil 2017 CKD-MBD metninde doğrulayamadık. Varsayılan **boş**.
3. **Serum bikarbonat ≥22 mmol/L** — "doğrulanmadı". Yaygın kullanılıyor
   ama KDIGO 2024 metninde doğrulayamadık.
4. **Nabız (50/120), SpO₂ (%92/%90), ateş (38 °C), kan şekeri (70/250),
   idrar çıkışı (400 mL), günlük kilo artışı (1 kg)** —
   "başlangıç değeri". Böbrek kılavuzları bu ölçümler için alarm eşiği
   tanımlamıyor; muhafazakâr değerler konuldu ve etiketlendi.
5. **Sistolik alt alarm (90 mmHg)** — "başlangıç değeri".
   ACC/AHA 2017 hipotansiyon için sayısal alarm eşiği tanımlamıyor.
6. **Hemodiyalizde 500–1000 mL/gün sıvı** — derleme düzeyinde bilgi,
   kılavuz önerisi değil; uygulamada böyle sunuluyor ve aynı literatürün
   "sabit hacim yerine bireysel reçete" görüşü de yazıyor.

### 4.4 Kaynak listesi

`lib/clinical/sources.dart` içinde **15 kaynak**, ad + yıl + URL +
Türkçe not olarak tutulur; uygulamadaki **Kaynaklar** ekranında ve
doktor raporunun sonunda gösterilir. Her kaynak hangi değerlerde
kullanıldığını da listeler. Bağlantıların hepsi 23 Kasım 2026'da
erişilebilirdi.

KDIGO 2024 CKD (tam metin) · KDIGO 2024 CKD öneri özeti (PDF) ·
KDOQI 2020 Nutrition · KDIGO 2017 CKD-MBD · KDIGO 2026 Anemi ·
ACC/AHA 2017 HT · KDIGO Potasyum Konferansı ·
Mayo Clinic Proceedings 2021 (hiperkalemi) · IDWG derlemesi 2025 ·
NKF ağrı kesiciler · NKF bitkisel ürünler · TürKomp ·
USDA FoodData Central · Türk Nefroloji Derneği · Open Food Facts.

**Veri kümesi büyüklükleri:** 36 klinik tanım (6 diyet hedefi,
18 alarm eşiği, 12 laboratuvar hedefi) · 10 NSAİİ etken maddesi
(Türkiye ticari adlarıyla) · 15 bitkisel/riskli ürün ·
106 besin, 14 kategori · 14 "günün notu" · 6 yerleşik okuma içeriği.

---

## 5. Ekranlar — ne tam çalışıyor, ne yaklaşık

### 5.1 Anahtarsız, tam çalışan (internet bile gerekmez)

| Ekran | Durum |
|---|---|
| Açılış animasyonu (damla-yaprak çizim) | ✅ Tam. `CustomPainter` ile üç fazlı çizim; hareket azaltmada atlanır. |
| İlk kurulum testi (12 adım) | ✅ Tam. Sonuçlar klinik ayarları ön doldurur, protein hedefini tedavi türüne göre uyarlar. |
| Klinik Ayarlar | ✅ Tam. Her değer için referans metni, kaynak, doğrulama etiketi, "senin değerin" vurgusu, varsayılana dön, bilerek boşalt, not, **değişiklik geçmişi**. |
| Kaynaklar | ✅ Tam. |
| Besin takibi (ara / elle gir) | ✅ Çalışır — **değerler yaklaşık** (bkz. 5.3). |
| Sıvı bütçesi | ✅ Tam. Hızlı ekleme, sesli kayıt, yemekten gelen sıvı, limit yok desteği. |
| Laboratuvar (manuel giriş) | ✅ Tam. Grafik, referans aralığı gölgesi, trend, kendi lab aralığın. |
| Takvim / randevu | ✅ Tam. Diyaliz günlerinden otomatik seans üretimi. |
| İlaç yönetimi | ✅ Tam. Hatırlatma, alındı/ertele/atla, stok düşümü ve bitiş uyarısı, **canlı ilaç güvenliği taraması**. |
| Kilo & ödem günlüğü | ✅ Tam. Grafikler, IDWG hesabı ve eşik uyarısı, eşik aşımında uyarı diyaloğu. |
| Diyet planı & uyum | ✅ Tam. |
| Acil durum | ✅ Tam. 112 kısayolu, mesaj önizleme, SMS/WhatsApp, doktoru ara. |
| Yakın modu (özet paylaşımı) | ✅ Tam (cihazda üretilir, kullanıcı paylaşır). |
| Doktor raporu (PDF) | ✅ Tam. 8 bölüm, gömülü fontlarla Türkçe, çizgi grafikler, kaynak listesi. |
| Ayarlar + erişilebilirlik | ✅ Tam. |
| İzinler ekranı | ✅ Tam. Her izin tek tek, gerekçeli. |
| JSON yedek al/geri yükle | ✅ Tam. Birleştir/değiştir seçenekli. |
| Uygulama kilidi (PIN + biyometrik) | ✅ Tam. Arka plandan dönüşte yeniden kilitlenir. |
| Okuma — "Temel bilgiler" | ✅ Tam. 6 elle yazılmış kaynaklı içerik, çevrimdışı. |
| Akıllı bildirimler | ⚠️ Hava/UV/AQI uyarısı tek bildirimde birleştirilir (uygulama açıldığında/öne geldiğinde hesaplanır); günlük özet akşam 20:00'ye zamanlanır ve uygulama kapalıyken de gelir. Hepsi sessiz saatlere ve günlük 3 bildirim sınırına uyar, sıvı limitine saygı duyar. **Gerçek cihazda doğrulanamadı.** |

### 5.2 İnternet gerektirenler

| Ekran | Durum |
|---|---|
| Hava / UV / hava kalitesi | ✅ Open-Meteo (anahtarsız), 30 dk önbellek, çevrimdışı eski kopya. |
| Barkod → ürün | ✅ Open Food Facts; **potasyum ve fosfor çoğu üründe etiketlenmediği için genelde boş gelir** ve "bilinmiyor" olarak gösterilir, sıfır sayılmaz. |
| Yakındaki restoranlar | ⚠️ Overpass API ücretsiz topluluk servisi; yoğun saatlerde "at capacity" döner. Üç ayna sırayla denenir, 6 saat önbellek, başarısızlıkta dürüst Türkçe mesaj. **Testler sırasında ana sunucu gerçekten dolu döndü** — bu beklenen bir durum, kod bunu düzgün karşılıyor. |
| Araba/yürüyüş süresi | ✅ OSRM demo sunucusu, 12 saat önbellek, mekan başına istek (ücretsiz sunucu sınırı için en yakın 12 mekan). |
| Okuma — kaynak akışları | ⚠️ Kısmi (bkz. 5.4). |

### 5.3 Yaklaşık/demo veriyle çalışanlar — açıkça etiketli

- **Yerel besin tablosu**: 106 besin, 14 kategori
  (`assets/data/turkish_foods.json`). TürKomp ve USDA FoodData Central
  temel alınarak derlendi; karışık yemeklerde (karnıyarık, mantı,
  iskender…) **tarif bazlı tahmin** kullanıldı. Her yerde
  "≈ yaklaşık" etiketi var. Sodyum ev yapımı ile lokanta arasında kat
  kat değişir ve bu söyleniyor.
- **Mutfak uygunluk puanı**: OSM `cuisine` etiketine dayanır, **menüye
  değil**. Her kartta "Menü doğrulanmadı" uyarısı var. Menü verisi
  uydurulmuyor; iki dürüst yol sunuluyor: (a) menü fotoğrafı →
  Claude vision analizi, (b) mutfak türüne göre genel öneri.
- **İlaç güvenliği veri seti**: 10 NSAİİ etken maddesi (Türkiye ticari
  adlarıyla: Brufen, Voltaren, Apranax, Arveles, Etol, Melox…) ve
  15 bitkisel/riskli ürün (ısırgan, meyan kökü, atkuyruğu,
  potasyumlu "light tuz" dahil). **"Örnek, kapsamlı değil"** olarak
  işaretli; bir ilacın listede olmaması güvenli olduğu anlamına gelmez
  ve bu her yerde yazıyor.
- **Yapay zeka tahminleri**: yemek fotoğrafı analizi her değerde
  `± sapma` ve güven düzeyi (düşük/orta/yüksek) döndürür; kullanıcı
  kaydetmeden önce düzeltir. Tuz miktarının fotoğraftan bilinemeyeceği
  modele özel olarak söyletilir.

### 5.4 Yapılamayanlar / kısmi olanlar

1. **Okuma sayfası RSS'leri.** Doğrulanmış ve çalışan üç akış:
   Kidney International (KDIGO'nun dergisi), NephJC, Kidney Research UK.
   **Çalışmayanlar (bulunamadı/engelliyor):** kidney.org (404),
   kidneyfund.org (404), NIDDK (404), Mayo Clinic (403),
   AJKD (404), Türk Nefroloji Derneği (RSS yok).
   Bu kurumların içeriği yerine **6 elle yazılmış, kaynak gösteren
   başlangıç içeriği** konuldu ve hangi kaynaklara erişilemediği
   uygulamanın içinde de yazıyor. Teknik akışlar (dergiler) yalnızca
   **uzman modu** açıkken indirilir.
2. **EKG verisi gösterilemiyor.** Android Health Connect ham EKG dalga
   formunu üçüncü taraf uygulamalara **açmıyor**. Uygulama bunu
   uydurmuyor: ekranda neden gösterilemediği ve EKG kaydının saatin
   kendi uygulamasından PDF olarak çıkarılabileceği yazıyor.
   Nabız, tansiyon, SpO₂, adım, uyku ve kilo okunabiliyor.
3. **Cihazda çalıştırılamadı.** Bağlı telefon/emülatör olmadığı için
   çalışma anı akışları (izin diyalogları, kamera, Health Connect,
   bildirim zamanlaması, SMS kanalı, harita döşemeleri) **gerçek
   cihazda doğrulanmadı.** Derleme ve statik analiz temiz, 143 birim
   testi geçiyor — ama bu çalışma anı testi yerine geçmez.
4. **Uzak senkronizasyon yok** (v1 gereği). `SyncRepository` arayüzü
   bırakıldı; uygulaması `NoOpSyncRepository` ve hiçbir yere veri
   göndermiyor.
5. **İmzalı release APK üretilmedi.** Sadece debug APK. Kişisel
   kullanım için yeterli; release için kendi imza anahtarın gerekir.
6. **Uygulama ikonu** varsayılan Flutter ikonu. Damla-yaprak işareti
   uygulama içinde kullanılıyor ama launcher ikonuna dönüştürülmedi.

---

## 6. Bilinen eksikler / TODO

### Önce şunu bilmek gerekir: neyin cihazda denenmediği

Uygulama iOS 27.2 simülatöründe (iPhone 17 Pro Max) **çalışır hâlde**
görüldü; ekranlar, şifreli veritabanı, açık/koyu tema ve gezinme
doğrulandı. Ama simülatörün **kamerası yoktur**. Bu yüzden şu üç yol
derlenir ve mantığı testlidir, fakat **gerçek bir çekimle denenmemiştir**:

- canlı barkod tarama,
- kamerayla etiket okuma (Apple Vision / ayrık ML Kit),
- yemek fotoğrafı çekimi.

Besin etiketi çözümleyicisi 18 testle doğrulandı ama testler **yazılmış
örnek etiket metinleri** üzerinde; gerçek bir fotoğraftan çıkan OCR
metni daha dağınık olur. İlk gerçek denemede çözümleyicinin
kaçırdıkları görülüp `nutrition_label_parser.dart` içindeki takma ad
listesi genişletilmelidir.

Aynı şekilde iOS'ta **HealthKit, bildirimler, konuşma tanıma ve
seslendirme** cihazda çalıştırılmadı; HealthKit için Xcode'da bir
geliştirici hesabı seçmek de gerekir.

```
[ ] Gerçek cihazda uçtan uca deneme: izin diyalogları, canlı barkod,
    kamerayla etiket okuma, yemek fotoğrafı, Health Connect / HealthKit
    eşleşmesi, bildirim zamanlaması (özellikle "tam zamanlı alarm" izni
    kapalıyken), SMS platform kanalı.
[ ] Android Lint tüm alt projelerde KAPALI (android/build.gradle.kts).
    Sebep: AGP'nin lint sürümü image_picker_android'in bir javadoc
    yorumunu ayrıştırırken çöküyor ve release derlemesini durduruyordu.
    Üst akış düzelince geri açılmalı.
[ ] ProGuard/R8 kuralları gözden geçirilmedi (release çalışıyor ama
    küçültme kuralları özelleştirilmedi).
[ ] Düşük adım bildirimi: ayar var ama bildirim üretilmiyor.
    Adım sayısı ana sayfada gösteriliyor; eşik altı için bildirim
    uygulama açıkken hesaplanabilir — henüz bağlanmadı.
[ ] Gerçek arka plan görevi: workmanager Flutter 3.50 ile
    derlenmiyor (yukarıdaki not). Alternatifler: eklenti düzelince
    geri eklemek, ya da küçük bir Kotlin WorkManager Worker'ı
    doğrudan android/ tarafında yazıp platform kanalıyla beslemek.
[ ] KGP uyarısı: device_info_plus, file_picker, flutter_timezone,
    flutter_tts, health, package_info_plus, share_plus hâlâ eski
    Kotlin Gradle Plugin'ini uyguluyor. Şimdilik derleniyor ama
    Flutter ileride bunu hata yapacak; eklentiler güncellenmeli.
[ ] Bildirim dokunuşunu ilgili ekrana yönlendirme (payload yazılıyor
    ama yönlendirme bağlanmadı).
[ ] Ertelenen dozun eski bildirimini iptal etme (yeni bildirim
    planlanıyor, eskisi duruyor).
[ ] Arka plan görevi veritabanını AYRI bir bağlantıyla açıyor.
    Uygulama ön planda açıkken aynı anda çalışırsa SQLite kilit
    çekişmesi olabilir ("database is locked"). Kod bu durumda görevi
    sessizce bırakıyor (bildirim gelmez, veri bozulmaz) ama gerçek
    cihazda ölçülmedi. Daha iyisi: tek bir isolate üzerinden
    serileştirmek.
[ ] Drift şema göçü (migration) stratejisi: şu an schemaVersion 1;
    v2'de alan eklenirse step-by-step migration yazılmalı.
[ ] Overpass isteklerini tek seferde daha az mekanla sınırlayıp
    OSRM "table" servisine geçmek (şu an mekan başına 2 istek).
[ ] Besin tablosunu TürKomp'tan programatik olarak güncelleme
    (şu an elle derlenmiş; TürKomp'un makine okunabilir API'si yok).
[ ] İlaç güvenliği listesini genişletmek: Türkiye'deki tüm NSAİİ
    ticari adları, ACE-İ/ARB + NSAİİ + diüretik "triple whammy"
    kombinasyon uyarısı, kontrast madde uyarısı.
[ ] eGFR hesaplayıcı (CKD-EPI 2021) — şu an eGFR elle giriliyor.
[ ] Tahlil OCR'ında tarih otomatik okuma (şu an kullanıcı seçiyor).
[ ] Ekranların tamamını pompalayan widget testleri: şu an taşma
    testleri ve veri katmanı duman testleri var, ama ekranlar uçtan
    uca render edilmiyor (platform eklentileri test ortamında yok).
[ ] image/pdf/archive sürüm kilidini kaldırmak (bkz. pubspec.yaml
    yorumu) — üst akış düzelince.
```

---

## 7. Testler

```bash
flutter test
```

**227 test, 16 dosya.** Kapsanan kritik mantık:

| Dosya | Ne test ediliyor |
|---|---|
| `fluid_budget_test.dart` | Sıvı bütçesi, limit yok hâli, aşım, **limit varken teşvik eden metin üretilmediği** |
| `nutrition_test.dart` | Besin ölçekleme, **bilinmeyen değerin sıfır sayılmaması**, g/kg hedefleri, diyaliz protein varsayılanı, klinik ayar çözümlemesi ve JSON turu |
| `alarm_rules_test.dart` | Tansiyon kriz/hipotansiyon eşikleri, potasyum kademeleri (+ EKG çekincesi), tek eşikli ölçümler, **anürik hastada idrar alarmının kapalı olması**, IDWG yüzdesi, acil belirti taraması |
| `drug_safety_test.dart` | Türkçe büyük-I normalleştirme, etken madde + ticari ad eşleştirme, **yanlış pozitif kontrolü** |
| `voice_command_test.dart` | Sesli sıvı/tansiyon/kilo komutları, Türkçe ölçü birimleri, yazıyla sayılar |
| `medication_logic_test.dart` | Saat/gün çözümleme, geçersiz girdi dayanıklılığı |
| `report_aggregation_test.dart` | İlaç uyumu, tansiyon istatistikleri, **ortalamaların veri girilen güne bölünmesi** |
| `cuisine_and_feed_test.dart` | Mutfak puanı (çoklu etikette en güvenli seçim), RSS/Atom ayrıştırma, tahlil OCR satır çözümleme, eski düz metin yemek yanıtı |
| `nutrition_label_test.dart` | **Besin etiketi çözümleyici (18 test)**: iki sütunlu TR etiketi, kJ yerine kcal seçimi, **Tuz → sodyum türetmesi**, "doymuş yağ" satırının "yağ"ı ezmemesi, porsiyon ağırlığı, birim çevrimi (g↔mg), binlik/ondalık ayırıcı, alt satıra düşen değer, alakasız metinden değer uydurmama |
| `theme_reactivity_test.dart` | **Tema tepkiselliği**: sistem teması değişince paletin anında dönmesi, "sistemi izle" kapalıyken dönmemesi, yüksek kontrastın korunması |
| `update_version_test.dart` | **Sürüm karşılaştırma**: sayısal sıralama (1.10.0 > 1.9.0), derleme numarasının yok sayılması, bozuk metinde çökmeme |
| `meal_vision_test.dart` | **Çok kalemli yemek analizi (11 test)**: JSON kalemleri, kalem başına güven, toplamların kalemlerden hesaplanması, porsiyon değişince orantılı ölçekleme, kalem çıkarma, bozuk JSON'da düz metne düşme, boş sonuçta sayı uydurmama |
| `quiet_hours_test.dart` | Gece yarısını geçen sessiz saat aralığı, kritik/isteğe bağlı kategori ayrımı |
| `phone_and_distance_test.dart` | Türkiye telefon numarası → WhatsApp biçimi, kuş uçuşu mesafe (haversine), Türkçe arama normalleştirme |
| `app_smoke_test.dart` | **Uçtan uca duman testleri, GERÇEK (bellek içi) veritabanıyla**: sağlayıcı zinciri, drift sorgu/akışları, acil durum mesajı içeriği, yakın modu özeti, **PDF'in gerçekten üretildiği** (%PDF- imzası, >20 KB), yerel besin tablosu + Türkçe arama ve **yapay zeka bağlamının ad/telefon/doktor/acil kişi İÇERMEDİĞİ** |
| `layout_overflow_test.dart` | **360x640, 390x844 ve 800x1280'de taşma (overflow) kontrolü**; 2.0× yazı ölçeği ve yüksek kontrast dahil; açılış animasyonu; responsive ölçek sınırları |

Statik analiz:

```bash
flutter analyze
```

→ `No issues found!`

---

## 8. Kalan tek insan adımı

1. **APK'yı telefona kur** (bkz. 1.1).
2. **İlk kurulum testini doldur** (12 adım, hepsi sonradan
   değiştirilebilir).
3. **Claude API anahtarını yapıştır**: Ayarlar → Yapay Zeka Bağlantısı.
   Ekranda adım adım rehber var. `platform.claude.com` → Billing'den
   kredi yükle → API keys → Create key → kopyala → yapıştır →
   "Kaydet ve test et". Konsolda aylık harcama limiti koymak önerilir.
4. **İzinleri onayla**: her izin ilk kullanımda, gerekçesiyle
   tek tek sorulur. Hiçbiri zorunlu değil.

Yapay zeka anahtarı girilmezse AI özellikleri nazikçe "önce bağlantıyı
kur" der; **uygulamanın geri kalanı normal çalışır.**

---

## 9. Proje yapısı

```
lib/
  main.dart                  Şifreli DB açılışı + hata ekranı
  app.dart                   Tema, metin ölçeği, hareket, kilit kapısı
  clinical/                  SAF DART — Flutter bağımlılığı yok
    sources.dart             Kaynak listesi (ad/yıl/URL/not)
    definitions.dart         Klinik tanımlar + varsayılan + referans metni
    settings.dart            Kullanıcı ayarları, çözümleme, JSON
    evaluator.dart           Sıvı, besin, IDWG, eşik/alarm, acil belirti
    drug_safety.dart         NSAİİ + bitkisel veri seti ve eşleştirici
    cuisine_score.dart       Mutfak uygunluk puanı
  core/
    config/                  app_config.dart, ai_config.dart (MODEL ADI)
    theme/                   Palet, tipografi, neumorphism/glass, hareket
    widgets/                 Responsive, halka, grafik, form, ortak kartlar
    db/                      Drift tabloları + SQLCipher açılışı
    services/                API/AI/hava/mekan/sağlık/ses/SMS/PDF/yedek…
    router/                  go_router rotaları
    providers.dart           Riverpod sağlayıcıları
  features/                  onboarding, home, nutrition, fluid, labs,
                             calendar, medications, weight, health, ai,
                             places, travel, reading, emergency, report,
                             settings
assets/
  fonts/                     Playfair Display + Nunito (statik, 3 ağırlık)
  data/turkish_foods.json    106 besin, kaynak notlu
android/
  app/src/main/AndroidManifest.xml      Tüm izinler, gerekçe yorumlarıyla
  app/src/main/kotlin/.../MainActivity.kt   SMS platform kanalı
  app/src/main/res/xml/data_extraction_rules.xml   Bulut yedeği kapalı
test/                        8 dosya, 143 test
```

---

## 10. Dış servisler

| Servis | Ne için | Anahtar | Politika uyumu |
|---|---|---|---|
| Open-Meteo | Hava, UV, hava kalitesi | Gerekmez | 30 dk önbellek |
| OpenStreetMap | Harita döşemeleri | Gerekmez | `userAgentPackageName`, atıf widget'ı |
| Overpass API | Yakın mekanlar | Gerekmez | 6 saat önbellek, 3 ayna, üstel geri çekilme |
| OSRM | Araba/yürüyüş süresi | Gerekmez | 12 saat önbellek, en yakın 12 mekan |
| Nominatim | Geocoding | Gerekmez | **Saniyede 1 istek sınırı uygulanıyor**, 7–30 gün önbellek, User-Agent |
| Open Food Facts | Barkod ürün verisi | Gerekmez | 30 gün önbellek |
| Anthropic Claude | AI metin + görsel | **Kullanıcının kendi anahtarı** | Yalnız kullanıcı eylemiyle, her seferinde onaylı |

Tüm isteklerde kişisel bilgi içermeyen bir User-Agent gönderilir:
`BobrekDostu/1.0.0 (kisisel saglik uygulamasi)`

---

## 11. Lisans / fontlar

Uygulama kişisel kullanım içindir. Gömülü fontlar SIL Open Font
License 1.1 altındadır (Playfair Display — Claus Eggers Sørensen;
Nunito — Vernon Adams, Cyreal, Jacques Le Bailly).
