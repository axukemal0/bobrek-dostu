/// Klinik eşik ve hedeflerin TANIMLARI (varsayılan + referans + kaynak).
///
/// Felsefe:
///  * Burada hiçbir değer kilitli değildir. Kullanıcı (doktor) her değeri
///    serbestçe değiştirebilir; uygulama alt/üst sınır dayatmaz.
///  * İki kavram AYRI tutulur:
///      - [ValueKind.dietTarget]  : günlük hedef / diyet değeri
///      - [ValueKind.alarmThreshold] : uyarı & acil SMS tetikleyici eşik
///      - [ValueKind.labTarget]   : laboratuvar hedef aralığı
///  * Doğrulanamayan her değer [Verification.unverified] veya
///    [Verification.startingPoint] olarak işaretlenir ve arayüzde
///    bu etiket görünür.
library;

enum ValueKind { dietTarget, alarmThreshold, labTarget }

extension ValueKindTr on ValueKind {
  String get labelTr => switch (this) {
        ValueKind.dietTarget => 'Hedef / diyet değeri',
        ValueKind.alarmThreshold => 'Uyarı / alarm eşiği',
        ValueKind.labTarget => 'Laboratuvar hedefi',
      };

  String get shortTr => switch (this) {
        ValueKind.dietTarget => 'Hedef',
        ValueKind.alarmThreshold => 'Alarm',
        ValueKind.labTarget => 'Lab',
      };
}

enum Verification {
  /// Birincil kılavuz metninden doğrulandı.
  verified,

  /// Kılavuzda sayı olarak YOK ya da kaynaklar arasında çelişiyor.
  unverified,

  /// Kılavuz sayı vermiyor; muhafazakâr bir başlangıç değeri koyduk.
  startingPoint,

  /// Kılavuz açıkça "bireyselleştir" diyor; varsayılan boş bırakıldı.
  individualized,
}

extension VerificationTr on Verification {
  String get labelTr => switch (this) {
        Verification.verified => 'Kaynaktan doğrulandı',
        Verification.unverified => 'Doğrulanmadı',
        Verification.startingPoint => 'Başlangıç değeri',
        Verification.individualized => 'Bireyselleştirilir',
      };

  String get explanationTr => switch (this) {
        Verification.verified =>
          'Bu değer, yanında listelenen birincil kılavuz metninden '
              'doğrudan alınmıştır.',
        Verification.unverified =>
          'Bu sayıyı birincil kılavuz metninde doğrulayamadık ya da '
              'kaynaklar farklı sayılar veriyor. Kendi değerini girmen '
              'önerilir.',
        Verification.startingPoint =>
          'Kılavuzlar bu konuda sayısal bir eşik vermiyor. Güvenli '
              'tarafta kalan bir başlangıç değeri koyduk; klinik kararı '
              'sana ait.',
        Verification.individualized =>
          'Kılavuz bu değerin sabit bir sayı yerine hastaya göre '
              '(örn. serum sonucuna göre) belirlenmesini söylüyor. '
              'Bu yüzden varsayılanı boş bıraktık.',
      };
}

/// Değerin biçimi: tek sayı mı, aralık mı?
enum ValueShape { single, range }

class ClinicalDefinition {
  const ClinicalDefinition({
    required this.key,
    required this.labelTr,
    required this.unit,
    required this.kind,
    required this.verification,
    required this.referenceTextTr,
    required this.sourceIds,
    this.shape = ValueShape.single,
    this.defaultValue,
    this.defaultMin,
    this.defaultMax,
    this.perKgBodyWeight = false,
    this.helpTr,
    this.decimals = 0,
    this.triggersEmergencySms = false,
    this.higherIsWorse = true,
  });

  final String key;
  final String labelTr;
  final String unit;
  final ValueKind kind;
  final Verification verification;
  final ValueShape shape;

  /// [ValueShape.single] için varsayılan. null => "varsayılan yok / boş".
  final double? defaultValue;

  /// [ValueShape.range] için varsayılanlar.
  final double? defaultMin;
  final double? defaultMax;

  /// true ise değer vücut ağırlığı ile çarpılır (örn. g/kg/gün).
  final bool perKgBodyWeight;

  /// Arayüzde "Referans değer" satırında gösterilen metin.
  /// Kaynak adı + yıl içerir.
  final String referenceTextTr;

  final List<String> sourceIds;

  /// Ek açıklama (bilgi kutusu).
  final String? helpTr;

  final int decimals;

  /// Eşik aşıldığında acil kişilere otomatik SMS tetikleyebilir mi?
  final bool triggersEmergencySms;

  /// Uyarı yönü: true => değer eşiği AŞARSA uyar; false => ALTINA düşerse.
  final bool higherIsWorse;

  bool get hasDefault =>
      defaultValue != null || defaultMin != null || defaultMax != null;
}

/// ---------------------------------------------------------------------------
/// DİYET / GÜNLÜK HEDEFLER
/// ---------------------------------------------------------------------------
const List<ClinicalDefinition> kDietTargets = [
  ClinicalDefinition(
    key: 'protein_g_per_kg',
    labelTr: 'Protein',
    unit: 'g/kg/gün',
    kind: ValueKind.dietTarget,
    verification: Verification.verified,
    defaultValue: 0.8,
    perKgBodyWeight: true,
    decimals: 2,
    referenceTextTr: 'KDIGO 2024: CKD G3-G5\'te 0,8 g/kg/gün (öneri 2C). '
        'Progresyon riski olanlarda >1,3 g/kg/gün\'den kaçınılır. '
        'KDOQI 2020: diyabetsiz CKD 3-5 metabolik stabil hastada '
        '0,55-0,60 g/kg/gün (ideal vücut ağırlığı); diyabetli '
        '0,6-0,8 g/kg/gün; hemodiyaliz/periton diyalizi 1,0-1,2 g/kg/gün '
        '(1C).',
    sourceIds: ['kdigo_ckd_2024', 'kdoqi_nutrition_2020'],
    helpTr: 'Günlük gram olarak hedef, bu değer × vücut ağırlığı (kg) '
        'ile hesaplanır. Diyaliz hastasında KDOQI 1,0-1,2 g/kg/gün '
        'önerir — diyaliz türünü ilk kurulumda seçtiysen uygulama '
        'bunu önerir ama değiştirmek sende.',
  ),
  ClinicalDefinition(
    key: 'sodium_mg',
    labelTr: 'Sodyum',
    unit: 'mg/gün',
    kind: ValueKind.dietTarget,
    verification: Verification.verified,
    defaultValue: 2000,
    referenceTextTr: 'KDIGO 2024: <2 g sodyum/gün (<90 mmol/gün, '
        '<5 g tuz/gün) — öneri 2C. KDOQI 2020: <2300 mg/gün. '
        'Tuz kaybettiren nefropatide sodyum kısıtlaması genellikle '
        'uygun DEĞİLDİR.',
    sourceIds: ['kdigo_ckd_2024', 'kdoqi_nutrition_2020'],
    helpTr: '2000 mg sodyum ≈ 5 g tuz (yemek tuzu) ≈ 1 silme çay kaşığı.',
  ),
  ClinicalDefinition(
    key: 'potassium_mg',
    labelTr: 'Potasyum',
    unit: 'mg/gün',
    kind: ValueKind.dietTarget,
    verification: Verification.individualized,
    defaultValue: null,
    referenceTextTr: 'KDOQI 2020 sabit bir sayı VERMEZ: diyet potasyumu '
        'serum potasyum sonucuna göre bireyselleştirilir. '
        'Literatürde sık görülen kısıtlama aralığı 2000-3000 mg/gün\'dür '
        'ancak bu bir kılavuz hedefi değildir.',
    sourceIds: ['kdoqi_nutrition_2020'],
    helpTr: 'Serum potasyum/fosfor sonucuna göre doktor belirler. '
        'Boş bırakırsan uygulama potasyumu yalnızca bilgi olarak '
        'gösterir, hedef çubuğu çizmez.',
  ),
  ClinicalDefinition(
    key: 'phosphorus_mg',
    labelTr: 'Fosfor',
    unit: 'mg/gün',
    kind: ValueKind.dietTarget,
    verification: Verification.individualized,
    defaultValue: null,
    referenceTextTr: 'KDOQI 2020 sabit bir sayı VERMEZ: diyet fosforu '
        'serum fosfat sonucuna göre ayarlanır. KDIGO 2017 CKD-MBD '
        'yükselmiş fosfatın normal aralığa doğru düşürülmesini önerir '
        '(G5D için 2C) ve fosfat bağlayıcıların önleyici amaçla '
        'kullanılmamasını söyler. Literatürde sık görülen kısıtlama '
        '800-1000 mg/gün\'dür ancak bu bir kılavuz hedefi değildir.',
    sourceIds: ['kdoqi_nutrition_2020', 'kdigo_mbd_2017'],
    helpTr: 'Serum fosfor sonucuna göre doktor belirler. '
        'Katkı maddesi fosforu (fosforik asit, fosfat tuzları) '
        'doğal fosfordan daha iyi emilir — paketli ürün etiketine '
        'bakmak işe yarar.',
  ),
  ClinicalDefinition(
    key: 'energy_kcal_per_kg',
    labelTr: 'Enerji',
    unit: 'kcal/kg/gün',
    kind: ValueKind.dietTarget,
    verification: Verification.verified,
    shape: ValueShape.range,
    defaultMin: 25,
    defaultMax: 35,
    perKgBodyWeight: true,
    referenceTextTr: 'KDOQI 2020: CKD 1-5D ve nakilde 25-35 kcal/kg/gün '
        '(yaş, cinsiyet, fiziksel aktivite, vücut kompozisyonu, '
        'eşlik eden hastalıklara göre).',
    sourceIds: ['kdoqi_nutrition_2020'],
  ),
  ClinicalDefinition(
    key: 'fluid_ml',
    labelTr: 'Sıvı limiti',
    unit: 'mL/gün',
    kind: ValueKind.dietTarget,
    verification: Verification.unverified,
    defaultValue: null,
    referenceTextTr: 'Kılavuzlarda tüm hastalar için geçerli sabit bir '
        'sayı YOKTUR. Derleme düzeyinde: hemodiyaliz hastalarına tipik '
        'olarak günlük 500-1000 mL sıvı kısıtlaması önerilir; '
        'rezidüel idrar çıkışı varsa limit daha esnektir. Aynı '
        'literatür sabit hacim yerine bireysel reçeteyi savunur.',
    sourceIds: ['idwg_review_2025'],
    helpTr: 'Boş bırakırsan "limit yok" demektir: uygulama sıvı '
        'halkasını hedefsiz gösterir ve sıcak havada hidrasyon '
        'önerebilir. Limit girersen hiçbir bildirim seni limitin '
        'üstüne teşvik etmez.',
  ),
];

/// ---------------------------------------------------------------------------
/// UYARI / ALARM EŞİKLERİ  (bildirim + acil kişilere SMS bunlara göre)
/// ---------------------------------------------------------------------------
const List<ClinicalDefinition> kAlarmThresholds = [
  ClinicalDefinition(
    key: 'bp_systolic_high',
    labelTr: 'Sistolik — üst alarm',
    unit: 'mmHg',
    kind: ValueKind.alarmThreshold,
    verification: Verification.verified,
    defaultValue: 180,
    triggersEmergencySms: true,
    referenceTextTr: '2017 ACC/AHA: hipertansif kriz eşiği sistolik '
        '>180 ve/veya diyastolik >120 mmHg. Hedef organ hasarı varsa '
        '"hipertansif acil", yoksa "ivedi" olarak sınıflanır. '
        'Sınıflama ≥2 ayrı ölçümün ortalamasına dayanır.',
    sourceIds: ['acc_aha_htn_2017'],
  ),
  ClinicalDefinition(
    key: 'bp_diastolic_high',
    labelTr: 'Diyastolik — üst alarm',
    unit: 'mmHg',
    kind: ValueKind.alarmThreshold,
    verification: Verification.verified,
    defaultValue: 120,
    triggersEmergencySms: true,
    referenceTextTr: '2017 ACC/AHA: hipertansif kriz eşiği sistolik >180 '
        've/veya diyastolik >120 mmHg.',
    sourceIds: ['acc_aha_htn_2017'],
  ),
  ClinicalDefinition(
    key: 'bp_systolic_low',
    labelTr: 'Sistolik — alt alarm',
    unit: 'mmHg',
    kind: ValueKind.alarmThreshold,
    verification: Verification.startingPoint,
    defaultValue: 90,
    higherIsWorse: false,
    triggersEmergencySms: true,
    referenceTextTr: 'ACC/AHA 2017 hipotansiyon için sayısal bir alt '
        'alarm eşiği TANIMLAMAZ. Başlangıç değeri olarak sistolik '
        '<90 mmHg kullanıldı (yaygın klinik eşik). KDIGO 2024, '
        'semptomatik postural hipotansiyon, kırılganlık veya düşme '
        'riskinde daha az yoğun tedavi önerir.',
    sourceIds: ['acc_aha_htn_2017', 'kdigo_ckd_2024'],
  ),
  ClinicalDefinition(
    key: 'bp_systolic_target',
    labelTr: 'Sistolik — tedavi hedefi',
    unit: 'mmHg',
    kind: ValueKind.alarmThreshold,
    verification: Verification.verified,
    defaultValue: 120,
    referenceTextTr: 'KDIGO 2024 (öneri 3.4.1, 2B): yüksek kan basıncı '
        'olan CKD\'li erişkinde, TOLERE EDİLİRSE, standart ofis ölçümü '
        'ile sistolik <120 mmHg hedeflenir. KDOQI ABD yorumu, hedefin '
        'yalnız AHA protokolüne uygun osilometrik ölçümle anlamlı '
        'olduğunu vurgular. Hedef tartışmalıdır: bazı uluslararası '
        'kılavuzlar <130/80 mmHg önerir.',
    sourceIds: ['kdigo_ckd_2024'],
    helpTr: 'Bu bir ALARM değil, hedef çizgisidir: grafiklerde '
        'referans çizgisi olarak görünür, bildirim tetiklemez.',
  ),
  ClinicalDefinition(
    key: 'potassium_mild',
    labelTr: 'Serum K — hafif hiperkalemi',
    unit: 'mEq/L',
    kind: ValueKind.alarmThreshold,
    verification: Verification.unverified,
    defaultValue: 5.0,
    decimals: 1,
    referenceTextTr: 'DİKKAT: KDIGO hiperkalemiyi yalnız potasyum '
        'sayısına göre değil, potasyum + EKG bulgusuna göre sınıflar '
        '(eşik noktaları 5,0 / 6,0 / 6,5 mEq/L) ve bunu "uzman görüşü" '
        'olarak niteler. Buradaki 5,0-5,5 / 5,5-6,0 / >6,0 kademeleri '
        'yaygın ALTERNATİF bir şemadır. Mayo Clinic Proceedings, '
        'kesin eşiklerin kılavuzlar arasında değiştiğini belirtir.',
    sourceIds: ['kdigo_potassium_2020', 'mayo_hyperkalemia_2021'],
  ),
  ClinicalDefinition(
    key: 'potassium_moderate',
    labelTr: 'Serum K — orta hiperkalemi',
    unit: 'mEq/L',
    kind: ValueKind.alarmThreshold,
    verification: Verification.unverified,
    defaultValue: 5.5,
    decimals: 1,
    triggersEmergencySms: true,
    referenceTextTr: 'KDIGO destekli bir sunumda ≥5,5-<6,0 mEq/L "orta", '
        '≥6,0 "ağır" olarak verilir; kılavuzun kendi şeması EKG\'yi de '
        'içerir. Eşikler kaynaklar arasında farklıdır.',
    sourceIds: ['kdigo_potassium_2020', 'mayo_hyperkalemia_2021'],
  ),
  ClinicalDefinition(
    key: 'potassium_severe',
    labelTr: 'Serum K — ağır hiperkalemi',
    unit: 'mEq/L',
    kind: ValueKind.alarmThreshold,
    verification: Verification.unverified,
    defaultValue: 6.0,
    decimals: 1,
    triggersEmergencySms: true,
    referenceTextTr: 'KDIGO şemasında ağır hiperkalemi: 6,0-6,4 mEq/L + '
        'EKG değişikliği VEYA ≥6,5 mEq/L (EKG\'den bağımsız). '
        'Uygulamada sadeleştirilmiş eşik >6,0 mEq/L.',
    sourceIds: ['kdigo_potassium_2020'],
  ),
  ClinicalDefinition(
    key: 'potassium_low',
    labelTr: 'Serum K — hipokalemi',
    unit: 'mEq/L',
    kind: ValueKind.alarmThreshold,
    verification: Verification.startingPoint,
    defaultValue: 3.5,
    decimals: 1,
    higherIsWorse: false,
    referenceTextTr: 'Çoğu laboratuvarın normal alt sınırı 3,5 mEq/L\'dir; '
        'KDIGO potasyum konferansı hipokalemiyi de ele alır ancak '
        'uygulamaya özel bir alarm eşiği vermez. Başlangıç değeri.',
    sourceIds: ['kdigo_potassium_2020'],
  ),
  ClinicalDefinition(
    key: 'idwg_percent',
    labelTr: 'Diyaliz arası kilo artışı',
    unit: '% kuru ağırlık',
    kind: ValueKind.alarmThreshold,
    verification: Verification.verified,
    defaultValue: 4.0,
    decimals: 1,
    referenceTextTr: 'Derleme düzeyinde kılavuz özeti: diyaliz arası '
        'kilo artışı (IDWG) hedefi kuru vücut ağırlığının '
        '%4,0-4,5\'inden AZ olmalıdır. Uygulama varsayılanı %4,0.',
    sourceIds: ['idwg_review_2025'],
    helpTr: 'Kuru ağırlığını Klinik Ayarlar\'da girersen yüzde '
        'otomatik hesaplanır.',
  ),
  ClinicalDefinition(
    key: 'weight_gain_daily_kg',
    labelTr: 'Günlük kilo artışı',
    unit: 'kg/gün',
    kind: ValueKind.alarmThreshold,
    verification: Verification.startingPoint,
    defaultValue: 1.0,
    decimals: 1,
    referenceTextTr: 'Kılavuzlarda sayısal bir günlük eşik yoktur. '
        'Günde 1 kg üzeri artış sıvı yüklenmesi açısından yaygın '
        'bir uyarı noktasıdır. Başlangıç değeri.',
    sourceIds: ['idwg_review_2025'],
  ),
  ClinicalDefinition(
    key: 'heart_rate_high',
    labelTr: 'Nabız — üst alarm',
    unit: '/dk',
    kind: ValueKind.alarmThreshold,
    verification: Verification.startingPoint,
    defaultValue: 120,
    triggersEmergencySms: true,
    referenceTextTr: 'Böbrek kılavuzlarında nabız için alarm eşiği '
        'TANIMLANMAMIŞTIR. İstirahatte >120/dk muhafazakâr bir '
        'başlangıç değeri olarak seçildi. Hiperkalemide bradikardi/'
        'aritmi de görülebilir — alt eşiğe de bak.',
    sourceIds: ['kdigo_potassium_2020'],
  ),
  ClinicalDefinition(
    key: 'heart_rate_low',
    labelTr: 'Nabız — alt alarm',
    unit: '/dk',
    kind: ValueKind.alarmThreshold,
    verification: Verification.startingPoint,
    defaultValue: 50,
    higherIsWorse: false,
    triggersEmergencySms: true,
    referenceTextTr: 'Kılavuzda eşik yok. <50/dk başlangıç değeri '
        '(ilaç kullanan veya sportif kişilerde normal olabilir — '
        'kendi değerini gir).',
    sourceIds: ['kdigo_potassium_2020'],
  ),
  ClinicalDefinition(
    key: 'spo2_warn',
    labelTr: 'SpO₂ — uyarı',
    unit: '%',
    kind: ValueKind.alarmThreshold,
    verification: Verification.startingPoint,
    defaultValue: 92,
    higherIsWorse: false,
    referenceTextTr: 'Böbrek kılavuzlarında SpO₂ eşiği yoktur. '
        '%92 yaygın bir "dikkat" eşiğidir. Başlangıç değeri. '
        'Akıllı saat ölçümleri tıbbi cihaz doğruluğunda değildir.',
    sourceIds: [],
  ),
  ClinicalDefinition(
    key: 'spo2_urgent',
    labelTr: 'SpO₂ — acil',
    unit: '%',
    kind: ValueKind.alarmThreshold,
    verification: Verification.startingPoint,
    defaultValue: 90,
    higherIsWorse: false,
    triggersEmergencySms: true,
    referenceTextTr: 'Kılavuzda eşik yok. %90 altı muhafazakâr acil '
        'başlangıç değeri. Başlangıç değeri.',
    sourceIds: [],
  ),
  ClinicalDefinition(
    key: 'urine_output_low_ml',
    labelTr: 'İdrar çıkışı — alt alarm',
    unit: 'mL/gün',
    kind: ValueKind.alarmThreshold,
    verification: Verification.startingPoint,
    defaultValue: 400,
    higherIsWorse: false,
    triggersEmergencySms: true,
    referenceTextTr: 'Oligüri için klasik tanım günlük <400 mL\'dir '
        '(bazı kaynaklar <500 mL kullanır). Anürik diyaliz '
        'hastasında bu alarm anlamsızdır — ilk kurulumda diyaliz '
        'seçtiysen uygulama bu alarmı kapalı başlatır.',
    sourceIds: [],
  ),
  ClinicalDefinition(
    key: 'temperature_high_c',
    labelTr: 'Ateş — üst alarm',
    unit: '°C',
    kind: ValueKind.alarmThreshold,
    verification: Verification.startingPoint,
    defaultValue: 38.0,
    decimals: 1,
    referenceTextTr: 'Ateş için 38,0 °C yaygın eşiktir. Diyaliz '
        'kateteri olan hastada ateş enfeksiyon açısından önemlidir. '
        'Başlangıç değeri.',
    sourceIds: [],
  ),
  ClinicalDefinition(
    key: 'glucose_low',
    labelTr: 'Kan şekeri — alt alarm',
    unit: 'mg/dL',
    kind: ValueKind.alarmThreshold,
    verification: Verification.startingPoint,
    defaultValue: 70,
    higherIsWorse: false,
    referenceTextTr: 'Hipoglisemi için yaygın eşik <70 mg/dL. '
        'Diyabetik böbrek hastalığında insülin klirensi azaldığı için '
        'hipoglisemi riski artar. Başlangıç değeri.',
    sourceIds: [],
  ),
  ClinicalDefinition(
    key: 'glucose_high',
    labelTr: 'Kan şekeri — üst alarm',
    unit: 'mg/dL',
    kind: ValueKind.alarmThreshold,
    verification: Verification.startingPoint,
    defaultValue: 250,
    referenceTextTr: 'Belirgin hiperglisemi için 250 mg/dL '
        'muhafazakâr bir başlangıç eşiğidir. Başlangıç değeri.',
    sourceIds: [],
  ),
];

/// ---------------------------------------------------------------------------
/// LABORATUVAR HEDEFLERİ
/// Varsayılan davranış: "kullanıcının laboratuvarının referans aralığı".
/// Tahlil girerken aralık da girilebilir; girilirse o aralık kullanılır.
/// ---------------------------------------------------------------------------
const List<ClinicalDefinition> kLabTargets = [
  ClinicalDefinition(
    key: 'lab_hemoglobin',
    labelTr: 'Hemoglobin',
    unit: 'g/dL',
    kind: ValueKind.labTarget,
    verification: Verification.verified,
    shape: ValueShape.range,
    defaultMin: 10.0,
    defaultMax: 11.5,
    decimals: 1,
    referenceTextTr: 'KDIGO 2026 Anemi: ESA tedavisi alan erişkinde '
        'hemoglobin hedefi 11,5 g/dL veya altı. ESA başlama eşiği: '
        'hemodiyalizde Hb ≤9,0-10,0 g/dL; diyaliz dışı CKD\'de '
        'çoğu kişide 8,5-10,0 g/dL. Alt sınır olarak 10,0 g/dL '
        'alındı (ESA başlama aralığının üstü).',
    sourceIds: ['kdigo_anemia_2026'],
  ),
  ClinicalDefinition(
    key: 'lab_ferritin',
    labelTr: 'Ferritin',
    unit: 'ng/mL',
    kind: ValueKind.labTarget,
    verification: Verification.verified,
    shape: ValueShape.range,
    defaultMin: 100,
    defaultMax: 500,
    referenceTextTr: 'KDIGO 2026 Anemi: G5HD\'de ferritin ≤500 ng/mL '
        've TSAT ≤%30 ise IV demir önerilir. Diyaliz dışı/PD\'de '
        'ferritin <100 ng/mL ve TSAT <%40, veya ferritin 100-300 ng/mL '
        've TSAT <%25 ise demir önerilir. Ferritin >700 ng/mL veya '
        'TSAT ≥%40 ise rutin demiri bekletmek makuldür.',
    sourceIds: ['kdigo_anemia_2026'],
  ),
  ClinicalDefinition(
    key: 'lab_tsat',
    labelTr: 'Transferrin satürasyonu (TSAT)',
    unit: '%',
    kind: ValueKind.labTarget,
    verification: Verification.verified,
    shape: ValueShape.range,
    defaultMin: 25,
    defaultMax: 40,
    referenceTextTr: 'KDIGO 2026 Anemi: TSAT ≥%40 ise rutin demir '
        'bekletilir; G5HD\'de TSAT ≤%30 (ferritin ≤500 ile) demir '
        'endikasyonudur.',
    sourceIds: ['kdigo_anemia_2026'],
  ),
  ClinicalDefinition(
    key: 'lab_phosphate',
    labelTr: 'Serum fosfat',
    unit: 'mg/dL',
    kind: ValueKind.labTarget,
    verification: Verification.individualized,
    shape: ValueShape.range,
    defaultMin: null,
    defaultMax: null,
    decimals: 1,
    referenceTextTr: 'KDIGO 2017 CKD-MBD sabit bir hedef aralık '
        'VERMEZ: G5D\'de "yükselmiş fosfatın normal aralığa doğru '
        'düşürülmesi" önerilir (2C). Diyaliz dışı CKD\'de fosfatın '
        'normal aralıkta tutulması vurgulanır. Bu yüzden varsayılan, '
        'kendi laboratuvarının referans aralığıdır.',
    sourceIds: ['kdigo_mbd_2017'],
    helpTr: 'Tahlil girerken laboratuvarının aralığını da girebilirsin; '
        'grafikte o aralık gölgelenir.',
  ),
  ClinicalDefinition(
    key: 'lab_calcium',
    labelTr: 'Düzeltilmiş kalsiyum',
    unit: 'mg/dL',
    kind: ValueKind.labTarget,
    verification: Verification.individualized,
    shape: ValueShape.range,
    decimals: 1,
    referenceTextTr: 'KDIGO 2017 CKD-MBD: erişkinde hiperkalsemiden '
        'kaçınılması önerilir (1C) ve hiperkalsemide kalsiyum içeren '
        'fosfat bağlayıcı / D vitamini analoğu dozunun kısıtlanması '
        'istenir. Sayısal hedef aralık verilmez — laboratuvar '
        'aralığın kullanılır.',
    sourceIds: ['kdigo_mbd_2017'],
  ),
  ClinicalDefinition(
    key: 'lab_pth',
    labelTr: 'Parathormon (PTH)',
    unit: 'pg/mL',
    kind: ValueKind.labTarget,
    verification: Verification.unverified,
    shape: ValueShape.range,
    defaultMin: null,
    defaultMax: null,
    referenceTextTr: 'DOĞRULANMADI: Diyaliz hastası için sık aktarılan '
        'hedef, normalin üst sınırının 2-9 KATI\'dır. Bu sayıyı '
        'birincil KDIGO 2017 CKD-MBD metninde doğrulayamadık '
        '(yalnız kılavuzu özetleyen bir sunumda görüldü). '
        'Diyaliz dışı CKD için kılavuz "optimal PTH düzeyi '
        'bilinmiyor" der. Kendi değerini girmen önerilir.',
    sourceIds: ['kdigo_mbd_2017'],
    helpTr: 'Laboratuvarının üst sınırını tahlil girerken yazarsan, '
        'uygulama 2-9 katı aralığını bilgi olarak hesaplayıp '
        '"doğrulanmadı" etiketiyle gösterir.',
  ),
  ClinicalDefinition(
    key: 'lab_potassium',
    labelTr: 'Serum potasyum',
    unit: 'mEq/L',
    kind: ValueKind.labTarget,
    verification: Verification.startingPoint,
    shape: ValueShape.range,
    defaultMin: 3.5,
    defaultMax: 5.0,
    decimals: 1,
    referenceTextTr: 'Çoğu laboratuvarın normal aralığı 3,5-5,0 mEq/L '
        'civarındadır; KDIGO potasyum konferansı 5,0 mEq/L\'yi '
        '(veya laboratuvarın üst sınırını) ilk kesim noktası olarak '
        'kullanır. Laboratuvarının aralığı farklıysa onu gir.',
    sourceIds: ['kdigo_potassium_2020'],
  ),
  ClinicalDefinition(
    key: 'lab_bicarbonate',
    labelTr: 'Serum bikarbonat',
    unit: 'mmol/L',
    kind: ValueKind.labTarget,
    verification: Verification.unverified,
    shape: ValueShape.range,
    defaultMin: 22,
    defaultMax: null,
    referenceTextTr: 'DOĞRULANMADI: CKD\'de metabolik asidoz için sık '
        'kullanılan alt sınır 22 mmol/L\'dir. KDIGO 2024 metninde '
        'bu sayıyı doğrulayamadık. Kendi değerini girmen önerilir.',
    sourceIds: ['kdigo_ckd_2024'],
  ),
  ClinicalDefinition(
    key: 'lab_albumin',
    labelTr: 'Serum albümin',
    unit: 'g/dL',
    kind: ValueKind.labTarget,
    verification: Verification.individualized,
    shape: ValueShape.range,
    decimals: 1,
    referenceTextTr: 'KDOQI 2020 beslenme kılavuzu albümini tek başına '
        'beslenme göstergesi olarak kullanmamayı söyler. '
        'Hedef aralık yerine laboratuvar aralığın kullanılır.',
    sourceIds: ['kdoqi_nutrition_2020'],
  ),
  ClinicalDefinition(
    key: 'lab_creatinine',
    labelTr: 'Kreatinin',
    unit: 'mg/dL',
    kind: ValueKind.labTarget,
    verification: Verification.individualized,
    shape: ValueShape.range,
    decimals: 2,
    referenceTextTr: 'Kreatinin için hedef aralık kılavuzla '
        'tanımlanmaz; kas kütlesi, yaş ve cinsiyete göre değişir. '
        'Laboratuvarının referans aralığı kullanılır. '
        'KDIGO 2024 evrelemeyi kreatinin yerine eGFR + albüminüri '
        'ile yapar.',
    sourceIds: ['kdigo_ckd_2024'],
  ),
  ClinicalDefinition(
    key: 'lab_egfr',
    labelTr: 'eGFR',
    unit: 'mL/dk/1,73m²',
    kind: ValueKind.labTarget,
    verification: Verification.verified,
    shape: ValueShape.range,
    defaultMin: 60,
    defaultMax: null,
    referenceTextTr: 'KDIGO 2024 GFR kategorileri: G1 ≥90, G2 60-89, '
        'G3a 45-59, G3b 30-44, G4 15-29, G5 <15 mL/dk/1,73m². '
        'G3a ve altı (eGFR <60) üç aydan uzun sürerse CKD tanımına '
        'girer. Grafikte 60 çizgisi referans olarak gösterilir.',
    sourceIds: ['kdigo_ckd_2024'],
  ),
  ClinicalDefinition(
    key: 'lab_uacr',
    labelTr: 'İdrar albümin/kreatinin (uACR)',
    unit: 'mg/g',
    kind: ValueKind.labTarget,
    verification: Verification.verified,
    shape: ValueShape.range,
    defaultMin: null,
    defaultMax: 30,
    referenceTextTr: 'KDIGO 2024 albüminüri kategorileri: '
        'A1 <30 mg/g, A2 30-300 mg/g, A3 >300 mg/g.',
    sourceIds: ['kdigo_ckd_2024'],
  ),
];

/// Tüm tanımlar tek listede.
const List<ClinicalDefinition> kAllDefinitions = [
  ...kDietTargets,
  ...kAlarmThresholds,
  ...kLabTargets,
];

ClinicalDefinition? definitionByKey(String key) {
  for (final d in kAllDefinitions) {
    if (d.key == key) return d;
  }
  return null;
}

/// Her yerde gösterilen tıbbi uyarı.
const String kMedicalDisclaimerTr =
    'Bu uygulama tıbbi tavsiye değildir, klinik karar kullanıcıya aittir.';

const String kReferenceCaveatTr =
    'Referans/kılavuz değeri — klinik karar sana ait.';

/// Türkçe dışındaki dillerde her sayfanın altında görünür.
///
/// Uygulamanın metinleri Türkçe yazıldı ve diğer dillere MAKİNE ile
/// çevrildi; klinik metinleri (ilaç uyarıları, tahlil yorumları, diyet
/// kuralları) hiçbir uzman gözden geçirmedi. Bu bir tıp uygulamasında
/// saklanacak bir şey değil: kullanıcı hangi metne ne kadar
/// güvenebileceğini bilmeli ve şüphede Türkçe aslına dönebilmeli.
const String kMachineTranslationNoticeTr =
    'Bu metin makine çevirisidir ve bir uzman tarafından gözden '
    'geçirilmemiştir. Şüphede kalırsan Türkçe aslına bak.';

const String kPrivacyNoteTr =
    'Verilerin telefonda, şifreli olarak saklanır. Hiçbir veri '
    'otomatik olarak dışarı gönderilmez. Yalnızca yapay zeka '
    'özelliklerini kendin kullandığında, gönderdiğin metin ve görsel '
    'Anthropic Claude API\'sine iletilir.';
