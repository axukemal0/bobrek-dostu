# Böbrek Dostu

Kronik böbrek hastalığı olan **tek bir kişi için**, tamamen telefonda
çalışan Android takip uygulaması. Giriş/üyelik yok, sunucu yok,
Play Store'da değil. Tüm veriler cihazda **şifreli** (SQLCipher) tutulur.

> **Bu uygulama tıbbi tavsiye değildir, klinik karar kullanıcıya aittir.**

Kullanıcı hekim olduğu için uygulamanın tüm klinik eşikleri ve hedefleri
**serbestçe düzenlenebilir**; uygulama hiçbir alt/üst sınır dayatmaz.
Varsayılanlar kılavuz referanslarıdır ve her değerin yanında kaynağı,
yılı ve **doğrulama durumu** yazar.

---

## 1. Hızlı başlangıç

### 1.1 Derlenmiş APK'yı telefona atmak

İki APK üretildi:

| Dosya | Boyut | Ne zaman |
|---|---|---|
| `app-arm64-v8a-debug.apk` | **132 MB** | **Önerilen.** 2017 sonrası tüm Android telefonlar (arm64). |
| `app-debug.apk` | 236 MB | Üç mimariyi birlikte taşır (arm64 + arm32 + x86_64). Emülatör veya çok eski cihaz gerekiyorsa. |

```bash
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk
```

ADB yoksa APK dosyasını telefona kopyalayıp dosya yöneticisinden
açmak da yeterli (telefonda "bilinmeyen kaynaklara izin ver" gerekir).

Boyut neden büyük? Bunlar **hata ayıklama (debug)** derlemeleri:
JIT için ek kod, sıkıştırılmamış semboller ve cihaz üstü ML Kit
modelleri (barkod + metin okuma) içinde. İmzalı release derlemesi
belirgin biçimde küçülür (bkz. TODO).

**Doğrulanan APK özellikleri:**

- Paket: `com.bobrekdostu.bobrek_dostu`, sürüm 1.0.0 (1)
- Uygulama adı: **Böbrek Dostu** (Türkçe karakterlerle)
- minSdk 26, targetSdk 36, compileSdk 36
- 21 izin manifest'te (konum, kamera, mikrofon, bildirim, tam alarm,
  SMS, aktivite tanıma, 7 Health Connect OKUMA izni)
- Gömülü varlıklar: 6 font dosyası (Playfair + Nunito, 3 ağırlık) ve
  `turkish_foods.json`

### 1.2 Kaynaktan derlemek

```bash
flutter pub get
```

```bash
dart run build_runner build
```

```bash
flutter build apk --debug
```

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
  (`#8A6A20`) vurgu. Buzlu cam kartlar (`GlassCard`, gerçek
  `BackdropFilter`), kabartmalı butonlar (`NeuCard`/`NeuButton`,
  çift yönlü yumuşak gölge).
- **Fontlar assets'e gömüldü**: Playfair Display (başlık, serif) ve
  Nunito (gövde, sans). Google Fonts'un değişken (variable) sürümleri
  indirilip `fontTools` ile **statik örneklere** (400/600/700)
  dönüştürüldü — hem Flutter hem de PDF tarafında güvenilir çalışması
  için. Türkçe karakterler (ı, İ, ş, ğ, ü, ö, ç) ikisinde de tam.
  *(Playfair'da `₂` alt simgesi yok; Flutter font geri dönüşüyle
  hallediyor, PDF'te gövde fontu kullanıldığı için sorun çıkmıyor.)*
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

```
[ ] Gerçek cihazda uçtan uca deneme: izin diyalogları, kamera + ML Kit,
    Health Connect eşleşmesi, bildirim zamanlaması (özellikle
    "tam zamanlı alarm" izni kapalıyken), SMS platform kanalı.
[ ] Launcher ikonu: DropLeafPainter'ı adaptive icon'a çevir
    (flutter_launcher_icons).
[ ] İmzalı release APK + ProGuard/R8 kuralları (ML Kit ve Drift için).
    Debug APK 132 MB (arm64); release derlemesi belirgin küçülür.
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

186 test, 12 dosya. Kapsanan kritik mantık:

| Dosya | Ne test ediliyor |
|---|---|
| `fluid_budget_test.dart` | Sıvı bütçesi, limit yok hâli, aşım, **limit varken teşvik eden metin üretilmediği** |
| `nutrition_test.dart` | Besin ölçekleme, **bilinmeyen değerin sıfır sayılmaması**, g/kg hedefleri, diyaliz protein varsayılanı, klinik ayar çözümlemesi ve JSON turu |
| `alarm_rules_test.dart` | Tansiyon kriz/hipotansiyon eşikleri, potasyum kademeleri (+ EKG çekincesi), tek eşikli ölçümler, **anürik hastada idrar alarmının kapalı olması**, IDWG yüzdesi, acil belirti taraması |
| `drug_safety_test.dart` | Türkçe büyük-I normalleştirme, etken madde + ticari ad eşleştirme, **yanlış pozitif kontrolü** |
| `voice_command_test.dart` | Sesli sıvı/tansiyon/kilo komutları, Türkçe ölçü birimleri, yazıyla sayılar |
| `medication_logic_test.dart` | Saat/gün çözümleme, geçersiz girdi dayanıklılığı |
| `report_aggregation_test.dart` | İlaç uyumu, tansiyon istatistikleri, **ortalamaların veri girilen güne bölünmesi** |
| `cuisine_and_feed_test.dart` | Mutfak puanı (çoklu etikette en güvenli seçim), RSS/Atom ayrıştırma, tahlil OCR satır çözümleme, yemek fotoğrafı yanıtı ayrıştırma |
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
