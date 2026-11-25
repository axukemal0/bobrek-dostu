import 'dart:io' show Platform;

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
/// `health` paketi Android'de Health Connect'i kullanır. Health Connect
/// ham EKG dalga formunu üçüncü taraf uygulamalara AÇMAZ; yalnızca
/// bazı üreticiler kendi uygulamalarında gösterir. Bu yüzden
/// uygulama EKG'yi gösteremez ve bunu saklamaz.
const String kEcgExplanationTr =
    'EKG hakkında dürüst bilgi: Android\'in Health Connect\'i, akıllı '
    'saatlerin ölçtüğü HAM EKG dalga formunu başka uygulamalara '
    'açmıyor. Bu yüzden bu uygulama EKG çizgisini gösteremez. '
    'EKG kaydını saatinin kendi uygulamasından (örn. Samsung Health, '
    'Fitbit) PDF olarak çıkarıp doktoruna iletebilirsin. '
    'Nabız, tansiyon, SpO₂, adım ve uyku verileri ise okunabiliyor.';

class HealthService {
  HealthService() : _health = Health();

  final Health _health;
  bool _configured = false;

  /// Okunacak veri türleri.
  static final List<HealthDataType> readTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.WEIGHT,
  ];

  /// Platformun sağlık servisinin kullanıcıya görünen adı.
  static String get providerNameTr =>
      Platform.isIOS ? 'Sağlık uygulaması' : 'Health Connect';

  /// iOS'ta izin isteğinin sessizce başarısız olmasının en sık sebebi,
  /// uygulamanın HealthKit hakkı OLMADAN imzalanmış olmasıdır. Ücretsiz
  /// Apple kimliğiyle imzalanan derlemeler böyledir: Apple bu yeteneği
  /// yalnız ücretli üyelikteki provizyon profillerine verir. Kullanıcıya
  /// "izin vermedin" demek yanıltıcı olurdu.
  static String? get entitlementNoteTr => Platform.isIOS
      ? 'Not: Bu uygulama ücretsiz bir Apple kimliğiyle kurulduysa '
          'iPhone Sağlık verisine hiç erişemez — Apple bu izni yalnız '
          'ücretli geliştirici üyeliğiyle imzalanmış uygulamalara verir. '
          'Ölçümlerini "Kilo, ödem ve tansiyon" ekranından elle '
          'girebilirsin.'
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
      // Health Connect ham EKG dalga formunu dışa açmaz.
      ecgAvailable: false,
      ecgCount: 0,
    );
  }
}
