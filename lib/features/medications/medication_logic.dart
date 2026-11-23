import '../../core/db/database.dart';

/// İlaç planlama ve uyum mantığı — SAF fonksiyonlar, test edilebilir.

/// "08:00,20:00" biçimindeki saat listesini çözer.
///
/// Geçersiz parçaları atlar (kullanıcı serbest metin girebilir).
List<({int hour, int minute})> parseTimes(String raw) {
  final out = <({int hour, int minute})>[];
  for (final part in raw.split(RegExp(r'[,;\s]+'))) {
    final t = part.trim();
    if (t.isEmpty) continue;
    final m = RegExp(r'^(\d{1,2})[:.](\d{1,2})$').firstMatch(t);
    if (m == null) {
      // "8" gibi tek sayıyı saat kabul et.
      final h = int.tryParse(t);
      if (h != null && h >= 0 && h <= 23) out.add((hour: h, minute: 0));
      continue;
    }
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    if (h < 0 || h > 23 || min < 0 || min > 59) continue;
    out.add((hour: h, minute: min));
  }
  out.sort((a, b) =>
      (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
  return out;
}

/// "1,3,5" biçimindeki gün listesini çözer (1 = Pazartesi).
Set<int> parseWeekdays(String? raw) {
  if (raw == null || raw.trim().isEmpty) return {1, 2, 3, 4, 5, 6, 7};
  final out = <int>{};
  for (final part in raw.split(RegExp(r'[,;\s]+'))) {
    final d = int.tryParse(part.trim());
    if (d != null && d >= 1 && d <= 7) out.add(d);
  }
  return out.isEmpty ? {1, 2, 3, 4, 5, 6, 7} : out;
}

/// Bir ilacın verilen gündeki planlanmış doz zamanları.
List<DateTime> scheduledTimesFor(
  MedicationRow med,
  DateTime day,
) {
  final weekdays = parseWeekdays(med.weekdays);
  if (!weekdays.contains(day.weekday)) return const [];
  return [
    for (final t in parseTimes(med.times))
      DateTime(day.year, day.month, day.day, t.hour, t.minute),
  ];
}

/// Bugünün bekleyen ilk dozu.
class NextDose {
  const NextDose({
    required this.medicationId,
    required this.medicationName,
    required this.scheduledAt,
    this.doseRowId,
  });

  final int medicationId;
  final String medicationName;
  final DateTime scheduledAt;
  final int? doseRowId;
}

/// Kayıtlı doz satırlarından sıradaki bekleyeni bulur.
///
/// Kayıt yoksa ilaç tanımından türetir (kullanıcı henüz uygulamayı
/// açmadıysa doz satırı oluşmamış olabilir).
NextDose? nextPendingDose(
  List<MedicationDoseRow> doses,
  List<MedicationRow> meds, {
  DateTime? now,
}) {
  final t = now ?? DateTime.now();
  final medById = {for (final m in meds) m.id: m};

  // 1) Kayıtlı bekleyen dozlar.
  final pending = doses
      .where((d) => d.status == 'pending' || d.status == 'snoozed')
      .where((d) => medById.containsKey(d.medicationId))
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  final upcoming = pending.where((d) => !d.scheduledAt.isBefore(t)).toList();
  final target = upcoming.isNotEmpty
      ? upcoming.first
      : (pending.isNotEmpty ? pending.first : null);

  if (target != null) {
    return NextDose(
      medicationId: target.medicationId,
      medicationName: medById[target.medicationId]!.name,
      scheduledAt: target.scheduledAt,
      doseRowId: target.id,
    );
  }

  // 2) Doz satırı yoksa tanımdan türet.
  final day = DateTime(t.year, t.month, t.day);
  final candidates = <NextDose>[];
  for (final m in meds) {
    for (final at in scheduledTimesFor(m, day)) {
      if (at.isBefore(t)) continue;
      candidates.add(
        NextDose(
          medicationId: m.id,
          medicationName: m.name,
          scheduledAt: at,
        ),
      );
    }
  }
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  return candidates.first;
}

/// Stok kaç gün yeter?
///
/// Günlük tüketim, haftalık doz sayısının 7'ye bölümüyle hesaplanır
/// (örn. haftada 3 gün × 2 doz = 6/7 ≈ 0,86 doz/gün).
double? daysOfStockRemaining(MedicationRow med) {
  final stock = med.stockCount;
  if (stock == null || stock <= 0) return 0;
  final perDay = dosesPerDay(med);
  if (perDay <= 0) return null;
  return stock / perDay;
}

double dosesPerDay(MedicationRow med) {
  final times = parseTimes(med.times).length;
  if (times == 0) return 0;
  final days = parseWeekdays(med.weekdays).length;
  return times * days / 7.0;
}

/// Stok uyarısı verilmeli mi?
bool shouldWarnStock(MedicationRow med) {
  final days = daysOfStockRemaining(med);
  if (days == null) return false;
  return days <= med.stockWarnAt;
}

/// Ertele süresi seçenekleri.
const List<({int minutes, String labelTr})> kSnoozeOptions = [
  (minutes: 10, labelTr: '10 dakika'),
  (minutes: 30, labelTr: '30 dakika'),
  (minutes: 60, labelTr: '1 saat'),
  (minutes: 120, labelTr: '2 saat'),
];
