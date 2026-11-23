import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../clinical/evaluator.dart';
import '../../core/providers.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/sms_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';

/// Yeni bir ölçüm kaydedildiğinde eşikleri değerlendirir.
///
/// Acil kişilere SMS yalnızca şu koşullarda gönderilir:
///  1. Klinik tanım `triggersEmergencySms` ise,
///  2. kullanıcı `autoSmsOnAlarm` ayarını AÇIKÇA açtıysa,
///  3. en az bir acil kişide `autoSmsEnabled` işaretliyse.
/// Aksi hâlde yalnızca ekranda uyarı gösterilir.
Future<void> evaluateAndDispatchAlerts({
  required BuildContext context,
  required WidgetRef ref,
  int? systolic,
  int? diastolic,
  int? heartRate,
  int? spo2,
  int? urineMl,
  double? weightKg,
  double? serumPotassium,
}) async {
  final settings = ref.read(clinicalSettingsProvider);
  final alerts = <Alert>[];

  if (systolic != null && diastolic != null) {
    alerts.add(
      evaluateBloodPressure(
        systolic: systolic,
        diastolic: diastolic,
        settings: settings,
      ),
    );
  }
  if (heartRate != null) {
    for (final key in ['heart_rate_high', 'heart_rate_low']) {
      alerts.add(
        evaluateSingleThreshold(
          measured: heartRate.toDouble(),
          definitionKey: key,
          settings: settings,
          displayLabelTr: 'Nabız',
        ),
      );
    }
  }
  if (spo2 != null) {
    for (final key in ['spo2_urgent', 'spo2_warn']) {
      final a = evaluateSingleThreshold(
        measured: spo2.toDouble(),
        definitionKey: key,
        settings: settings,
        displayLabelTr: 'SpO2',
      );
      if (a.level != AlertLevel.none) {
        alerts.add(a);
        break;
      }
    }
  }
  if (urineMl != null) {
    alerts.add(evaluateUrineOutput(ml: urineMl, settings: settings));
  }
  if (serumPotassium != null) {
    alerts.add(
      evaluateSerumPotassium(
        mEqPerL: serumPotassium,
        settings: settings,
      ),
    );
  }
  if (weightKg != null && settings.dryWeightKg != null) {
    final idwg = computeIdwg(
      currentKg: weightKg,
      dryWeightKg: settings.dryWeightKg!,
      thresholdPercent: settings.resolve('idwg_percent').value ?? 4.0,
    );
    if (idwg != null && idwg.isOverThreshold) {
      alerts.add(
        Alert(
          level: idwg.level,
          titleTr: 'Diyaliz arası kilo artışı eşiğin üstünde',
          messageTr: '${idwg.gainKg.toStringAsFixed(1)} kg '
              '(%${idwg.percent.toStringAsFixed(1)}) — eşik '
              '%${idwg.thresholdPercent.toStringAsFixed(1)}.',
          definitionKey: 'idwg_percent',
          sourceIds: const ['idwg_review_2025'],
        ),
      );
    }
  }

  final significant = alerts
      .where((a) => a.level.severity >= AlertLevel.warning.severity)
      .toList()
    ..sort((a, b) => b.level.severity.compareTo(a.level.severity));

  if (significant.isEmpty) return;
  final top = significant.first;

  // Bildirim (ilaç/randevu dışı kategoriler günlük limite tabi değildir
  // çünkü bu bir ölçüm alarmı; "smart" kategorisinde ama kritik.
  // Bu yüzden medication kanalında, kritik olarak gönderilir.)
  if (top.level == AlertLevel.urgent) {
    await ref.read(notificationServiceProvider).show(
          category: NotifCategory.medication,
          title: top.titleTr,
          body: top.messageTr,
        );
  }

  if (!context.mounted) return;

  // Ekranda göster.
  await showDialog<void>(
    context: context,
    builder: (context) => _AlertDialog(alerts: significant),
  );

  if (!context.mounted) return;

  // Otomatik SMS.
  final prefs = ref.read(preferencesProvider);
  if (!prefs.autoSmsOnAlarm) return;
  if (!top.shouldNotifyEmergencyContacts) return;

  final contacts = await ref.read(databaseProvider).getEmergencyContacts();
  final targets =
      contacts.where((c) => c.autoSmsEnabled).toList();
  if (targets.isEmpty) return;

  final loc = ref.read(locationProvider);
  final message = await ref.read(caregiverServiceProvider).buildAlertMessage(
        alert: top,
        latitude: loc?.latitude,
        longitude: loc?.longitude,
      );

  try {
    final sent = await ref.read(smsServiceProvider).sendDirect(
          phoneNumbers: targets.map((c) => c.phone).toList(),
          message: message,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sent > 0
                ? '$sent acil kişiye otomatik SMS gönderildi.'
                : 'Otomatik SMS gönderilemedi.',
          ),
        ),
      );
    }
  } on SmsFailure catch (e) {
    if (!context.mounted) return;
    // İzin yoksa mesajı hazırla, gönderimi kullanıcıya bırak.
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otomatik SMS gönderilemedi'),
        content: Text(
          '${e.messageTr}\n\nMesajı hazırlayıp SMS uygulamasını '
          'açabilirim; gönder tuşuna sen basarsın.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SMS uygulamasını aç'),
          ),
        ],
      ),
    );
    if (open == true) {
      await ref.read(smsServiceProvider).openComposer(
            phoneNumbers: targets.map((c) => c.phone).toList(),
            message: message,
          );
    }
  }
}

class _AlertDialog extends StatelessWidget {
  const _AlertDialog({required this.alerts});

  final List<Alert> alerts;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final urgent = alerts.first.level == AlertLevel.urgent;

    return AlertDialog(
      icon: Icon(
        urgent ? Icons.emergency_rounded : Icons.warning_amber_rounded,
        color: urgent ? p.danger : p.warning,
        size: 36,
      ),
      title: Text(
        urgent ? 'Dikkat gerektiren ölçüm' : 'Eşik aşıldı',
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final a in alerts) ...[
              AlertCard(alert: a),
              const SizedBox(height: 10),
            ],
            const MedicalDisclaimerBanner(compact: true),
          ],
        ),
      ),
      actions: [
        NeuButton(
          label: 'Anladım',
          compact: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
