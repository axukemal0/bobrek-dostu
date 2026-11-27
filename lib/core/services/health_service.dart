import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:health/health.dart';

/// Health Connect üzerinden akıllı saat / telefon sağlık verisi.
///
/// Uygulama yalnızca OKUR, hiçbir şey YAZMAZ.
class HealthSample {
  const HealthSample({
    required this.value,
    required this.at,
    this.unit,
    this.extra,
  });

  final double value;
  final DateTime at;
  final String? unit;

  /// Tansiyon gibi çift değerli ölçümler için (diyastolik).
  final double? extra;
}

/// Apple Watch'tan okunan tek bir EKG kaydı.
class EcgRecord {
  const EcgRecord({
    required this.at,
    required this.classificationTr,
    this.averageHeartRate,
    this.sampleCount = 0,
  });

  final DateTime at;
  final String classificationTr;
  final double? averageHeartRate;
  final int sampleCount;
}

class HealthSnapshot {
  const HealthSnapshot({
    this.steps,
    this.heartRates = const [],
    this.restingHeartRate,
    this.bloodPressure = const [],
    this.spo2 = const [],
    this.sleepMinutes,
    this.sleepSessions = const [],
    this.weight,
    this.ecgAvailable = false,
    this.ecgCount = 0,
    this.ecgRecords = const [],
  });

  final int? steps;
  final List<HealthSample> heartRates;
  final double? restingHeartRate;

  /// value = sistolik, extra = diyastolik
  final List<HealthSample> bloodPressure;
  final List<HealthSample> spo2;
  final int? sleepMinutes;
  final List<HealthSample> sleepSessions;
  final HealthSample? weight;

  /// EKG verisi okunabildi mi?
  final bool ecgAvailable;
  final int ecgCount;

  /// iOS'ta okunan EKG kayıtları (en yeniden eskiye).
  final List<EcgRecord> ecgRecords;

  bool get isEmpty =>
      steps == null &&
      heartRates.isEmpty &&
      bloodPressure.isEmpty &&
      spo2.isEmpty &&
      sleepMinutes == null &&
      weight == null;
}

/// EKG hakkında kullanıcıya söylenen dürüst açıklama.
///
/// İki platform BİRBİRİNDEN FARKLI, bu yüzden metin de farklı:
///
///  * Android — `health` paketi Health Connect'i kullanır. Health
///    Connect ham EKG dalga formunu üçüncü taraf uygulamalara AÇMAZ;
///    yalnız üreticinin kendi uygulaması gösterir. Uygulama EKG
///    çizemez.
///  * iOS — HealthKit, Apple Watch'un çektiği EKG'yi
///    `HKElectrocardiogram` olarak PAYLAŞIR: sınıflandırma (sinüs
///    ritmi, atriyal fibrilasyon…), ortalama nabız ve voltaj örnekleri
///    okunabilir. Bu yüzden iOS'ta EKG kaydı listelenebiliyor.
///
/// Eskiden her iki platformda da Android'in metni gösteriliyordu;
/// iPhone kullanıcısına "Android'in Health Connect'i" diye başlayan
/// bir açıklama okutmak hem yanlış hem de güveni zedeleyici.
String get kEcgExplanationTr => Platform.isIOS
    ? 'EKG hakkında: Apple Watch ile çektiğin EKG kayıtları iPhone '
        'Sağlık uygulamasında saklanır ve bu uygulama onları '
        'OKUYABİLİR — kaydın tarihi, sınıflandırması (sinüs ritmi, '
        'atriyal fibrilasyon vb.) ve ortalama nabzı görünür. '
        'Hekiminin isteyeceği ayrıntılı PDF\'i yine Sağlık '
        'uygulamasından dışa aktarman gerekir. Uygulama Sağlık\'a '
        'hiçbir şey YAZMAZ.'
    : 'EKG hakkında dürüst bilgi: Android\'in Health Connect\'i, '
        'akıllı saatlerin ölçtüğü HAM EKG dalga formunu başka '
        'uygulamalara açmıyor. Bu yüzden bu uygulama EKG çizgisini '
        'gösteremez. EKG kaydını saatinin kendi uygulamasından (örn. '
        'Samsung Health, Fitbit) PDF olarak çıkarıp doktoruna '
        'iletebilirsin. Nabız, tansiyon, SpO\u2082, adım ve uyku '
        'verileri ise okunabiliyor.';

/// iPhone Sağlık (HealthKit) erişim durumu.
class HealthKitStatus {
  const HealthKitStatus({
    required this.dataAvailable,
    required this.entitled,
    required this.signedForDevelopment,
  });

  /// Cihaz Sağlık verisi tutabiliyor mu (iPad'lerin bir kısmı tutmaz).
  final bool dataAvailable;

  /// Bu DERLEME HealthKit hakkıyla imzalanmış mı?
  ///
  /// Ücretsiz Apple kimliğiyle yan yüklenen derlemelerde false olur ve
  /// izin ekranı hiç açılmaz.
  final bool entitled;

  /// Pakette provizyon profili var mı (yani geliştirme derlemesi mi)?
  final bool signedForDevelopment;

  bool get usable => dataAvailable && entitled;

  static const HealthKitStatus unsupported = HealthKitStatus(
    dataAvailable: false,
    entitled: false,
    signedForDevelopment: false,
  );
}

class HealthService {
  HealthService() : _health = Health();

  final Health _health;
  bool _configured = false;

  static const MethodChannel _iosChannel =
      MethodChannel('com.bobrekdostu.app/healthkit');

  /// Okunacak veri türleri.
  ///
  /// EKG YALNIZ iOS'ta listelenir: `HealthDataType.ELECTROCARDIOGRAM`
  /// Android'de desteklenmiyor ve listeye konursa izin isteği
  /// tamamen başarısız oluyor (eklenti bilinmeyen türde atıyor).
  static List<HealthDataType> get readTypes => [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.RESTING_HEART_RATE,
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        HealthDataType.BLOOD_OXYGEN,
        HealthDataType.SLEEP_SESSION,
        HealthDataType.WEIGHT,
        if (Platform.isIOS) HealthDataType.ELECTROCARDIOGRAM,
      ];

  /// Platformun sağlık servisinin kullanıcıya görünen adı.
  static String get providerNameTr =>
      Platform.isIOS ? 'Sağlık uygulaması' : 'Health Connect';

  /// Verinin GELDİĞİ yerin kullanıcıya görünen adı.
  static String get sourceNameTr =>
      Platform.isIOS ? 'Apple Watch / iPhone Sağlık' : 'akıllı saatin';

  /// iOS'ta HealthKit erişiminin gerçek durumu.
  ///
  /// Android'de [HealthKitStatus.unsupported] döner; orada
  /// Health Connect'in kendi durum sorgusu ([sdkStatus]) kullanılır.
  Future<HealthKitStatus> healthKitStatus() async {
    if (!Platform.isIOS) return HealthKitStatus.unsupported;
    try {
      final raw = await _iosChannel.invokeMapMethod<String, dynamic>('status');
      if (raw == null) return HealthKitStatus.unsupported;
      return HealthKitStatus(
        dataAvailable: raw['dataAvailable'] == true,
        entitled: raw['entitled'] == true,
        signedForDevelopment: raw['signedForDevelopment'] == true,
      );
    } on MissingPluginException {
      // Yerel taraf bu derlemede yok; eski bir derleme olabilir.
      return const HealthKitStatus(
        dataAvailable: true,
        entitled: true,
        signedForDevelopment: false,
      );
    } on PlatformException {
      return HealthKitStatus.unsupported;
    }
  }

  /// iOS'ta izin isteğinin sessizce başarısız olmasının en sık sebebi,
  /// uygulamanın HealthKit hakkı OLMADAN imzalanmış olmasıdır. Ücretsiz
  /// Apple kimliğiyle imzalanan derlemeler böyledir: Apple bu yeteneği
  /// yalnız ücretli üyelikteki provizyon profillerine verir. Kullanıcıya
  /// "izin vermedin" demek yanıltıcı olurdu.
  static String? get entitlementNoteTr => Platform.isIOS
      ? 'Bu derleme ücretsiz bir Apple kimliğiyle imzalanmış. Apple, '
          'Sağlık verisi okuma hakkını yalnız ÜCRETLİ geliştirici '
          'üyeliğiyle imzalanmış uygulamalara veriyor; bu yüzden izin '
          'ekranı hiç açılmıyor ve Apple Watch verisi okunamıyor. '
          'Senin bir şeyi yanlış yapmandan kaynaklanmıyor. '
          'Üyelik alındığında TestFlight\'tan gelen sürüm bu veriyi '
          'sorunsuz okuyacak. O zamana kadar ölçümlerini "Kilo, ödem '
          've tansiyon" ekranından elle girebilirsin.'
      : null;

  Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Health Connect cihazda var mı / kullanılabilir mi?
  Future<HealthConnectSdkStatus?> sdkStatus() async {
    await _configure();
    try {
      return await _health.getHealthConnectSdkStatus();
    } on Object {
      return null;
    }
  }

  /// Health Connect uygulamasını / Play Store sayfasını açar.
  Future<void> installHealthConnect() async {
    await _configure();
    await _health.installHealthConnect();
  }

  Future<bool> hasPermissions() async {
    await _configure();
    final granted = await _health.hasPermissions(readTypes);
    return granted ?? false;
  }

  /// İzinleri ister. Çağıran taraf önce gerekçeyi göstermiş olmalıdır.
  Future<bool> requestPermissions() async {
    await _configure();
    return _health.requestAuthorization(
      readTypes,
      permissions: List.filled(readTypes.length, HealthDataAccess.READ),
    );
  }

  /// Verilen aralıktaki verileri okur.
  Future<HealthSnapshot> fetch({
    DateTime? from,
    DateTime? to,
  }) async {
    await _configure();
    final end = to ?? DateTime.now();
    final start = from ?? end.subtract(const Duration(days: 7));

    List<HealthDataPoint> points;
    try {
      points = await _health.getHealthDataFromTypes(
        types: readTypes,
        startTime: start,
        endTime: end,
      );
    } on Object {
      return const HealthSnapshot();
    }

    points = _health.removeDuplicates(points);

    int? steps;
    try {
      steps = await _health.getTotalStepsInInterval(start, end);
    } on Object {
      steps = null;
    }

    final hr = <HealthSample>[];
    final spo2 = <HealthSample>[];
    final sleep = <HealthSample>[];
    final ecg = <EcgRecord>[];
    final systolic = <DateTime, double>{};
    final diastolic = <DateTime, double>{};
    double? restingHr;
    HealthSample? weight;

    for (final pt in points) {
      final v = pt.value;
      final numeric = v is NumericHealthValue
          ? v.numericValue.toDouble()
          : null;

      switch (pt.type) {
        case HealthDataType.HEART_RATE:
          if (numeric != null) {
            hr.add(HealthSample(value: numeric, at: pt.dateFrom, unit: '/dk'));
          }
        case HealthDataType.RESTING_HEART_RATE:
          if (numeric != null) restingHr = numeric;
        case HealthDataType.BLOOD_OXYGEN:
          if (numeric != null) {
            spo2.add(HealthSample(value: numeric, at: pt.dateFrom, unit: '%'));
          }
        case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
          if (numeric != null) systolic[pt.dateFrom] = numeric;
        case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
          if (numeric != null) diastolic[pt.dateFrom] = numeric;
        case HealthDataType.WEIGHT:
          if (numeric != null) {
            weight = HealthSample(value: numeric, at: pt.dateFrom, unit: 'kg');
          }
        case HealthDataType.SLEEP_SESSION:
          final minutes =
              pt.dateTo.difference(pt.dateFrom).inMinutes.toDouble();
          sleep.add(
            HealthSample(value: minutes, at: pt.dateFrom, unit: 'dk'),
          );
        case HealthDataType.ELECTROCARDIOGRAM:
          // iOS: Apple Watch EKG kaydı. Ham dalga formunu ÇİZMİYORUZ
          // (hekime PDF olarak Sağlık uygulamasından çıkarılmalı);
          // kaydın varlığı, sınıflandırması ve ortalama nabzı
          // gösteriliyor.
          final ecgValue = v;
          if (ecgValue is ElectrocardiogramHealthValue) {
            ecg.add(
              EcgRecord(
                at: pt.dateFrom,
                classificationTr:
                    _ecgClassificationTr(ecgValue.classification),
                averageHeartRate: ecgValue.averageHeartRate?.toDouble(),
                sampleCount: ecgValue.voltageValues.length,
              ),
            );
          }
        default:
          break;
      }
    }

    // Tansiyonu eşleştir: aynı/yakın zaman damgasındaki sistolik+diyastolik.
    final bp = <HealthSample>[];
    for (final entry in systolic.entries) {
      final dia = diastolic[entry.key] ??
          diastolic.entries
              .where(
                (d) =>
                    d.key.difference(entry.key).abs() <
                    const Duration(minutes: 5),
              )
              .map((d) => d.value)
              .firstOrNull;
      bp.add(
        HealthSample(
          value: entry.value,
          extra: dia,
          at: entry.key,
          unit: 'mmHg',
        ),
      );
    }

    hr.sort((a, b) => a.at.compareTo(b.at));
    spo2.sort((a, b) => a.at.compareTo(b.at));
    bp.sort((a, b) => a.at.compareTo(b.at));
    sleep.sort((a, b) => a.at.compareTo(b.at));

    // Son gecenin uykusu.
    final lastNight = sleep.isEmpty ? null : sleep.last.value.round();

    return HealthSnapshot(
      steps: steps,
      heartRates: hr,
      restingHeartRate: restingHr,
      bloodPressure: bp,
      spo2: spo2,
      sleepMinutes: lastNight,
      sleepSessions: sleep,
      weight: weight,
      // Android (Health Connect) ham EKG dalga formunu dışa açmaz;
      // iOS'ta Apple Watch kayıtları okunabiliyor.
      ecgAvailable: ecg.isNotEmpty,
      ecgCount: ecg.length,
      ecgRecords: ecg..sort((a, b) => b.at.compareTo(a.at)),
    );
  }
}

/// Apple'ın EKG sınıflandırmasının Türkçesi.
///
/// Çeviri YORUM DEĞİLDİR: Apple'ın kendi etiketini Türkçeye çevirir,
/// üstüne bir değerlendirme eklemez. Karar hekimindir.
String _ecgClassificationTr(ElectrocardiogramClassification? c) =>
    switch (c) {
      ElectrocardiogramClassification.SINUS_RHYTHM => 'Sinüs ritmi',
      ElectrocardiogramClassification.ATRIAL_FIBRILLATION =>
        'Atriyal fibrilasyon',
      ElectrocardiogramClassification.INCONCLUSIVE_HIGH_HEART_RATE =>
        'Sonuçsuz — nabız yüksekti',
      ElectrocardiogramClassification.INCONCLUSIVE_LOW_HEART_RATE =>
        'Sonuçsuz — nabız düşüktü',
      ElectrocardiogramClassification.INCONCLUSIVE_POOR_READING =>
        'Sonuçsuz — kayıt kalitesi düşük',
      ElectrocardiogramClassification.INCONCLUSIVE_OTHER => 'Sonuçsuz',
      ElectrocardiogramClassification.UNRECOGNIZED => 'Tanımlanamadı',
      ElectrocardiogramClassification.NOT_SET || null => 'Belirtilmemiş',
    };
