/// Böbrek hastalığında dikkat gerektiren ilaç ve bitkisel ürün veri seti.
///
/// !!! BU LİSTE ÖRNEKTİR, KAPSAMLI DEĞİLDİR !!!
/// Kaynak: National Kidney Foundation hasta bilgilendirme sayfaları
/// (ağrı kesiciler, bitkisel ürünler) ve ikincil derlemeler.
/// Türkiye'deki ticari adlar yaygın olanlardan derlenmiştir ve
/// eksik olabilir. Hiçbir maddenin yokluğu "güvenli" anlamına GELMEZ.
library;

enum RiskClass {
  /// NSAİİ — CKD'de kaçınılması önerilir (özellikle eGFR <60).
  nsaid,

  /// Böbrek hastalarında riskli bitkisel ürün.
  herbal,

  /// Böbrekten atılan, doz ayarı gerekebilen ilaç grubu.
  doseAdjust,

  /// Kontrast madde / nefrotoksik potansiyel.
  nephrotoxicOther,
}

extension RiskClassTr on RiskClass {
  String get labelTr => switch (this) {
        RiskClass.nsaid => 'NSAİİ (ağrı kesici)',
        RiskClass.herbal => 'Bitkisel ürün',
        RiskClass.doseAdjust => 'Doz ayarı gerekebilir',
        RiskClass.nephrotoxicOther => 'Böbreğe yük bindirebilir',
      };
}

enum RiskSeverity { caution, avoid }

extension RiskSeverityTr on RiskSeverity {
  String get labelTr => switch (this) {
        RiskSeverity.caution => 'Dikkat',
        RiskSeverity.avoid => 'Kaçınılması önerilir',
      };
}

class DrugRisk {
  const DrugRisk({
    required this.id,
    required this.genericTr,
    required this.riskClass,
    required this.severity,
    required this.reasonTr,
    required this.sourceIds,
    this.brandNamesTr = const [],
    this.aliases = const [],
  });

  final String id;

  /// Etken madde adı (Türkçe yazım).
  final String genericTr;

  /// Türkiye'de yaygın ticari adlar. Eksik olabilir.
  final List<String> brandNamesTr;

  /// Arama için ek yazımlar (İngilizce, yaygın yanlış yazım).
  final List<String> aliases;

  final RiskClass riskClass;
  final RiskSeverity severity;
  final String reasonTr;
  final List<String> sourceIds;

  /// Eşleştirmede kullanılan tüm adlar.
  List<String> get allNames => [genericTr, ...brandNamesTr, ...aliases];
}

/// NSAİİ'ler (Türkiye'de yaygın ticari adlarla).
const List<DrugRisk> kNsaidRisks = [
  DrugRisk(
    id: 'ibuprofen',
    genericTr: 'İbuprofen',
    brandNamesTr: ['Brufen', 'Nurofen', 'Dolven', 'Advil', 'Pedifen', 'Suprafen'],
    aliases: ['ibuprofen', 'ibubrofen'],
    riskClass: RiskClass.nsaid,
    severity: RiskSeverity.avoid,
    reasonTr: 'NSAİİ: böbreğe giden kan akımını azaltır. '
        'NKF, CKD\'de NSAİİ\'lerden kaçınılmasını, özellikle '
        'eGFR <60 ise, önerir.',
    sourceIds: ['nkf_pain_meds'],
  ),
  DrugRisk(
    id: 'diklofenak',
    genericTr: 'Diklofenak',
    brandNamesTr: ['Voltaren', 'Dikloron', 'Cataflam', 'Miyadren', 'Dolorex'],
    aliases: ['diclofenac', 'diklofenak sodyum'],
    riskClass: RiskClass.nsaid,
    severity: RiskSeverity.avoid,
    reasonTr: 'NSAİİ: böbrek kan akımını azaltır. Jel formu dahil '
        'NKF listesinde yer alır.',
    sourceIds: ['nkf_pain_meds'],
  ),
  DrugRisk(
    id: 'naproksen',
    genericTr: 'Naproksen',
    brandNamesTr: ['Apranax', 'Aprol', 'Synax', 'Naprosyn'],
    aliases: ['naproxen', 'naproksen sodyum'],
    riskClass: RiskClass.nsaid,
    severity: RiskSeverity.avoid,
    reasonTr: 'NSAİİ: NKF\'nin CKD\'de kaçınılacak ağrı kesiciler '
        'listesinde.',
    sourceIds: ['nkf_pain_meds'],
  ),
  DrugRisk(
    id: 'deksketoprofen',
    genericTr: 'Deksketoprofen',
    brandNamesTr: ['Arveles', 'Desalgin', 'Deksalgin'],
    aliases: ['dexketoprofen'],
    riskClass: RiskClass.nsaid,
    severity: RiskSeverity.avoid,
    reasonTr: 'NSAİİ grubundandır; Türkiye\'de çok yaygın kullanılır. '
        'NKF\'nin genel NSAİİ uyarısı kapsamındadır.',
    sourceIds: ['nkf_pain_meds'],
  ),
  DrugRisk(
    id: 'etodolak',
    genericTr: 'Etodolak',
    brandNamesTr: ['Etol', 'Tadolak'],
    aliases: ['etodolac'],
    riskClass: RiskClass.nsaid,
    severity: RiskSeverity.avoid,
    reasonTr: 'NSAİİ grubundandır. NKF\'nin genel NSAİİ uyarısı '
        'kapsamındadır.',
    sourceIds: ['nkf_pain_meds'],
  ),
  DrugRisk(
    id: 'meloksikam',
    genericTr: 'Meloksikam',
    brandNamesTr: ['Melox', 'Mobic', 'Zeloxim', 'Exen'],
    aliases: ['meloxicam'],
    riskClass: RiskClass.nsaid,
    severity: RiskSeverity.avoid,
    reasonTr: 'NSAİİ grubundandır.',
    sourceIds: ['nkf_pain_meds'],
  ),
  DrugRisk(
    id: 'tenoksikam',
    genericTr: 'Tenoksikam',
    brandNamesTr: ['Tilcotil', 'Oksamen'],
    aliases: ['tenoxicam'],
    riskClass: RiskClass.nsaid,
    severity: RiskSeverity.avoid,
    reasonTr: 'NSAİİ grubundandır.',
    sourceIds: ['nkf_pain_meds'],
  ),
  DrugRisk(
    id: 'nimesulid',
    genericTr: 'Nimesulid',
    brandNamesTr: ['Nimes', 'Mesulid'],
    aliases: ['nimesulide'],
    riskClass: RiskClass.nsaid,
    severity: RiskSeverity.avoid,
    reasonTr: 'NSAİİ grubundandır.',
    sourceIds: ['nkf_pain_meds'],
  ),
  DrugRisk(
    id: 'selekoksib',
    genericTr: 'Selekoksib',
    brandNamesTr: ['Celebrex', 'Defalgin'],
    aliases: ['celecoxib'],
    riskClass: RiskClass.nsaid,
    severity: RiskSeverity.caution,
    reasonTr: 'COX-2 seçici NSAİİ. Mide açısından daha güvenli '
        'sayılsa da böbrek üzerindeki etkisi diğer NSAİİ\'lere '
        'benzerdir.',
    sourceIds: ['nkf_pain_meds'],
  ),
  DrugRisk(
    id: 'aspirin_high',
    genericTr: 'Asetilsalisilik asit (yüksek doz)',
    brandNamesTr: ['Aspirin', 'Ecopirin', 'Coraspin'],
    aliases: ['asetilsalisilik', 'acetylsalicylic', 'aspirin'],
    riskClass: RiskClass.nsaid,
    severity: RiskSeverity.caution,
    reasonTr: 'NKF yüksek doz aspirini NSAİİ olarak listeler. '
        'ÖNEMLİ: kalp hastalığı için hekimin önerdiği DÜŞÜK DOZ '
        'aspirin bundan ayrıdır ve kesilmemelidir — doktoruna sor.',
    sourceIds: ['nkf_pain_meds'],
  ),
];

/// Bitkisel ürünler. NKF/AND listelerinden ve ikincil derlemelerden.
const List<DrugRisk> kHerbalRisks = [
  DrugRisk(
    id: 'kereviz_tohumu',
    genericTr: 'Kereviz (tohumu/özü)',
    aliases: ['apium graveolens', 'celery seed', 'kereviz özü'],
    riskClass: RiskClass.herbal,
    severity: RiskSeverity.avoid,
    reasonTr: 'NKF kaynaklı listede böbrek hastalarının kaçınması '
        'gereken bitkiler arasında (idrar söktürücü etki).',
    sourceIds: ['nkf_herbal'],
  ),
  DrugRisk(
    id: 'atkuyrugu',
    genericTr: 'Atkuyruğu',
    aliases: ['horsetail', 'equisetum'],
    riskClass: RiskClass.herbal,
    severity: RiskSeverity.avoid,
    reasonTr: 'Güçlü idrar söktürücü; NKF kaynaklı kaçınma listesinde.',
    sourceIds: ['nkf_herbal'],
  ),
  DrugRisk(
    id: 'meyan_koku',
    genericTr: 'Meyan kökü',
    aliases: ['licorice', 'glycyrrhiza', 'meyan balı'],
    riskClass: RiskClass.herbal,
    severity: RiskSeverity.avoid,
    reasonTr: 'Potasyum düşürücü ve kan basıncı yükseltici etki '
        'yapabilir; NKF kaynaklı kaçınma listesinde. '
        'Türkiye\'de meyan şerbeti olarak yaygın.',
    sourceIds: ['nkf_herbal'],
  ),
  DrugRisk(
    id: 'maydanoz_koku',
    genericTr: 'Maydanoz kökü',
    aliases: ['parsley root', 'petroselinum'],
    riskClass: RiskClass.herbal,
    severity: RiskSeverity.avoid,
    reasonTr: 'NKF kaynaklı kaçınma listesinde. '
        '(Yemekteki bir tutam maydanoz ile konsantre kök özü '
        'aynı şey değildir.)',
    sourceIds: ['nkf_herbal'],
  ),
  DrugRisk(
    id: 'ayi_uzumu',
    genericTr: 'Ayı üzümü',
    aliases: ['uva ursi', 'arctostaphylos', 'bearberry'],
    riskClass: RiskClass.herbal,
    severity: RiskSeverity.avoid,
    reasonTr: 'NKF kaynaklı kaçınma listesinde.',
    sourceIds: ['nkf_herbal'],
  ),
  DrugRisk(
    id: 'kadin_tuzlugu',
    genericTr: 'Kadın tuzluğu (barberry)',
    aliases: ['barberry', 'berberis', 'berberin'],
    riskClass: RiskClass.herbal,
    severity: RiskSeverity.avoid,
    reasonTr: 'NKF kaynaklı kaçınma listesinde.',
    sourceIds: ['nkf_herbal'],
  ),
  DrugRisk(
    id: 'kreatin',
    genericTr: 'Kreatin (takviye)',
    aliases: ['creatine', 'kreatin monohidrat'],
    riskClass: RiskClass.herbal,
    severity: RiskSeverity.avoid,
    reasonTr: 'NKF kaynaklı kaçınma listesinde. Ayrıca serum '
        'kreatinin ölçümünü yükselterek tahlil yorumunu bozabilir.',
    sourceIds: ['nkf_herbal'],
  ),
  DrugRisk(
    id: 'isirgan',
    genericTr: 'Isırgan otu',
    aliases: ['nettle', 'urtica', 'isirgan'],
    riskClass: RiskClass.herbal,
    severity: RiskSeverity.avoid,
    reasonTr: 'NKF kaynaklı kaçınma listesinde. Türkiye\'de '
        '"böbrek temizler" diye çok tavsiye edilir — bu iddianın '
        'kanıtı yoktur.',
    sourceIds: ['nkf_herbal'],
  ),
  DrugRisk(
    id: 'yohimbe',
    genericTr: 'Yohimbe',
    aliases: ['yohimbine', 'yohimbin'],
    riskClass: RiskClass.herbal,
    severity: RiskSeverity.avoid,
    reasonTr: 'NKF kaynaklı kaçınma listesinde; kan basıncını '
        'yükseltebilir.',
    sourceIds: ['nkf_herbal'],
  ),
  DrugRisk(
    id: 'kedi_pencesi',
    genericTr: 'Kedi pençesi',
    aliases: ['cat\'s claw', 'uncaria'],
    riskClass: RiskClass.herbal,
    severity: RiskSeverity.avoid,
    reasonTr: 'NKF kaynaklı kaçınma listesinde.',
    sourceIds: ['nkf_herbal'],
  ),
  DrugRisk(
    id: 'altin_basak',
    genericTr: 'Altın başak (goldenrod)',
    aliases: ['goldenrod', 'solidago'],
    riskClass: RiskClass.herbal,
    severity: RiskSeverity.avoid,
    reasonTr: 'NKF kaynaklı kaçınma listesinde.',
    sourceIds: ['nkf_herbal'],
  ),
  DrugRisk(
    id: 'java_cayi',
    genericTr: 'Java çayı',
    aliases: ['java tea', 'orthosiphon'],
    riskClass: RiskClass.herbal,
    severity: RiskSeverity.avoid,
    reasonTr: 'NKF kaynaklı kaçınma listesinde.',
    sourceIds: ['nkf_herbal'],
  ),
  DrugRisk(
    id: 'sedef_otu',
    genericTr: 'Sedef otu',
    aliases: ['ruta graveolens', 'rue'],
    riskClass: RiskClass.herbal,
    severity: RiskSeverity.avoid,
    reasonTr: 'NKF kaynaklı kaçınma listesinde.',
    sourceIds: ['nkf_herbal'],
  ),
  DrugRisk(
    id: 'yarpuz',
    genericTr: 'Yarpuz (pennyroyal)',
    aliases: ['pennyroyal', 'mentha pulegium'],
    riskClass: RiskClass.herbal,
    severity: RiskSeverity.avoid,
    reasonTr: 'NKF kaynaklı kaçınma listesinde; karaciğer ve '
        'böbrek için toksik kabul edilir.',
    sourceIds: ['nkf_herbal'],
  ),
  DrugRisk(
    id: 'potasyumlu_tuz',
    genericTr: 'Potasyum klorürlü "diyet tuzu"',
    brandNamesTr: ['Light tuz', 'Az sodyumlu tuz'],
    aliases: ['potasyum klorür', 'kcl', 'sodyumsuz tuz'],
    riskClass: RiskClass.nephrotoxicOther,
    severity: RiskSeverity.avoid,
    reasonTr: 'Sodyumu azaltmak için satılan tuz ikameleri '
        'potasyum klorür içerir ve böbrek hastasında tehlikeli '
        'hiperkalemiye yol açabilir. Etiketi oku.',
    sourceIds: ['kdigo_potassium_2020'],
  ),
];

const List<DrugRisk> kAllDrugRisks = [...kNsaidRisks, ...kHerbalRisks];

const String kDrugDatasetDisclaimerTr =
    'Bu liste ÖRNEK niteliğindedir ve KAPSAMLI DEĞİLDİR. '
    'Bir ilacın listede olmaması güvenli olduğu anlamına gelmez. '
    'Türkiye\'deki ticari adlar eksik olabilir. '
    'Her ilaç değişikliğini kendi hekiminle değerlendir.';

/// Eşleşme sonucu.
class DrugMatch {
  const DrugMatch({
    required this.risk,
    required this.matchedName,
    required this.isExact,
  });

  final DrugRisk risk;

  /// Hangi ad eşleşti (etken madde mi, ticari ad mı).
  final String matchedName;

  /// Tam ad eşleşmesi mi, yoksa içeren eşleşme mi?
  final bool isExact;
}

/// Türkçe karakterleri ve noktalama işaretlerini sadeleştirir.
///
/// Dart'ın `toLowerCase()`'i Türkçe'de "I" -> "i" yapar ("ı" değil),
/// bu yüzden eşleştirme öncesi elle normalize ediyoruz.
String normalizeDrugName(String input) {
  const map = {
    'ı': 'i', 'İ': 'i', 'I': 'i', 'i': 'i',
    'ş': 's', 'Ş': 's',
    'ğ': 'g', 'Ğ': 'g',
    'ü': 'u', 'Ü': 'u',
    'ö': 'o', 'Ö': 'o',
    'ç': 'c', 'Ç': 'c',
    'â': 'a', 'Â': 'a',
    'î': 'i', 'Î': 'i',
    'û': 'u', 'Û': 'u',
  };
  final sb = StringBuffer();
  for (final ch in input.characters2()) {
    final mapped = map[ch];
    if (mapped != null) {
      sb.write(mapped);
      continue;
    }
    final lower = ch.toLowerCase();
    // Harf ve rakam dışını boşluğa çevir.
    if (RegExp(r'[a-z0-9]').hasMatch(lower)) {
      sb.write(lower);
    } else {
      sb.write(' ');
    }
  }
  return sb.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

extension _Chars on String {
  Iterable<String> characters2() => split('');
}

/// Kullanıcının girdiği ilaç adını riskli ürünlerle eşleştirir.
///
/// Önce tam ad eşleşmesi, sonra kelime bazlı içeren eşleşme aranır.
/// 3 harften kısa parçalarla eşleşme yapılmaz (yanlış pozitifi azaltır).
List<DrugMatch> matchDrugRisks(String userInput) {
  final q = normalizeDrugName(userInput);
  if (q.isEmpty) return const [];

  final exact = <DrugMatch>[];
  final partial = <DrugMatch>[];
  final seen = <String>{};

  for (final risk in kAllDrugRisks) {
    for (final name in risk.allNames) {
      final n = normalizeDrugName(name);
      if (n.length < 3) continue;

      if (q == n) {
        if (seen.add(risk.id)) {
          exact.add(DrugMatch(risk: risk, matchedName: name, isExact: true));
        }
        break;
      }

      // Kullanıcı "brufen 400 mg" yazdıysa "brufen" yakalanmalı.
      if (_containsWord(q, n) || _containsWord(n, q)) {
        if (!seen.contains(risk.id)) {
          partial.add(DrugMatch(risk: risk, matchedName: name, isExact: false));
        }
      }
    }
  }

  // Tam eşleşenleri kısmi listeden çıkar.
  final exactIds = exact.map((m) => m.risk.id).toSet();
  final dedupPartial = <DrugMatch>[];
  final partialSeen = <String>{};
  for (final m in partial) {
    if (exactIds.contains(m.risk.id)) continue;
    if (partialSeen.add(m.risk.id)) dedupPartial.add(m);
  }

  return [...exact, ...dedupPartial];
}

/// [haystack] içinde [needle] tam kelime (veya kelime dizisi) olarak var mı?
bool _containsWord(String haystack, String needle) {
  if (needle.length < 3) return false;
  final hWords = haystack.split(' ');
  final nWords = needle.split(' ');
  if (nWords.length == 1) {
    return hWords.contains(nWords.first);
  }
  for (var i = 0; i + nWords.length <= hWords.length; i++) {
    var ok = true;
    for (var j = 0; j < nWords.length; j++) {
      if (hWords[i + j] != nWords[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}
