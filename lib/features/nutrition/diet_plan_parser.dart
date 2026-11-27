/// Diyet planı metnini ÖĞÜNLERE ve KAÇINILACAKLARA ayırır.
///
/// Saf fonksiyonlar: ekrana, veritabanına ve ağa bağlı değil, bu yüzden
/// test edilebiliyor. Diyetisyen kağıdı fotoğraftan okunduğunda metin
/// bozuk gelebilir — çözümleyici "yakalayabildiğini" döner, kesinlik
/// iddia etmez; kullanıcı sonucu her zaman düzeltir.
library;

import '../../clinical/definitions.dart' show Verification;
import '../../core/i18n/i18n.dart';

/// Plandan çıkarılmış tek bir öğün.
class ParsedMeal {
  const ParsedMeal({
    required this.name,
    this.detail,
    this.timeHint,
  });

  /// "Kahvaltı", "Ara öğün", "Akşam"…
  final String name;

  /// Başlığın altındaki satırlar (plandaki içerik).
  final String? detail;

  /// Başlıkta saat yazıyorsa ("Kahvaltı (08:00)") "08:00".
  final String? timeHint;

  @override
  String toString() => 'ParsedMeal($name)';
}

/// Plan metninin çözümlenmiş hâli.
class ParsedDietPlan {
  const ParsedDietPlan({required this.meals, required this.avoid});

  final List<ParsedMeal> meals;

  /// "Kaçınılacaklar" bölümünden çıkan maddeler.
  final List<String> avoid;

  bool get isEmpty => meals.isEmpty && avoid.isEmpty;
}

/// Türkçe öğün başlıkları.
///
/// Sıra ÖNEMLİ: uzun ad önce denenir, yoksa "Ara öğün" satırında
/// "öğle" aranırken "ara" eşleşip yanlış başlık üretilebilir.
const List<({String canonical, List<String> aliases})> kMealHeadings = [
  (canonical: 'Kahvaltı', aliases: ['kahvaltı', 'kahvaltu', 'sabah']),
  (
    canonical: 'Kuşluk (ara öğün)',
    aliases: ['kuşluk', 'kusluk', 'sabah ara', 'sabah arası'],
  ),
  (canonical: 'Öğle', aliases: ['öğle yemeği', 'öğlen', 'öğle', 'ogle']),
  (
    canonical: 'İkindi (ara öğün)',
    aliases: ['ikindi', 'öğleden sonra', 'öğle arası'],
  ),
  (canonical: 'Akşam', aliases: ['akşam yemeği', 'akşam', 'aksam']),
  (
    canonical: 'Gece',
    aliases: ['gece', 'yatmadan önce', 'yatmadan', 'gece ara'],
  ),
  (canonical: 'Ara öğün', aliases: ['ara öğün', 'ara ögün', 'ara']),
];

/// Hiç başlık bulunamazsa kullanılan standart liste.
const List<String> kDefaultMealNames = [
  'Kahvaltı',
  'Ara öğün',
  'Öğle',
  'Akşam',
  'Gece',
];

/// "Kaçınılacaklar" bölümünü başlatan sözcükler.
const List<String> kAvoidHeadings = [
  'kaçınılacaklar',
  'kaçınılacak',
  'kaçın',
  'yasak',
  'yenmeyecekler',
  'tüketilmeyecek',
  'uzak durulacaklar',
  'uzak dur',
  'sınırlanacaklar',
];

/// Türkçe küçük harfe çevirir (I/İ sorununu düzeltir).
String trLower(String s) => s
    .replaceAll('I', 'ı')
    .replaceAll('İ', 'i')
    .toLowerCase();

/// Karşılaştırma için Türkçe harfleri sadeleştirir: "Kahvaltı" ve
/// "Kahvalti" aynı şeye iner.
///
/// NEDEN GEREKLİ: fotoğraftan okuma (OCR) Türkçe işaretleri sık
/// düşürür — "Kahvaltı" çoğu zaman "Kahvalti", "Öğle" ise "Ogle"
/// gelir. İnsanlar da telefonda plan yazarken işaretleri kullanmayı
/// bırakabiliyor. Eşleştirme işaretlere bağlı kalırsa öğün başlığı
/// tanınmaz, altındaki satırlar bir önceki öğüne yapışır ve
/// "Kaçınılacaklar" bölümü bile öğün içeriği sanılır — bu tam olarak
/// ilk denemede olan şeydi.
///
/// Yalnız KARŞILAŞTIRMA için kullanılır; gösterilen metin hiç
/// değişmez.
String foldTr(String s) {
  const map = {
    'ı': 'i',
    'İ': 'i',
    'I': 'i',
    'ş': 's',
    'Ş': 's',
    'ğ': 'g',
    'Ğ': 'g',
    'ü': 'u',
    'Ü': 'u',
    'ö': 'o',
    'Ö': 'o',
    'ç': 'c',
    'Ç': 'c',
    'â': 'a',
    'Â': 'a',
    'î': 'i',
    'û': 'u',
  };
  final buffer = StringBuffer();
  for (final ch in s.split('')) {
    buffer.write(map[ch] ?? ch);
  }
  return buffer.toString().toLowerCase();
}

final RegExp _bulletPrefix = RegExp(r'^[\s\-\*•·–—]+');
final RegExp _numberPrefix = RegExp(r'^\s*\d+\s*[\.\)]\s*');
final RegExp _timeInHeading = RegExp(r'(\d{1,2})[:.](\d{2})');

String _stripBullet(String line) =>
    line.replaceFirst(_bulletPrefix, '').replaceFirst(_numberPrefix, '').trim();

/// Yalnız madde işaretini atar, baştaki SAYIYI bırakır.
///
/// Başlık ararken sayı gerekli: "3. Öğün" numaralı bir başlıktır.
String _stripBulletOnly(String line) =>
    line.replaceFirst(_bulletPrefix, '').trim();

/// Başlığı içerikten ayıran işaretin yerini bulur.
///
/// DİKKAT — İKİ TUZAK: ayırıcıyı düz bir `[:\-]` araması bulamaz.
///  * "Kahvaltı (08:00):" satırında ilk iki nokta SAATİN içindedir;
///    orada bölünürse başlık "Kahvaltı (08" olur ve hiçbir takma ada
///    uymaz — öğün kaybolur, altındaki satırlar bir önceki öğüne
///    yapışır.
///  * Parantez içindeki tire de ayırıcı değildir.
/// Bu yüzden parantez derinliği izlenir ve iki rakam ARASINDAKİ iki
/// nokta atlanır.
int _separatorIndex(String line) {
  var depth = 0;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (c == '(' || c == '[') depth++;
    if (c == ')' || c == ']') depth = depth > 0 ? depth - 1 : 0;
    if (depth > 0) continue;
    if (c == ':') {
      final prevDigit = i > 0 && _isDigit(line[i - 1]);
      final nextDigit = i + 1 < line.length && _isDigit(line[i + 1]);
      if (prevDigit && nextDigit) continue;
      return i;
    }
    if (c == '-' || c == '–' || c == '—') return i;
  }
  return -1;
}

bool _isDigit(String c) => c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;

/// Satır bir öğün başlığı mı? Öyleyse (ad, saat, kalan metin) döner.
({String name, String? time, String rest})? matchMealHeading(String rawLine) {
  final line = _stripBulletOnly(rawLine);
  if (line.isEmpty) return null;

  final sepIndex = _separatorIndex(line);
  final head = sepIndex < 0 ? line : line.substring(0, sepIndex);
  final rest = sepIndex < 0 ? '' : line.substring(sepIndex + 1).trim();

  // Başlık uzunsa cümledir, başlık değildir.
  if (head.trim().length > 32) return null;

  final lowered = foldTr(head);
  // "2. öğün" gibi numaralı başlıklar.
  final numbered =
      RegExp(r'^\s*(\d+)\s*[\.\)]?\s*ogun\s*$').firstMatch(lowered);
  if (numbered != null) {
    return (
      name: tf('{0}. öğün', [numbered.group(1)]),
      time: _timeOf(head),
      rest: rest,
    );
  }

  for (final h in kMealHeadings) {
    for (final alias in h.aliases) {
      // Başlık tam olarak takma addan (ve varsa saat/parantezden) ibaret
      // olmalı; "öğle yemeğinde zeytinyağlı sebze ye" bir başlık değildir.
      final cleaned = lowered
          .replaceAll(RegExp(r'\(.*?\)'), '')
          .replaceAll(RegExp(r'[0-9:.]'), '')
          .replaceAll('ogunu', '')
          .replaceAll('ogun', '')
          .replaceAll('yemegi', '')
          .trim();
      if (cleaned == foldTr(alias)) {
        return (name: h.canonical, time: _timeOf(head), rest: rest);
      }
    }
  }
  return null;
}

String? _timeOf(String head) {
  final m = _timeInHeading.firstMatch(head);
  if (m == null) return null;
  final hour = int.tryParse(m.group(1)!);
  final minute = int.tryParse(m.group(2)!);
  if (hour == null || minute == null) return null;
  if (hour > 23 || minute > 59) return null;
  return '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}

bool _isAvoidHeading(String rawLine) {
  final line = foldTr(_stripBullet(rawLine));
  if (line.isEmpty || line.length > 48) return false;
  for (final h in kAvoidHeadings) {
    if (line.startsWith(foldTr(h))) return true;
  }
  return false;
}

/// Plan metnini öğünlere ve kaçınılacaklara ayırır.
ParsedDietPlan parseDietPlan(String text) {
  final meals = <ParsedMeal>[];
  final avoid = <String>[];

  String? currentName;
  String? currentTime;
  final currentLines = <String>[];
  var inAvoid = false;

  void flushMeal() {
    if (currentName == null) return;
    final detail = currentLines.join('\n').trim();
    meals.add(
      ParsedMeal(
        name: currentName!,
        detail: detail.isEmpty ? null : detail,
        timeHint: currentTime,
      ),
    );
    currentName = null;
    currentTime = null;
    currentLines.clear();
  }

  for (final rawLine in text.split('\n')) {
    final line = rawLine.trimRight();
    if (line.trim().isEmpty) continue;

    if (_isAvoidHeading(line)) {
      flushMeal();
      inAvoid = true;
      // Başlıkla aynı satırda liste olabilir: "Kaçınılacaklar: tuz, turşu"
      final sep = RegExp(r'[:\-–—]').firstMatch(_stripBullet(line));
      if (sep != null) {
        avoid.addAll(splitAvoidItems(_stripBullet(line).substring(sep.end)));
      }
      continue;
    }

    final heading = matchMealHeading(line);
    if (heading != null) {
      flushMeal();
      inAvoid = false;
      currentName = heading.name;
      currentTime = heading.time;
      if (heading.rest.isNotEmpty) currentLines.add(heading.rest);
      continue;
    }

    if (inAvoid) {
      avoid.addAll(splitAvoidItems(line));
    } else if (currentName != null) {
      currentLines.add(_stripBullet(line));
    }
  }
  flushMeal();

  // Aynı başlık iki kez geçerse ikincisini ayrı öğün say ("Ara öğün" x2)
  // ama birebir aynı ve içeriksiz tekrarları at.
  final seen = <String>{};
  final uniqueMeals = <ParsedMeal>[];
  for (final m in meals) {
    final key = '${foldTr(m.name)}|${m.detail ?? ""}';
    if (m.detail == null && !seen.add(key)) continue;
    uniqueMeals.add(m);
  }

  return ParsedDietPlan(
    meals: uniqueMeals,
    avoid: dedupeAvoid(avoid),
  );
}

/// "tuz, turşu; salamura" → ["tuz", "turşu", "salamura"]
List<String> splitAvoidItems(String line) {
  final cleaned = _stripBullet(line);
  if (cleaned.isEmpty) return const [];
  return cleaned
      .split(RegExp(r'[,;•·]|\s+ve\s+'))
      .map((s) => _stripBullet(s).replaceAll(RegExp(r'[.]+$'), '').trim())
      .where((s) => s.length >= 2 && s.length <= 60)
      .toList(growable: false);
}

/// Büyük/küçük harf ve baştaki/sondaki boşluk farklarını birleştirir.
List<String> dedupeAvoid(Iterable<String> items) {
  final seen = <String>{};
  final out = <String>[];
  for (final item in items) {
    final key = foldTr(item).trim();
    if (key.isEmpty) continue;
    if (!seen.add(key)) continue;
    out.add(item.trim());
  }
  return out;
}

// ---------------------------------------------------------------------------
// HAZIR KAÇINILACAKLAR LİSTESİ
// ---------------------------------------------------------------------------

/// Hazır listedeki tek bir madde.
///
/// DİKKAT: Bu liste bir TALİMAT DEĞİLDİR, bir başlangıç listesidir.
/// Her maddenin yanında hangi kaynağa dayandığı ve o kaynağın ne kadar
/// kesin konuştuğu ([verification]) yazar. Potasyum maddeleri
/// "bireyselleştirilir" etiketlidir: KDOQI 2020 potasyum için SAYI
/// VERMEZ ve herkese kısıtlama önermez — yalnız serum potasyumu
/// yüksekse ve hekim söylediyse anlamlıdır.
class AvoidLibraryItem {
  const AvoidLibraryItem({
    required this.label,
    required this.reasonTr,
    required this.sourceId,
    required this.verification,
    required this.group,
  });

  final String label;
  final String reasonTr;

  /// `lib/clinical/sources.dart` içindeki kaynak kimliği.
  final String sourceId;
  final Verification verification;

  /// 'sodyum' | 'fosfor' | 'potasyum' | 'ilaç'
  final String group;
}

/// Böbrek hastalığında sık geçen kaçınma maddeleri.
///
/// KAPSAMLI DEĞİLDİR ve kişiye özel değildir. Kullanıcı istediğini
/// siler, istediğini ekler.
const List<AvoidLibraryItem> kAvoidLibrary = [
  // --- SODYUM: KDOQI 2020 sayı veriyor (<2,3 g/gün sodyum) ---
  AvoidLibraryItem(
    label: 'Sofrada tuzluk',
    reasonTr: 'Yemeğe sonradan eklenen tuz, günlük sodyumun büyük '
        'bölümünü tek başına doldurabilir.',
    sourceId: 'kdoqi_nutrition_2020',
    verification: Verification.verified,
    group: 'sodyum',
  ),
  AvoidLibraryItem(
    label: 'Turşu ve salamura',
    reasonTr: 'Salamura suyu yoğun sodyum içerir.',
    sourceId: 'kdoqi_nutrition_2020',
    verification: Verification.verified,
    group: 'sodyum',
  ),
  AvoidLibraryItem(
    label: 'Şarküteri (salam, sucuk, sosis, pastırma)',
    reasonTr: 'Hem tuz hem fosfat katkısı yüksektir.',
    sourceId: 'kdoqi_nutrition_2020',
    verification: Verification.verified,
    group: 'sodyum',
  ),
  AvoidLibraryItem(
    label: 'Hazır çorba, bulyon, tablet et suyu',
    reasonTr: 'Tek porsiyonu günlük sodyumun önemli bir kısmını '
        'karşılayabilir.',
    sourceId: 'kdoqi_nutrition_2020',
    verification: Verification.verified,
    group: 'sodyum',
  ),
  AvoidLibraryItem(
    label: 'Cips, kraker, tuzlu kuruyemiş',
    reasonTr: 'Tuz yoğun atıştırmalıklar.',
    sourceId: 'kdoqi_nutrition_2020',
    verification: Verification.verified,
    group: 'sodyum',
  ),
  AvoidLibraryItem(
    label: 'Konserve sebze ve bakliyat (suyuyla)',
    reasonTr: 'Konserve suyu tuzludur; süzüp durulamak sodyumu azaltır.',
    sourceId: 'kdoqi_nutrition_2020',
    verification: Verification.verified,
    group: 'sodyum',
  ),

  // --- FOSFOR KATKILARI: KDOQI 2020 katkı kaynağına dikkat çeker ---
  AvoidLibraryItem(
    label: 'Kola ve koyu renkli gazozlar',
    reasonTr: 'Fosforik asit içerir; katkı fosforu besindeki fosfordan '
        'çok daha fazla emilir.',
    sourceId: 'kdoqi_nutrition_2020',
    verification: Verification.verified,
    group: 'fosfor',
  ),
  AvoidLibraryItem(
    label: 'İçeriğinde "fosfat" geçen paketli ürünler',
    reasonTr: 'Etikette fosfat katkısı (E338-E452) varsa fosfor yükü '
        'yüksektir.',
    sourceId: 'kdoqi_nutrition_2020',
    verification: Verification.verified,
    group: 'fosfor',
  ),
  AvoidLibraryItem(
    label: 'İşlenmiş/eritme peynir',
    reasonTr: 'Hem fosfat katkısı hem tuz içerir.',
    sourceId: 'kdoqi_nutrition_2020',
    verification: Verification.verified,
    group: 'fosfor',
  ),

  // --- POTASYUM: kılavuz SAYI VERMEZ, bireyselleştirilir ---
  AvoidLibraryItem(
    label: 'Muz',
    reasonTr: 'Potasyumdan zengin. KILAVUZ HERKESE KISITLAMA ÖNERMEZ: '
        'yalnız serum potasyumun yüksekse ve hekimin söylediyse işaretle.',
    sourceId: 'kdigo_potassium_2020',
    verification: Verification.individualized,
    group: 'potasyum',
  ),
  AvoidLibraryItem(
    label: 'Kuru kayısı, kuru üzüm, kuru incir',
    reasonTr: 'Kurutulmuş meyvede potasyum yoğunlaşır. Kısıtlama '
        'kişiye özeldir.',
    sourceId: 'kdigo_potassium_2020',
    verification: Verification.individualized,
    group: 'potasyum',
  ),
  AvoidLibraryItem(
    label: 'Patates (haşlanıp suyu dökülmemiş)',
    reasonTr: 'Doğrayıp bol suda haşlayıp suyunu dökmek potasyumu '
        'azaltır. Kısıtlama kişiye özeldir.',
    sourceId: 'kdigo_potassium_2020',
    verification: Verification.individualized,
    group: 'potasyum',
  ),
  AvoidLibraryItem(
    label: 'Domates salçası ve konsantre domates',
    reasonTr: 'Konsantre edildiği için potasyum yoğundur. Kısıtlama '
        'kişiye özeldir.',
    sourceId: 'kdigo_potassium_2020',
    verification: Verification.individualized,
    group: 'potasyum',
  ),
  AvoidLibraryItem(
    label: 'Tuz yerine geçen ürünler (potasyum klorür)',
    reasonTr: 'Düşük sodyumlu "diyet tuzu" çoğunlukla POTASYUM '
        'klorürdür ve böbrek hastasında tehlikeli olabilir.',
    sourceId: 'kdigo_potassium_2020',
    verification: Verification.verified,
    group: 'potasyum',
  ),

  // --- İLAÇ / TAKVİYE: NKF kurum sayfaları ---
  AvoidLibraryItem(
    label: 'Ağrı kesici (ibuprofen, naproksen gibi NSAİİ)',
    reasonTr: 'Böbrek fonksiyonunu bozabilir. Hekimine sormadan alma.',
    sourceId: 'nkf_pain_meds',
    verification: Verification.verified,
    group: 'ilaç',
  ),
  AvoidLibraryItem(
    label: 'Bitkisel ürün ve bitki çayı takviyeleri',
    reasonTr: 'Böbrek hastalarında genel olarak önerilmez; içeriği '
        'denetlenmez.',
    sourceId: 'nkf_herbal',
    verification: Verification.verified,
    group: 'ilaç',
  ),
];

/// Hazır listenin kullanıcıya gösterilen grup adları.
const Map<String, String> kAvoidGroupLabels = {
  'sodyum': 'Tuz / sodyum',
  'fosfor': 'Fosfor katkısı',
  'potasyum': 'Potasyum (kişiye özel)',
  'ilaç': 'İlaç ve takviye',
};

// ---------------------------------------------------------------------------
// UYUM HESABI
// ---------------------------------------------------------------------------

/// Bir öğünün o günkü işareti.
enum MealMark {
  /// Plana uyuldu.
  full,

  /// Kısmen uyuldu.
  partial,

  /// Uyulmadı.
  missed;

  static MealMark? fromCode(String? code) => switch (code) {
        'full' => MealMark.full,
        'partial' => MealMark.partial,
        'missed' => MealMark.missed,
        _ => null,
      };

  String get code => switch (this) {
        MealMark.full => 'full',
        MealMark.partial => 'partial',
        MealMark.missed => 'missed',
      };

  String get labelTr => switch (this) {
        MealMark.full => 'Uydum',
        MealMark.partial => 'Kısmen',
        MealMark.missed => 'Uymadım',
      };

  /// Yüzde hesabındaki ağırlığı.
  int get score => switch (this) {
        MealMark.full => 100,
        MealMark.partial => 50,
        MealMark.missed => 0,
      };
}

/// İşaretlenen öğünlerden günün uyum yüzdesini hesaplar.
///
/// YALNIZ İŞARETLENMİŞ öğünler hesaba katılır: daha öğlen olmadan
/// "akşam yemeğine uymadın" demek yanlış olurdu. Hiç işaret yoksa null
/// döner ve o gün "kayıt yok" sayılır.
int? adherencePercent(Iterable<MealMark> marks) {
  final list = marks.toList(growable: false);
  if (list.isEmpty) return null;
  final total = list.fold<int>(0, (sum, m) => sum + m.score);
  return (total / list.length).round();
}
