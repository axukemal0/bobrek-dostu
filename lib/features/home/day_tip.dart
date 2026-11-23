/// Günün kısa bilgilendirici notu.
///
/// Kaynaklı, kısa ve döngüsel. Günün sırasına göre deterministik
/// seçilir (her gün farklı, her açılışta aynı).
class DayTip {
  const DayTip({
    required this.textTr,
    required this.sourceTr,
  });

  final String textTr;
  final String sourceTr;
}

const List<DayTip> kDayTips = [
  DayTip(
    textTr: 'Haşlama suyunu dökmek, patates ve sebzedeki potasyumu '
        'belirgin ölçüde azaltır. Suyu çorbaya katarsan bu kazanç gider.',
    sourceTr: 'KDOQI 2020',
  ),
  DayTip(
    textTr: 'Tuzluk günlük sodyumun küçük bir kısmıdır. Büyük kısmı '
        'salça, turşu, peynir ve işlenmiş etten gelir.',
    sourceTr: 'KDIGO 2024 (<2 g sodyum/gün)',
  ),
  DayTip(
    textTr: '"Light tuz" ve "az sodyumlu tuz" ürünleri potasyum klorür '
        'içerir; böbrek hastasında tehlikeli olabilir. Etiketi oku.',
    sourceTr: 'KDIGO potasyum konferansı',
  ),
  DayTip(
    textTr: 'Katkı maddesi fosforu (fosforik asit, fosfat tuzları) '
        'doğal fosfordan çok daha iyi emilir. Kola ve işlenmiş et '
        'bu yüzden riskli.',
    sourceTr: 'KDIGO 2017 CKD-MBD',
  ),
  DayTip(
    textTr: 'NSAİİ ağrı kesiciler (Brufen, Voltaren, Apranax, Arveles…) '
        'böbreğe giden kan akımını azaltır. Ağrı için hekimine sor.',
    sourceTr: 'National Kidney Foundation',
  ),
  DayTip(
    textTr: 'Diyaliz arası kilo artışının ana belirleyicisi su değil '
        'SODYUMDUR. Tuzu azaltmak, sıvıyı kısıtlamaktan kolay sonuç verir.',
    sourceTr: 'Nutrients 2025 derlemesi',
  ),
  DayTip(
    textTr: 'Tansiyon sınıflaması tek ölçüme değil, en az iki ayrı '
        'günde alınan ölçümlerin ortalamasına dayanır.',
    sourceTr: 'ACC/AHA 2017',
  ),
  DayTip(
    textTr: 'Ağız kuruluğu için buz parçası emmek, şekersiz sakız '
        'çiğnemek veya limon dilimi sıvı bütçesini neredeyse '
        'hiç tüketmez.',
    sourceTr: 'Hemodiyaliz hasta eğitimi derlemeleri',
  ),
  DayTip(
    textTr: 'Protein hem az hem çok olduğunda sorun yaratır. '
        'Diyaliz hastasında ihtiyaç ARTAR (1,0-1,2 g/kg/gün), '
        'diyaliz öncesinde kısıtlanır.',
    sourceTr: 'KDOQI 2020',
  ),
  DayTip(
    textTr: 'Hiperkalemi belirtisiz seyredebilir ve kalp ritmini '
        'bozabilir. Tahlil takvimini kaçırmamak bu yüzden önemli.',
    sourceTr: 'KDIGO potasyum konferansı',
  ),
  DayTip(
    textTr: 'Bitkisel "böbrek temizleyici" ürünlerin yararı '
        'kanıtlanmamıştır; bazıları (ısırgan, atkuyruğu, meyan kökü) '
        'riskli kabul edilir.',
    sourceTr: 'National Kidney Foundation',
  ),
  DayTip(
    textTr: 'Fosfat bağlayıcıları yemekle birlikte almak etkisini '
        'artırır. Dozu ve zamanlamayı hekimin belirler.',
    sourceTr: 'KDIGO 2017 CKD-MBD',
  ),
  DayTip(
    textTr: 'Kuru kayısı, kuru üzüm ve kuru incir taze hâllerinden '
        'kat kat fazla potasyum içerir — kurutma suyu uçurur, '
        'minerali yoğunlaştırır.',
    sourceTr: 'TürKomp / USDA',
  ),
  DayTip(
    textTr: 'Göğüs ağrısı, ciddi nefes darlığı, bayılma, idrarın '
        'kesilmesi veya ciddi kas güçsüzlüğünde beklemeden 112\'yi ara.',
    sourceTr: 'Acil değerlendirme ölçütleri',
  ),
];

/// Günün notunu verir (tarihe göre deterministik).
DayTip tipForDay(DateTime day) {
  final dayOfYear =
      day.difference(DateTime(day.year, 1, 1)).inDays;
  return kDayTips[dayOfYear % kDayTips.length];
}
