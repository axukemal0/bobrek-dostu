import '../../clinical/evaluator.dart';
import '../../clinical/settings.dart';
import '../db/database.dart';
import 'report_service.dart';

/// Acil durum mesajı ve yakın modu özeti üretir.
///
/// v1'de hiçbir şey sunucuya gitmez: metin cihazda üretilir,
/// kullanıcı SMS/WhatsApp ile paylaşır (veya ayarı açtıysa
/// alarm eşiği aşımında otomatik SMS gider).
class CaregiverService {
  CaregiverService(this._db);

  final AppDatabase _db;

  /// Acil durum mesajı: konum + kritik bilgiler.
  ///
  /// SMS 160 karakterden uzunsa çoklu parça olarak gider; bu yüzden
  /// mesaj kısa ve öz tutulur.
  Future<String> buildEmergencyMessage({
    double? latitude,
    double? longitude,
    String? placeName,
    String? triggerReasonTr,
  }) async {
    final profile = await _db.getProfile();
    final settings = await _readSettings();
    final meds = await _db.getActiveMedications();

    final sb = StringBuffer();
    sb.write('ACİL — ${profile?.name ?? "Hasta"}');
    if (profile?.birthYear != null) {
      sb.write(' (${DateTime.now().year - profile!.birthYear!} yaş)');
    }
    sb.write('. ');

    if (triggerReasonTr != null) {
      sb.write('$triggerReasonTr ');
    }

    sb.write('Böbrek hastası: ${settings.treatmentMode.labelTr}. ');

    if (profile?.comorbidities?.isNotEmpty == true) {
      sb.write('Ek hastalık: ${profile!.comorbidities}. ');
    }
    if (profile?.allergies?.isNotEmpty == true) {
      sb.write('ALERJİ: ${profile!.allergies}. ');
    } else {
      sb.write('Bilinen alerji yok. ');
    }

    if (meds.isNotEmpty) {
      final names = meds.map((m) => m.name).take(8).join(', ');
      sb.write('İlaçlar: $names');
      if (meds.length > 8) sb.write(' (+${meds.length - 8})');
      sb.write('. ');
    }

    if (profile?.doctorName?.isNotEmpty == true) {
      sb.write('Hekim: ${profile!.doctorName}');
      if (profile.doctorPhone?.isNotEmpty == true) {
        sb.write(' ${profile.doctorPhone}');
      }
      sb.write('. ');
    }

    if (latitude != null && longitude != null) {
      if (placeName != null) sb.write('Konum: $placeName. ');
      sb.write(
        'Haritada: https://www.openstreetmap.org/'
        '?mlat=${latitude.toStringAsFixed(5)}'
        '&mlon=${longitude.toStringAsFixed(5)}#map=17/'
        '${latitude.toStringAsFixed(5)}/'
        '${longitude.toStringAsFixed(5)}',
      );
    } else {
      sb.write('Konum alınamadı.');
    }

    return sb.toString();
  }

  /// Ölçüm alarm eşiğini aştığında gönderilen kısa uyarı.
  Future<String> buildAlertMessage({
    required Alert alert,
    double? latitude,
    double? longitude,
  }) async {
    final profile = await _db.getProfile();
    final sb = StringBuffer()
      ..write('${profile?.name ?? "Hasta"} — ')
      ..write('${alert.titleTr}. ')
      ..write(_firstSentence(alert.messageTr))
      ..write(' ');

    if (latitude != null && longitude != null) {
      sb.write(
        'Konum: https://www.openstreetmap.org/'
        '?mlat=${latitude.toStringAsFixed(5)}'
        '&mlon=${longitude.toStringAsFixed(5)}',
      );
    }
    sb.write(' (Böbrek Dostu otomatik uyarısı)');
    return sb.toString();
  }

  /// Yakın modu özeti: günlük veya haftalık.
  Future<String> buildShareSummary({
    required Duration window,
  }) async {
    final now = DateTime.now();
    final from = now.subtract(window);

    final profile = await _db.getProfile();
    final settings = await _readSettings();
    final vitals = await _db.vitalsBetween(from, now);
    final doses = await _db.dosesBetween(from, now);
    final fluids = await _db.fluidLogsBetween(from, now);
    final labs = await _db.labResultsBetween(from, now);

    final isWeek = window.inDays > 2;
    final sb = StringBuffer()
      ..writeln('${profile?.name ?? "Hasta"} — '
          '${isWeek ? "haftalık" : "günlük"} özet')
      ..writeln('${_fmtDate(from)} – ${_fmtDate(now)}')
      ..writeln();

    // --- İlaç uyumu ---
    final adherence = computeAdherence(doses);
    if (adherence.totalDoses > 0) {
      sb.writeln('İLAÇ');
      sb.writeln(
        '${adherence.taken}/${adherence.totalDoses} doz alındı '
        '(%${(adherence.takenRatio * 100).round()})',
      );
      if (adherence.skipped > 0) {
        sb.writeln('${adherence.skipped} doz atlandı');
      }
      sb.writeln();
    }

    // --- Tansiyon ---
    final bp = computeBpStats(
      vitals,
      alarmSystolic: settings.resolve('bp_systolic_high').value ?? 180,
      targetSystolic: settings.resolve('bp_systolic_target').value ?? 120,
    );
    if (bp != null) {
      sb.writeln('TANSİYON (${bp.count} ölçüm)');
      sb.writeln(
        'Ortalama ${bp.meanSystolic.round()}/${bp.meanDiastolic.round()} '
        'mmHg · en yüksek ${bp.maxSystolic}/${bp.maxDiastolic}',
      );
      if (bp.aboveAlarm > 0) {
        sb.writeln('⚠ ${bp.aboveAlarm} ölçüm alarm eşiğinin üstünde');
      }
      sb.writeln();
    }

    // --- Kilo ---
    final weights = vitals.where((v) => v.weightKg != null).toList();
    if (weights.isNotEmpty) {
      sb.writeln('KİLO');
      sb.writeln(
        'Son: ${weights.last.weightKg!.toStringAsFixed(1)} kg'
        '${weights.length > 1 ? " (ilk ${weights.first.weightKg!.toStringAsFixed(1)} kg)" : ""}',
      );
      final dry = settings.dryWeightKg;
      if (dry != null) {
        final idwg = computeIdwg(
          currentKg: weights.last.weightKg!,
          dryWeightKg: dry,
          thresholdPercent:
              settings.resolve('idwg_percent').value ?? 4.0,
        );
        if (idwg != null) {
          sb.writeln(
            'Kuru ağırlık üstü: ${idwg.gainKg.toStringAsFixed(1)} kg '
            '(%${idwg.percent.toStringAsFixed(1)})'
            '${idwg.isOverThreshold ? " ⚠ eşik üstü" : ""}',
          );
        }
      }
      sb.writeln();
    }

    // --- Sıvı ---
    if (fluids.isNotEmpty) {
      final avg = computeFluidAverage(fluids, from, now);
      final limit = settings.resolve('fluid_ml');
      sb.writeln('SIVI');
      sb.writeln('Günlük ortalama ${avg.round()} mL');
      if (limit.hasValue && !limit.isCleared) {
        sb.writeln('Limit ${limit.value!.round()} mL');
      } else {
        sb.writeln('Limit girilmemiş');
      }
      sb.writeln();
    }

    // --- Tahlil ---
    if (labs.isNotEmpty) {
      sb.writeln('TAHLİL');
      final seen = <String>{};
      for (final l in labs.reversed) {
        if (!seen.add(l.analyteLabel)) continue;
        sb.writeln('${l.analyteLabel}: ${l.value} ${l.unit} '
            '(${_fmtDate(l.takenAt)})');
        if (seen.length >= 8) break;
      }
      sb.writeln();
    }

    // --- Uyarılar ---
    final alerts = await collectAlerts(vitals: vitals, labs: labs);
    if (alerts.isNotEmpty) {
      sb.writeln('UYARILAR');
      for (final a in alerts.take(5)) {
        sb.writeln('• [${a.level.labelTr}] ${a.titleTr}');
      }
      sb.writeln();
    }

    sb.writeln('—');
    sb.writeln(
      'Böbrek Dostu uygulamasından paylaşıldı. '
      'Bu bir tıbbi rapor değildir.',
    );

    return sb.toString();
  }

  /// Dönemdeki ölçümlerden eşiği aşanları toplar.
  Future<List<Alert>> collectAlerts({
    required List<VitalRow> vitals,
    required List<LabResultRow> labs,
  }) async {
    final settings = await _readSettings();
    final out = <Alert>[];

    for (final v in vitals) {
      if (v.systolic != null && v.diastolic != null) {
        final a = evaluateBloodPressure(
          systolic: v.systolic!,
          diastolic: v.diastolic!,
          settings: settings,
        );
        if (a.level.severity >= AlertLevel.warning.severity) out.add(a);
      }
      if (v.heartRate != null) {
        for (final key in ['heart_rate_high', 'heart_rate_low']) {
          final a = evaluateSingleThreshold(
            measured: v.heartRate!.toDouble(),
            definitionKey: key,
            settings: settings,
            displayLabelTr: 'Nabız',
          );
          if (a.level.severity >= AlertLevel.warning.severity) out.add(a);
        }
      }
      if (v.spo2 != null) {
        for (final key in ['spo2_urgent', 'spo2_warn']) {
          final a = evaluateSingleThreshold(
            measured: v.spo2!.toDouble(),
            definitionKey: key,
            settings: settings,
            displayLabelTr: 'SpO2',
          );
          if (a.level.severity >= AlertLevel.warning.severity) {
            out.add(a);
            break;
          }
        }
      }
      if (v.urineMl != null) {
        final a = evaluateUrineOutput(ml: v.urineMl!, settings: settings);
        if (a.level.severity >= AlertLevel.warning.severity) out.add(a);
      }
    }

    for (final l in labs) {
      if (l.analyte == 'lab_potassium') {
        final a = evaluateSerumPotassium(
          mEqPerL: l.value,
          settings: settings,
        );
        if (a.level.severity >= AlertLevel.warning.severity) out.add(a);
      }
    }

    // En ağır uyarı önce, aynı başlık tekrarlanmasın.
    out.sort((a, b) => b.level.severity.compareTo(a.level.severity));
    final seen = <String>{};
    return out.where((a) => seen.add(a.titleTr)).toList();
  }

  Future<ClinicalSettings> _readSettings() async {
    final json = await _db.readJsonSetting('clinical_settings');
    return json == null
        ? const ClinicalSettings()
        : ClinicalSettings.fromJson(json);
  }
}

String _firstSentence(String text) {
  final idx = text.indexOf('.');
  if (idx <= 0) return text.length > 120 ? text.substring(0, 120) : text;
  return text.substring(0, idx + 1);
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.'
    '${d.month.toString().padLeft(2, '0')}.${d.year}';
