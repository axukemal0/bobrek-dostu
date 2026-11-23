/// Saf (yan etkisiz) klinik değerlendirme mantığı.
///
/// Bu dosyadaki her şey birim testlidir: sıvı bütçesi, besin hesapları,
/// eşik/alarm kuralları, diyaliz arası kilo artışı yüzdesi.
/// Flutter'a bağımlı DEĞİLDİR — bu yüzden saf Dart testiyle çalışır.
library;

import 'definitions.dart';
import 'settings.dart';

enum AlertLevel { none, info, warning, urgent }

extension AlertLevelTr on AlertLevel {
  String get labelTr => switch (this) {
        AlertLevel.none => 'Normal',
        AlertLevel.info => 'Bilgi',
        AlertLevel.warning => 'Dikkat',
        AlertLevel.urgent => 'Acil',
      };

  int get severity => switch (this) {
        AlertLevel.none => 0,
        AlertLevel.info => 1,
        AlertLevel.warning => 2,
        AlertLevel.urgent => 3,
      };
}

/// Bir ölçümün eşiklere göre değerlendirmesi.
class Alert {
  const Alert({
    required this.level,
    required this.titleTr,
    required this.messageTr,
    this.definitionKey,
    this.shouldNotifyEmergencyContacts = false,
    this.sourceIds = const [],
    this.verification,
  });

  final AlertLevel level;
  final String titleTr;
  final String messageTr;
  final String? definitionKey;

  /// Acil kişilere otomatik SMS tetiklenmeli mi?
  /// (kullanıcı ayarı ayrıca açık olmalı — bu yalnız klinik sinyal)
  final bool shouldNotifyEmergencyContacts;

  final List<String> sourceIds;
  final Verification? verification;

  static const Alert ok = Alert(
    level: AlertLevel.none,
    titleTr: 'Normal',
    messageTr: '',
  );
}

/// ---------------------------------------------------------------------------
/// SIVI BÜTÇESİ
/// ---------------------------------------------------------------------------
class FluidBudget {
  const FluidBudget({
    required this.consumedMl,
    required this.limitMl,
    required this.hasLimit,
  });

  final int consumedMl;

  /// Limit yoksa 0.
  final int limitMl;
  final bool hasLimit;

  /// Kalan miktar. Limit yoksa null. Negatif olabilir (aşım).
  int? get remainingMl => hasLimit ? limitMl - consumedMl : null;

  /// 0.0 - 1.0+ arası doluluk. Limit yoksa null.
  double? get ratio {
    if (!hasLimit || limitMl <= 0) return null;
    return consumedMl / limitMl;
  }

  bool get isOverLimit => hasLimit && consumedMl > limitMl;

  /// Aşım miktarı (yoksa 0).
  int get overshootMl => isOverLimit ? consumedMl - limitMl : 0;
}

/// Sıvı bütçesini hesaplar.
///
/// [limitMl] null ise "limit yok" demektir ve bütçe hedefsiz döner.
FluidBudget computeFluidBudget({
  required int consumedMl,
  required int? limitMl,
}) {
  final has = limitMl != null && limitMl > 0;
  return FluidBudget(
    consumedMl: consumedMl < 0 ? 0 : consumedMl,
    limitMl: has ? limitMl : 0,
    hasLimit: has,
  );
}

/// Sıvı durumu için yumuşak uyarı metni.
///
/// Kritik kural: limit VARSA hiçbir metin "daha çok su iç" demez.
String fluidAdviceTr(FluidBudget b, {bool hotWeather = false}) {
  if (!b.hasLimit) {
    return hotWeather
        ? 'Hava sıcak. Sıvı limiti girilmemiş; susadıkça içmekte '
            'serbestsin. Limit eklemek istersen Klinik Ayarlar\'dan '
            'girebilirsin.'
        : 'Sıvı limiti girilmemiş. Kayıtlar yalnızca takip için '
            'tutuluyor.';
  }
  final remaining = b.remainingMl!;
  if (b.isOverLimit) {
    return 'Günlük limitini ${b.overshootMl} mL aştın. '
        'Bugün sıvıyı azaltmak ve kiloyu izlemek iyi olur. '
        'Ağız kuruluğu için buz parçası emmeyi veya şekersiz sakız '
        'çiğnemeyi dene.';
  }
  final r = b.ratio ?? 0;
  if (hotWeather) {
    return 'Hava sıcak; limitin ${b.limitMl} mL, kalan $remaining mL. '
        'Susuzluk için buz parçası, şekersiz sakız veya '
        'limon dilimi dene — bunlar sıvı bütçesini tüketmez.';
  }
  if (r >= 0.9) {
    return 'Limitine çok yaklaştın: kalan $remaining mL. '
        'Kalanı ilaç saatlerine ayırmak isteyebilirsin.';
  }
  if (r >= 0.6) {
    return 'Bugünün yarısını geçtin: kalan $remaining mL.';
  }
  return 'Kalan $remaining mL.';
}

/// ---------------------------------------------------------------------------
/// BESİN TOPLAMLARI
/// ---------------------------------------------------------------------------
/// Bir besin öğesinin durumu. [value] null ise "bilinmiyor"dur —
/// sıfır sayılmaz.
class NutrientTotal {
  const NutrientTotal({
    required this.key,
    required this.labelTr,
    required this.unit,
    required this.value,
    required this.target,
    required this.unknownItemCount,
  });

  final String key;
  final String labelTr;
  final String unit;
  final double value;

  /// Hedef yoksa null (örn. potasyum hedefi boş bırakılmış).
  final double? target;

  /// Değeri bilinmeyen (etiketi eksik) kaç öğe var?
  final int unknownItemCount;

  bool get hasTarget => target != null && target! > 0;

  double? get ratio => hasTarget ? value / target! : null;

  bool get isOverTarget => hasTarget && value > target!;

  /// Bilinmeyen öğe varsa toplam "en az" demektir.
  bool get isPartial => unknownItemCount > 0;
}

/// Tek bir yenen öğe. Değeri bilinmeyen besin öğesi null olmalıdır.
class FoodEntryValues {
  const FoodEntryValues({
    required this.grams,
    this.kcalPer100g,
    this.proteinPer100g,
    this.sodiumMgPer100g,
    this.potassiumMgPer100g,
    this.phosphorusMgPer100g,
    this.fluidMlPer100g,
  });

  final double grams;
  final double? kcalPer100g;
  final double? proteinPer100g;
  final double? sodiumMgPer100g;
  final double? potassiumMgPer100g;
  final double? phosphorusMgPer100g;

  /// Çorba, çay, meyve gibi öğelerin sıvı katkısı.
  final double? fluidMlPer100g;

  double? _scaled(double? per100g) =>
      per100g == null ? null : per100g * grams / 100.0;

  double? get kcal => _scaled(kcalPer100g);
  double? get proteinG => _scaled(proteinPer100g);
  double? get sodiumMg => _scaled(sodiumMgPer100g);
  double? get potassiumMg => _scaled(potassiumMgPer100g);
  double? get phosphorusMg => _scaled(phosphorusMgPer100g);
  double? get fluidMl => _scaled(fluidMlPer100g);
}

class DailyNutrition {
  const DailyNutrition({
    required this.energy,
    required this.protein,
    required this.sodium,
    required this.potassium,
    required this.phosphorus,
    required this.fluidFromFoodMl,
  });

  final NutrientTotal energy;
  final NutrientTotal protein;
  final NutrientTotal sodium;
  final NutrientTotal potassium;
  final NutrientTotal phosphorus;

  /// Yemekten gelen sıvı (çorba, meyve vb.) — sıvı bütçesine eklenir.
  final double fluidFromFoodMl;

  List<NutrientTotal> get all =>
      [energy, protein, sodium, potassium, phosphorus];

  List<NutrientTotal> get exceeded =>
      all.where((n) => n.isOverTarget).toList(growable: false);
}

/// Günün besin toplamlarını ve hedeflerle kıyasını hesaplar.
DailyNutrition computeDailyNutrition({
  required List<FoodEntryValues> entries,
  required ClinicalSettings settings,
}) {
  double kcal = 0, protein = 0, sodium = 0, potassium = 0, phos = 0, fluid = 0;
  int uKcal = 0, uProt = 0, uNa = 0, uK = 0, uP = 0;

  for (final e in entries) {
    final v = e.kcal;
    if (v == null) {
      uKcal++;
    } else {
      kcal += v;
    }
    final p = e.proteinG;
    if (p == null) {
      uProt++;
    } else {
      protein += p;
    }
    final na = e.sodiumMg;
    if (na == null) {
      uNa++;
    } else {
      sodium += na;
    }
    final k = e.potassiumMg;
    if (k == null) {
      uK++;
    } else {
      potassium += k;
    }
    final ph = e.phosphorusMg;
    if (ph == null) {
      uP++;
    } else {
      phos += ph;
    }
    fluid += e.fluidMl ?? 0;
  }

  // Enerji hedefi aralık: üst sınırı hedef olarak kullanırız,
  // çünkü "aşım" uyarısı üst sınıra göre anlam taşır.
  final energyRange = settings.dailyAbsoluteRange('energy_kcal_per_kg');

  return DailyNutrition(
    energy: NutrientTotal(
      key: 'energy',
      labelTr: 'Enerji',
      unit: 'kcal',
      value: kcal,
      target: energyRange?.max,
      unknownItemCount: uKcal,
    ),
    protein: NutrientTotal(
      key: 'protein',
      labelTr: 'Protein',
      unit: 'g',
      value: protein,
      target: settings.dailyAbsolute('protein_g_per_kg'),
      unknownItemCount: uProt,
    ),
    sodium: NutrientTotal(
      key: 'sodium',
      labelTr: 'Sodyum',
      unit: 'mg',
      value: sodium,
      target: settings.resolve('sodium_mg').value,
      unknownItemCount: uNa,
    ),
    potassium: NutrientTotal(
      key: 'potassium',
      labelTr: 'Potasyum',
      unit: 'mg',
      value: potassium,
      target: settings.resolve('potassium_mg').value,
      unknownItemCount: uK,
    ),
    phosphorus: NutrientTotal(
      key: 'phosphorus',
      labelTr: 'Fosfor',
      unit: 'mg',
      value: phos,
      target: settings.resolve('phosphorus_mg').value,
      unknownItemCount: uP,
    ),
    fluidFromFoodMl: fluid,
  );
}

/// Hedef aşımı için yumuşak uyarı metni.
String nutrientExceededAdviceTr(NutrientTotal n) {
  final over = (n.value - (n.target ?? 0)).round();
  final base = '${n.labelTr} hedefini $over ${n.unit} aştın.';
  final extra = switch (n.key) {
    'sodium' => ' Yarın turşu, salça, hazır çorba ve şarküteri '
        'ürünlerini azaltmak hızlı etki eder.',
    'potassium' => ' Patates/sebzeyi haşlayıp suyunu dökmek '
        'potasyumu azaltır. Serum potasyumun yüksekse doktoruna söyle.',
    'phosphorus' => ' Kola, hazır et ürünleri ve işlenmiş peynirde '
        'katkı maddesi fosforu yüksektir; bu fosfor daha iyi emilir.',
    'protein' => ' Protein hedefi hem az hem çok olduğunda sorun '
        'yaratır; tek günlük aşım genelde önemli değildir.',
    _ => '',
  };
  return '$base$extra Bu bir uyarı değil, bilgi — $kReferenceCaveatTr';
}

/// ---------------------------------------------------------------------------
/// DİYALİZ ARASI KİLO ARTIŞI (IDWG)
/// ---------------------------------------------------------------------------
class IdwgResult {
  const IdwgResult({
    required this.gainKg,
    required this.percent,
    required this.thresholdPercent,
    required this.level,
  });

  final double gainKg;

  /// Kuru ağırlığa göre yüzde.
  final double percent;
  final double thresholdPercent;
  final AlertLevel level;

  bool get isOverThreshold => percent > thresholdPercent;
}

/// Diyaliz arası kilo artışını yüzde olarak hesaplar.
///
/// [currentKg] son ölçüm, [dryWeightKg] hedef (kuru) ağırlık.
/// Kuru ağırlık 0 veya negatifse hesaplama yapılamaz (null döner).
IdwgResult? computeIdwg({
  required double currentKg,
  required double dryWeightKg,
  required double thresholdPercent,
}) {
  if (dryWeightKg <= 0) return null;
  final gain = currentKg - dryWeightKg;
  final pct = gain / dryWeightKg * 100.0;

  final AlertLevel level;
  if (pct <= thresholdPercent) {
    level = AlertLevel.none;
  } else if (pct <= thresholdPercent * 1.5) {
    level = AlertLevel.warning;
  } else {
    level = AlertLevel.urgent;
  }

  return IdwgResult(
    gainKg: gain,
    percent: pct,
    thresholdPercent: thresholdPercent,
    level: level,
  );
}

/// ---------------------------------------------------------------------------
/// EŞİK / ALARM KURALLARI
/// ---------------------------------------------------------------------------
/// Kan basıncı değerlendirmesi.
Alert evaluateBloodPressure({
  required int systolic,
  required int diastolic,
  required ClinicalSettings settings,
}) {
  final sysHigh = settings.resolve('bp_systolic_high');
  final diaHigh = settings.resolve('bp_diastolic_high');
  final sysLow = settings.resolve('bp_systolic_low');

  final sh = sysHigh.value;
  final dh = diaHigh.value;
  final sl = sysLow.value;

  if (sh != null && systolic >= sh || dh != null && diastolic >= dh) {
    return Alert(
      level: AlertLevel.urgent,
      titleTr: 'Çok yüksek tansiyon',
      messageTr: '$systolic/$diastolic mmHg — alarm eşiğinin '
          '(${sh?.toStringAsFixed(0)}/${dh?.toStringAsFixed(0)}) '
          'üstünde. Hipertansif kriz aralığında. Doktoruna hemen '
          'başvur; göğüs ağrısı, nefes darlığı, görme bozukluğu, '
          'konuşma güçlüğü veya şiddetli baş ağrısı varsa 112\'yi ara.',
      definitionKey: 'bp_systolic_high',
      shouldNotifyEmergencyContacts: true,
      sourceIds: sysHigh.definition.sourceIds,
      verification: sysHigh.definition.verification,
    );
  }

  if (sl != null && systolic < sl) {
    return Alert(
      level: AlertLevel.warning,
      titleTr: 'Düşük tansiyon',
      messageTr: '$systolic/$diastolic mmHg — alt alarm eşiğinin '
          '(${sl.toStringAsFixed(0)}) altında. Baş dönmesi, '
          'bayılma hissi veya halsizlik varsa otur/uzan ve '
          'doktoruna haber ver. Diyaliz seansı sonrası düşük '
          'tansiyon sık görülür.',
      definitionKey: 'bp_systolic_low',
      shouldNotifyEmergencyContacts: true,
      sourceIds: sysLow.definition.sourceIds,
      verification: sysLow.definition.verification,
    );
  }

  final target = settings.resolve('bp_systolic_target').value;
  if (target != null && systolic > target) {
    return Alert(
      level: AlertLevel.info,
      titleTr: 'Hedefin üstünde',
      messageTr: '$systolic/$diastolic mmHg. Tedavi hedefi sistolik '
          '<${target.toStringAsFixed(0)} mmHg. $kReferenceCaveatTr',
      definitionKey: 'bp_systolic_target',
      sourceIds: const ['kdigo_ckd_2024'],
      verification: Verification.verified,
    );
  }

  return Alert(
    level: AlertLevel.none,
    titleTr: 'Hedef aralıkta',
    messageTr: '$systolic/$diastolic mmHg.',
  );
}

/// Serum potasyum değerlendirmesi (hiperkalemi kademeleri).
Alert evaluateSerumPotassium({
  required double mEqPerL,
  required ClinicalSettings settings,
}) {
  final mild = settings.resolve('potassium_mild');
  final mod = settings.resolve('potassium_moderate');
  final sev = settings.resolve('potassium_severe');
  final low = settings.resolve('potassium_low');

  const caveat = 'Not: KDIGO hiperkalemiyi potasyum + EKG ile birlikte '
      'sınıflar; buradaki kademeler yaygın alternatif bir şemadır '
      've "doğrulanmadı" olarak işaretlidir.';

  final s = sev.value;
  if (s != null && mEqPerL > s) {
    return Alert(
      level: AlertLevel.urgent,
      titleTr: 'Ağır hiperkalemi aralığı',
      messageTr: 'Serum K ${mEqPerL.toStringAsFixed(1)} mEq/L — '
          'ağır kademe (>${s.toStringAsFixed(1)}). '
          'Çarpıntı, ciddi kas güçsüzlüğü, uyuşma veya nefes darlığı '
          'varsa HEMEN 112\'yi ara. $caveat',
      definitionKey: 'potassium_severe',
      shouldNotifyEmergencyContacts: true,
      sourceIds: sev.definition.sourceIds,
      verification: sev.definition.verification,
    );
  }

  final m = mod.value;
  if (m != null && mEqPerL > m) {
    return Alert(
      level: AlertLevel.warning,
      titleTr: 'Orta hiperkalemi aralığı',
      messageTr: 'Serum K ${mEqPerL.toStringAsFixed(1)} mEq/L — '
          'orta kademe (>${m.toStringAsFixed(1)}). '
          'Doktoruna bugün haber ver. $caveat',
      definitionKey: 'potassium_moderate',
      shouldNotifyEmergencyContacts: true,
      sourceIds: mod.definition.sourceIds,
      verification: mod.definition.verification,
    );
  }

  final mi = mild.value;
  if (mi != null && mEqPerL > mi) {
    return Alert(
      level: AlertLevel.info,
      titleTr: 'Hafif hiperkalemi aralığı',
      messageTr: 'Serum K ${mEqPerL.toStringAsFixed(1)} mEq/L — '
          'hafif kademe (>${mi.toStringAsFixed(1)}). '
          'Diyet potasyumunu gözden geçirmek isteyebilirsin. $caveat',
      definitionKey: 'potassium_mild',
      sourceIds: mild.definition.sourceIds,
      verification: mild.definition.verification,
    );
  }

  final l = low.value;
  if (l != null && mEqPerL < l) {
    return Alert(
      level: AlertLevel.warning,
      titleTr: 'Hipokalemi aralığı',
      messageTr: 'Serum K ${mEqPerL.toStringAsFixed(1)} mEq/L — '
          'alt eşiğin (${l.toStringAsFixed(1)}) altında.',
      definitionKey: 'potassium_low',
      sourceIds: low.definition.sourceIds,
      verification: low.definition.verification,
    );
  }

  return Alert(
    level: AlertLevel.none,
    titleTr: 'Aralıkta',
    messageTr: 'Serum K ${mEqPerL.toStringAsFixed(1)} mEq/L.',
  );
}

/// Genel tek eşikli ölçüm değerlendirmesi (nabız, SpO2, ateş,
/// kan şekeri, idrar çıkışı...).
Alert evaluateSingleThreshold({
  required double measured,
  required String definitionKey,
  required ClinicalSettings settings,
  required String displayLabelTr,
  String unitOverride = '',
}) {
  final r = settings.resolve(definitionKey);
  final t = r.value;
  if (t == null) return Alert.ok;

  final def = r.definition;
  final unit = unitOverride.isEmpty ? def.unit : unitOverride;
  final breached = def.higherIsWorse ? measured >= t : measured <= t;
  if (!breached) {
    return Alert(
      level: AlertLevel.none,
      titleTr: 'Aralıkta',
      messageTr: '$displayLabelTr ${_fmt(measured, def.decimals)} $unit.',
      definitionKey: definitionKey,
    );
  }

  return Alert(
    level: def.triggersEmergencySms ? AlertLevel.urgent : AlertLevel.warning,
    titleTr: def.labelTr,
    messageTr: '$displayLabelTr ${_fmt(measured, def.decimals)} $unit — '
        'eşik ${_fmt(t, def.decimals)} $unit '
        '(${def.higherIsWorse ? "üst" : "alt"} alarm). '
        '${def.verification == Verification.startingPoint ? "Bu eşik bir "
            "başlangıç değeridir; Klinik Ayarlar'dan değiştirebilirsin." : ""}',
    definitionKey: definitionKey,
    shouldNotifyEmergencyContacts: def.triggersEmergencySms,
    sourceIds: def.sourceIds,
    verification: def.verification,
  );
}

/// İdrar çıkışı alarmı — anürik diyaliz hastasında anlamsızdır.
Alert evaluateUrineOutput({
  required int ml,
  required ClinicalSettings settings,
}) {
  if (settings.treatmentMode.isDialysis && !settings.hasResidualUrine) {
    return const Alert(
      level: AlertLevel.none,
      titleTr: 'Kayıt alındı',
      messageTr: 'Rezidüel idrar yok olarak işaretli; bu ölçüm için '
          'alarm kapalı.',
    );
  }
  return evaluateSingleThreshold(
    measured: ml.toDouble(),
    definitionKey: 'urine_output_low_ml',
    settings: settings,
    displayLabelTr: 'Günlük idrar',
  );
}

String _fmt(double v, int decimals) => v.toStringAsFixed(decimals);

/// ---------------------------------------------------------------------------
/// ACİL BELİRTİLER — yapay zekadan bağımsız, kural tabanlı tarama
/// ---------------------------------------------------------------------------
/// Kullanıcının yazdığı metinde acil belirti geçiyorsa yakalar.
/// Amaç: AI cevabı gecikse/başarısız olsa bile 112 mesajının görünmesi.
const List<({List<String> patterns, String labelTr})> kRedFlagPatterns = [
  (
    patterns: ['göğüs ağrı', 'gögüs ağrı', 'göğsüm ağrı', 'göğsüme ağrı'],
    labelTr: 'göğüs ağrısı'
  ),
  (
    patterns: ['nefes darlığı', 'nefes alamıyor', 'soluk alamıyor', 'boğuluyor'],
    labelTr: 'ciddi nefes darlığı'
  ),
  (
    patterns: ['bayıl', 'kendimden geçt', 'baygın'],
    labelTr: 'bayılma'
  ),
  (
    patterns: ['idrar çıkmıyor', 'idrarım kesil', 'hiç idrar'],
    labelTr: 'idrarın kesilmesi'
  ),
  (
    patterns: ['kas güçsüzlüğ', 'kaslarım tutm', 'felç', 'uyuşma yayıl'],
    labelTr: 'ciddi kas güçsüzlüğü'
  ),
  (
    patterns: ['çarpıntı', 'kalbim fırlı', 'nabız düzensiz'],
    labelTr: 'çarpıntı'
  ),
  (
    patterns: ['bilinç bulanık', 'sersem', 'ne olduğunu anlamıyor', 'şuuru'],
    labelTr: 'bilinç bulanıklığı'
  ),
  (
    patterns: ['kusma durmu', 'kan kusma', 'kanlı kusmuk'],
    labelTr: 'durdurulamayan kusma'
  ),
  (
    patterns: ['konuşamıyor', 'dili dolan', 'yüzü kay'],
    labelTr: 'konuşma güçlüğü'
  ),
];

/// Metinde acil belirti varsa uyarı döner.
Alert? detectRedFlags(String text) {
  final t = text.toLowerCase();
  final found = <String>[];
  for (final rf in kRedFlagPatterns) {
    for (final p in rf.patterns) {
      if (t.contains(p)) {
        found.add(rf.labelTr);
        break;
      }
    }
  }
  if (found.isEmpty) return null;
  return Alert(
    level: AlertLevel.urgent,
    titleTr: 'Hemen 112\'yi ara',
    messageTr: 'Yazdıklarında acil değerlendirme gerektirebilecek '
        'belirti var (${found.join(", ")}). '
        'Beklemeden 112\'yi ara ya da en yakın acile git. '
        'Bu uygulama teşhis koymaz.',
    shouldNotifyEmergencyContacts: true,
  );
}
