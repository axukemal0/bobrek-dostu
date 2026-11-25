/// Ambalaj besin değerleri tablosunu OCR metninden çözümler.
///
/// SAF fonksiyonlar — testlerle doğrulanır, arayüzden bağımsızdır.
///
/// Neden ayrı bir çözümleyici: önceki sürüm etiketteki sayıyı
/// `anahtar[^0-9]{0,20}(sayı)` kalıbıyla yakalıyordu ve bu, böbrek hastası
/// için en kritik üç alanda sessizce yanlış sonuç veriyordu:
///
///  1. **Tuz.** Türkiye'deki etiketler neredeyse her zaman "Sodyum" değil
///     **"Tuz"** yazar. Eski kalıp "sodyum" arıyordu, bulamıyordu ve sodyum
///     alanı BOŞ kalıyordu — yani günün en önemli kısıtı hiç okunmuyordu.
///     Tuz (g) × 400 = sodyum (mg).
///  2. **Enerji.** Etiket "1850 kJ / 442 kcal" yazar. Eski kalıp ilk sayıyı
///     (kJ) alıp kcal diye kaydediyordu: ~4,2 kat fazla.
///  3. **Sütun.** AB/TR etiketlerinde iki sütun vardır: "100 g'da" ve
///     "porsiyonda". Eski kalıp hangisi önce geldiyse onu alıyordu; değer
///     100 g kabul edilip porsiyona göre ölçeklendiği için sonuç iki katına
///     çıkabiliyor ya da yarıya inebiliyordu.
///
/// Bu çözümleyici birimi, sütunu ve türetmeyi AÇIKÇA raporlar; arayüz de
/// bunları kullanıcıya gösterir. Karar yine kullanıcınındır.
library;

/// Değerin hangi sütundan okunduğu.
enum NutrientBasis {
  /// "100 g'da" / "100 ml'de" sütunu.
  per100,

  /// "Porsiyonda" / "Bir serviste" sütunu.
  perPortion,

  /// Sütun ayırt edilemedi — kullanıcı onaylamalı.
  unknown,
}

extension NutrientBasisTr on NutrientBasis {
  String get labelTr => switch (this) {
        NutrientBasis.per100 => '100 g/ml için',
        NutrientBasis.perPortion => 'porsiyon için',
        NutrientBasis.unknown => 'sütun belirsiz',
      };
}

/// Okunan değere ne kadar güvenilebilir.
enum LabelConfidence { high, medium, low }

extension LabelConfidenceTr on LabelConfidence {
  String get labelTr => switch (this) {
        LabelConfidence.high => 'net okundu',
        LabelConfidence.medium => 'okundu, kontrol et',
        LabelConfidence.low => 'şüpheli, mutlaka kontrol et',
      };
}

/// Etiketten okunan tek bir alan.
class LabelField {
  const LabelField({
    required this.value,
    required this.unit,
    required this.basis,
    required this.confidence,
    required this.sourceLine,
    this.derivationTr,
  });

  /// Kanonik birimdeki değer: kcal, protein g, sodyum/potasyum/fosfor mg.
  final double value;
  final String unit;
  final NutrientBasis basis;
  final LabelConfidence confidence;

  /// Değerin okunduğu ham OCR satırı — kullanıcı karşılaştırabilsin diye.
  final String sourceLine;

  /// Doğrudan okunmadıysa nasıl elde edildiği ("Tuz 1,2 g → sodyum").
  final String? derivationTr;
}

/// Etiketin tamamı.
class ParsedNutritionLabel {
  const ParsedNutritionLabel({
    required this.fields,
    required this.basis,
    this.portionG,
    this.portionLabelTr,
    this.productName,
  });

  /// Anahtarlar: kcal, protein, sodium, potassium, phosphorus,
  /// carbs, sugar, fat, saturatedFat, fiber.
  final Map<String, LabelField> fields;

  /// Tablonun genel sütun yorumu.
  final NutrientBasis basis;

  /// Etikette yazan porsiyon ağırlığı (varsa).
  final double? portionG;
  final String? portionLabelTr;

  final String? productName;

  LabelField? operator [](String key) => fields[key];

  bool get isEmpty => fields.isEmpty;

  /// Böbrek diyeti için kritik alanlardan okunamayanlar.
  List<String> get missingCriticalTr => [
        if (fields['sodium'] == null) 'sodyum/tuz',
        if (fields['potassium'] == null) 'potasyum',
        if (fields['phosphorus'] == null) 'fosfor',
      ];
}

// ---------------------------------------------------------------------------
// Normalleştirme
// ---------------------------------------------------------------------------

/// Türkçeye uygun küçültme. Dart'ın `toLowerCase()`'i 'I' harfini 'i' yapar
/// (Türkçede 'ı' olmalı) ve 'İ' için birleşik nokta üretir.
String normalizeLabelText(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    buffer.writeCharCode(switch (rune) {
      0x49 => 0x131, // I -> ı
      0x130 => 0x69, // İ -> i
      _ => rune,
    });
  }
  return buffer
      .toString()
      .toLowerCase()
      // SIRA ÖNEMLİ. Önce binlik ayırıcı nokta atılır ("1.850 kj" -> "1850 kj"),
      // sonra ondalık virgül noktaya çevrilir. Ters sırada "12,345 g" önce
      // "12.345" olup ardından binlik kuralına takılır ve 12345'e şişerdi.
      // (AB/TR etiket biçimi: ondalık ayırıcı virgül, binlik ayırıcı nokta.)
      .replaceAllMapped(RegExp(r'(\d)\.(\d{3})(?!\d)'), (m) => '${m[1]}${m[2]}')
      .replaceAllMapped(RegExp(r'(\d),(\d)'), (m) => '${m[1]}.${m[2]}')
      .replaceAll(' ', ' ')
      .replaceAll(' ', ' ');
}

/// Satırdaki "sayı + birim" çiftleri, göründükleri sırayla.
class _Measure {
  const _Measure(this.value, this.unit);
  final double value;
  final String unit; // '', 'g', 'mg', 'µg', 'kcal', 'kj', 'ml'
}

final RegExp _measureRe = RegExp(
  r'(\d+(?:\.\d+)?)\s*(kcal|kj|mg|mcg|µg|ug|g|ml|%)?',
  caseSensitive: false,
);

List<_Measure> _measures(String line) {
  final out = <_Measure>[];
  for (final m in _measureRe.allMatches(line)) {
    final v = double.tryParse(m.group(1)!);
    if (v == null) continue;
    var unit = (m.group(2) ?? '').toLowerCase();
    if (unit == 'mcg' || unit == 'ug') unit = 'µg';
    out.add(_Measure(v, unit));
  }
  return out;
}

// ---------------------------------------------------------------------------
// Besin adları
// ---------------------------------------------------------------------------

/// Uzun eşleşme önce denenir ("doymuş yağ" > "yağ").
const Map<String, List<String>> _aliases = {
  'kcal': ['enerji', 'energy', 'kalori', 'enerji değeri'],
  'protein': ['protein', 'proteinler'],
  'carbs': ['karbonhidrat', 'karbonhidratlar', 'carbohydrate'],
  'sugar': ['şeker', 'seker', 'sugars', 'şekerler'],
  'fat': ['yağ', 'yag', 'fat'],
  'saturatedFat': ['doymuş yağ', 'doymus yag', 'saturates', 'doymuş yağlar'],
  'fiber': ['lif', 'posa', 'fibre', 'fiber', 'diyet lifi'],
  'salt': ['tuz', 'salt'],
  'sodium': ['sodyum', 'sodium', 'na'],
  'potassium': ['potasyum', 'potassium'],
  'phosphorus': ['fosfor', 'fosfat', 'phosphorus', 'phosphate'],
};

/// Alt satırların ("doymuş yağ") üst satır adıyla ("yağ") eşleşmemesi için
/// önce daha uzun adlar denenir.
final List<MapEntry<String, String>> _aliasIndex = () {
  final entries = <MapEntry<String, String>>[];
  _aliases.forEach((key, names) {
    for (final n in names) {
      entries.add(MapEntry(n, key));
    }
  });
  entries.sort((a, b) => b.key.length.compareTo(a.key.length));
  return entries;
}();

String? _nutrientOf(String line) {
  for (final e in _aliasIndex) {
    // Kelime sınırıyla ara: "na" her yerde eşleşmesin.
    final re = RegExp('(?<![a-zçğıöşü])${RegExp.escape(e.key)}(?![a-zçğıöşü])');
    if (re.hasMatch(line)) return e.value;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Sütun düzeni
// ---------------------------------------------------------------------------

class _Layout {
  const _Layout({required this.per100Index, required this.portionIndex});

  /// Değer listesinde "100 g" sütununun sırası (bulunamazsa null).
  final int? per100Index;
  final int? portionIndex;

  bool get known => per100Index != null || portionIndex != null;
}

final RegExp _per100Re = RegExp(r'100\s*(g|gr|ml)');
final RegExp _portionRe =
    RegExp(r'porsiyon|porsiyonda|servis|serviste|bir\s*adet|paket');

_Layout _detectLayout(List<String> lines) {
  for (final line in lines) {
    final hasPer100 = _per100Re.hasMatch(line);
    final hasPortion = _portionRe.hasMatch(line);
    if (!hasPer100 && !hasPortion) continue;

    if (hasPer100 && hasPortion) {
      // Hangisi önce yazılmış?
      final i100 = _per100Re.firstMatch(line)!.start;
      final iPortion = _portionRe.firstMatch(line)!.start;
      return i100 < iPortion
          ? const _Layout(per100Index: 0, portionIndex: 1)
          : const _Layout(per100Index: 1, portionIndex: 0);
    }
    if (hasPer100) return const _Layout(per100Index: 0, portionIndex: null);
    // Yalnız porsiyon sütunu var.
    return const _Layout(per100Index: null, portionIndex: 0);
  }
  return const _Layout(per100Index: null, portionIndex: null);
}

/// Etiketteki porsiyon ağırlığı: "porsiyon (30 g)", "1 porsiyon = 250 ml".
({double? grams, String? labelTr}) _detectPortion(List<String> lines) {
  for (final line in lines) {
    if (!_portionRe.hasMatch(line)) continue;
    // Satırdaki TÜM ölçüleri gez: başlıkta önce "100 g'da" geçtiği için
    // ilk eşleşmeye bakmak porsiyonu ("Porsiyonda (30 g)") kaçırıyordu.
    for (final m in RegExp(r'(\d+(?:\.\d+)?)\s*(g|gr|ml)\b').allMatches(line)) {
      final v = double.tryParse(m.group(1)!);
      if (v == null || v <= 0 || v > 2000) continue;
      // "100 g'da" başlığını porsiyon sanma.
      if (v == 100 && _per100Re.hasMatch(line)) continue;
      return (grams: v, labelTr: line.trim());
    }
  }
  return (grams: null, labelTr: null);
}

// ---------------------------------------------------------------------------
// Ana çözümleyici
// ---------------------------------------------------------------------------

/// OCR satırlarından besin değerleri tablosunu çıkarır.
ParsedNutritionLabel parseNutritionLabel(String rawText) {
  final normalized = normalizeLabelText(rawText);
  final rawLines = rawText.split('\n');
  final lines = normalized
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  if (lines.isEmpty) {
    return const ParsedNutritionLabel(
      fields: {},
      basis: NutrientBasis.unknown,
    );
  }

  final layout = _detectLayout(lines);
  final portion = _detectPortion(lines);
  final fields = <String, LabelField>{};

  String rawLineFor(int index) {
    // Normalleştirilmiş satır sırası ham metinle birebir olmayabilir;
    // yaklaşık eşleşme kullanıcıya yeter.
    final candidates = rawLines.where((l) => l.trim().isNotEmpty).toList();
    return index < candidates.length ? candidates[index].trim() : lines[index];
  }

  /// Satırdaki ölçümlerden doğru sütunu seçer.
  ({_Measure m, NutrientBasis basis, LabelConfidence conf})? pick(
    List<_Measure> ms,
  ) {
    if (ms.isEmpty) return null;
    if (layout.per100Index != null && ms.length > layout.per100Index!) {
      return (
        m: ms[layout.per100Index!],
        basis: NutrientBasis.per100,
        conf: LabelConfidence.high
      );
    }
    if (layout.portionIndex != null && ms.length > layout.portionIndex!) {
      return (
        m: ms[layout.portionIndex!],
        basis: NutrientBasis.perPortion,
        conf: LabelConfidence.high
      );
    }
    return (
      m: ms.first,
      basis: NutrientBasis.unknown,
      conf: LabelConfidence.low
    );
  }

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final nutrient = _nutrientOf(line);
    if (nutrient == null) continue;
    if (fields.containsKey(nutrient)) continue;

    var ms = _measures(line);
    var usedLine = i;
    var nextLinePenalty = false;

    // Değer bir alt satıra düşmüş olabilir (çok sütunlu OCR).
    if (ms.isEmpty && i + 1 < lines.length) {
      ms = _measures(lines[i + 1]);
      usedLine = i + 1;
      nextLinePenalty = true;
    }
    if (ms.isEmpty) continue;

    // --- Enerji: kJ değil kcal istiyoruz ---
    if (nutrient == 'kcal') {
      final kcal = ms.where((m) => m.unit == 'kcal').toList();
      if (kcal.isNotEmpty) {
        final chosen = pick(kcal)!;
        fields['kcal'] = LabelField(
          value: chosen.m.value,
          unit: 'kcal',
          basis: kcal.length == 1 ? NutrientBasis.unknown : chosen.basis,
          confidence: kcal.length == 1
              ? LabelConfidence.medium
              : LabelConfidence.high,
          sourceLine: rawLineFor(usedLine),
        );
        continue;
      }
      final kj = ms.where((m) => m.unit == 'kj').toList();
      if (kj.isNotEmpty) {
        final chosen = pick(kj)!;
        fields['kcal'] = LabelField(
          value: chosen.m.value / 4.184,
          unit: 'kcal',
          basis: kj.length == 1 ? NutrientBasis.unknown : chosen.basis,
          confidence: LabelConfidence.medium,
          sourceLine: rawLineFor(usedLine),
          derivationTr:
              '${_fmt(chosen.m.value)} kJ ÷ 4,184 → kcal (etikette kcal yoktu)',
        );
        continue;
      }
      // Birimsiz: etikette kcal sütunu ayrı satırda olabilir.
      final chosen = pick(ms)!;
      fields['kcal'] = LabelField(
        value: chosen.m.value,
        unit: 'kcal',
        basis: chosen.basis,
        confidence: LabelConfidence.low,
        sourceLine: rawLineFor(usedLine),
        derivationTr: 'Birim okunamadı; kcal varsayıldı',
      );
      continue;
    }

    final chosen = pick(ms)!;
    var confidence = chosen.conf;
    if (nextLinePenalty && confidence == LabelConfidence.high) {
      confidence = LabelConfidence.medium;
    }
    if (chosen.m.unit.isEmpty && confidence != LabelConfidence.low) {
      confidence = LabelConfidence.medium;
    }

    switch (nutrient) {
      // --- gram cinsinden alanlar ---
      case 'protein':
      case 'carbs':
      case 'sugar':
      case 'fat':
      case 'saturatedFat':
      case 'fiber':
        fields[nutrient] = LabelField(
          value: _toGrams(chosen.m),
          unit: 'g',
          basis: chosen.basis,
          confidence: confidence,
          sourceLine: rawLineFor(usedLine),
        );

      // --- miligram cinsinden mineraller ---
      case 'sodium':
      case 'potassium':
      case 'phosphorus':
        fields[nutrient] = LabelField(
          value: _toMilligrams(chosen.m),
          unit: 'mg',
          basis: chosen.basis,
          confidence: confidence,
          sourceLine: rawLineFor(usedLine),
          derivationTr: chosen.m.unit == 'g'
              ? '${_fmt(chosen.m.value)} g → mg (×1000)'
              : null,
        );

      // --- tuz: sodyuma çevrilir ---
      case 'salt':
        final grams = _toGrams(chosen.m);
        fields['salt'] = LabelField(
          value: grams,
          unit: 'g',
          basis: chosen.basis,
          confidence: confidence,
          sourceLine: rawLineFor(usedLine),
        );
    }
  }

  // Sodyum doğrudan yazmıyorsa tuzdan türet (Türkiye'de olağan durum).
  final salt = fields['salt'];
  if (fields['sodium'] == null && salt != null) {
    fields['sodium'] = LabelField(
      // Tuz (NaCl) kütlece %39,34 sodyum → g tuz × 393,4 ≈ mg sodyum.
      // Etiket mevzuatı yuvarlak 2,5 katsayısını kullanır: Na × 2,5 = tuz.
      value: salt.value * 400,
      unit: 'mg',
      basis: salt.basis,
      confidence: salt.confidence == LabelConfidence.high
          ? LabelConfidence.medium
          : salt.confidence,
      sourceLine: salt.sourceLine,
      derivationTr:
          'Tuz ${_fmt(salt.value)} g ÷ 2,5 → sodyum (${_fmt(salt.value * 400)} mg)',
    );
  }

  // Tablonun genel yorumu: alanların çoğunluğu hangi sütundan geldi?
  final basisCounts = <NutrientBasis, int>{};
  for (final f in fields.values) {
    basisCounts[f.basis] = (basisCounts[f.basis] ?? 0) + 1;
  }
  var overall = NutrientBasis.unknown;
  var best = 0;
  basisCounts.forEach((k, v) {
    if (k != NutrientBasis.unknown && v > best) {
      best = v;
      overall = k;
    }
  });

  return ParsedNutritionLabel(
    fields: fields,
    basis: overall,
    portionG: portion.grams,
    portionLabelTr: portion.labelTr,
  );
}

double _toGrams(_Measure m) => switch (m.unit) {
      'mg' => m.value / 1000,
      'µg' => m.value / 1000000,
      _ => m.value,
    };

double _toMilligrams(_Measure m) => switch (m.unit) {
      'g' => m.value * 1000,
      'µg' => m.value / 1000,
      _ => m.value,
    };

String _fmt(double v) {
  final s = v >= 100 ? v.round().toString() : v.toStringAsFixed(2);
  return s.replaceAll('.', ',').replaceAll(RegExp(r',?0+$'), '');
}

const String kLabelScanDisclaimerTr =
    'Etiket okuma telefonun içinde yapılır, internete gönderilmez. '
    'Yine de OCR hata yapabilir: virgül kayması, kJ ile kcal karışması ve '
    'özellikle "100 g" / "porsiyon" sütunlarının karışması sık görülür. '
    'Her değeri kaydetmeden önce etiketle karşılaştır.';
