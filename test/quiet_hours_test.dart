import 'package:bobrek_dostu/core/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sessiz saatler', () {
    const night = QuietHours(startHour: 22, endHour: 8);

    test('gece yarısını geçen aralık doğru çalışır', () {
      expect(night.contains(DateTime(2026, 11, 23, 23)), isTrue);
      expect(night.contains(DateTime(2026, 11, 23, 2)), isTrue);
      expect(night.contains(DateTime(2026, 11, 23, 7, 59)), isTrue);
      expect(night.contains(DateTime(2026, 11, 23, 8)), isFalse);
      expect(night.contains(DateTime(2026, 11, 23, 14)), isFalse);
      expect(night.contains(DateTime(2026, 11, 23, 21, 59)), isFalse);
      expect(night.contains(DateTime(2026, 11, 23, 22)), isTrue);
    });

    test('gün içi aralık (13:00-15:00) doğru çalışır', () {
      const siesta = QuietHours(startHour: 13, endHour: 15);
      expect(siesta.contains(DateTime(2026, 11, 23, 14)), isTrue);
      expect(siesta.contains(DateTime(2026, 11, 23, 12)), isFalse);
      expect(siesta.contains(DateTime(2026, 11, 23, 15)), isFalse);
    });

    test('kapalıysa hiçbir zaman içine almaz', () {
      const off = QuietHours(enabled: false, startHour: 22, endHour: 8);
      expect(off.contains(DateTime(2026, 11, 23, 23)), isFalse);
    });

    test('başlangıç = bitiş ise aralık yok sayılır', () {
      const same = QuietHours(startHour: 10, endHour: 10);
      expect(same.contains(DateTime(2026, 11, 23, 10)), isFalse);
    });

    test('dakika hassasiyeti', () {
      const q = QuietHours(
        startHour: 22,
        startMinute: 30,
        endHour: 7,
        endMinute: 15,
      );
      expect(q.contains(DateTime(2026, 11, 23, 22, 29)), isFalse);
      expect(q.contains(DateTime(2026, 11, 23, 22, 30)), isTrue);
      expect(q.contains(DateTime(2026, 11, 23, 7, 14)), isTrue);
      expect(q.contains(DateTime(2026, 11, 23, 7, 15)), isFalse);
      expect(q.labelTr, '22:30 - 07:15');
    });

    test('JSON turu korunur', () {
      const q = QuietHours(
        enabled: false,
        startHour: 21,
        startMinute: 45,
        endHour: 6,
        endMinute: 30,
      );
      final back = QuietHours.fromJson(q.toJson());
      expect(back.enabled, isFalse);
      expect(back.startHour, 21);
      expect(back.startMinute, 45);
      expect(back.endHour, 6);
      expect(back.endMinute, 30);
    });
  });

  group('Bildirim kategorileri', () {
    test('ilaç ve randevu kritiktir (günlük limite tabi değil)', () {
      expect(NotifCategory.medication.isCritical, isTrue);
      expect(NotifCategory.appointment.isCritical, isTrue);
      expect(NotifCategory.smart.isCritical, isFalse);
      expect(NotifCategory.summary.isCritical, isFalse);
    });

    test('her kategori ayrı kanal kullanır', () {
      final ids = NotifCategory.values.map((c) => c.channelId).toSet();
      expect(ids.length, NotifCategory.values.length);
    });

    test('günlük isteğe bağlı bildirim sınırı 3', () {
      expect(NotificationService.maxDiscretionaryPerDay, 3);
    });
  });
}
