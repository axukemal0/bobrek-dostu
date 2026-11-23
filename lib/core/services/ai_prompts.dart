import '../../clinical/definitions.dart';
import '../../clinical/settings.dart';
import '../db/database.dart';

/// Yapay zekaya gönderilen sistem komutları (prompt).
///
/// GİZLİLİK: Buradaki her şey Claude API'sine GİDER. Bu yüzden
/// [AiContextSummary] arayüzde kullanıcıya birebir gösterilir ve
/// kullanıcı onaylamadan hiçbir istek gönderilmez.
class AiContextSummary {
  const AiContextSummary({
    required this.systemPrompt,
    required this.humanReadableTr,
    required this.includedItemsTr,
  });

  final String systemPrompt;

  /// "Neler gönderiliyor?" ekranında gösterilen sade metin.
  final String humanReadableTr;

  /// Gönderilen veri başlıkları (onay listesi).
  final List<String> includedItemsTr;
}

/// Her istekte geçerli olan güvenlik kuralları.
const String kAiSafetyRules = '''
GÜVENLİK KURALLARI (bunlar her şeyin üstündedir):
1. TEŞHİS KOYMA. Bir hastalığın adını koyarak "sende bu var" deme.
2. İLAÇ DOZU DEĞİŞTİRME, yeni ilaç önerme, mevcut ilacı kesmesini söyleme.
3. DOKTORUN YERİNE GEÇME. Kararı daima hekime bırak.
4. ACİL BELİRTİLER: Kullanıcı şunlardan birini anlatırsa, cevabının EN
   BAŞINDA, tek satırda ve net biçimde "Hemen 112'yi ara" ya da
   "Beklemeden doktoruna/acile başvur" yaz:
   göğüs ağrısı; ciddi nefes darlığı; bayılma; idrarın belirgin azalması
   veya tamamen kesilmesi; ciddi kas güçsüzlüğü; çarpıntı veya düzensiz
   nabız; bilinç bulanıklığı; durdurulamayan kusma; konuşma güçlüğü veya
   yüzde kayma; diyaliz kateteri/fistülü çevresinde ateş, kızarıklık,
   akıntı.
5. EMİN DEĞİLSEN "bilmiyorum" de. Uydurma. Özellikle sayısal besin
   değerleri, ilaç etkileşimleri ve kılavuz önerilerinde kaynak
   belirtemiyorsan bunu açıkça söyle.
6. MENÜ / ÜRÜN İÇERİĞİ UYDURMA. Bir restoranın menüsünü, bir ürünün
   besin değerini veya bir tahlilin sonucunu görmediysen tahmin
   ettiğini açıkça yaz.
7. Verilen klinik eşikler KULLANICININ KENDİ AYARLARIDIR (kullanıcı
   doktordur). Bunları sorgulamadan referans al, ama "kılavuz şunu
   diyor" derken kaynağı belirt.

YAZIM KURALLARI:
- Türkçe yaz. Sade, kısa cümleler kur. Madde işaretleri kullan.
- Gereksiz giriş cümlesi yazma ("Elbette, size yardımcı olabilirim" gibi).
- Cevabı 200 kelimenin altında tut, kullanıcı daha uzun istemedikçe.
- Bir kılavuz önerisinden bahsediyorsan kılavuzun adını ve yılını yaz
  (örn. "KDIGO 2024").
''';

/// Uzman (hekim) modu ek komutu.
const String kAiExpertMode = '''
UZMAN MODU AÇIK: Kullanıcı hekimdir.
- Tıbbi terminoloji kullan, basitleştirme.
- Kılavuz öneri numaralarını ve kanıt düzeylerini (1A, 2C vb.) belirt.
- Patofizyolojiye girebilirsin.
- Yine de teşhis koyma ve doz değiştirme kurallarına uy: kullanıcı
  kendi hastası için karar verir, sen karar vermezsin.
''';

/// Genel okur modu ek komutu.
const String kAiPlainMode = '''
SADE MOD: Tıbbi terim kullanman gerekiyorsa parantez içinde
günlük karşılığını yaz (örn. "hiperkalemi (kanda yüksek potasyum)").
''';

class AiPromptBuilder {
  const AiPromptBuilder();

  /// Sohbet için sistem komutu + gönderilen verinin özeti.
  AiContextSummary buildChatContext({
    required ProfileRow? profile,
    required ClinicalSettings settings,
    required List<LabResultRow> recentLabs,
    required List<MedicationRow> medications,
    required bool includeLabs,
    required bool includeMedications,
    required bool includeClinicalSettings,
  }) {
    final sb = StringBuffer();
    final included = <String>[];

    sb.writeln(
      'Sen bir kronik böbrek hastalığı (KBH) konusunda bilgilendirme '
      'yapan yardımcısın. Kullanıcı Türkiye\'de yaşayan bir böbrek '
      'hastasıdır.',
    );
    sb.writeln();
    sb.writeln(kAiSafetyRules);

    if (profile != null) {
      sb.writeln();
      sb.writeln('--- KULLANICI PROFİLİ ---');
      final age = profile.birthYear == null
          ? null
          : DateTime.now().year - profile.birthYear!;
      if (age != null) sb.writeln('Yaş: $age');
      if (profile.heightCm != null) {
        sb.writeln('Boy: ${profile.heightCm!.toStringAsFixed(0)} cm');
      }
      if (profile.weightKg != null) {
        sb.writeln('Kilo: ${profile.weightKg!.toStringAsFixed(1)} kg');
      }
      sb.writeln('Durum: ${settings.treatmentMode.labelTr}');
      if (settings.treatmentMode.isDialysis) {
        sb.writeln(
          'Rezidüel idrar çıkışı: '
          '${settings.hasResidualUrine ? "var" : "yok"}',
        );
      }
      if (profile.comorbidities?.isNotEmpty == true) {
        sb.writeln('Diğer hastalıklar: ${profile.comorbidities}');
      }
      if (profile.allergies?.isNotEmpty == true) {
        sb.writeln('Alerjiler: ${profile.allergies}');
      }
      if (profile.dislikedFoods?.isNotEmpty == true) {
        sb.writeln('Sevmediği yemekler: ${profile.dislikedFoods}');
      }
      included.add(
        'Profil: yaş, boy, kilo, hastalık durumu, diğer hastalıklar, '
        'alerjiler, sevmediği yemekler',
      );

      sb.writeln();
      sb.writeln(
        profile.expertMode ? kAiExpertMode : kAiPlainMode,
      );
    }

    if (includeClinicalSettings) {
      sb.writeln();
      sb.writeln('--- KULLANICININ KENDİ KLİNİK AYARLARI ---');
      sb.writeln(
        '(Kullanıcı hekimdir ve bu değerleri kendisi belirlemiştir. '
        'Önerilerini bu değerlere göre yap.)',
      );
      for (final def in kDietTargets) {
        final r = settings.resolveDefinition(def);
        sb.writeln(
          '${def.labelTr}: ${r.formatted()} ${def.unit}'
          '${r.isCustom ? " (kullanıcı ayarı)" : " (varsayılan)"}',
        );
      }
      final protein = settings.dailyAbsolute('protein_g_per_kg');
      if (protein != null) {
        sb.writeln(
          'Günlük protein hedefi (hesaplanmış): '
          '${protein.toStringAsFixed(0)} g',
        );
      }
      for (final def in kAlarmThresholds) {
        final r = settings.resolveDefinition(def);
        if (!r.hasValue) continue;
        sb.writeln('ALARM — ${def.labelTr}: ${r.formatted()} ${def.unit}');
      }
      included.add(
        'Klinik ayarlar: diyet hedefleri ve alarm eşikleri',
      );
    }

    if (includeLabs && recentLabs.isNotEmpty) {
      sb.writeln();
      sb.writeln('--- SON TAHLİLLER (en yeniden eskiye) ---');
      for (final lab in recentLabs.take(20)) {
        final range = (lab.refMin != null && lab.refMax != null)
            ? ' [lab aralığı ${lab.refMin}-${lab.refMax}]'
            : '';
        sb.writeln(
          '${_dateTr(lab.takenAt)} — ${lab.analyteLabel}: '
          '${lab.value} ${lab.unit}$range',
        );
      }
      included.add('Son ${recentLabs.take(20).length} tahlil sonucu');
    }

    if (includeMedications && medications.isNotEmpty) {
      sb.writeln();
      sb.writeln('--- KULLANDIĞI İLAÇLAR ---');
      for (final m in medications) {
        sb.writeln(
          '${m.name}${m.dose == null ? "" : " ${m.dose}"} '
          '— saatler: ${m.times}',
        );
      }
      included.add('İlaç listesi (ad, doz, saat)');
    }

    final human = StringBuffer()
      ..writeln('Yapay zekaya şu bilgiler gönderilecek:')
      ..writeln();
    for (final item in included) {
      human.writeln('• $item');
    }
    if (included.isEmpty) {
      human.writeln('• Yalnızca yazdığın soru (başka hiçbir veri yok)');
    }
    human
      ..writeln()
      ..writeln('• Yazdığın soru metni')
      ..writeln()
      ..writeln(
        'Bunlar Anthropic\'in Claude API sunucusuna gönderilir. '
        'Adın, telefon numaran, doktorunun bilgileri ve acil durum '
        'kişilerin GÖNDERİLMEZ. İstersen aşağıdaki anahtarlarla '
        'hangi verinin gideceğini kısıtlayabilirsin.',
      );

    return AiContextSummary(
      systemPrompt: sb.toString(),
      humanReadableTr: human.toString(),
      includedItemsTr: included,
    );
  }

  /// Yemek fotoğrafı analizi komutu.
  String buildMealVisionPrompt({required ClinicalSettings settings}) {
    final targets = StringBuffer();
    for (final key in [
      'protein_g_per_kg',
      'sodium_mg',
      'potassium_mg',
      'phosphorus_mg',
    ]) {
      final r = settings.resolve(key);
      if (r.hasValue) {
        targets.writeln('${r.definition.labelTr}: ${r.formatted()} '
            '${r.definition.unit}');
      }
    }

    return '''
Sen bir besin tahmini yardımcısısın. Verilen fotoğraftaki yemeği
tanımla ve böbrek hastası için önemli besin değerlerini TAHMİN et.

$kAiSafetyRules

KULLANICININ GÜNLÜK HEDEFLERİ:
${targets.isEmpty ? "(hedef girilmemiş)" : targets}

ÇIKTI BİÇİMİ — tam olarak bu başlıkları kullan:

YEMEK: <tanıdığın yemeğin adı>
PORSİYON: <tahmini gram>
GÜVEN: <düşük | orta | yüksek>
KALORİ: <sayı> kcal (± <sapma>)
PROTEİN: <sayı> g (± <sapma>)
SODYUM: <sayı> mg (± <sapma>)
POTASYUM: <sayı> mg (± <sapma>)
FOSFOR: <sayı> mg (± <sapma>)
NOT: <bir iki cümle: neyi göremedin, ne belirsiz>

KURALLAR:
- Fotoğraftan porsiyonu kesin bilemezsin. Her sayının yanına
  gerçekçi bir ± sapma yaz.
- Tuz miktarını göremezsin: ev yapımı ile lokanta yemeği arasında
  sodyum kat kat değişir. Bunu NOT satırında yaz.
- Fotoğrafta yemek yoksa ya da tanıyamadıysan GÜVEN: düşük yaz ve
  NOT satırında bunu söyle; sayı uydurma.
- Görünmeyen malzemeleri (içine konan tereyağı, salça, tuz)
  tahmin ettiğini belirt.
''';
  }

  /// Tahlil kağıdı fotoğrafı analizi komutu.
  String buildLabVisionPrompt() => '''
Verilen fotoğraf bir laboratuvar tahlil raporudur. İçindeki
değerleri OKU ve listele. YORUM YAPMA, sadece oku.

$kAiSafetyRules

ÇIKTI BİÇİMİ — her satır için:
<analit adı> | <değer> | <birim> | <referans aralığı (varsa)>

KURALLAR:
- Yalnızca fotoğrafta GÖRDÜĞÜN değerleri yaz. Göremediğin satırı
  atlamak, uydurmaktan iyidir.
- Okuyamadığın bir karakter varsa o satırın sonuna "(okunamadı)" ekle.
- Virgül/nokta ayrımına dikkat et: Türk raporlarında ondalık
  ayırıcı virgüldür (4,5 = 4.5).
- Sonunda bir satırda: "GÖREMEDİĞİM/EMİN OLMADIĞIM: ..." yaz.
- Hiçbir değeri yorumlamayacaksın. "Yüksek", "düşük", "normal"
  gibi nitelemeler YAZMA.
''';

  /// Menü fotoğrafı analizi komutu.
  String buildMenuVisionPrompt({required ClinicalSettings settings}) {
    final sodium = settings.resolve('sodium_mg');
    final potassium = settings.resolve('potassium_mg');
    final phosphorus = settings.resolve('phosphorus_mg');

    return '''
Verilen fotoğraf bir restoran menüsüdür. Böbrek hastası için
uygun ve uygun olmayan seçenekleri ayır.

$kAiSafetyRules

KULLANICININ HEDEFLERİ:
Sodyum: ${sodium.formatted()} mg/gün
Potasyum: ${potassium.hasValue ? "${potassium.formatted()} mg/gün" : "hedef girilmemiş"}
Fosfor: ${phosphorus.hasValue ? "${phosphorus.formatted()} mg/gün" : "hedef girilmemiş"}

ÇIKTI BİÇİMİ:

İYİ SEÇENEKLER
• <yemek adı> — <neden uygun, nasıl sipariş etmeli>

DİKKATLİ OL
• <yemek adı> — <neden dikkat, nasıl azaltılır>

KAÇIN
• <yemek adı> — <neden>

SİPARİŞ CÜMLESİ
<garsona söyleyebileceği tek bir cümle>

KURALLAR:
- Menüde OLMAYAN yemeği yazma.
- Okuyamadığın kalemleri "okunamadı" diye ayrı listele.
- Besin değeri SAYISI verme: menüden porsiyon ve tuz bilinmez.
  Sadece göreli olarak "yüksek/düşük sodyum beklenir" de.
''';
  }

  /// Sağlık verisi yorumlama komutu.
  String buildHealthInterpretPrompt({
    required ClinicalSettings settings,
    required bool expertMode,
  }) =>
      '''
Sana bir akıllı saatten / telefondan okunan sağlık verileri
verilecek. Bunları yorumla.

$kAiSafetyRules
${expertMode ? kAiExpertMode : kAiPlainMode}

EK KURALLAR:
- Akıllı saat ölçümleri TIBBİ CİHAZ DOĞRULUĞUNDA DEĞİLDİR.
  Yorumuna bunu bir kez yaz.
- Tek bir ölçüm değil, EĞİLİM (trend) üzerine konuş.
- Kullanıcının kendi alarm eşiklerini referans al.
- Sayıları tekrar etmek yerine ne anlama geldiğini yaz.
- En fazla 4 madde yaz.
''';

  /// Seyahat planı komutu.
  String buildTravelPrompt({
    required ClinicalSettings settings,
    required ProfileRow? profile,
    required String destination,
    required int days,
  }) {
    final fluid = settings.resolve('fluid_ml');
    final sodium = settings.resolve('sodium_mg');

    return '''
Kullanıcı $destination'a $days günlük bir seyahat planlıyor.
Böbrek hastası için bir "gastro-seyahat planı" hazırla.

$kAiSafetyRules

KULLANICI BİLGİLERİ:
Durum: ${settings.treatmentMode.labelTr}
Sıvı limiti: ${fluid.isCleared || !fluid.hasValue ? "limit yok" : "${fluid.formatted()} mL/gün"}
Sodyum hedefi: ${sodium.formatted()} mg/gün
${profile?.allergies?.isNotEmpty == true ? "Alerjiler: ${profile!.allergies}" : ""}
${profile?.dislikedFoods?.isNotEmpty == true ? "Sevmediği yemekler: ${profile!.dislikedFoods}" : ""}

ÇIKTI BİÇİMİ (Markdown başlıkları kullan):

## Yolda
- Yenebilecekler ve neden
- Kaçınılacaklar ve neden

## $destination mutfağı
- Bu yöredeki hangi yemekler böbrek diyetine uygun
- Hangileri riskli (yüksek tuz/potasyum/fosfor) ve nasıl hafifletilir

## Sıvı ve ilaç saatleri
- Yol boyunca sıvıyı nasıl böler
- İlaç saatleri için pratik öneriler (saat dilimi değişirse ne yapar)

## Hazırlık listesi
- Yanına alması gerekenler

## Diyaliz/kontrol
${settings.treatmentMode.isDialysis ? "- Gidilen yerde konuk diyaliz için neleri önceden ayarlaması gerekir" : "- Kontrol ve tahlil takvimi seyahate denk geliyorsa ne yapmalı"}

KURALLAR:
- Belirli bir restoran veya otel adı UYDURMA. Yöresel yemek
  türlerinden konuş.
- Konuk diyaliz için "merkezle ve hekiminle önceden görüş" de;
  merkez adı veya telefon uydurma.
- Sıvı limiti varsa hiçbir yerde "bol su iç" yazma.
''';
  }
}

String _dateTr(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.'
    '${d.month.toString().padLeft(2, '0')}.${d.year}';
