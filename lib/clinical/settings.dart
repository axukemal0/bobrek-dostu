/// Kullanıcının (doktorun) klinik ayarları: tanımların üzerine yazdığı
/// değerler ve değişiklik geçmişi.
library;

import 'definitions.dart';
import '../core/i18n/i18n.dart';

/// Tek bir değer için kullanıcı ayarı.
///
/// [isCleared] true ise kullanıcı değeri BİLEREK boşalttı
/// (örn. "sıvı limiti yok") — bu, "hiç dokunulmadı"dan farklıdır.
class ClinicalOverride {
  const ClinicalOverride({
    this.value,
    this.min,
    this.max,
    this.isCleared = false,
    this.noteTr,
    this.updatedAt,
  });

  final double? value;
  final double? min;
  final double? max;
  final bool isCleared;
  final String? noteTr;
  final DateTime? updatedAt;

  bool get isEmpty =>
      value == null && min == null && max == null && !isCleared;

  Map<String, dynamic> toJson() => {
        if (value != null) 'value': value,
        if (min != null) 'min': min,
        if (max != null) 'max': max,
        if (isCleared) 'isCleared': true,
        if (noteTr != null) 'note': noteTr,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  static ClinicalOverride fromJson(Map<String, dynamic> j) => ClinicalOverride(
        value: (j['value'] as num?)?.toDouble(),
        min: (j['min'] as num?)?.toDouble(),
        max: (j['max'] as num?)?.toDouble(),
        isCleared: j['isCleared'] == true,
        noteTr: j['note'] as String?,
        updatedAt: j['updatedAt'] == null
            ? null
            : DateTime.tryParse(j['updatedAt'] as String),
      );
}

/// Bir değerin o anki hâli: varsayılan mı, özelleştirilmiş mi?
class ResolvedValue {
  const ResolvedValue({
    required this.definition,
    required this.value,
    required this.min,
    required this.max,
    required this.isCustom,
    required this.isCleared,
    this.noteTr,
    this.updatedAt,
  });

  final ClinicalDefinition definition;
  final double? value;
  final double? min;
  final double? max;

  /// Kullanıcı varsayılandan farklı bir değer girdi mi?
  final bool isCustom;

  /// Kullanıcı bilerek boşalttı mı? (örn. "limit yok")
  final bool isCleared;

  final String? noteTr;
  final DateTime? updatedAt;

  bool get hasValue => value != null || min != null || max != null;

  /// Aralık biçimindeki değerler için "22 - 30" gibi metin.
  String formatted() {
    final d = definition.decimals;
    String f(double v) => v.toStringAsFixed(d);
    if (isCleared) return 'Limit yok';
    if (definition.shape == ValueShape.range) {
      if (min == null && max == null) return 'Laboratuvar aralığı';
      if (min == null) return '≤ ${f(max!)}';
      if (max == null) return '≥ ${f(min!)}';
      return '${f(min!)} - ${f(max!)}';
    }
    if (value == null) return 'Belirtilmedi';
    return f(value!);
  }
}

/// Klinik ayarların tamamı. Salt veri — test edilebilir.
class ClinicalSettings {
  const ClinicalSettings({
    this.overrides = const {},
    this.bodyWeightKg,
    this.dryWeightKg,
    this.hasResidualUrine = true,
    this.treatmentMode = TreatmentMode.unknown,
  });

  final Map<String, ClinicalOverride> overrides;

  /// Hesaplamalarda kullanılan vücut ağırlığı (g/kg hedefleri için).
  final double? bodyWeightKg;

  /// Diyaliz hastaları için kuru ağırlık (IDWG yüzdesi için).
  final double? dryWeightKg;

  /// Rezidüel idrar çıkışı var mı? (sıvı ve oligüri alarmını etkiler)
  final bool hasResidualUrine;

  final TreatmentMode treatmentMode;

  ClinicalSettings copyWith({
    Map<String, ClinicalOverride>? overrides,
    double? bodyWeightKg,
    double? dryWeightKg,
    bool? hasResidualUrine,
    TreatmentMode? treatmentMode,
  }) =>
      ClinicalSettings(
        overrides: overrides ?? this.overrides,
        bodyWeightKg: bodyWeightKg ?? this.bodyWeightKg,
        dryWeightKg: dryWeightKg ?? this.dryWeightKg,
        hasResidualUrine: hasResidualUrine ?? this.hasResidualUrine,
        treatmentMode: treatmentMode ?? this.treatmentMode,
      );

  /// Bir anahtarın o anki çözümlenmiş değeri.
  ResolvedValue resolve(String key) {
    final def = definitionByKey(key);
    if (def == null) {
      throw ArgumentError(tf('Bilinmeyen klinik anahtar: {0}', [key]));
    }
    return resolveDefinition(def);
  }

  ResolvedValue resolveDefinition(ClinicalDefinition def) {
    final o = overrides[def.key];

    if (o == null || o.isEmpty) {
      return ResolvedValue(
        definition: def,
        value: _defaultValueFor(def),
        min: def.defaultMin,
        max: def.defaultMax,
        isCustom: false,
        isCleared: false,
      );
    }

    if (o.isCleared) {
      return ResolvedValue(
        definition: def,
        value: null,
        min: null,
        max: null,
        isCustom: true,
        isCleared: true,
        noteTr: o.noteTr,
        updatedAt: o.updatedAt,
      );
    }

    return ResolvedValue(
      definition: def,
      value: o.value ?? _defaultValueFor(def),
      min: o.min ?? def.defaultMin,
      max: o.max ?? def.defaultMax,
      isCustom: true,
      isCleared: false,
      noteTr: o.noteTr,
      updatedAt: o.updatedAt,
    );
  }

  /// Tedavi türüne göre protein varsayılanını uyarlar.
  ///
  /// KDOQI 2020: hemodiyaliz/periton diyalizi 1,0-1,2 g/kg/gün.
  /// Uygulama orta noktayı (1,1) değil, alt sınırı (1,0) önerir:
  /// daha muhafazakâr ve doktor kolayca yükseltebilir.
  double? _defaultValueFor(ClinicalDefinition def) {
    if (def.key == 'protein_g_per_kg') {
      switch (treatmentMode) {
        case TreatmentMode.hemodialysis:
        case TreatmentMode.peritonealDialysis:
          return 1.0;
        case TreatmentMode.transplant:
        case TreatmentMode.stage1:
        case TreatmentMode.stage2:
        case TreatmentMode.stage3:
        case TreatmentMode.stage4:
        case TreatmentMode.stage5:
        case TreatmentMode.unknown:
          return def.defaultValue;
      }
    }
    return def.defaultValue;
  }

  /// g/kg türü hedeflerin günlük mutlak değeri.
  double? dailyAbsolute(String key) {
    final r = resolve(key);
    if (!r.definition.perKgBodyWeight) return r.value;
    final w = bodyWeightKg;
    if (w == null || r.value == null) return null;
    return r.value! * w;
  }

  /// Aralık türü (ör. enerji 25-35 kcal/kg) için günlük mutlak aralık.
  ({double min, double max})? dailyAbsoluteRange(String key) {
    final r = resolve(key);
    if (r.min == null || r.max == null) return null;
    if (!r.definition.perKgBodyWeight) {
      return (min: r.min!, max: r.max!);
    }
    final w = bodyWeightKg;
    if (w == null) return null;
    return (min: r.min! * w, max: r.max! * w);
  }

  Map<String, dynamic> toJson() => {
        'overrides': {
          for (final e in overrides.entries) e.key: e.value.toJson(),
        },
        'bodyWeightKg': bodyWeightKg,
        'dryWeightKg': dryWeightKg,
        'hasResidualUrine': hasResidualUrine,
        'treatmentMode': treatmentMode.name,
      };

  static ClinicalSettings fromJson(Map<String, dynamic> j) {
    final raw = (j['overrides'] as Map?) ?? const {};
    return ClinicalSettings(
      overrides: {
        for (final e in raw.entries)
          e.key as String:
              ClinicalOverride.fromJson(Map<String, dynamic>.from(e.value as Map)),
      },
      bodyWeightKg: (j['bodyWeightKg'] as num?)?.toDouble(),
      dryWeightKg: (j['dryWeightKg'] as num?)?.toDouble(),
      hasResidualUrine: j['hasResidualUrine'] as bool? ?? true,
      treatmentMode: TreatmentMode.values.firstWhere(
        (m) => m.name == j['treatmentMode'],
        orElse: () => TreatmentMode.unknown,
      ),
    );
  }
}

enum TreatmentMode {
  stage1,
  stage2,
  stage3,
  stage4,
  stage5,
  hemodialysis,
  peritonealDialysis,
  transplant,
  unknown,
}

extension TreatmentModeTr on TreatmentMode {
  String get labelTr => switch (this) {
        TreatmentMode.stage1 => 'Evre 1',
        TreatmentMode.stage2 => 'Evre 2',
        TreatmentMode.stage3 => 'Evre 3',
        TreatmentMode.stage4 => 'Evre 4',
        TreatmentMode.stage5 => 'Evre 5 (diyaliz öncesi)',
        TreatmentMode.hemodialysis => 'Hemodiyaliz',
        TreatmentMode.peritonealDialysis => 'Periton diyalizi',
        TreatmentMode.transplant => 'Böbrek nakli',
        TreatmentMode.unknown => 'Bilmiyorum',
      };

  bool get isDialysis =>
      this == TreatmentMode.hemodialysis ||
      this == TreatmentMode.peritonealDialysis;
}

/// Bir klinik değerin değişiklik geçmişi kaydı.
class ClinicalChange {
  const ClinicalChange({
    required this.key,
    required this.changedAt,
    this.oldText,
    this.newText,
    this.noteTr,
  });

  final String key;
  final DateTime changedAt;
  final String? oldText;
  final String? newText;
  final String? noteTr;
}
