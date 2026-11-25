/// Claude vision yanıtını çözümler — SAF fonksiyonlar, test edilebilir.
///
/// Bir tabakta genelde tek bir yemek olmaz: pilav + tavuk + salata + ekmek.
/// Bunları tek bir toplamda birleştirmek kullanıcıyı çaresiz bırakıyordu —
/// "pilavın yarısını yedim" diyemiyordu. Artık model KALEM KALEM yanıt
/// verir, kullanıcı her kalemi ayrı ayrı düzeltir, çıkarır ya da porsiyonunu
/// değiştirir.
///
/// Birincil biçim JSON; model eski düz metin biçimiyle yanıt verirse
/// [parseMealAnalysis] ona da düşer, böylece eski davranış kırılmaz.
library;

import 'dart:convert';

enum AiConfidence { low, medium, high, unknown }

extension AiConfidenceTr on AiConfidence {
  String get labelTr => switch (this) {
        AiConfidence.low => 'düşük güven',
        AiConfidence.medium => 'orta güven',
        AiConfidence.high => 'yüksek güven',
        AiConfidence.unknown => 'güven bilinmiyor',
      };

  String get dbValue => name;

  static AiConfidence parse(String? raw) {
    final v = (raw ?? '').toLowerCase();
    if (v.contains('yüksek') || v.contains('yuksek') || v.contains('high')) {
      return AiConfidence.high;
    }
    if (v.contains('orta') || v.contains('medium')) return AiConfidence.medium;
    if (v.contains('düşük') || v.contains('dusuk') || v.contains('low')) {
      return AiConfidence.low;
    }
    return AiConfidence.unknown;
  }
}

/// Bir besin değeri + sapma aralığı.
class EstimatedValue {
  const EstimatedValue({required this.value, this.plusMinus});

  final double value;
  final double? plusMinus;

  /// Porsiyon değişince değerler orantılı ölçeklenir.
  EstimatedValue scaled(double factor) => EstimatedValue(
        value: value * factor,
        plusMinus: plusMinus == null ? null : plusMinus! * factor,
      );

  String formatted(String unit) {
    final v = value >= 100 ? value.round().toString() : value.toStringAsFixed(1);
    if (plusMinus == null) return '≈ $v $unit';
    final pm = plusMinus! >= 100
        ? plusMinus!.round().toString()
        : plusMinus!.toStringAsFixed(1);
    return '≈ $v ± $pm $unit';
  }
}

/// Tabaktaki tek bir kalem.
class MealItem {
  const MealItem({
    required this.name,
    this.portionG,
    this.portionNoteTr,
    this.confidence = AiConfidence.unknown,
    this.kcal,
    this.protein,
    this.sodium,
    this.potassium,
    this.phosphorus,
  });

  final String name;
  final double? portionG;

  /// Modelin porsiyonu nasıl tahmin ettiği ("yaklaşık 1 kepçe").
  final String? portionNoteTr;

  final AiConfidence confidence;
  final EstimatedValue? kcal;
  final EstimatedValue? protein;
  final EstimatedValue? sodium;
  final EstimatedValue? potassium;
  final EstimatedValue? phosphorus;

  bool get hasAnyValue =>
      kcal != null ||
      protein != null ||
      sodium != null ||
      potassium != null ||
      phosphorus != null;

  /// Porsiyon değiştiğinde tüm değerleri yeniden ölçekler.
  MealItem withPortion(double newPortionG) {
    final base = portionG;
    if (base == null || base <= 0) {
      return MealItem(
        name: name,
        portionG: newPortionG,
        portionNoteTr: portionNoteTr,
        confidence: confidence,
        kcal: kcal,
        protein: protein,
        sodium: sodium,
        potassium: potassium,
        phosphorus: phosphorus,
      );
    }
    final f = newPortionG / base;
    return MealItem(
      name: name,
      portionG: newPortionG,
      portionNoteTr: portionNoteTr,
      confidence: confidence,
      kcal: kcal?.scaled(f),
      protein: protein?.scaled(f),
      sodium: sodium?.scaled(f),
      potassium: potassium?.scaled(f),
      phosphorus: phosphorus?.scaled(f),
    );
  }
}

/// Fotoğraf analizinin tamamı.
class MealAnalysis {
  const MealAnalysis({
    required this.rawText,
    required this.items,
    this.confidence = AiConfidence.unknown,
    this.noteTr,
    this.dishNameTr,
  });

  final String rawText;
  final List<MealItem> items;
  final AiConfidence confidence;
  final String? noteTr;

  /// Tabağın bütününe verilen ad ("Ev yemeği tabağı").
  final String? dishNameTr;

  bool get isEmpty => items.isEmpty;

  double get totalPortionG =>
      items.fold(0.0, (sum, i) => sum + (i.portionG ?? 0));

  EstimatedValue? _sum(EstimatedValue? Function(MealItem) pick) {
    var any = false;
    var value = 0.0;
    var pm = 0.0;
    var anyPm = false;
    for (final i in items) {
      final v = pick(i);
      if (v == null) continue;
      any = true;
      value += v.value;
      if (v.plusMinus != null) {
        anyPm = true;
        pm += v.plusMinus!;
      }
    }
    if (!any) return null;
    return EstimatedValue(value: value, plusMinus: anyPm ? pm : null);
  }

  EstimatedValue? get kcal => _sum((i) => i.kcal);
  EstimatedValue? get protein => _sum((i) => i.protein);
  EstimatedValue? get sodium => _sum((i) => i.sodium);
  EstimatedValue? get potassium => _sum((i) => i.potassium);
  EstimatedValue? get phosphorus => _sum((i) => i.phosphorus);

  MealAnalysis withItems(List<MealItem> next) => MealAnalysis(
        rawText: rawText,
        items: next,
        confidence: confidence,
        noteTr: noteTr,
        dishNameTr: dishNameTr,
      );
}

// ---------------------------------------------------------------------------
// Çözümleme
// ---------------------------------------------------------------------------

/// Yanıtı çözümler: önce JSON, olmazsa düz metin.
MealAnalysis parseMealAnalysis(String text) {
  final json = _parseJson(text);
  if (json != null && json.items.isNotEmpty) return json;
  return _parseFlatText(text);
}

/// Yanıt içindeki ilk JSON nesnesini bulur (model bazen açıklama ekler).
String? _extractJsonObject(String text) {
  final start = text.indexOf('{');
  if (start < 0) return null;
  var depth = 0;
  var inString = false;
  var escape = false;
  for (var i = start; i < text.length; i++) {
    final c = text[i];
    if (escape) {
      escape = false;
      continue;
    }
    if (c == r'\') {
      escape = true;
      continue;
    }
    if (c == '"') inString = !inString;
    if (inString) continue;
    if (c == '{') depth++;
    if (c == '}') {
      depth--;
      if (depth == 0) return text.substring(start, i + 1);
    }
  }
  return null;
}

double? _num(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) {
    final cleaned = v.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned);
  }
  return null;
}

EstimatedValue? _estimated(Map<String, dynamic> m, String key) {
  final value = _num(m[key]);
  if (value == null) return null;
  final pm = _num(m['${key}_pm']) ?? _num(m['${key}Pm']);
  return EstimatedValue(value: value, plusMinus: pm);
}

MealAnalysis? _parseJson(String text) {
  final blob = _extractJsonObject(text);
  if (blob == null) return null;
  Object? decoded;
  try {
    decoded = jsonDecode(blob);
  } on FormatException {
    return null;
  }
  if (decoded is! Map) return null;
  final map = Map<String, dynamic>.from(decoded);

  final rawItems = map['kalemler'] ?? map['items'];
  if (rawItems is! List) return null;

  final items = <MealItem>[];
  for (final raw in rawItems) {
    if (raw is! Map) continue;
    final m = Map<String, dynamic>.from(raw);
    final name = (m['ad'] ?? m['name'] ?? '').toString().trim();
    if (name.isEmpty) continue;
    items.add(
      MealItem(
        name: name,
        portionG: _num(m['porsiyon_g'] ?? m['portion_g'] ?? m['gram']),
        portionNoteTr: (m['porsiyon_not'] ?? m['portion_note'])?.toString(),
        confidence: AiConfidenceTr.parse(
          (m['guven'] ?? m['güven'] ?? m['confidence'])?.toString(),
        ),
        kcal: _estimated(m, 'kcal'),
        protein: _estimated(m, 'protein'),
        sodium: _estimated(m, 'sodyum') ?? _estimated(m, 'sodium'),
        potassium: _estimated(m, 'potasyum') ?? _estimated(m, 'potassium'),
        phosphorus: _estimated(m, 'fosfor') ?? _estimated(m, 'phosphorus'),
      ),
    );
  }
  if (items.isEmpty) return null;

  return MealAnalysis(
    rawText: text,
    items: items,
    confidence: AiConfidenceTr.parse(
      (map['guven'] ?? map['güven'] ?? map['confidence'])?.toString(),
    ),
    noteTr: (map['not'] ?? map['note'])?.toString(),
    dishNameTr: (map['tabak'] ?? map['dish'])?.toString(),
  );
}

/// Eski "BAŞLIK: değer" biçimi — tek kalemlik sonuç üretir.
MealAnalysis _parseFlatText(String text) {
  String? field(String key) {
    final m = RegExp(
      '^\\s*$key\\s*:\\s*(.+)\$',
      multiLine: true,
      caseSensitive: false,
    ).firstMatch(text);
    return m?.group(1)?.trim();
  }

  EstimatedValue? value(String key) {
    final raw = field(key);
    if (raw == null) return null;
    final normalized = raw.replaceAll(',', '.');
    final numbers = RegExp(r'\d+\.?\d*')
        .allMatches(normalized)
        .map((m) => double.tryParse(m.group(0)!))
        .whereType<double>()
        .toList();
    if (numbers.isEmpty) return null;
    return EstimatedValue(
      value: numbers.first,
      plusMinus: numbers.length > 1 ? numbers[1] : null,
    );
  }

  final confidence = AiConfidenceTr.parse(field('GÜVEN'));
  final portionRaw = field('PORSİYON')?.replaceAll(',', '.');
  final portion = portionRaw == null
      ? null
      : double.tryParse(
          RegExp(r'\d+\.?\d*').firstMatch(portionRaw)?.group(0) ?? '',
        );

  final name = field('YEMEK');
  final item = MealItem(
    name: name == null || name.isEmpty ? 'Fotoğraftan analiz' : name,
    portionG: portion,
    confidence: confidence,
    kcal: value('KALORİ'),
    protein: value('PROTEİN'),
    sodium: value('SODYUM'),
    potassium: value('POTASYUM'),
    phosphorus: value('FOSFOR'),
  );

  return MealAnalysis(
    rawText: text,
    items: item.hasAnyValue ? [item] : const [],
    confidence: confidence,
    noteTr: field('NOT'),
    dishNameTr: name,
  );
}
