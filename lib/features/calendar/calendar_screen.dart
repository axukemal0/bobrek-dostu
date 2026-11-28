import 'package:drift/drift.dart' show Value;
import 'package:drift/drift.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' hide Text;

import '../../clinical/settings.dart';
import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/responsive.dart';
import '../home/home_screen.dart' show showPermissionDialog;
import '../../core/i18n/text.dart';
import '../../core/i18n/i18n.dart';

const Map<String, ({String labelTr, IconData icon})> kAppointmentKinds = {
  'dialysis': (labelTr: 'Diyaliz seansı', icon: Icons.bloodtype_outlined),
  'checkup': (labelTr: 'Kontrol', icon: Icons.local_hospital_outlined),
  'lab': (labelTr: 'Tahlil', icon: Icons.science_outlined),
  'other': (labelTr: 'Diğer', icon: Icons.event_outlined),
};

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final appointments =
        ref.watch(appointmentsProvider).value ?? const [];
    final profile = ref.watch(profileProvider).value;
    final settings = ref.watch(clinicalSettingsProvider);

    // Diyaliz günlerinden otomatik öneri.
    final dialysisDays = profile?.dialysisDays;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(title: const Text('Takvim')),
      floatingActionButtonLocation:
          ShellFabLocation(BottomBarInset.of(context)),
      floatingActionButton: SectionFab(
        label: 'Randevu ekle',
        tone: p.accents.appointment,
        onPressed: () => _showSheet(context),
      ),
      body: SafeArea(
        child: PageBody(
          hasFab: true,
          children: [
            if (settings.treatmentMode.isDialysis && dialysisDays != null)
              NeuCard(
                color: p.primarySoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diyaliz günlerin',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: r.gapXs),
                    Text(
                      dialysisDays
                          .split(',')
                          .map((d) =>
                              WeekdayPicker.shortNames[(int.tryParse(d) ?? 1) - 1])
                          .join(', '),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    SizedBox(height: r.gapSm),
                    NeuButton(
                      label: 'Bu haftanın seanslarını takvime ekle',
                      icon: Icons.event_repeat_rounded,
                      compact: true,
                      filled: false,
                      expanded: true,
                      onPressed: () => _generateDialysisSessions(
                        dialysisDays,
                      ),
                    ),
                  ],
                ),
              ),

            SectionHeader(
              title: tf('Yaklaşan ({0})', [appointments.length]),
              icon: Icons.upcoming_outlined,
            ),
            if (appointments.isEmpty)
              const EmptyState(
                title: 'Yaklaşan randevu yok',
                message: 'Diyaliz seansı, kontrol ve tahlil tarihlerini '
                    'ekle; zamanı gelmeden hatırlatırım.',
                icon: Icons.calendar_month_outlined,
              )
            else
              for (final a in appointments)
                Padding(
                  padding: EdgeInsets.only(bottom: r.gapSm),
                  child: _AppointmentCard(appointment: a),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateDialysisSessions(String daysRaw) async {
    final db = ref.read(databaseProvider);
    final days = daysRaw
        .split(',')
        .map((d) => int.tryParse(d.trim()))
        .whereType<int>()
        .toSet();
    final now = DateTime.now();
    var added = 0;

    for (var i = 0; i < 14; i++) {
      final day = DateTime(now.year, now.month, now.day + i, 9);
      if (!days.contains(day.weekday)) continue;
      if (day.isBefore(now)) continue;

      final existing = await (db.select(db.appointmentRows)
            ..where((t) => t.kind.equals('dialysis'))
            ..where((t) => t.startsAt.isBetweenValues(
                  DateTime(day.year, day.month, day.day),
                  DateTime(day.year, day.month, day.day, 23, 59),
                )))
          .get();
      if (existing.isNotEmpty) continue;

      await db.into(db.appointmentRows).insert(
            AppointmentRowsCompanion.insert(
              title: 'Diyaliz seansı',
              kind: 'dialysis',
              startsAt: day,
              durationMinutes: const Value(240),
            ),
          );
      added++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added == 0
                ? 'Eklenecek yeni seans bulunmadı (zaten kayıtlı).'
                : tf(
                    '{0} seans takvime eklendi. Saatlerini '
                    'düzenleyebilirsin.',
                    [added],
                  ),
          ),
        ),
      );
    }
    await _scheduleReminders();
  }

  Future<void> _scheduleReminders() async {
    final permission = ref.read(permissionServiceProvider);
    if (await permission.status(AppPermission.notifications) !=
        AppPermissionStatus.granted) {
      if (!mounted) return;
      final ok = await showPermissionDialog(
        context,
        permissionInfo(AppPermission.notifications),
      );
      if (!ok) return;
      if (await permission.request(AppPermission.notifications) !=
          AppPermissionStatus.granted) {
        return;
      }
    }

    final service = ref.read(notificationServiceProvider);
    final db = ref.read(databaseProvider);
    final rows = await (db.select(db.appointmentRows)
          ..where((t) => t.startsAt.isBiggerThanValue(DateTime.now()))
          ..where((t) => t.reminderEnabled.equals(true)))
        .get();

    for (final a in rows) {
      final when =
          a.startsAt.subtract(Duration(minutes: a.reminderMinutesBefore));
      if (when.isBefore(DateTime.now())) continue;
      await service.schedule(
        id: NotificationService.appointmentNotificationId(a.id),
        category: NotifCategory.appointment,
        title: a.title,
        body: '${_fmtDateTime(a.startsAt)}'
            '${a.location == null ? "" : " · ${a.location}"}',
        when: when,
      );
    }
  }

  void _showSheet(BuildContext context, {AppointmentRow? existing}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _AppointmentSheet(existing: existing),
    ).then((_) => _scheduleReminders());
  }
}

String _fmtDateTime(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.'
    '${d.month.toString().padLeft(2, '0')}.${d.year} '
    '${d.hour.toString().padLeft(2, '0')}:'
    '${d.minute.toString().padLeft(2, '0')}';

class _AppointmentCard extends ConsumerWidget {
  const _AppointmentCard({required this.appointment});

  final AppointmentRow appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final kind = kAppointmentKinds[appointment.kind] ??
        kAppointmentKinds['other']!;
    final until = appointment.startsAt.difference(DateTime.now());
    final soon = until.inHours < 24 && !until.isNegative;

    return NeuCard(
      padding: EdgeInsets.all(r.gapMd),
      color: soon ? p.primarySoft : null,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(r.gapSm),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(kind.icon, color: p.primary, size: r.s(21)),
          ),
          SizedBox(width: r.gapMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  _fmtDateTime(appointment.startsAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (appointment.location != null)
                  Text(
                    appointment.location!,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                if (soon)
                  Text(
                    until.inHours < 1
                        ? tf('{0} dakika kaldı', [until.inMinutes])
                        : tf('{0} saat kaldı', [until.inHours]),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                          color: p.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
              ],
            ),
          ),
          TapIcon(
            icon: Icons.delete_outline_rounded,
            semanticLabel: tf('{0} randevusunu sil', [appointment.title]),
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await ref.read(notificationServiceProvider).cancel(
                    NotificationService.appointmentNotificationId(
                      appointment.id,
                    ),
                  );
              await (db.delete(db.appointmentRows)
                    ..where((t) => t.id.equals(appointment.id)))
                  .go();
            },
          ),
        ],
      ),
    );
  }
}

class _AppointmentSheet extends ConsumerStatefulWidget {
  const _AppointmentSheet({this.existing});

  final AppointmentRow? existing;

  @override
  ConsumerState<_AppointmentSheet> createState() =>
      _AppointmentSheetState();
}

class _AppointmentSheetState extends ConsumerState<_AppointmentSheet> {
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.title ?? '');
  late final TextEditingController _location =
      TextEditingController(text: widget.existing?.location ?? '');
  late final TextEditingController _note =
      TextEditingController(text: widget.existing?.note ?? '');

  String _kind = 'checkup';
  DateTime _when = DateTime.now().add(const Duration(days: 1));
  int _reminderMinutes = 120;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final db = ref.read(databaseProvider);
    final title = _title.text.trim().isEmpty
        ? kAppointmentKinds[_kind]!.labelTr
        : _title.text.trim();

    await db.into(db.appointmentRows).insert(
          AppointmentRowsCompanion.insert(
            title: title,
            kind: _kind,
            location: Value(
              _location.text.trim().isEmpty ? null : _location.text.trim(),
            ),
            note: Value(
              _note.text.trim().isEmpty ? null : _note.text.trim(),
            ),
            startsAt: _when,
            reminderMinutesBefore: Value(_reminderMinutes),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
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
              'Randevu ekle',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: r.gapMd),
            LabeledField(
              label: 'Tür',
              child: ChipSelector<String>(
                options: kAppointmentKinds.keys.toList(),
                selected: _kind,
                labelOf: (k) => kAppointmentKinds[k]!.labelTr,
                onSelected: (k) => setState(() => _kind = k),
              ),
            ),
            SizedBox(height: r.gapMd),
            TextField(
              controller: _title,
              decoration: InputDecoration(
                labelText: t('Başlık'),
                hintText: kAppointmentKinds[_kind]!.labelTr,
              ),
            ),
            SizedBox(height: r.gapMd),
            LabeledField(
              label: 'Tarih ve saat',
              child: Row(
                children: [
                  Expanded(
                    child: NeuButton(
                      label: '${_when.day.toString().padLeft(2, '0')}.'
                          '${_when.month.toString().padLeft(2, '0')}.'
                          '${_when.year}',
                      icon: Icons.calendar_today_outlined,
                      filled: false,
                      compact: true,
                      expanded: true,
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _when,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 1)),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 730)),
                        );
                        if (picked != null) {
                          setState(() => _when = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                _when.hour,
                                _when.minute,
                              ));
                        }
                      },
                    ),
                  ),
                  SizedBox(width: r.gapSm),
                  Expanded(
                    child: NeuButton(
                      label: '${_when.hour.toString().padLeft(2, '0')}:'
                          '${_when.minute.toString().padLeft(2, '0')}',
                      icon: Icons.schedule_rounded,
                      filled: false,
                      compact: true,
                      expanded: true,
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_when),
                        );
                        if (picked != null) {
                          setState(() => _when = DateTime(
                                _when.year,
                                _when.month,
                                _when.day,
                                picked.hour,
                                picked.minute,
                              ));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: r.gapMd),
            TextField(
              controller: _location,
              decoration: InputDecoration(
                labelText: 'Yer',
                hintText: t('Örn. X Diyaliz Merkezi'),
              ),
            ),
            SizedBox(height: r.gapMd),
            LabeledField(
              label: 'Hatırlatma',
              child: ChipSelector<int>(
                options: const [30, 60, 120, 360, 1440],
                selected: _reminderMinutes,
                labelOf: (m) => m < 60
                    ? tf('{0} dk önce', [m])
                    : (m < 1440 ? tf('{0} saat önce', [m ~/ 60]) : '1 gün önce'),
                onSelected: (m) => setState(() => _reminderMinutes = m),
              ),
            ),
            SizedBox(height: r.gapMd),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Not'),
            ),
            SizedBox(height: r.gapLg),
            NeuButton(
              label: 'Kaydet',
              icon: Icons.check_rounded,
              expanded: true,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
