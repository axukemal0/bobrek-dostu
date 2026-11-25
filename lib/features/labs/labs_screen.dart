import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../clinical/definitions.dart';
import '../../clinical/settings.dart';
import '../../clinical/evaluator.dart';
import '../../core/config/ai_config.dart';
import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/scanner_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/responsive.dart';
import '../../core/widgets/trend_chart.dart';
import '../emergency/alert_dispatcher.dart';
import '../home/home_screen.dart' show showPermissionDialog;

class LabsScreen extends ConsumerWidget {
  const LabsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final labsAsync = ref.watch(labResultsProvider);
    final settings = ref.watch(clinicalSettingsProvider);

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(title: const Text('Laboratuvar')),
      floatingActionButtonLocation:
          ShellFabLocation(BottomBarInset.of(context)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tahlil ekle'),
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
      ),
      body: SafeArea(
        child: labsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Okunamadı: $e')),
          data: (labs) {
            if (labs.isEmpty) {
              return PageBody(
                children: [
                  const EmptyState(
                    title: 'Henüz tahlil yok',
                    message: 'Tahlil sonuçlarını elle girebilir ya da '
                        'tahlil kağıdının fotoğrafını çekip okutabilirsin. '
                        'Okunan her değeri kaydetmeden önce onaylarsın.',
                    icon: Icons.science_outlined,
                  ),
                ],
              );
            }

            // Analite göre grupla.
            final grouped = <String, List<LabResultRow>>{};
            for (final l in labs) {
              grouped.putIfAbsent(l.analyteLabel, () => []).add(l);
            }

            return PageBody(
              children: [
                for (final entry in grouped.entries)
                  _AnalyteCard(
                    label: entry.key,
                    results: entry.value,
                    settings: settings,
                  ),
                NeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hedef aralıklar nasıl belirleniyor?',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      SizedBox(height: r.gapSm),
                      Text(
                        'Varsayılan olarak KENDİ LABORATUVARININ '
                        'referans aralığı kullanılır — tahlil girerken '
                        'aralığı da yazabilirsin. Kılavuzun sayı verdiği '
                        'değerlerde (hemoglobin, ferritin, TSAT, eGFR) '
                        'kılavuz aralığı gösterilir ve kaynağı yazar. '
                        'Hepsini Klinik Ayarlar\'dan değiştirebilirsin.',
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
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _AddLabSheet(),
    );
  }
}

class _AnalyteCard extends ConsumerWidget {
  const _AnalyteCard({
    required this.label,
    required this.results,
    required this.settings,
  });

  final String label;
  final List<LabResultRow> results;
  final ClinicalSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final sorted = [...results]
      ..sort((a, b) => a.takenAt.compareTo(b.takenAt));
    final latest = sorted.last;

    // Hedef aralığı: kullanıcının lab aralığı > klinik tanım.
    final def = definitionByKey(latest.analyte);
    final resolved = def == null ? null : settings.resolveDefinition(def);
    final refMin = latest.refMin ?? resolved?.min;
    final refMax = latest.refMax ?? resolved?.max;

    // Potasyum için kademeli değerlendirme.
    Alert? alert;
    if (latest.analyte == 'lab_potassium') {
      alert = evaluateSerumPotassium(
        mEqPerL: latest.value,
        settings: settings,
      );
    }

    final outOfRange = (refMin != null && latest.value < refMin) ||
        (refMax != null && latest.value > refMax);

    return NeuCard(
      margin: EdgeInsets.only(bottom: r.gapMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${results.length} kayıt · son '
                      '${_fmt(latest.takenAt)}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${latest.value} ${latest.unit}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          color: outOfRange ? p.warning : p.textPrimary,
                        ),
                  ),
                  if (refMin != null || refMax != null)
                    Text(
                      'aralık '
                      '${refMin?.toStringAsFixed(1) ?? "—"}'
                      '-${refMax?.toStringAsFixed(1) ?? "—"}',
                      style: Theme.of(context).textTheme.labelSmall,
                    )
                  else
                    Text(
                      'aralık girilmedi',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: r.gapSm),
          TrendSummary(
            points: [
              for (final l in sorted) (at: l.takenAt, value: l.value),
            ],
            unit: latest.unit,
            decimals: 1,
          ),
          if (sorted.length >= 2) ...[
            SizedBox(height: r.gapSm),
            TrendChart(
              points: [
                for (final l in sorted) (at: l.takenAt, value: l.value),
              ],
              unit: latest.unit,
              refMin: refMin,
              refMax: refMax,
              height: r.s(200),
            ),
          ],
          if (alert != null && alert.level != AlertLevel.none) ...[
            SizedBox(height: r.gapSm),
            AlertCard(
              alert: alert,
              onSourceTap: () => context.push(Routes.sources),
            ),
          ],
          if (def != null) ...[
            SizedBox(height: r.gapSm),
            Row(
              children: [
                VerificationChip(
                  verification: def.verification,
                  dense: true,
                ),
                SizedBox(width: r.gapSm),
                Expanded(
                  child: SourceFootnote(
                    sourceIds: def.sourceIds,
                    onTap: () => context.push(Routes.sources),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: r.gapSm),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              'Tüm kayıtlar',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            children: [
              for (final l in sorted.reversed)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${l.value} ${l.unit}'),
                  subtitle: Text(
                    [
                      _fmt(l.takenAt),
                      if (l.labName != null) l.labName!,
                      if (l.origin == 'ocr') 'fotoğraftan okundu',
                      if (l.note != null) l.note!,
                    ].join(' · '),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  trailing: TapIcon(
                    icon: Icons.delete_outline_rounded,
                    semanticLabel: 'Kaydı sil',
                    onPressed: () async {
                      final db = ref.read(databaseProvider);
                      await (db.delete(db.labResultRows)
                            ..where((t) => t.id.equals(l.id)))
                          .go();
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';
}

// ===========================================================================
// TAHLİL EKLEME (elle + OCR + AI)
// ===========================================================================
class _AddLabSheet extends ConsumerStatefulWidget {
  const _AddLabSheet();

  @override
  ConsumerState<_AddLabSheet> createState() => _AddLabSheetState();
}

class _AddLabSheetState extends ConsumerState<_AddLabSheet> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final p = context.palette;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              r.pagePadding,
              r.gapMd,
              r.pagePadding,
              r.gapSm,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tahlil ekle',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    TapIcon(
                      icon: Icons.close_rounded,
                      semanticLabel: 'Kapat',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: r.gapSm),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Elle gir')),
                    ButtonSegment(value: 1, label: Text('Fotoğraftan')),
                  ],
                  selected: {_tab},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: p.divider),
          Expanded(
            child: _tab == 0
                ? const _ManualLabTab()
                : const _OcrLabTab(),
          ),
        ],
      ),
    );
  }
}

class _ManualLabTab extends ConsumerStatefulWidget {
  const _ManualLabTab();

  @override
  ConsumerState<_ManualLabTab> createState() => _ManualLabTabState();
}

class _ManualLabTabState extends ConsumerState<_ManualLabTab> {
  String? _analyteKey;
  final _customName = TextEditingController();
  final _value = TextEditingController();
  final _unit = TextEditingController();
  final _refMin = TextEditingController();
  final _refMax = TextEditingController();
  final _labName = TextEditingController();
  DateTime _takenAt = DateTime.now();

  @override
  void dispose() {
    for (final c in [
      _customName, _value, _unit, _refMin, _refMax, _labName,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _selectAnalyte(String key) {
    final def = definitionByKey(key);
    setState(() {
      _analyteKey = key;
      if (def != null) {
        _unit.text = def.unit;
        _refMin.text = def.defaultMin?.toStringAsFixed(def.decimals) ?? '';
        _refMax.text = def.defaultMax?.toStringAsFixed(def.decimals) ?? '';
      }
    });
  }

  Future<void> _save() async {
    final value = parseLocaleNumber(_value.text);
    if (value == null) return;
    final def = _analyteKey == null ? null : definitionByKey(_analyteKey!);
    final label = def?.labelTr ??
        (_customName.text.trim().isEmpty
            ? 'Tahlil'
            : _customName.text.trim());

    final db = ref.read(databaseProvider);
    await db.into(db.labResultRows).insert(
          LabResultRowsCompanion.insert(
            analyte: _analyteKey ?? 'custom_${normalizeKey(label)}',
            analyteLabel: label,
            value: value,
            unit: _unit.text.trim().isEmpty ? '' : _unit.text.trim(),
            refMin: Value(parseLocaleNumber(_refMin.text)),
            refMax: Value(parseLocaleNumber(_refMax.text)),
            labName: Value(
              _labName.text.trim().isEmpty ? null : _labName.text.trim(),
            ),
            takenAt: _takenAt,
          ),
        );

    // Serum potasyum kritik kademedeyse uyarı göster ve (ayar açıksa)
    // acil kişilere haber ver.
    if (mounted && _analyteKey == 'lab_potassium') {
      await evaluateAndDispatchAlerts(
        context: context,
        ref: ref,
        serumPotassium: value,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  static String normalizeKey(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final def = _analyteKey == null ? null : definitionByKey(_analyteKey!);

    return SingleChildScrollView(
      padding: EdgeInsets.all(r.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(
            label: 'Hangi tahlil?',
            child: Wrap(
              spacing: r.gapSm,
              runSpacing: r.gapSm,
              children: [
                for (final d in kLabTargets)
                  ChoiceChip(
                    label: Text(d.labelTr),
                    selected: _analyteKey == d.key,
                    onSelected: (_) => _selectAnalyte(d.key),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 10,
                    ),
                  ),
                ChoiceChip(
                  label: const Text('Diğer'),
                  selected: _analyteKey == null,
                  onSelected: (_) => setState(() => _analyteKey = null),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 10,
                  ),
                ),
              ],
            ),
          ),
          if (_analyteKey == null) ...[
            SizedBox(height: r.gapMd),
            TextField(
              controller: _customName,
              decoration: const InputDecoration(
                labelText: 'Tahlil adı',
                hintText: 'Örn. CRP',
              ),
            ),
          ],
          if (def != null) ...[
            SizedBox(height: r.gapMd),
            NeuCard(
              color: context.palette.primarySoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Referans',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Flexible(
                        child: VerificationChip(
                          verification: def.verification,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.gapXs),
                  Text(
                    def.referenceTextTr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: r.gapXs),
                  SourceFootnote(sourceIds: def.sourceIds),
                ],
              ),
            ),
          ],
          SizedBox(height: r.gapMd),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: LabeledField(
                  label: 'Sonuç',
                  child: NumberField(
                    controller: _value,
                    hintText: '0,0',
                  ),
                ),
              ),
              SizedBox(width: r.gapSm),
              Expanded(
                child: LabeledField(
                  label: 'Birim',
                  child: TextField(
                    controller: _unit,
                    decoration: const InputDecoration(hintText: 'mg/dL'),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: r.gapMd),
          LabeledField(
            label: 'Laboratuvarının referans aralığı',
            hint: 'Tahlil kağıdında yazan aralık. Girersen grafikte '
                'bu aralık gölgelenir ve hedef olarak bu kullanılır.',
            child: Row(
              children: [
                Expanded(
                  child: NumberField(
                    controller: _refMin,
                    hintText: 'alt',
                  ),
                ),
                SizedBox(width: r.gapSm),
                Expanded(
                  child: NumberField(
                    controller: _refMax,
                    hintText: 'üst',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: r.gapMd),
          LabeledField(
            label: 'Tarih',
            child: NeuButton(
              label: '${_takenAt.day.toString().padLeft(2, '0')}.'
                  '${_takenAt.month.toString().padLeft(2, '0')}.'
                  '${_takenAt.year}',
              icon: Icons.calendar_today_outlined,
              filled: false,
              expanded: true,
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _takenAt,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _takenAt = picked);
              },
            ),
          ),
          SizedBox(height: r.gapMd),
          TextField(
            controller: _labName,
            decoration: const InputDecoration(
              labelText: 'Laboratuvar / hastane (isteğe bağlı)',
            ),
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
    );
  }
}

/// Tahlil kağıdından okuma: önce cihaz üstü OCR, isteğe bağlı AI.
class _OcrLabTab extends ConsumerStatefulWidget {
  const _OcrLabTab();

  @override
  ConsumerState<_OcrLabTab> createState() => _OcrLabTabState();
}

class _OcrLabTabState extends ConsumerState<_OcrLabTab> {
  File? _image;
  bool _busy = false;
  String? _statusTr;
  List<ParsedLabValue> _parsed = const [];
  final Set<int> _selected = {};
  String? _aiRaw;
  DateTime _takenAt = DateTime.now();

  Future<void> _capture() async {
    final service = ref.read(permissionServiceProvider);
    if (await service.status(AppPermission.camera) !=
        AppPermissionStatus.granted) {
      if (!mounted) return;
      final ok = await showPermissionDialog(
        context,
        permissionInfo(AppPermission.camera),
      );
      if (!ok) return;
      if (await service.request(AppPermission.camera) !=
          AppPermissionStatus.granted) {
        return;
      }
    }

    final file = await ref
        .read(scannerServiceProvider)
        .captureFromCamera(maxWidth: 2000);
    if (file == null || !mounted) return;
    setState(() {
      _image = file;
      _parsed = const [];
      _selected.clear();
      _aiRaw = null;
    });
    await _runOcr();
  }

  Future<void> _runOcr() async {
    final image = _image;
    if (image == null) return;
    setState(() {
      _busy = true;
      _statusTr = 'Metin okunuyor (telefonun içinde)…';
    });
    try {
      final result =
          await ref.read(scannerServiceProvider).recognizeText(image);
      final parsed = parseLabLines(result.lines);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _parsed = parsed;
        _selected
          ..clear()
          ..addAll(List.generate(parsed.length, (i) => i));
        _statusTr = parsed.isEmpty
            ? 'Tanıdığım bir tahlil değeri bulamadım. '
                'Daha net bir fotoğraf dene ya da "Yapay zekaya okut" '
                'seçeneğini kullan.'
            : null;
      });
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _statusTr = 'Okuma başarısız: $e';
        });
      }
    }
  }

  Future<void> _runAi() async {
    final image = _image;
    if (image == null) return;

    final consent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tahlil fotoğrafı yapay zekaya gönderilecek'),
        content: const Text(
          'Bu fotoğraf Anthropic Claude API sunucusuna gönderilecek. '
          'Fotoğrafta adın ve TC kimlik numaran yazıyor olabilir — '
          'göndermeden önce bu alanları parmağınla kapatarak yeniden '
          'çekebilirsin.\n\n'
          'Yapay zeka yalnızca değerleri OKUR, yorumlamaz. '
          'Okunan her değeri kaydetmeden önce onaylarsın.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
    if (consent != true) return;

    setState(() {
      _busy = true;
      _statusTr = 'Yapay zeka okuyor…';
    });
    try {
      final prompt =
          ref.read(aiPromptBuilderProvider).buildLabVisionPrompt();
      final model =
          ref.read(preferencesProvider).aiModel ?? AiConfig.defaultModel;
      final reply = await ref.read(aiServiceProvider).sendVision(
            systemPrompt: prompt,
            userText: 'Bu tahlil raporundaki değerleri oku.',
            image: image,
            model: model,
          );
      // "Analit | değer | birim | aralık" satırlarını çöz.
      final parsed = <ParsedLabValue>[];
      for (final line in reply.text.split('\n')) {
        final parts = line.split('|').map((s) => s.trim()).toList();
        if (parts.length < 3) continue;
        final value = parseLocaleNumber(parts[1]);
        if (value == null) continue;
        double? min;
        double? max;
        if (parts.length >= 4) {
          final m = RegExp(r'(\d+[.,]?\d*)\s*[-–]\s*(\d+[.,]?\d*)')
              .firstMatch(parts[3]);
          if (m != null) {
            min = parseLocaleNumber(m.group(1));
            max = parseLocaleNumber(m.group(2));
          }
        }
        // Bilinen analitle eşleştir.
        String? key;
        final norm = parts[0].toLowerCase();
        for (final e in kLabAliases.entries) {
          if (norm.contains(e.key)) {
            key = e.value.key;
            break;
          }
        }
        parsed.add(
          ParsedLabValue(
            rawLine: line,
            analyteLabel: parts[0],
            analyteKey: key,
            value: value,
            unit: parts[2],
            refMin: min,
            refMax: max,
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _aiRaw = reply.text;
        _parsed = parsed;
        _selected
          ..clear()
          ..addAll(List.generate(parsed.length, (i) => i));
        _statusTr = parsed.isEmpty
            ? 'Yapay zeka da okunabilir değer bulamadı.'
            : null;
      });
    } on AiFailure catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _statusTr = e.messageTr;
        });
      }
    }
  }

  Future<void> _saveSelected() async {
    final db = ref.read(databaseProvider);
    for (final i in _selected) {
      final v = _parsed[i];
      await db.into(db.labResultRows).insert(
            LabResultRowsCompanion.insert(
              analyte: v.analyteKey ??
                  'custom_${v.analyteLabel.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]+"), "_")}',
              analyteLabel: v.analyteLabel,
              value: v.value,
              unit: v.unit,
              refMin: Value(v.refMin),
              refMax: Value(v.refMax),
              origin: const Value('ocr'),
              confirmedByUser: const Value(true),
              note: const Value('Fotoğraftan okundu, kullanıcı onayladı'),
              takenAt: _takenAt,
            ),
          );
    }

    // Okunan değerler arasında serum potasyum varsa eşiği değerlendir.
    final potassium = _selected
        .map((i) => _parsed[i])
        .where((v) => v.analyteKey == 'lab_potassium')
        .firstOrNull;
    if (mounted && potassium != null) {
      await evaluateAndDispatchAlerts(
        context: context,
        ref: ref,
        serumPotassium: potassium.value,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final p = context.palette;
    final conn = ref.watch(aiConnectionProvider).value;

    return SingleChildScrollView(
      padding: EdgeInsets.all(r.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                _image!,
                height: r.s(170),
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          if (_image != null) SizedBox(height: r.gapMd),
          NeuButton(
            label: _busy
                ? 'İşleniyor…'
                : (_image == null
                    ? 'Tahlil kağıdını çek'
                    : 'Yeniden çek'),
            icon: Icons.document_scanner_outlined,
            expanded: true,
            onPressed: _busy ? null : _capture,
          ),
          if (_image != null && conn == AiConnectionState.ok) ...[
            SizedBox(height: r.gapSm),
            NeuButton(
              label: 'Yapay zekaya okut (daha iyi sonuç)',
              icon: Icons.auto_awesome_rounded,
              tone: NeuTone.accent,
              filled: false,
              expanded: true,
              onPressed: _busy ? null : _runAi,
            ),
          ],
          SizedBox(height: r.gapSm),
          Text(
            kOcrDisclaimerTr,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          if (_statusTr != null) ...[
            SizedBox(height: r.gapMd),
            NeuCard(
              color: p.accentSoft.withValues(alpha: 0.5),
              child: Text(
                _statusTr!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          if (_parsed.isNotEmpty) ...[
            SizedBox(height: r.gapLg),
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Bulunan değerleri onayla (${_parsed.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: r.gapXs),
                  Text(
                    'Yanlış okunanı işaretini kaldırarak atlayabilirsin. '
                    'Kaydettikten sonra her değeri elle düzeltebilirsin.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: r.gapSm),
                  for (final e in _parsed.indexed)
                    CheckboxListTile(
                      value: _selected.contains(e.$1),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _selected.add(e.$1);
                        } else {
                          _selected.remove(e.$1);
                        }
                      }),
                      title: Text(
                        '${e.$2.analyteLabel}: '
                        '${e.$2.value} ${e.$2.unit}',
                      ),
                      subtitle: Text(
                        [
                          if (e.$2.refMin != null && e.$2.refMax != null)
                            'aralık ${e.$2.refMin}-${e.$2.refMax}',
                          'ham: ${e.$2.rawLine}',
                        ].join(' · '),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  SizedBox(height: r.gapMd),
                  LabeledField(
                    label: 'Tahlil tarihi',
                    child: NeuButton(
                      label: '${_takenAt.day.toString().padLeft(2, '0')}.'
                          '${_takenAt.month.toString().padLeft(2, '0')}.'
                          '${_takenAt.year}',
                      icon: Icons.calendar_today_outlined,
                      filled: false,
                      compact: true,
                      expanded: true,
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _takenAt,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _takenAt = picked);
                        }
                      },
                    ),
                  ),
                  SizedBox(height: r.gapMd),
                  NeuButton(
                    label: '${_selected.length} değeri kaydet',
                    icon: Icons.check_rounded,
                    expanded: true,
                    onPressed:
                        _selected.isEmpty ? null : _saveSelected,
                  ),
                ],
              ),
            ),
          ],
          if (_aiRaw != null) ...[
            SizedBox(height: r.gapMd),
            ExpansionTile(
              title: Text(
                'Yapay zekanın ham yanıtı',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(r.gapSm),
                  child: Text(
                    _aiRaw!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
