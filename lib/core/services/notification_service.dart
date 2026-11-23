import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../db/database.dart';

/// Sessiz saatler ayarı.
class QuietHours {
  const QuietHours({
    this.enabled = true,
    this.startHour = 22,
    this.startMinute = 0,
    this.endHour = 8,
    this.endMinute = 0,
  });

  final bool enabled;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  /// Verilen zaman sessiz saatlerin içinde mi?
  /// Gece yarısını geçen aralıkları (22:00-08:00) doğru işler.
  bool contains(DateTime t) {
    if (!enabled) return false;
    final minutes = t.hour * 60 + t.minute;
    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;
    if (start == end) return false;
    if (start < end) return minutes >= start && minutes < end;
    return minutes >= start || minutes < end;
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
      };

  static QuietHours fromJson(Map<String, dynamic>? j) {
    if (j == null) return const QuietHours();
    return QuietHours(
      enabled: j['enabled'] as bool? ?? true,
      startHour: j['startHour'] as int? ?? 22,
      startMinute: j['startMinute'] as int? ?? 0,
      endHour: j['endHour'] as int? ?? 8,
      endMinute: j['endMinute'] as int? ?? 0,
    );
  }

  String get labelTr =>
      '${startHour.toString().padLeft(2, '0')}:'
      '${startMinute.toString().padLeft(2, '0')} - '
      '${endHour.toString().padLeft(2, '0')}:'
      '${endMinute.toString().padLeft(2, '0')}';
}

/// Bildirim kategorileri.
///
/// İLAÇ ve RANDEVU bildirimleri günlük limite TABİ DEĞİLDİR
/// (bunlar kritik). Diğerleri (akıllı/özet) günde en fazla
/// [NotificationService.maxDiscretionaryPerDay] gönderilir.
enum NotifCategory { medication, appointment, smart, summary }

extension NotifCategoryX on NotifCategory {
  String get id => name;

  bool get isCritical =>
      this == NotifCategory.medication || this == NotifCategory.appointment;

  String get channelId => switch (this) {
        NotifCategory.medication => 'medication_channel',
        NotifCategory.appointment => 'appointment_channel',
        NotifCategory.smart => 'smart_channel',
        NotifCategory.summary => 'summary_channel',
      };

  String get channelNameTr => switch (this) {
        NotifCategory.medication => 'İlaç hatırlatmaları',
        NotifCategory.appointment => 'Randevu hatırlatmaları',
        NotifCategory.smart => 'Akıllı bildirimler',
        NotifCategory.summary => 'Günlük özet',
      };

  String get channelDescTr => switch (this) {
        NotifCategory.medication =>
          'İlaç saatleri ve stok bitiş uyarıları. Kritik.',
        NotifCategory.appointment =>
          'Diyaliz seansı, kontrol ve tahlil randevuları. Kritik.',
        NotifCategory.smart =>
          'Hava/UV/hava kalitesi ve hareket bildirimleri. '
              'Günde en fazla 3 tanesi gönderilir.',
        NotifCategory.summary => 'Günün kısa özeti.',
      };
}

class NotificationService {
  NotificationService(this._db);

  final AppDatabase _db;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// İlaç + randevu HARİÇ günlük bildirim üst sınırı.
  static const int maxDiscretionaryPerDay = 3;

  static const String kQuietHoursKey = 'quiet_hours';

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } on Object {
      // Saat dilimi okunamazsa İstanbul varsayılır (uygulama TR içindir).
      try {
        tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
      } on Object {
        tz.setLocalLocation(tz.UTC);
      }
    }

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      for (final c in NotifCategory.values) {
        await android.createNotificationChannel(
          AndroidNotificationChannel(
            c.channelId,
            c.channelNameTr,
            description: c.channelDescTr,
            importance:
                c.isCritical ? Importance.max : Importance.defaultImportance,
          ),
        );
      }
    }

    _initialized = true;
  }

  Future<QuietHours> readQuietHours() async {
    final raw = await _db.readSetting(kQuietHoursKey);
    if (raw == null) return const QuietHours();
    try {
      return QuietHours.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on FormatException {
      return const QuietHours();
    }
  }

  Future<void> writeQuietHours(QuietHours q) =>
      _db.writeSetting(kQuietHoursKey, jsonEncode(q.toJson()));

  /// Bildirim gönderilebilir mi?
  ///
  /// Kritik kategoriler sessiz saatlerde de gönderilir (ilaç saati
  /// gece olabilir), ama isteğe bağlı olanlar gönderilmez.
  Future<({bool allowed, String? reasonTr})> canSend(
    NotifCategory category, {
    DateTime? at,
  }) async {
    final when = at ?? DateTime.now();

    if (!category.isCritical) {
      final quiet = await readQuietHours();
      if (quiet.contains(when)) {
        return (
          allowed: false,
          reasonTr: 'Sessiz saatler (${quiet.labelTr}) içinde.',
        );
      }
      final count = await _db.notificationCountToday([
        NotifCategory.smart.id,
        NotifCategory.summary.id,
      ]);
      if (count >= maxDiscretionaryPerDay) {
        return (
          allowed: false,
          reasonTr: 'Günlük bildirim sınırına ulaşıldı '
              '($count/$maxDiscretionaryPerDay).',
        );
      }
    }
    return (allowed: true, reasonTr: null);
  }

  /// Anında bildirim gönderir (limit ve sessiz saat kontrollü).
  Future<bool> show({
    required NotifCategory category,
    required String title,
    required String body,
    int? id,
    String? payload,
  }) async {
    await init();
    final check = await canSend(category);
    if (!check.allowed) return false;

    await _plugin.show(
      id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          category.channelId,
          category.channelNameTr,
          channelDescription: category.channelDescTr,
          importance:
              category.isCritical ? Importance.max : Importance.defaultImportance,
          priority: category.isCritical ? Priority.high : Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
      payload: payload,
    );

    await _db.into(_db.notificationLogRows).insert(
          NotificationLogRowsCompanion.insert(
            category: category.id,
            title: title,
            body: Value(body),
          ),
        );
    return true;
  }

  /// Belirli bir zamana planlanmış bildirim (ilaç/randevu).
  ///
  /// `exactAllowWhileIdle` kullanılır; "tam zamanlı alarm" izni yoksa
  /// Android isteği daha gevşek bir modla karşılar.
  Future<void> schedule({
    required int id,
    required NotifCategory category,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {
    await init();
    if (when.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          category.channelId,
          category.channelNameTr,
          channelDescription: category.channelDescTr,
          importance:
              category.isCritical ? Importance.max : Importance.defaultImportance,
          priority:
              category.isCritical ? Priority.high : Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> pending() async {
    await init();
    return _plugin.pendingNotificationRequests();
  }

  /// İlaç bildirimi kimliği: ilaç id + saat indeksinden türetilir.
  static int medicationNotificationId(int medicationId, int timeIndex) =>
      100000 + medicationId * 100 + timeIndex;

  static int appointmentNotificationId(int appointmentId) =>
      500000 + appointmentId;
}
