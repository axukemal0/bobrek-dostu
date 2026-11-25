import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../clinical/evaluator.dart';
import '../../clinical/settings.dart';
import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/responsive.dart';
import '../../core/widgets/trend_chart.dart';
import '../emergency/alert_dispatcher.dart';

class WeightScreen extends ConsumerWidget {
  const WeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final settings = ref.watch(clinicalSettingsProvider);
    final vitalsAsync = ref.watch(vitalsProvider);

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(title: const Text('Kilo, ödem ve tansiyon')),
      floatingActionButtonLocation:
          ShellFabLocation(BottomBarInset.of(context)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => const _AddVitalSheet(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ölçüm ekle'),
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
      ),
      body: SafeArea(
        child: vitalsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Okunamadı: $e')),
          data: (vitals) {
            if (vitals.isEmpty) {
              return PageBody(
                children: [
                  const EmptyState(
                    title: 'Henüz ölçüm yok',
                    message: 'Günlük kilo, şişlik düzeyi, idrar miktarı '
                        've tansiyonunu kaydet. Grafikler ve diyaliz '
                        'arası kilo artışı otomatik hesaplanır.',
                    icon: Icons.monitor_weight_outlined,
                  ),
                ],
              );
            }

            final sorted = [...vitals]
              ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

            final weights = sorted
                .where((v) => v.weightKg != null)
                .map((v) => (at: v.measuredAt, value: v.weightKg!))
                .toList();
            final systolic = sorted
                .where((v) => v.systolic != null)
                .map((v) => (at: v.measuredAt, value: v.systolic!.toDouble()))
                .toList();
            final diastolic = sorted
                .where((v) => v.diastolic != null)
                .map((v) => (at: v.measuredAt, value: v.diastolic!.toDouble()))
                .toList();
            final urine = sorted
                .where((v) => v.urineMl != null)
                .map((v) => (at: v.measuredAt, value: v.urineMl!.toDouble()))
                .toList();

            // Diyaliz arası kilo artışı.
            final latestWeight =
                weights.isEmpty ? null : weights.last.value;
            final dry = settings.dryWeightKg;
            final idwg = (latestWeight != null && dry != null)
                ? computeIdwg(
                    currentKg: latestWeight,
                    dryWeightKg: dry,
                    thresholdPercent:
                        settings.resolve('idwg_percent').value ?? 4.0,
                  )
                : null;

            final latest = sorted.last;
            final bpAlert = (latest.systolic != null &&
                    latest.diastolic != null)
                ? evaluateBloodPressure(
                    systolic: latest.systolic!,
                    diastolic: latest.diastolic!,
                    settings: settings,
                  )
                : null;

            return PageBody(
              children: [
                // --- IDWG ---
                if (idwg != null)
                  NeuCard(
                    color: idwg.isOverThreshold
                        ? p.warning.withValues(alpha: p.isDark ? 0.15 : 0.09)
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              idwg.isOverThreshold
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_outline_rounded,
                              color: idwg.isOverThreshold
                                  ? p.warning
                                  : p.success,
                            ),
                            SizedBox(width: r.gapSm),
                            Expanded(
                              child: Text(
                                'Diyaliz arası kilo artışı',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: r.gapSm),
                        Text(
                          '${idwg.gainKg.toStringAsFixed(1)} kg '
                          '(kuru ağırlığın '
                          '%${idwg.percent.toStringAsFixed(1)}\'i) · '
                          'eşik %${idwg.thresholdPercent.toStringAsFixed(1)}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        SizedBox(height: r.gapXs),
                        Text(
                          idwg.isOverThreshold
                              ? 'Eşiğin üstünde. Artışın ana belirleyicisi '
                                  'genellikle SODYUMDUR: tuzu azaltmak, '
                                  'sıvıyı kısmaktan daha kolay sonuç verir.'
                              : 'Hedef aralıkta.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SizedBox(height: r.gapXs),
                        const SourceFootnote(sourceIds: ['idwg_review_2025']),
                      ],
                    ),
                  )
                else if (settings.dryWeightKg == null &&
                    settings.treatmentMode.isDialysis)
                  NeuCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kuru ağırlık girilmedi',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        SizedBox(height: r.gapXs),
                        Text(
                          'Diyaliz arası kilo artışı yüzdesini '
                          'hesaplayabilmem için kuru ağırlığını girmen '
                          'gerekiyor.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SizedBox(height: r.gapSm),
                        NeuButton(
                          label: 'Klinik Ayarlar',
                          icon: Icons.tune_rounded,
                          compact: true,
                          filled: false,
                          onPressed: () =>
                              context.push(Routes.clinicalSettings),
                        ),
                      ],
                    ),
                  ),

                if (bpAlert != null && bpAlert.level != AlertLevel.none)
                  AlertCard(
                    alert: bpAlert,
                    onSourceTap: () => context.push(Routes.sources),
                  ),

                // --- kilo grafiği ---
                if (weights.isNotEmpty)
                  NeuCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kilo',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: r.gapXs),
                        TrendSummary(
                          points: weights,
                          unit: 'kg',
                          higherIsWorse: true,
                        ),
                        SizedBox(height: r.gapSm),
                        TrendChart(
                          points: weights,
                          unit: 'kg',
                          targetLine: settings.dryWeightKg,
                          targetLabelTr: settings.dryWeightKg == null
                              ? null
                              : 'kuru ağırlık',
                          height: r.s(210),
                        ),
                      ],
                    ),
                  ),

                // --- tansiyon grafiği ---
                if (systolic.isNotEmpty)
                  NeuCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Tansiyon',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium,
                              ),
                            ),
                            _Legend(color: p.primary, label: 'sistolik'),
                            SizedBox(width: r.gapSm),
                            _Legend(color: p.accent, label: 'diyastolik'),
                          ],
                        ),
                        SizedBox(height: r.gapSm),
                        TrendChart(
                          points: systolic,
                          secondarySeries: diastolic,
                          unit: 'mmHg',
                          decimals: 0,
                          targetLine:
                              settings.resolve('bp_systolic_target').value,
                          targetLabelTr: 'hedef sistolik',
                          height: r.s(220),
                        ),
                        SizedBox(height: r.gapXs),
                        const SourceFootnote(
                          sourceIds: ['kdigo_ckd_2024', 'acc_aha_htn_2017'],
                        ),
                      ],
                    ),
                  ),

                // --- idrar ---
                if (urine.isNotEmpty)
                  NeuCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'İdrar miktarı',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: r.gapSm),
                        TrendChart(
                          points: urine,
                          unit: 'mL',
                          decimals: 0,
                          targetLine: settings
                              .resolve('urine_output_low_ml')
                              .value,
                          targetLabelTr: 'alt alarm',
                          height: r.s(190),
                        ),
                      ],
                    ),
                  ),

                // --- kayıt listesi ---
                SectionHeader(
                  title: 'Kayıtlar (${vitals.length})',
                  icon: Icons.list_alt_rounded,
                ),
                for (final v in vitals)
                  Padding(
                    padding: EdgeInsets.only(bottom: r.gapSm),
                    child: _VitalTile(vital: v),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _VitalTile extends ConsumerWidget {
  const _VitalTile({required this.vital});

  final VitalRow vital;

  static const List<String> edemaLabels = [
    'yok',
    'hafif',
    'orta',
    'belirgin',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = Responsive.fromContext(context);
    final parts = <String>[
      if (vital.weightKg != null)
        '${vital.weightKg!.toStringAsFixed(1)} kg',
      if (vital.systolic != null && vital.diastolic != null)
        '${vital.systolic}/${vital.diastolic} mmHg',
      if (vital.heartRate != null) '${vital.heartRate} /dk',
      if (vital.spo2 != null) 'SpO₂ %${vital.spo2}',
      if (vital.urineMl != null) 'idrar ${vital.urineMl} mL',
      if (vital.edemaLevel != null)
        'şişlik ${edemaLabels[vital.edemaLevel!.clamp(0, 3)]}',
      if (vital.temperatureC != null)
        '${vital.temperatureC!.toStringAsFixed(1)} °C',
      if (vital.glucoseMgDl != null)
        'şeker ${vital.glucoseMgDl!.round()} mg/dL',
    ];

    return NeuCard(
      padding: EdgeInsets.all(r.gapMd),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parts.isEmpty ? 'Boş kayıt' : parts.join(' · '),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: r.s(2)),
                Text(
                  [
                    _fmt(vital.measuredAt),
                    if (vital.dialysisPhase == 'pre') 'diyaliz öncesi',
                    if (vital.dialysisPhase == 'post') 'diyaliz sonrası',
                    if (vital.note != null) vital.note!,
                  ].join(' · '),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          TapIcon(
            icon: Icons.delete_outline_rounded,
            semanticLabel: 'Kaydı sil',
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await (db.delete(db.vitalRows)
                    ..where((t) => t.id.equals(vital.id)))
                  .go();
            },
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

class _AddVitalSheet extends ConsumerStatefulWidget {
  const _AddVitalSheet();

  @override
  ConsumerState<_AddVitalSheet> createState() => _AddVitalSheetState();
}

class _AddVitalSheetState extends ConsumerState<_AddVitalSheet> {
  final _weight = TextEditingController();
  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  final _heartRate = TextEditingController();
  final _spo2 = TextEditingController();
  final _urine = TextEditingController();
  final _temp = TextEditingController();
  final _glucose = TextEditingController();
  final _note = TextEditingController();
  int? _edema;
  String? _phase;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _weight, _systolic, _diastolic, _heartRate, _spo2,
      _urine, _temp, _glucose, _note,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final now = DateTime.now();

    final companion = VitalRowsCompanion.insert(
      weightKg: Value(parseLocaleNumber(_weight.text)),
      edemaLevel: Value(_edema),
      urineMl: Value(parseLocaleInt(_urine.text)),
      systolic: Value(parseLocaleInt(_systolic.text)),
      diastolic: Value(parseLocaleInt(_diastolic.text)),
      heartRate: Value(parseLocaleInt(_heartRate.text)),
      temperatureC: Value(parseLocaleNumber(_temp.text)),
      spo2: Value(parseLocaleInt(_spo2.text)),
      glucoseMgDl: Value(parseLocaleNumber(_glucose.text)),
      note: Value(_note.text.trim().isEmpty ? null : _note.text.trim()),
      dialysisPhase: Value(_phase),
      measuredAt: now,
    );
    await db.into(db.vitalRows).insert(companion);

    // Eşik aşımı kontrolü ve (ayar açıksa) acil kişilere bildirim.
    if (mounted) {
      await evaluateAndDispatchAlerts(
        context: context,
        ref: ref,
        systolic: parseLocaleInt(_systolic.text),
        diastolic: parseLocaleInt(_diastolic.text),
        heartRate: parseLocaleInt(_heartRate.text),
        spo2: parseLocaleInt(_spo2.text),
        urineMl: parseLocaleInt(_urine.text),
        weightKg: parseLocaleNumber(_weight.text),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final settings = ref.watch(clinicalSettingsProvider);

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
              'Ölçüm ekle',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: r.gapXs),
            Text(
              'Sadece ölçtüklerini doldur, gerisini boş bırak.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: r.gapMd),
            Row(
              children: [
                Expanded(
                  child: LabeledField(
                    label: 'Kilo',
                    child: NumberField(
                      controller: _weight,
                      suffix: 'kg',
                    ),
                  ),
                ),
                SizedBox(width: r.gapSm),
                Expanded(
                  child: LabeledField(
                    label: 'İdrar',
                    child: NumberField(
                      controller: _urine,
                      suffix: 'mL',
                      allowDecimal: false,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: r.gapMd),
            LabeledField(
              label: 'Tansiyon',
              hint: 'Oturarak, 5 dakika dinlendikten sonra ölç. '
                  'KDIGO 2024 hedefi standart ofis ölçümüne dayanır.',
              child: Row(
                children: [
                  Expanded(
                    child: NumberField(
                      controller: _systolic,
                      hintText: 'sistolik',
                      allowDecimal: false,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: r.gapSm),
                    child: const Text('/'),
                  ),
                  Expanded(
                    child: NumberField(
                      controller: _diastolic,
                      hintText: 'diyastolik',
                      allowDecimal: false,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: r.gapMd),
            Row(
              children: [
                Expanded(
                  child: LabeledField(
                    label: 'Nabız',
                    child: NumberField(
                      controller: _heartRate,
                      suffix: '/dk',
                      allowDecimal: false,
                    ),
                  ),
                ),
                SizedBox(width: r.gapSm),
                Expanded(
                  child: LabeledField(
                    label: 'SpO₂',
                    child: NumberField(
                      controller: _spo2,
                      suffix: '%',
                      allowDecimal: false,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: r.gapMd),
            Row(
              children: [
                Expanded(
                  child: LabeledField(
                    label: 'Ateş',
                    child: NumberField(
                      controller: _temp,
                      suffix: '°C',
                    ),
                  ),
                ),
                SizedBox(width: r.gapSm),
                Expanded(
                  child: LabeledField(
                    label: 'Kan şekeri',
                    child: NumberField(
                      controller: _glucose,
                      suffix: 'mg/dL',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: r.gapMd),
            LabeledField(
              label: 'Şişlik (ödem) düzeyi',
              child: ChipSelector<int>(
                options: const [0, 1, 2, 3],
                selected: _edema,
                labelOf: (i) => _VitalTile.edemaLabels[i],
                onSelected: (i) => setState(() => _edema = i),
              ),
            ),
            if (settings.treatmentMode.isDialysis) ...[
              SizedBox(height: r.gapMd),
              LabeledField(
                label: 'Diyaliz seansı',
                child: ChipSelector<String>(
                  options: const ['pre', 'post'],
                  selected: _phase,
                  labelOf: (s) =>
                      s == 'pre' ? 'Seans öncesi' : 'Seans sonrası',
                  onSelected: (s) => setState(() => _phase = s),
                ),
              ),
            ],
            SizedBox(height: r.gapMd),
            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Not',
                hintText: 'Örn. sabah aç karnına',
              ),
            ),
            SizedBox(height: r.gapLg),
            NeuButton(
              label: _saving ? 'Kaydediliyor…' : 'Kaydet',
              icon: Icons.check_rounded,
              expanded: true,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
