import 'package:drift/drift.dart';

import '../../clinical/evaluator.dart';
import '../../clinical/settings.dart';
import '../db/database.dart';
import 'api_client.dart';
import 'notification_service.dart';
import 'weather_service.dart';

/// Akıllı bildirimler: hava/UV/hava kalitesi uyarıları ve günlük özet.
///
/// NEDEN ARKA PLAN GÖREVİ YOK?
/// workmanager eklentisi Flutter 3.50 ile derlenmiyor (bkz. pubspec
/// notu). Bu yüzden:
///   * Hava/UV/hava kalitesi uyarısı: uygulama AÇILDIĞINDA veya öne
///     geldiğinde hesaplanır ve gerekiyorsa hemen gösterilir.
///   * Günlük özet: içeriği ŞİMDİ hesaplanıp akşam saatine
///     ZAMANLANIR (flutter_local_notifications), yani uygulama kapalı
///     olsa da bildirim gelir.
///   * İlaç ve randevu hatırlatmaları zaten ayrı ve zamanlanmıştır;
///     bunlar arka plan görevine hiç ihtiyaç duymaz.
///
/// KURALLAR (her yerde olduğu gibi):
///   * Sıvı limiti olan hastaya daha fazla içmesi söylenmez.
///   * Sessiz saatlerde isteğe bağlı bildirim gönderilmez.
///   * İlaç/randevu dışı bildirimler günde en fazla 3 tanedir.
class SmartNotifications {
  SmartNotifications({
    required this.db,
    required this.notifications,
    required this.weather,
  });

  final AppDatabase db;
  final NotificationService notifications;
  final WeatherService weather;

  /// Günlük özet bildiriminin sabit kimliği (her gün üzerine yazılır).
  static const int dailySummaryId = 900001;

  /// Günlük özetin gönderileceği saat.
  static const int summaryHour = 20;

  /// Uygulama açılışında / öne gelişinde çağrılır.
  ///
  /// Hata fırlatmaz: bildirim gelmemesi uygulamayı etkilemez.
  Future<void> runOnForeground({
    required bool smartEnabled,
    required bool dailySummaryEnabled,
  }) async {
    try {
      if (smartEnabled) await _weatherAlerts();
    } on Object {
      // yoksay
    }
    try {
      if (dailySummaryEnabled) {
        await scheduleDailySummary();
      } else {
        await notifications.cancel(dailySummaryId);
      }
    } on Object {
      // yoksay
    }
  }

  Future<ClinicalSettings> _settings() async {
    final json = await db.readJsonSetting('clinical_settings');
    return json == null
        ? const ClinicalSettings()
        : ClinicalSettings.fromJson(json);
  }

  /// Bugünün sıvı bütçesi (yemekten gelen sıvı dahil).
  Future<FluidBudget> _todayFluid(ClinicalSettings settings) async {
    final (start, end) = AppDatabase.dayBounds(DateTime.now());
    final fluids = await db.fluidLogsBetween(start, end);
    final foods = await db.foodLogsBetween(start, end);
    final consumed = fluids.fold<int>(0, (a, b) => a + b.ml) +
        foods
            .map((f) => f.fluidMl ?? 0)
            .fold<double>(0, (a, b) => a + b)
            .round();
    final limit = settings.resolve('fluid_ml');
    return computeFluidBudget(
      consumedMl: consumed,
      limitMl: limit.isCleared ? null : limit.value?.round(),
    );
  }

  /// Hava/UV/hava kalitesi uyarısı — tek bildirimde birleştirilir.
  Future<void> _weatherAlerts() async {
    final loc = await db.readJsonSetting('last_location');
    final lat = (loc?['lat'] as num?)?.toDouble();
    final lon = (loc?['lon'] as num?)?.toDouble();
    if (lat == null || lon == null) return;

    final WeatherSnapshot snapshot;
    try {
      snapshot = await weather.fetch(latitude: lat, longitude: lon);
    } on ServiceFailure {
      return;
    }

    if (!snapshot.isHot && !snapshot.isUvHigh && !snapshot.isAirPoor) return;

    final settings = await _settings();
    final budget = await _todayFluid(settings);

    final parts = <String>[
      if (snapshot.isHot) fluidAdviceTr(budget, hotWeather: true),
      if (snapshot.isUvHigh) snapshot.uvAdviceTr,
      if (snapshot.isAirPoor) snapshot.airAdviceTr,
    ];

    await notifications.show(
      category: NotifCategory.smart,
      title: snapshot.isHot
          ? 'Hava sıcak'
          : (snapshot.isUvHigh ? 'UV yüksek' : 'Hava kalitesi düşük'),
      body: parts.join('\n\n'),
    );
  }

  /// Günlük özeti akşam saatine zamanlar.
  ///
  /// İçerik ŞİMDİ hesaplanır; uygulama kapalı olsa da bildirim gelir.
  /// Her çağrıda aynı kimlikle yeniden zamanlanır, böylece içerik
  /// uygulama her açıldığında tazelenir.
  Future<void> scheduleDailySummary() async {
    final body = await buildSummaryBody();
    if (body == null) {
      await notifications.cancel(dailySummaryId);
      return;
    }

    final now = DateTime.now();
    var when = DateTime(now.year, now.month, now.day, summaryHour);
    if (!when.isAfter(now)) {
      // Saat geçtiyse yarına kur.
      when = when.add(const Duration(days: 1));
    }

    await notifications.cancel(dailySummaryId);
    await notifications.schedule(
      id: dailySummaryId,
      category: NotifCategory.summary,
      title: 'Günün özeti',
      body: body,
      when: when,
    );
  }

  /// Özet metni. Gösterilecek bir şey yoksa null.
  Future<String?> buildSummaryBody() async {
    final settings = await _settings();
    final (start, end) = AppDatabase.dayBounds(DateTime.now());

    final doses = await db.dosesBetween(start, end);
    final foods = await db.foodLogsBetween(start, end);
    final budget = await _todayFluid(settings);

    final lines = <String>[];

    if (doses.isNotEmpty) {
      final taken = doses.where((d) => d.status == 'taken').length;
      final pending = doses
          .where((d) => d.status == 'pending' || d.status == 'snoozed')
          .length;
      lines.add('İlaç: $taken/${doses.length} alındı'
          '${pending > 0 ? ", $pending doz bekliyor" : ""}');
    }

    if (budget.hasLimit) {
      lines.add(budget.isOverLimit
          ? 'Sıvı: limiti ${budget.overshootMl} mL aştın'
          : 'Sıvı: ${budget.consumedMl} / ${budget.limitMl} mL');
    } else if (budget.consumedMl > 0) {
      lines.add('Sıvı: ${budget.consumedMl} mL kaydedildi');
    }

    if (foods.isEmpty) lines.add('Bugün yemek kaydı girilmedi');

    // Yarının randevuları.
    final upcoming = await (db.select(db.appointmentRows)
          ..where((t) => t.startsAt.isBetweenValues(
                end,
                end.add(const Duration(days: 1)),
              ))
          ..orderBy([(t) => OrderingTerm.asc(t.startsAt)])
          ..limit(2))
        .get();
    for (final a in upcoming) {
      lines.add('Yarın: ${a.title} '
          '${a.startsAt.hour.toString().padLeft(2, '0')}:'
          '${a.startsAt.minute.toString().padLeft(2, '0')}');
    }

    return lines.isEmpty ? null : lines.join('\n');
  }
}
