import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../clinical/definitions.dart';
import '../../clinical/settings.dart';
import '../../core/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/responsive.dart';

/// Klinik Ayarlar — uygulamanın en önemli ekranı.
///
/// İLKE: Hiçbir değer kilitli değildir, hiçbir sınır dayatılmaz.
/// Her değerin yanında referans değer (kaynak adıyla), senin değerin,
/// varsayılana dön butonu ve değişiklik geçmişi bulunur.
class ClinicalSettingsScreen extends ConsumerStatefulWidget {
  const ClinicalSettingsScreen({super.key});

  @override
  ConsumerState<ClinicalSettingsScreen> createState() =>
      _ClinicalSettingsScreenState();
}

class _ClinicalSettingsScreenState
    extends ConsumerState<ClinicalSettingsScreen> {
  ValueKind _tab = ValueKind.dietTarget;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(clinicalSettingsProvider);
    final r = Responsive.fromContext(context);
    final p = context.palette;

    final defs = switch (_tab) {
      ValueKind.dietTarget => kDietTargets,
      ValueKind.alarmThreshold => kAlarmThresholds,
      ValueKind.labTarget => kLabTargets,
    };

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: const Text('Klinik Ayarlar'),
        actions: [
          TapIcon(
            icon: Icons.menu_book_outlined,
            semanticLabel: 'Kaynaklar',
            onPressed: () => context.push(Routes.sources),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- bilgi + sekmeler ---
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.pagePadding),
              child: ContentColumn(
                child: Column(
                  children: [
                    GlassCard(
                      padding: EdgeInsets.all(r.gapMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bu değerler SANA aittir',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: r.gapXs),
                          Text(
                            'Uygulama hiçbir alt/üst sınır dayatmaz. '
                            'Varsayılanlar kılavuz referanslarıdır ve '
                            'her birinin yanında kaynağı, yılı ve '
                            'doğrulama durumu yazar. $kReferenceCaveatTr',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: r.gapMd),
                    _BodyWeightCard(settings: settings),
                    SizedBox(height: r.gapMd),
                    SegmentedButton<ValueKind>(
                      segments: [
                        for (final k in ValueKind.values)
                          ButtonSegment(
                            value: k,
                            label: Text(k.shortTr),
                            tooltip: k.labelTr,
                          ),
                      ],
                      selected: {_tab},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) =>
                          setState(() => _tab = s.first),
                    ),
                    SizedBox(height: r.gapSm),
                  ],
                ),
              ),
            ),

            // --- değer listesi ---
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  r.pagePadding,
                  r.gapSm,
                  r.pagePadding,
                  r.gapXl * 2,
                ),
                itemCount: defs.length + 1,
                separatorBuilder: (_, _) => SizedBox(height: r.gapSm),
                itemBuilder: (context, i) {
                  if (i == defs.length) {
                    return Padding(
                      padding: EdgeInsets.only(top: r.gapMd),
                      child: const MedicalDisclaimerBanner(),
                    );
                  }
                  return ContentColumn(
                    child: ClinicalValueTile(
                      definition: defs[i],
                      settings: settings,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vücut ağırlığı / kuru ağırlık kartı — g/kg hesapları buna bağlı.
class _BodyWeightCard extends ConsumerWidget {
  const _BodyWeightCard({required this.settings});

  final ClinicalSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = Responsive.fromContext(context);
    return NeuCard(
      padding: EdgeInsets.all(r.gapMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hesaplama ağırlıkları',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: r.gapXs),
          Text(
            'g/kg/gün türü hedefler bu kiloyla çarpılır. '
            'Kuru ağırlık, diyaliz arası kilo artışı yüzdesi için '
            'kullanılır.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: r.gapMd),
          Row(
            children: [
              Expanded(
                child: _InlineNumber(
                  label: 'Vücut ağırlığı',
                  unit: 'kg',
                  value: settings.bodyWeightKg,
                  onChanged: (v) => ref
                      .read(clinicalSettingsProvider.notifier)
                      .setBodyWeight(v),
                ),
              ),
              SizedBox(width: r.gapSm),
              Expanded(
                child: _InlineNumber(
                  label: 'Kuru ağırlık',
                  unit: 'kg',
                  value: settings.dryWeightKg,
                  onChanged: (v) => ref
                      .read(clinicalSettingsProvider.notifier)
                      .setDryWeight(v),
                ),
              ),
            ],
          ),
          SizedBox(height: r.gapMd),
          LabeledField(
            label: 'Durum',
            child: ChipSelector<TreatmentMode>(
              options: TreatmentMode.values,
              selected: settings.treatmentMode,
              labelOf: (m) => m.labelTr,
              onSelected: (m) => ref
                  .read(clinicalSettingsProvider.notifier)
                  .setTreatmentMode(m),
            ),
          ),
          if (settings.treatmentMode.isDialysis)
            SwitchListTile.adaptive(
              value: settings.hasResidualUrine,
              onChanged: (v) => ref
                  .read(clinicalSettingsProvider.notifier)
                  .setResidualUrine(v),
              title: const Text('Rezidüel idrar çıkışı var'),
              subtitle: const Text(
                'Kapalıysa "idrar azaldı" alarmı devre dışıdır.',
              ),
              contentPadding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}

class _InlineNumber extends StatefulWidget {
  const _InlineNumber({
    required this.label,
    required this.unit,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String unit;
  final double? value;
  final ValueChanged<double?> onChanged;

  @override
  State<_InlineNumber> createState() => _InlineNumberState();
}

class _InlineNumberState extends State<_InlineNumber> {
  late final TextEditingController _c = TextEditingController(
    text: widget.value?.toStringAsFixed(1) ?? '',
  );

  @override
  void didUpdateWidget(_InlineNumber old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      final text = widget.value?.toStringAsFixed(1) ?? '';
      if (_c.text != text) _c.text = text;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: widget.label,
      child: NumberField(
        controller: _c,
        suffix: widget.unit,
        hintText: '—',
        onChanged: (v) => widget.onChanged(parseLocaleNumber(v)),
      ),
    );
  }
}

/// Tek bir klinik değer kartı.
class ClinicalValueTile extends ConsumerStatefulWidget {
  const ClinicalValueTile({
    required this.definition,
    required this.settings,
    this.readOnly = false,
    super.key,
  });

  final ClinicalDefinition definition;
  final ClinicalSettings settings;

  /// Kurulum sırasında yalnız önizleme.
  final bool readOnly;

  @override
  ConsumerState<ClinicalValueTile> createState() => _ClinicalValueTileState();
}

class _ClinicalValueTileState extends ConsumerState<ClinicalValueTile> {
  bool _expanded = false;
  bool _editing = false;

  final _value = TextEditingController();
  final _min = TextEditingController();
  final _max = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _value.dispose();
    _min.dispose();
    _max.dispose();
    _note.dispose();
    super.dispose();
  }

  void _startEditing(ResolvedValue r) {
    final d = widget.definition.decimals;
    _value.text = r.value?.toStringAsFixed(d) ?? '';
    _min.text = r.min?.toStringAsFixed(d) ?? '';
    _max.text = r.max?.toStringAsFixed(d) ?? '';
    _note.text = r.noteTr ?? '';
    setState(() {
      _editing = true;
      _expanded = true;
    });
  }

  Future<void> _save() async {
    final def = widget.definition;
    final notifier = ref.read(clinicalSettingsProvider.notifier);

    await notifier.setOverride(
      def.key,
      ClinicalOverride(
        value: def.shape == ValueShape.single
            ? parseLocaleNumber(_value.text)
            : null,
        min: def.shape == ValueShape.range
            ? parseLocaleNumber(_min.text)
            : null,
        max: def.shape == ValueShape.range
            ? parseLocaleNumber(_max.text)
            : null,
      ),
      noteTr: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    ref.invalidate(clinicalHistoryProvider(def.key));
    if (mounted) setState(() => _editing = false);
  }

  Future<void> _clear() async {
    await ref
        .read(clinicalSettingsProvider.notifier)
        .setOverride(
          widget.definition.key,
          const ClinicalOverride(isCleared: true),
          noteTr: 'Bilerek boş bırakıldı (limit yok)',
        );
    ref.invalidate(clinicalHistoryProvider(widget.definition.key));
    if (mounted) setState(() => _editing = false);
  }

  Future<void> _reset() async {
    await ref
        .read(clinicalSettingsProvider.notifier)
        .resetToDefault(widget.definition.key);
    ref.invalidate(clinicalHistoryProvider(widget.definition.key));
    if (mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.definition;
    final resolved = widget.settings.resolveDefinition(def);
    final p = context.palette;
    final r = Responsive.fromContext(context);

    final absolute = def.perKgBodyWeight
        ? (def.shape == ValueShape.range
            ? widget.settings.dailyAbsoluteRange(def.key)
            : null)
        : null;
    final absoluteSingle = def.perKgBodyWeight && def.shape == ValueShape.single
        ? widget.settings.dailyAbsolute(def.key)
        : null;

    return NeuCard(
      padding: EdgeInsets.all(r.gapMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- başlık satırı ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.labelTr,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: r.s(2)),
                    Text(
                      def.unit,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // SENİN DEĞERİN — özelleştirilmişse vurgulu.
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: r.gapSm,
                      vertical: r.s(5),
                    ),
                    decoration: BoxDecoration(
                      color: resolved.isCustom
                          ? p.primary
                          : p.backgroundDeep.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: resolved.isCustom ? p.primary : p.divider,
                        width: resolved.isCustom ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      resolved.formatted(),
                      style: AppTypography.numeric(p, size: r.s(17)).copyWith(
                        color: resolved.isCustom
                            ? p.onPrimary
                            : p.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(height: r.s(4)),
                  Text(
                    resolved.isCustom ? 'senin değerin' : 'varsayılan',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: resolved.isCustom ? p.primary : p.textMuted,
                          fontWeight:
                              resolved.isCustom ? FontWeight.w700 : null,
                        ),
                  ),
                ],
              ),
            ],
          ),

          // --- hesaplanan mutlak değer ---
          if (absoluteSingle != null || absolute != null) ...[
            SizedBox(height: r.gapSm),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(r.gapSm),
              decoration: BoxDecoration(
                color: p.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                absoluteSingle != null
                    ? 'Günlük hedef: '
                        '${absoluteSingle.toStringAsFixed(0)} g '
                        '(${resolved.formatted()} × '
                        '${widget.settings.bodyWeightKg?.toStringAsFixed(1)} kg)'
                    : 'Günlük hedef: '
                        '${absolute!.min.toStringAsFixed(0)}'
                        '-${absolute.max.toStringAsFixed(0)} kcal',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: p.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],

          SizedBox(height: r.gapSm),
          Row(
            children: [
              Flexible(
                child: VerificationChip(
                  verification: def.verification,
                  dense: true,
                ),
              ),
              const Spacer(),
              if (!widget.readOnly)
                Flexible(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    icon: Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _expanded ? 'Kapat' : 'Referans & düzenle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),

          // --- genişletilmiş kısım ---
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _expandedContent(context, resolved),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: context.motionDuration,
            sizeCurve: Curves.easeOutCubic,
          ),

          if (widget.readOnly) ...[
            SizedBox(height: r.gapSm),
            Text(
              'Referans: ${def.referenceTextTr}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: r.gapXs),
            SourceFootnote(sourceIds: def.sourceIds),
          ],
        ],
      ),
    );
  }

  Widget _expandedContent(BuildContext context, ResolvedValue resolved) {
    final def = widget.definition;
    final p = context.palette;
    final r = Responsive.fromContext(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: r.gapSm),
        Divider(color: p.divider),
        SizedBox(height: r.gapSm),

        // --- REFERANS DEĞER ---
        Text(
          'Referans değer',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: p.accent,
              ),
        ),
        SizedBox(height: r.gapXs),
        Text(
          def.referenceTextTr,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: r.gapXs),
        Text(
          def.verification.explanationTr,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
        ),
        SizedBox(height: r.gapSm),
        SourceFootnote(
          sourceIds: def.sourceIds,
          onTap: () => context.push(Routes.sources),
        ),

        if (def.helpTr != null) ...[
          SizedBox(height: r.gapSm),
          Container(
            padding: EdgeInsets.all(r.gapSm),
            decoration: BoxDecoration(
              color: p.accentSoft.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              def.helpTr!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],

        if (def.triggersEmergencySms) ...[
          SizedBox(height: r.gapSm),
          Row(
            children: [
              Icon(Icons.sms_outlined, size: r.s(15), color: p.danger),
              SizedBox(width: r.gapXs),
              Expanded(
                child: Text(
                  'Bu eşik aşıldığında acil kişilere otomatik SMS '
                  'gönderilebilir (ayrı bir ayarla açılır, '
                  'varsayılan kapalı).',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ],

        SizedBox(height: r.gapMd),

        // --- DÜZENLEME ---
        if (!_editing)
          Row(
            children: [
              Expanded(
                child: NeuButton(
                  label: 'Değiştir',
                  icon: Icons.edit_outlined,
                  compact: true,
                  expanded: true,
                  onPressed: () => _startEditing(resolved),
                ),
              ),
              SizedBox(width: r.gapSm),
              if (resolved.isCustom)
                Expanded(
                  child: NeuButton(
                    label: 'Varsayılana dön',
                    icon: Icons.restart_alt_rounded,
                    filled: false,
                    compact: true,
                    expanded: true,
                    onPressed: _reset,
                  ),
                ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (def.shape == ValueShape.single)
                LabeledField(
                  label: 'Senin değerin',
                  hint: 'Boş bırakırsan varsayılan kullanılır.',
                  child: NumberField(
                    controller: _value,
                    suffix: def.unit,
                    hintText: def.defaultValue
                            ?.toStringAsFixed(def.decimals) ??
                        'belirtilmedi',
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: LabeledField(
                        label: 'Alt',
                        child: NumberField(
                          controller: _min,
                          hintText: def.defaultMin
                                  ?.toStringAsFixed(def.decimals) ??
                              '—',
                        ),
                      ),
                    ),
                    SizedBox(width: r.gapSm),
                    Expanded(
                      child: LabeledField(
                        label: 'Üst',
                        child: NumberField(
                          controller: _max,
                          hintText: def.defaultMax
                                  ?.toStringAsFixed(def.decimals) ??
                              '—',
                        ),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: r.gapMd),
              LabeledField(
                label: 'Not (isteğe bağlı)',
                hint: 'Neden bu değeri seçtin? Geçmişte görünür.',
                child: TextField(
                  controller: _note,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Örn. son tahlile göre düşürdüm',
                  ),
                ),
              ),
              SizedBox(height: r.gapMd),
              Row(
                children: [
                  Expanded(
                    child: NeuButton(
                      label: 'Kaydet',
                      icon: Icons.check_rounded,
                      compact: true,
                      expanded: true,
                      onPressed: _save,
                    ),
                  ),
                  SizedBox(width: r.gapSm),
                  Expanded(
                    child: NeuButton(
                      label: 'Vazgeç',
                      filled: false,
                      compact: true,
                      expanded: true,
                      onPressed: () => setState(() => _editing = false),
                    ),
                  ),
                ],
              ),
              SizedBox(height: r.gapSm),
              TextButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.block_outlined, size: 17),
                label: Text(
                  def.key == 'fluid_ml'
                      ? 'Limit yok olarak işaretle'
                      : 'Bilerek boş bırak',
                ),
              ),
            ],
          ),

        // --- DEĞİŞİKLİK GEÇMİŞİ ---
        SizedBox(height: r.gapSm),
        _HistorySection(valueKey: def.key),
      ],
    );
  }
}

class _HistorySection extends ConsumerWidget {
  const _HistorySection({required this.valueKey});

  final String valueKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(clinicalHistoryProvider(valueKey));
    final r = Responsive.fromContext(context);
    final p = context.palette;

    return history.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text(
        'Geçmiş okunamadı: $e',
        style: Theme.of(context).textTheme.labelSmall,
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return Text(
            'Değişiklik geçmişi yok.',
            style: Theme.of(context).textTheme.labelSmall,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Değişiklik geçmişi (${rows.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: r.gapXs),
            for (final row in rows.take(6))
              Padding(
                padding: EdgeInsets.only(bottom: r.gapXs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.history_rounded, size: 13, color: p.textMuted),
                    SizedBox(width: r.gapXs),
                    Expanded(
                      child: Text(
                        '${_fmt(row.changedAt)} · '
                        '${row.oldText ?? "—"} → ${row.newText ?? "—"}'
                        '${row.note == null ? "" : "\n${row.note}"}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

extension on BuildContext {
  Duration get motionDuration {
    final media = MediaQuery.maybeOf(this);
    return (media?.disableAnimations ?? false)
        ? Duration.zero
        : const Duration(milliseconds: 260);
  }
}
