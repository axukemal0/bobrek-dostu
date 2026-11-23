import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../clinical/drug_safety.dart';
import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/responsive.dart';
import '../home/home_screen.dart' show showPermissionDialog;
import 'medication_logic.dart';

class MedicationsScreen extends ConsumerStatefulWidget {
  const MedicationsScreen({super.key});

  @override
  ConsumerState<MedicationsScreen> createState() =>
      _MedicationsScreenState();
}

class _MedicationsScreenState extends ConsumerState<MedicationsScreen> {
  @override
  void initState() {
    super.initState();
    // Bugünün dozlarını oluştur ve bildirimleri planla.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncToday());
  }

  Future<void> _syncToday() async {
    final db = ref.read(databaseProvider);
    final meds = await db.getActiveMedications();
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);

    final existing = await db.dosesBetween(
      day,
      day.add(const Duration(days: 1)),
    );

    for (final med in meds) {
      for (final at in scheduledTimesFor(med, day)) {
        final already = existing.any(
          (d) => d.medicationId == med.id && d.scheduledAt == at,
        );
        if (already) continue;
        await db.into(db.medicationDoseRows).insert(
              MedicationDoseRowsCompanion.insert(
                medicationId: med.id,
                scheduledAt: at,
              ),
            );
      }
    }

    await _scheduleNotifications();
  }

  Future<void> _scheduleNotifications() async {
    final service = ref.read(notificationServiceProvider);
    final permission = ref.read(permissionServiceProvider);
    if (await permission.status(AppPermission.notifications) !=
        AppPermissionStatus.granted) {
      return;
    }

    await service.init();
    final meds = await ref.read(databaseProvider).getActiveMedications();
    final now = DateTime.now();

    for (final med in meds) {
      // Önümüzdeki 7 gün için planla.
      for (var d = 0; d < 7; d++) {
        final day = DateTime(now.year, now.month, now.day + d);
        final times = scheduledTimesFor(med, day);
        for (var i = 0; i < times.length; i++) {
          final at = times[i];
          if (at.isBefore(now)) continue;
          await service.schedule(
            id: NotificationService.medicationNotificationId(
              med.id,
              d * 10 + i,
            ),
            category: NotifCategory.medication,
            title: 'İlaç saati: ${med.name}',
            body: med.dose == null
                ? 'Alma zamanı geldi.'
                : '${med.dose} — alma zamanı geldi.',
            when: at,
          );
        }
      }
    }
  }

  Future<void> _ensureNotificationPermission() async {
    final permission = ref.read(permissionServiceProvider);
    if (await permission.status(AppPermission.notifications) ==
        AppPermissionStatus.granted) {
      await _scheduleNotifications();
      return;
    }
    if (!mounted) return;
    final ok = await showPermissionDialog(
      context,
      permissionInfo(AppPermission.notifications),
    );
    if (!ok) return;
    final granted = await permission.request(AppPermission.notifications);
    if (granted != AppPermissionStatus.granted) return;

    // Tam zamanlı alarm izni ayrıca istenir.
    if (await permission.status(AppPermission.exactAlarm) !=
        AppPermissionStatus.granted) {
      if (!mounted) return;
      final ok2 = await showPermissionDialog(
        context,
        permissionInfo(AppPermission.exactAlarm),
      );
      if (ok2) await permission.request(AppPermission.exactAlarm);
    }
    await _scheduleNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final meds = ref.watch(medicationsProvider).value ?? const [];
    final doses = ref.watch(dosesForDayProvider).value ?? const [];
    final medById = {for (final m in meds) m.id: m};

    final pending = doses
        .where((d) => d.status == 'pending' || d.status == 'snoozed')
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final done = doses
        .where((d) => d.status == 'taken' || d.status == 'skipped')
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    final warnStock = meds.where(shouldWarnStock).toList();

    return Scaffold(
      backgroundColor: p.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMedSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('İlaç ekle'),
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
      ),
      body: SafeArea(
        child: PageBody(
          children: [
            Text(
              'İlaçlar',
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            // --- bildirim izni ---
            _NotificationPrompt(onEnable: _ensureNotificationPermission),

            // --- stok uyarıları ---
            for (final m in warnStock)
              NeuCard(
                color: p.warning.withValues(alpha: p.isDark ? 0.15 : 0.09),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: p.warning),
                    SizedBox(width: r.gapSm),
                    Expanded(
                      child: Text(
                        '${m.name} stoku azalıyor: ${m.stockCount} adet '
                        'kaldı (yaklaşık '
                        '${daysOfStockRemaining(m)?.toStringAsFixed(0) ?? "?"} '
                        'gün). Reçete yenilemeyi düşün.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),

            // --- bugünün dozları ---
            SectionHeader(
              title: 'Bugün alınacak (${pending.length})',
              icon: Icons.schedule_rounded,
            ),
            if (pending.isEmpty && meds.isEmpty)
              const EmptyState(
                title: 'Henüz ilaç yok',
                message: 'Sağ alttaki düğmeyle ilaçlarını ekle. '
                    'Her ilaç böbrek güvenliği açısından taranır ve '
                    'riskli olanlarda uyarı gösterilir.',
                icon: Icons.medication_outlined,
              )
            else if (pending.isEmpty)
              NeuCard(
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: p.success),
                    SizedBox(width: r.gapSm),
                    Expanded(
                      child: Text(
                        'Bugün için bekleyen doz yok.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final dose in pending)
                if (medById[dose.medicationId] != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: r.gapSm),
                    child: _DoseCard(
                      dose: dose,
                      med: medById[dose.medicationId]!,
                    ),
                  ),

            // --- işaretlenmişler ---
            if (done.isNotEmpty) ...[
              SectionHeader(
                title: 'İşaretlenenler (${done.length})',
                icon: Icons.done_all_rounded,
              ),
              for (final dose in done.take(10))
                if (medById[dose.medicationId] != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: r.gapXs),
                    child: NeuCard(
                      padding: EdgeInsets.symmetric(
                        horizontal: r.gapMd,
                        vertical: r.gapSm,
                      ),
                      depth: 0.4,
                      child: Row(
                        children: [
                          Icon(
                            dose.status == 'taken'
                                ? Icons.check_circle_rounded
                                : Icons.cancel_outlined,
                            color: dose.status == 'taken'
                                ? p.success
                                : p.textMuted,
                            size: r.s(18),
                          ),
                          SizedBox(width: r.gapSm),
                          Expanded(
                            child: Text(
                              '${medById[dose.medicationId]!.name} · '
                              '${_hm(dose.scheduledAt)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium,
                            ),
                          ),
                          Text(
                            dose.status == 'taken' ? 'alındı' : 'atlandı',
                            style:
                                Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
            ],

            // --- ilaç listesi ---
            SectionHeader(
              title: 'Tanımlı ilaçlar (${meds.length})',
              icon: Icons.inventory_2_outlined,
            ),
            for (final med in meds)
              Padding(
                padding: EdgeInsets.only(bottom: r.gapSm),
                child: _MedCard(
                  med: med,
                  onEdit: () => _showMedSheet(context, existing: med),
                ),
              ),

            NeuCard(
              color: p.danger.withValues(alpha: p.isDark ? 0.12 : 0.07),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: p.danger),
                      SizedBox(width: r.gapSm),
                      Expanded(
                        child: Text(
                          'İlaç güvenliği taraması hakkında',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(color: p.danger),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.gapSm),
                  Text(
                    kDrugDatasetDisclaimerTr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMedSheet(BuildContext context, {MedicationRow? existing}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _MedSheet(existing: existing),
    ).then((_) => _syncToday());
  }

  static String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

class _NotificationPrompt extends ConsumerWidget {
  const _NotificationPrompt({required this.onEnable});

  final Future<void> Function() onEnable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = Responsive.fromContext(context);
    final p = context.palette;
    return FutureBuilder<AppPermissionStatus>(
      future: ref
          .read(permissionServiceProvider)
          .status(AppPermission.notifications),
      builder: (context, snapshot) {
        if (snapshot.data == AppPermissionStatus.granted) {
          return const SizedBox.shrink();
        }
        return NeuCard(
          color: p.accentSoft.withValues(alpha: 0.6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_off_outlined, color: p.accent),
                  SizedBox(width: r.gapSm),
                  Expanded(
                    child: Text(
                      'Hatırlatmalar kapalı',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              SizedBox(height: r.gapSm),
              Text(
                'İlaç saatlerini hatırlatabilmem için bildirim izni '
                'gerekiyor. İzin vermezsen ilaçları buradan elle '
                'işaretleyebilirsin.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: r.gapMd),
              NeuButton(
                label: 'Bildirimleri aç',
                icon: Icons.notifications_active_outlined,
                compact: true,
                expanded: true,
                onPressed: onEnable,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Güzel hatırlatma kartı: alındı / ertele.
class _DoseCard extends ConsumerWidget {
  const _DoseCard({required this.dose, required this.med});

  final MedicationDoseRow dose;
  final MedicationRow med;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final overdue = dose.scheduledAt.isBefore(DateTime.now());

    Future<void> mark(String status) async {
      final db = ref.read(databaseProvider);
      await (db.update(db.medicationDoseRows)
            ..where((t) => t.id.equals(dose.id)))
          .write(
        MedicationDoseRowsCompanion(
          status: Value(status),
          takenAt: Value(status == 'taken' ? DateTime.now() : null),
        ),
      );
      // Stok düş.
      if (status == 'taken' && med.stockCount != null) {
        await (db.update(db.medicationRows)
              ..where((t) => t.id.equals(med.id)))
            .write(
          MedicationRowsCompanion(
            stockCount: Value((med.stockCount! - 1).clamp(0, 99999)),
          ),
        );
      }
    }

    Future<void> snooze() async {
      final choice = await showModalBottomSheet<int>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Ne kadar ertelensin?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final o in kSnoozeOptions)
                ListTile(
                  leading: const Icon(Icons.snooze_rounded),
                  title: Text(o.labelTr),
                  onTap: () => Navigator.pop(context, o.minutes),
                ),
            ],
          ),
        ),
      );
      if (choice == null) return;
      final until = DateTime.now().add(Duration(minutes: choice));
      final db = ref.read(databaseProvider);
      await (db.update(db.medicationDoseRows)
            ..where((t) => t.id.equals(dose.id)))
          .write(
        MedicationDoseRowsCompanion(
          status: const Value('snoozed'),
          snoozedUntil: Value(until),
        ),
      );
      await ref.read(notificationServiceProvider).schedule(
            id: NotificationService.medicationNotificationId(
              med.id,
              90 + choice,
            ),
            category: NotifCategory.medication,
            title: 'İlaç hatırlatması: ${med.name}',
            body: 'Ertelenen doz zamanı geldi.',
            when: until,
          );
    }

    return GlassCard(
      padding: EdgeInsets.all(r.gapMd),
      tint: overdue
          ? p.warning.withValues(alpha: p.isDark ? 0.18 : 0.10)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: r.s(54),
                height: r.s(54),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _hm(dose.scheduledAt),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: p.onPrimary),
                ),
              ),
              SizedBox(width: r.gapMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (med.dose != null)
                      Text(
                        med.dose!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (overdue)
                      Text(
                        'Zamanı geçti',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: p.warning,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    if (dose.status == 'snoozed' &&
                        dose.snoozedUntil != null)
                      Text(
                        '${_hm(dose.snoozedUntil!)} için ertelendi',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: r.gapMd),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: NeuButton(
                  label: 'Aldım',
                  icon: Icons.check_rounded,
                  compact: true,
                  expanded: true,
                  onPressed: () => mark('taken'),
                ),
              ),
              SizedBox(width: r.gapSm),
              Expanded(
                child: NeuButton(
                  label: 'Ertele',
                  icon: Icons.snooze_rounded,
                  filled: false,
                  compact: true,
                  expanded: true,
                  onPressed: snooze,
                ),
              ),
              SizedBox(width: r.gapSm),
              Expanded(
                child: NeuButton(
                  label: 'Atla',
                  filled: false,
                  compact: true,
                  expanded: true,
                  tone: NeuTone.neutral,
                  onPressed: () => mark('skipped'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

class _MedCard extends ConsumerWidget {
  const _MedCard({required this.med, required this.onEdit});

  final MedicationRow med;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final matches = matchDrugRisks(med.name);

    return NeuCard(
      padding: EdgeInsets.all(r.gapMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      [
                        if (med.dose != null) med.dose!,
                        med.times,
                        if (med.stockCount != null)
                          'stok ${med.stockCount}',
                      ].join(' · '),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              TapIcon(
                icon: Icons.edit_outlined,
                semanticLabel: '${med.name} düzenle',
                onPressed: onEdit,
              ),
              TapIcon(
                icon: Icons.delete_outline_rounded,
                semanticLabel: '${med.name} sil',
                onPressed: () async {
                  final db = ref.read(databaseProvider);
                  await (db.update(db.medicationRows)
                        ..where((t) => t.id.equals(med.id)))
                      .write(
                    const MedicationRowsCompanion(active: Value(false)),
                  );
                },
              ),
            ],
          ),
          if (matches.isNotEmpty) ...[
            SizedBox(height: r.gapSm),
            for (final m in matches)
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: r.gapXs),
                padding: EdgeInsets.all(r.gapSm),
                decoration: BoxDecoration(
                  color: (m.risk.severity == RiskSeverity.avoid
                          ? p.danger
                          : p.warning)
                      .withValues(alpha: p.isDark ? 0.16 : 0.09),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (m.risk.severity == RiskSeverity.avoid
                            ? p.danger
                            : p.warning)
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: r.s(16),
                          color: m.risk.severity == RiskSeverity.avoid
                              ? p.danger
                              : p.warning,
                        ),
                        SizedBox(width: r.gapXs),
                        Expanded(
                          child: Text(
                            '${m.risk.severity.labelTr} — '
                            '${m.risk.genericTr} '
                            '(${m.risk.riskClass.labelTr})',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color:
                                      m.risk.severity == RiskSeverity.avoid
                                          ? p.danger
                                          : p.warning,
                                ),
                          ),
                        ),
                        if (!m.isExact)
                          Tooltip(
                            message: '"${m.matchedName}" adıyla kısmi '
                                'eşleşme — yanlış eşleşme olabilir.',
                            triggerMode: TooltipTriggerMode.tap,
                            child: Icon(
                              Icons.help_outline_rounded,
                              size: r.s(15),
                              color: p.textMuted,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: r.gapXs),
                    Text(
                      m.risk.reasonTr,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    SizedBox(height: r.gapXs),
                    SourceFootnote(sourceIds: m.risk.sourceIds),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// İlaç ekleme / düzenleme.
class _MedSheet extends ConsumerStatefulWidget {
  const _MedSheet({this.existing});

  final MedicationRow? existing;

  @override
  ConsumerState<_MedSheet> createState() => _MedSheetState();
}

class _MedSheetState extends ConsumerState<_MedSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _dose =
      TextEditingController(text: widget.existing?.dose ?? '');
  late final TextEditingController _stock = TextEditingController(
    text: widget.existing?.stockCount?.toString() ?? '',
  );
  late final TextEditingController _note =
      TextEditingController(text: widget.existing?.note ?? '');

  late List<TimeOfDay> _times = widget.existing == null
      ? [const TimeOfDay(hour: 8, minute: 0)]
      : parseTimes(widget.existing!.times)
          .map((t) => TimeOfDay(hour: t.hour, minute: t.minute))
          .toList();

  late Set<int> _weekdays = parseWeekdays(widget.existing?.weekdays);

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    _stock.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final db = ref.read(databaseProvider);
    final timesText = _times
        .map((t) => '${t.hour.toString().padLeft(2, '0')}:'
            '${t.minute.toString().padLeft(2, '0')}')
        .join(',');
    final weekdaysText =
        _weekdays.length == 7 ? null : (_weekdays.toList()..sort()).join(',');

    if (widget.existing == null) {
      await db.into(db.medicationRows).insert(
            MedicationRowsCompanion.insert(
              name: name,
              dose: Value(_dose.text.trim().isEmpty ? null : _dose.text.trim()),
              times: timesText,
              weekdays: Value(weekdaysText),
              stockCount: Value(parseLocaleInt(_stock.text)),
              note: Value(_note.text.trim().isEmpty ? null : _note.text.trim()),
            ),
          );
    } else {
      await (db.update(db.medicationRows)
            ..where((t) => t.id.equals(widget.existing!.id)))
          .write(
        MedicationRowsCompanion(
          name: Value(name),
          dose: Value(_dose.text.trim().isEmpty ? null : _dose.text.trim()),
          times: Value(timesText),
          weekdays: Value(weekdaysText),
          stockCount: Value(parseLocaleInt(_stock.text)),
          note: Value(_note.text.trim().isEmpty ? null : _note.text.trim()),
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final p = context.palette;
    final matches = matchDrugRisks(_name.text);

    return Padding(
      padding: EdgeInsets.only(
        left: r.pagePadding,
        right: r.pagePadding,
        top: r.gapLg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + r.gapLg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'İlaç ekle' : 'İlacı düzenle',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: r.gapMd),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'İlaç adı',
                hintText: 'Örn. Renagel, Brufen…',
              ),
            ),

            // --- canlı güvenlik taraması ---
            if (matches.isNotEmpty) ...[
              SizedBox(height: r.gapMd),
              for (final m in matches)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: r.gapSm),
                  padding: EdgeInsets.all(r.gapMd),
                  decoration: BoxDecoration(
                    color: p.danger.withValues(alpha: p.isDark ? 0.18 : 0.09),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: p.danger.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.priority_high_rounded, color: p.danger),
                          SizedBox(width: r.gapSm),
                          Expanded(
                            child: Text(
                              '${m.risk.genericTr}: '
                              '${m.risk.severity.labelTr}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: p.danger),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: r.gapSm),
                      Text(
                        m.risk.reasonTr,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(height: r.gapSm),
                      SourceFootnote(sourceIds: m.risk.sourceIds),
                      SizedBox(height: r.gapXs),
                      Text(
                        'Bu bir engel değil, hatırlatmadır — '
                        'hekim olarak kararı sen verirsin.',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
            ],

            SizedBox(height: r.gapMd),
            TextField(
              controller: _dose,
              decoration: const InputDecoration(
                labelText: 'Doz',
                hintText: '800 mg, 1 tablet…',
              ),
            ),
            SizedBox(height: r.gapLg),
            LabeledField(
              label: 'Saatler',
              child: TimeChips(
                times: _times,
                onAdd: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 8, minute: 0),
                  );
                  if (picked != null) {
                    setState(() {
                      _times = [..._times, picked]
                        ..sort((a, b) => (a.hour * 60 + a.minute)
                            .compareTo(b.hour * 60 + b.minute));
                    });
                  }
                },
                onRemove: (t) => setState(
                  () => _times = _times.where((x) => x != t).toList(),
                ),
              ),
            ),
            SizedBox(height: r.gapLg),
            LabeledField(
              label: 'Günler',
              hint: 'Hepsi seçiliyse her gün alınır.',
              child: WeekdayPicker(
                selected: _weekdays,
                onToggle: (d) => setState(() {
                  if (!_weekdays.remove(d)) _weekdays.add(d);
                  if (_weekdays.isEmpty) _weekdays = {1, 2, 3, 4, 5, 6, 7};
                }),
              ),
            ),
            SizedBox(height: r.gapLg),
            LabeledField(
              label: 'Stok (adet)',
              hint: 'Girersen bitmeden önce uyarırım. '
                  'Her "Aldım" işaretinde 1 düşer.',
              child: NumberField(
                controller: _stock,
                allowDecimal: false,
                hintText: '30',
              ),
            ),
            SizedBox(height: r.gapMd),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Not',
                hintText: 'Örn. yemekle birlikte al',
              ),
            ),
            SizedBox(height: r.gapLg),
            NeuButton(
              label: 'Kaydet',
              icon: Icons.check_rounded,
              expanded: true,
              onPressed: _name.text.trim().isEmpty ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
