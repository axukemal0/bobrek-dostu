import 'package:bobrek_dostu/core/db/database.dart';
import 'package:bobrek_dostu/core/services/report_service.dart';
import 'package:flutter_test/flutter_test.dart';

MedicationDoseRow dose(String status, DateTime at) => MedicationDoseRow(
      id: at.millisecondsSinceEpoch.remainder(100000),
      medicationId: 1,
      scheduledAt: at,
      status: status,
    );

VitalRow vital({
  required DateTime at,
  int? systolic,
  int? diastolic,
  double? weight,
}) =>
    VitalRow(
      id: at.millisecondsSinceEpoch.remainder(100000),
      measuredAt: at,
      systolic: systolic,
      diastolic: diastolic,
      weightKg: weight,
    );

FoodLogRow food({
  required DateTime at,
  double? kcal,
  double? protein,
  double? sodium,
}) =>
    FoodLogRow(
      id: at.millisecondsSinceEpoch.remainder(100000),
      label: 'test',
      grams: 100,
      kcal: kcal,
      proteinG: protein,
      sodiumMg: sodium,
      origin: 'manual',
      consumedAt: at,
    );

FluidLogRow fluid({required DateTime at, required int ml}) => FluidLogRow(
      id: at.millisecondsSinceEpoch.remainder(100000),
      label: 'su',
      ml: ml,
      kind: 'drink',
      consumedAt: at,
    );

void main() {
  final day1 = DateTime(2026, 11, 20, 8);
  final day2 = DateTime(2026, 11, 21, 8);
  final day3 = DateTime(2026, 11, 22, 8);

  group('İlaç uyumu', () {
    test('alınan/atlanan/işaretlenmemiş doğru sayılır', () {
      final a = computeAdherence([
        dose('taken', day1),
        dose('taken', day1.add(const Duration(hours: 12))),
        dose('skipped', day2),
        dose('pending', day3),
        dose('snoozed', day3.add(const Duration(hours: 1))),
      ]);
      expect(a.totalDoses, 5);
      expect(a.taken, 2);
      expect(a.skipped, 1);
      // pending + snoozed = işaretlenmemiş
      expect(a.pending, 2);
      expect(a.takenRatio, closeTo(0.4, 1e-9));
    });

    test('boş liste sıfır oran verir, bölme hatası olmaz', () {
      final a = computeAdherence([]);
      expect(a.totalDoses, 0);
      expect(a.takenRatio, 0);
    });
  });

  group('Kan basıncı istatistikleri', () {
    test('ortalama, uç değerler ve eşik sayımı', () {
      final stats = computeBpStats(
        [
          vital(at: day1, systolic: 120, diastolic: 70),
          vital(at: day2, systolic: 185, diastolic: 95),
          vital(at: day3, systolic: 110, diastolic: 65),
        ],
        alarmSystolic: 180,
        targetSystolic: 120,
      )!;

      expect(stats.count, 3);
      expect(stats.meanSystolic, closeTo((120 + 185 + 110) / 3, 1e-9));
      expect(stats.maxSystolic, 185);
      expect(stats.minSystolic, 110);
      expect(stats.aboveAlarm, 1);
      // Hedefin ALTINDA olanlar: yalnız 110 (120 dahil değil)
      expect(stats.belowTarget, 1);
      // Seri zamana göre sıralanmış olmalı
      expect(stats.series.first.at, day1);
      expect(stats.series.last.at, day3);
    });

    test('tansiyonsuz ölçümler yok sayılır', () {
      expect(
        computeBpStats([vital(at: day1, weight: 70)]),
        isNull,
      );
    });

    test('yalnız sistolik girilmişse kayıt sayılmaz', () {
      expect(computeBpStats([vital(at: day1, systolic: 140)]), isNull);
    });
  });

  group('Besin ortalaması', () {
    test('VERİ GİRİLEN GÜN sayısına bölünür (boş günler düşürmez)', () {
      // 3 günlük pencere ama yalnız 2 günde kayıt var.
      final avg = computeNutritionAverages(
        [
          food(at: day1, kcal: 1000, protein: 40, sodium: 1500),
          food(at: day1.add(const Duration(hours: 6)), kcal: 500),
          food(at: day3, kcal: 1500, protein: 60, sodium: 2500),
        ],
        day1,
        day3.add(const Duration(days: 1)),
      );

      expect(avg.daysWithData, 2);
      // (1000+500+1500)/2 = 1500
      expect(avg.kcal, closeTo(1500, 1e-9));
      // (40+60)/2 = 50 — null protein toplamı etkilemez
      expect(avg.proteinG, closeTo(50, 1e-9));
      expect(avg.sodiumMg, closeTo(2000, 1e-9));
    });

    test('kayıt yoksa sıfır döner', () {
      final avg = computeNutritionAverages([], day1, day3);
      expect(avg.daysWithData, 0);
      expect(avg.kcal, 0);
    });

    test('aynı gün içindeki kayıtlar tek gün sayılır', () {
      final avg = computeNutritionAverages(
        [
          food(at: DateTime(2026, 11, 20, 8), kcal: 300),
          food(at: DateTime(2026, 11, 20, 13), kcal: 600),
          food(at: DateTime(2026, 11, 20, 20), kcal: 400),
        ],
        day1,
        day2,
      );
      expect(avg.daysWithData, 1);
      expect(avg.kcal, closeTo(1300, 1e-9));
    });
  });

  group('Sıvı ortalaması', () {
    test('günlük ortalama veri girilen güne bölünür', () {
      final avg = computeFluidAverage(
        [
          fluid(at: day1, ml: 400),
          fluid(at: day1.add(const Duration(hours: 4)), ml: 200),
          fluid(at: day2, ml: 900),
        ],
        day1,
        day3,
      );
      // (400+200+900) / 2 gün = 750
      expect(avg, closeTo(750, 1e-9));
    });

    test('kayıt yoksa sıfır', () {
      expect(computeFluidAverage([], day1, day3), 0);
    });
  });
}
