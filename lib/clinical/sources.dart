/// Klinik kaynak kaydı. Uygulama içindeki "Kaynaklar" ekranı bu listeyi gösterir.
///
/// ÖNEMLİ: Buradaki hiçbir değer tıbbi talimat değildir. Her değer
/// "Referans/kılavuz değeri — klinik karar sana ait" ilkesiyle sunulur.
library;

/// Bir kaynağın ne kadar doğrulandığını anlatır.
enum SourceTier {
  /// Birincil kılavuz metni veya kılavuzun resmî özeti.
  primaryGuideline,

  /// Kılavuzu özetleyen hakemli derleme / yorum yazısı.
  secondaryReview,

  /// Resmî kurum bilgilendirme sayfası (hasta eğitimi).
  institutionalPage,

  /// Ulusal besin kompozisyon veri tabanı.
  foodDatabase,
}

extension SourceTierTr on SourceTier {
  String get labelTr => switch (this) {
        SourceTier.primaryGuideline => 'Birincil kılavuz',
        SourceTier.secondaryReview => 'Hakemli derleme',
        SourceTier.institutionalPage => 'Kurum sayfası',
        SourceTier.foodDatabase => 'Besin veri tabanı',
      };
}

class ClinicalSource {
  const ClinicalSource({
    required this.id,
    required this.name,
    required this.year,
    required this.url,
    required this.tier,
    this.noteTr,
  });

  final String id;
  final String name;
  final int year;
  final String url;
  final SourceTier tier;

  /// Türkçe, sade bir not: bu kaynak neyi söylüyor, sınırı ne.
  final String? noteTr;

  String get citation => '$name ($year)';
}

/// Uygulamadaki tüm klinik kaynaklar.
///
/// Son kontrol tarihi: 23 Kasım 2026 (bağlantılar bu tarihte erişilebilirdi).
const String kSourcesLastCheckedTr = '23 Kasım 2026';

const List<ClinicalSource> kClinicalSources = [
  ClinicalSource(
    id: 'kdigo_ckd_2024',
    name: 'KDIGO 2024 Clinical Practice Guideline for the Evaluation and '
        'Management of Chronic Kidney Disease',
    year: 2024,
    url: 'https://www.kidney-international.org/article/S0085-2538(23)00766-4/fulltext',
    tier: SourceTier.primaryGuideline,
    noteTr: 'Protein (0,8 g/kg/gün, CKD G3-G5), sodyum (<2 g/gün) ve '
        'kan basıncı (sistolik <120 mmHg, standart ofis ölçümü) '
        'önerilerinin kaynağı. Üç öneri de "zayıf öneri" (2B/2C) '
        'düzeyindedir; kılavuz bireyselleştirmeyi vurgular.',
  ),
  ClinicalSource(
    id: 'kdigo_ckd_2024_summary',
    name: 'KDIGO 2024 CKD Guideline — Summary of Recommendations and '
        'Practice Points',
    year: 2024,
    url: 'https://kdigo.org/wp-content/uploads/2026/05/'
        'KDIGO-2024-CKD-Guideline-Summary-Recommendations-and-Practice-Points.pdf',
    tier: SourceTier.primaryGuideline,
    noteTr: 'Yukarıdaki kılavuzun ücretsiz öneri özeti (PDF). '
        'Madde numaralarını doğrulamak için en pratik kaynak.',
  ),
  ClinicalSource(
    id: 'kdoqi_nutrition_2020',
    name: 'KDOQI Clinical Practice Guideline for Nutrition in CKD: '
        '2020 Update',
    year: 2020,
    url: 'https://www.ajkd.org/article/S0272-6386(20)30726-5/fulltext',
    tier: SourceTier.primaryGuideline,
    noteTr: 'Diyaliz dışı CKD 3-5 (diyabetsiz) 0,55-0,60 g/kg/gün; '
        'diyabetli 0,6-0,8 g/kg/gün; hemodiyaliz/periton diyalizi '
        '1,0-1,2 g/kg/gün protein. Enerji 25-35 kcal/kg/gün. '
        'Potasyum ve fosfor için SABİT sayı vermez: serum düzeyine '
        'göre bireyselleştirilmesini söyler.',
  ),
  ClinicalSource(
    id: 'kdigo_mbd_2017',
    name: 'KDIGO 2017 Clinical Practice Guideline Update for CKD-MBD',
    year: 2017,
    url: 'https://kdigo.org/wp-content/uploads/2017/02/'
        '2017-KDIGO-CKD-MBD-GL-Update.pdf',
    tier: SourceTier.primaryGuideline,
    noteTr: 'Fosfat: CKD G5D\'de yükselmiş fosfatın normal aralığa doğru '
        'düşürülmesi (2C). Kalsiyum içeren bağlayıcıların dozunun '
        'kısıtlanması. PTH için diyaliz hedef aralığı bu PDF\'ten '
        'teyit edilmelidir (bkz. "doğrulanmadı" etiketli değer).',
  ),
  ClinicalSource(
    id: 'kdigo_anemia_2026',
    name: 'KDIGO 2026 Clinical Practice Guideline for the Management of '
        'Anemia in Chronic Kidney Disease',
    year: 2026,
    url: 'https://www.kidney-international.org/article/S0085-2538(25)00495-8/fulltext',
    tier: SourceTier.primaryGuideline,
    noteTr: 'Erişkinde ESA ile hemoglobin hedefi 11,5 g/dL veya altı. '
        'Hemodiyalizde ESA başlama eşiği Hb ≤9,0-10,0 g/dL. '
        'Demir: G5HD\'de ferritin ≤500 ng/mL ve TSAT ≤%30 ise IV demir; '
        'ferritin >700 ng/mL veya TSAT ≥%40 ise rutin demiri bekletmek '
        'makul. 2012 anemi kılavuzunun yerini alır.',
  ),
  ClinicalSource(
    id: 'acc_aha_htn_2017',
    name: '2017 ACC/AHA Guideline for the Prevention, Detection, '
        'Evaluation, and Management of High Blood Pressure in Adults',
    year: 2017,
    url: 'https://www.acc.org/Latest-in-Cardiology/Articles/2017/11/08/11/47/'
        'mon-5pm-bp-guideline-aha-2017',
    tier: SourceTier.primaryGuideline,
    noteTr: 'Kan basıncı sınıflaması ve hipertansif kriz eşiği: '
        'sistolik >180 ve/veya diyastolik >120 mmHg. Hedef organ hasarı '
        'varsa "acil" (emergency), yoksa "ivedi" (urgency). '
        'Sınıflama ≥2 ayrı ölçümün ortalamasına dayanır.',
  ),
  ClinicalSource(
    id: 'kdigo_potassium_2020',
    name: 'KDIGO Controversies Conference — Potassium Homeostasis and '
        'Management of Dyskalemia in Kidney Diseases',
    year: 2020,
    url: 'https://kdigo.org/wp-content/uploads/2018/04/'
        'KDIGO-Potassium-Management-Final-publication.pdf',
    tier: SourceTier.primaryGuideline,
    noteTr: 'ÖNEMLİ: KDIGO hiperkalemiyi yalnız potasyum sayısına göre '
        'değil, potasyum + EKG bulgusuna göre sınıflar (eşik noktaları '
        '5,0 / 6,0 / 6,5 mEq/L). Sınıflama "uzman görüşü" olarak '
        'nitelenir. Uygulamadaki 5,0/5,5/6,0 kademeleri yaygın '
        'ALTERNATİF bir şemadır, KDIGO\'nun kendi şeması değildir.',
  ),
  ClinicalSource(
    id: 'mayo_hyperkalemia_2021',
    name: 'Clinical Management of Hyperkalemia (Mayo Clinic Proceedings)',
    year: 2021,
    url: 'https://www.mayoclinicproceedings.org/article/S0025-6196(20)30618-2/fulltext',
    tier: SourceTier.secondaryReview,
    noteTr: 'Hafif/orta/ağır hiperkalemi için kesin potasyum eşiklerinin '
        'kılavuzlar arasında DEĞİŞTİĞİNİ açıkça belirtir. '
        'Uygulamadaki kademelerin "doğrulanmadı" etiketi bu yüzdendir.',
  ),
  ClinicalSource(
    id: 'idwg_review_2025',
    name: 'How to Limit Interdialytic Weight Gain in Patients on '
        'Maintenance Hemodialysis: State of the Art and Perspectives',
    year: 2025,
    url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC11942859/',
    tier: SourceTier.secondaryReview,
    noteTr: 'Diyaliz arası kilo artışı (IDWG) hedefi: kuru ağırlığın '
        '%4,0-4,5\'inden az. Hemodiyalizde günlük sıvının tipik olarak '
        '500-1000 mL ile sınırlandığını belirtir; bu bir kılavuz '
        'önerisi değil, klinik pratiğin derlemesidir. Aynı literatür '
        'sabit hacim yerine bireysel reçeteyi savunur.',
  ),
  ClinicalSource(
    id: 'nkf_pain_meds',
    name: 'National Kidney Foundation — Pain Medications and Kidney Disease',
    year: 2024,
    url: 'https://www.kidney.org/kidney-topics/pain-medicines-and-kidney-disease',
    tier: SourceTier.institutionalPage,
    noteTr: 'CKD\'de NSAİİ\'lerden kaçınılması, özellikle eGFR <60 '
        'ise. Kalp hastalığı için hekimin önerdiği düşük doz aspirin '
        'ayrı değerlendirilir.',
  ),
  ClinicalSource(
    id: 'nkf_herbal',
    name: 'National Kidney Foundation — Herbal Supplements and Kidney Disease',
    year: 2024,
    url: 'https://www.kidney.org/kidney-topics/herbal-supplements-and-kidney-disease',
    tier: SourceTier.institutionalPage,
    noteTr: 'Böbrek hastalarında bitkisel ürünlerin genel olarak '
        'önerilmediğini belirtir. Uygulamadaki bitkisel ürün listesi '
        'bu sayfanın ve ikincil derlemelerin birleşimidir; '
        'KAPSAMLI DEĞİLDİR.',
  ),
  ClinicalSource(
    id: 'turkomp',
    name: 'TürKomp — Türkiye Ulusal Besin Kompozisyon Veri Tabanı',
    year: 2024,
    url: 'https://turkomp.tarimorman.gov.tr/',
    tier: SourceTier.foodDatabase,
    noteTr: 'Türkiye\'de üretilen/tüketilen besinler için analitik '
        'besin değerleri (yaklaşık 580-645 besin). Tarım ve Orman '
        'Bakanlığı yürütür. Uygulamadaki yerel besin değerleri bu '
        'veri tabanı ve USDA FoodData Central temel alınarak '
        'girilmiştir; porsiyon ve pişirme yöntemine göre DEĞİŞİR.',
  ),
  ClinicalSource(
    id: 'usda_fdc',
    name: 'USDA FoodData Central',
    year: 2024,
    url: 'https://fdc.nal.usda.gov/',
    tier: SourceTier.foodDatabase,
    noteTr: 'Uluslararası besin kompozisyon referansı. Türk mutfağına '
        'özgü yemeklerde TürKomp tercih edilmiştir.',
  ),
  ClinicalSource(
    id: 'turk_nefroloji',
    name: 'Türk Nefroloji Derneği',
    year: 2026,
    url: 'https://www.nefroloji.org.tr/',
    tier: SourceTier.institutionalPage,
    noteTr: 'Türkiye\'deki ulusal kayıt verileri ve hasta bilgilendirme '
        'materyalleri. Bu sürümde makine ile okunabilir (RSS) bir '
        'içerik akışı bulunamadı; Okuma sayfasında elle yazılmış '
        'kaynaklı içerik kullanılır.',
  ),
  ClinicalSource(
    id: 'openfoodfacts',
    name: 'Open Food Facts',
    year: 2026,
    url: 'https://world.openfoodfacts.org/',
    tier: SourceTier.foodDatabase,
    noteTr: 'Barkod ile paketli ürün verisi. Topluluk katkılı: '
        'etiket değerleri eksik veya hatalı olabilir. Uygulama '
        'eksik besin öğesini "bilinmiyor" olarak gösterir, sıfır '
        'saymaz.',
  ),
];

ClinicalSource? sourceById(String id) {
  for (final s in kClinicalSources) {
    if (s.id == id) return s;
  }
  return null;
}

List<ClinicalSource> sourcesByIds(Iterable<String> ids) =>
    ids.map(sourceById).whereType<ClinicalSource>().toList(growable: false);
