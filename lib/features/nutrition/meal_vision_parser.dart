/// Claude vision yanıtını çözümler — SAF fonksiyon, test edilebilir.
library;

enum AiConfidence { low, medium, high, unknown }

extension AiConfidenceTr on AiConfidence {
  String get labelTr => switch (this) {
        AiConfidence.low => 'düşük güven',
        AiConfidence.medium => 'orta güven',
        AiConfidence.high => 'yüksek güven',
        AiConfidence.unknown => 'güven bilinmiyor',
      };

  String get dbValue => name;
}

/// Bir besin değeri + sapma aralığı.
class EstimatedValue {
  const EstimatedValue({required this.value, this.plusMinus});

  final double value;
  final double? plusMinus;

  String formatted(String unit) {
    final v = value >= 100 ? value.round().toString() : value.toStringAsFixed(1);
    if (plusMinus == null) return '≈ $v $unit';
    final pm = plusMinus! >= 100
        ? plusMinus!.round().toString()
        : plusMinus!.toStringAsFixed(1);
    return '≈ $v ± $pm $unit';
  }
}

class MealEstimate {
  const MealEstimate({
    required this.rawText,
    this.name,
    this.portionG,
    this.confidence = AiConfidence.unknown,
    this.kcal,
    this.protein,
    this.sodium,
    this.potassium,
    this.phosphorus,
    this.noteTr,
  });

  final String rawText;
  final String? name;
  final double? portionG;
  final AiConfidence confidence;
  final EstimatedValue? kcal;
  final EstimatedValue? protein;
  final EstimatedValue? sodium;
  final EstimatedValue? potassium;
  final EstimatedValue? phosphorus;
  final String? noteTr;

  bool get hasAnyValue =>
      kcal != null ||
      protein != null ||
      sodium != null ||
      potassium != null ||
      phosphorus != null;
}

/// "KALORİ: 420 kcal (± 80)" gibi satırları çözer.
MealEstimate parseMealEstimate(String text) {
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

  final confRaw = field('GÜVEN')?.toLowerCase() ?? '';
  final confidence = confRaw.contains('yüksek')
      ? AiConfidence.high
      : confRaw.contains('orta')
          ? AiConfidence.medium
          : confRaw.contains('düşük')
              ? AiConfidence.low
              : AiConfidence.unknown;

  final portionRaw = field('PORSİYON')?.replaceAll(',', '.');
  final portion = portionRaw == null
      ? null
      : double.tryParse(
          RegExp(r'\d+\.?\d*').firstMatch(portionRaw)?.group(0) ?? '',
        );

  return MealEstimate(
    rawText: text,
    name: field('YEMEK'),
    portionG: portion,
    confidence: confidence,
    kcal: value('KALORİ'),
    protein: value('PROTEİN'),
    sodium: value('SODYUM'),
    potassium: value('POTASYUM'),
    phosphorus: value('FOSFOR'),
    noteTr: field('NOT'),
  );
}
