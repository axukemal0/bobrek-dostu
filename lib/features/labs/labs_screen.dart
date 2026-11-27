import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' hide Text;

import '../../clinical/definitions.dart';
import '../../clinical/settings.dart';
import '../../clinical/evaluator.dart';
import '../../core/config/ai_config.dart';
import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/document_intake.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/scanner_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/responsive.dart';
import '../../core/widgets/trend_chart.dart';
import '../emergency/alert_dispatcher.dart';
import '../home/home_screen.dart' show showPermissionDialog;
import '../../core/i18n/text.dart';

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
      floatingActionButton: SectionFab(
        label: 'Tahlil ekle',
        tone: p.accents.lab,
        onPressed: () => _showAddSheet(context),
      ),
      body: SafeArea(
        child: labsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Okunamadı: $e')),
          data: (labs) {
            if (labs.isEmpty) {
              return PageBody(
                hasFab: true,
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
              hasFab: true,
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
// TAHLİL EKLEME
// ===========================================================================
//
// Eski kurulum tek bir alt sayfada "Elle gir / Fotoğraftan" sekmeleri
// gösteriyordu: kullanıcı daha ne yapacağını seçmeden analit çipleri,
// referans kartı, birim ve aralık alanlarıyla karşılaşıyordu. Uzman
// olmayan biri için bu ekran okunmuyordu bile.
//
// Yeni akış İKİ ADIM: önce "nasıl ekleyeceksin" (üç büyük seçenek),
// sonra yalnız o yolun alanları. Fotoğraf ve dosya yolunda okunan her
// değer DÜZENLENEBİLİR — okuma yanılabilir, kullanıcı düzeltebilmeli.

/// Tahlil eklemenin üç yolu.
enum _LabMethod { manual, camera, file }

class _AddLabSheet extends ConsumerStatefulWidget {
  const _AddLabSheet();

  @override
  ConsumerState<_AddLabSheet> createState() => _AddLabSheetState();
}

class _AddLabSheetState extends ConsumerState<_AddLabSheet> {
  _LabMethod? _method;

  String get _titleTr => switch (_method) {
        null => 'Tahlil ekle',
        _LabMethod.manual => 'Elle gir',
        _LabMethod.camera => 'Fotoğraftan oku',
        _LabMethod.file => 'Dosyadan oku',
      };

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final p = context.palette;
    final motion = context.motion;

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
            child: Row(
              children: [
                if (_method != null)
                  TapIcon(
                    icon: Icons.arrow_back_rounded,
                    semanticLabel: 'Yöntem seçimine dön',
                    onPressed: () => setState(() => _method = null),
                  ),
                Expanded(
                  child: Text(
                    _titleTr,
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
          ),
          Divider(height: 1, color: p.divider),
          Expanded(
            child: AnimatedSwitcher(
              duration: motion.normal,
              switchInCurve: motion.enter,
              switchOutCurve: motion.exit,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.06, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: switch (_method) {
                null => _LabMethodChooser(
                    key: const ValueKey('chooser'),
                    onPick: (m) => setState(() => _method = m),
                  ),
                _LabMethod.manual =>
                  const _ManualLabTab(key: ValueKey('manual')),
                _LabMethod.camera => const _ReaderLabTab(
                    key: ValueKey('camera'),
                    startWithCamera: true,
                  ),
                _LabMethod.file => const _ReaderLabTab(
                    key: ValueKey('file'),
                    startWithCamera: false,
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Birinci adım: "nasıl ekleyeceksin?"
class _LabMethodChooser extends ConsumerWidget {
  const _LabMethodChooser({required this.onPick, super.key});

  final ValueChanged<_LabMethod> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = Responsive.fromContext(context);
    final p = context.palette;
    final conn = ref.watch(aiConnectionProvider).value;
    final aiReady = conn == AiConnectionState.ok;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.all(r.pagePadding),
      children: [
        Text(
          'Sonuçları nasıl eklemek istersin?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: r.gapXs),
        Text(
          'Üçü de aynı yere kaydeder. Okutursan değerleri kaydetmeden '
          'önce tek tek düzeltebilirsin.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SizedBox(height: r.gapLg),
        _MethodCard(
          icon: Icons.keyboard_alt_outlined,
          tone: p.accents.lab,
          title: 'Elle gir',
          subtitle: 'Tahlil kağıdına bakarak yaz. En güvenilir yol; '
              'internet gerekmez.',
          onTap: () => onPick(_LabMethod.manual),
        ),
        SizedBox(height: r.gapMd),
        _MethodCard(
          icon: Icons.photo_camera_outlined,
          tone: p.accents.activity,
          title: 'Fotoğrafını çek',
          subtitle: 'Kağıdı çek, uygulama okusun. Okuma telefonun '
              'içinde yapılır, fotoğraf internete gitmez.',
          onTap: () => onPick(_LabMethod.camera),
        ),
        SizedBox(height: r.gapMd),
        _MethodCard(
          icon: Icons.folder_open_outlined,
          tone: p.accents.appointment,
          title: 'Dosyadan ekle',
          subtitle: aiReady
              ? 'Hastaneden gelen PDF ya da kayıtlı görsel. PDF yalnız '
                  'yapay zekayla okunabilir ve göndermeden önce onay '
                  'istenir.'
              : 'Kayıtlı görseli telefonun içinde okur. PDF için yapay '
                  'zeka bağlantısı gerekir (Ayarlar > Yapay Zeka).',
          onTap: () => onPick(_LabMethod.file),
        ),
        SizedBox(height: r.gapLg),
        Text(
          kOcrDisclaimerTr,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color tone;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final p = context.palette;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        radius: 18,
        child: NeuCard(
          color: p.accentFill(tone, opacity: p.isDark ? 0.13 : 0.08),
          padding: EdgeInsets.all(r.gapMd),
          child: Row(
            children: [
              AccentTile(icon: icon, color: tone, size: r.s(24)),
              SizedBox(width: r.gapMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: tone),
                    ),
                    SizedBox(height: r.s(3)),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              SizedBox(width: r.gapSm),
              Icon(
                Icons.chevron_right_rounded,
                color: p.textMuted,
                size: r.s(22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FOTOĞRAF / DOSYA İLE OKUMA + DÜZENLENEBİLİR ONAY LİSTESİ
// ---------------------------------------------------------------------------

/// Okunan tek bir satır — alanların HEPSİ düzenlenebilir.
///
/// Önceki sürümde kullanıcı yalnız "bu satırı al / alma" diyebiliyordu.
/// OCR virgülü nokta okuduğunda ya da birimi kaçırdığında tek çare
/// satırı atıp elle baştan girmekti. Artık yanlış okunan değer yerinde
/// düzeltilir.
class _EditableLab {
  _EditableLab({
    required this.rawLine,
    required String label,
    required String value,
    required String unit,
    String min = '',
    String max = '',
    this.analyteKey,
  })  : label = TextEditingController(text: label),
        value = TextEditingController(text: value),
        unit = TextEditingController(text: unit),
        min = TextEditingController(text: min),
        max = TextEditingController(text: max);

  final String rawLine;
  final TextEditingController label;
  final TextEditingController value;
  final TextEditingController unit;
  final TextEditingController min;
  final TextEditingController max;
  String? analyteKey;
  bool include = true;

  bool get isValid =>
      label.text.trim().isNotEmpty && parseLocaleNumber(value.text) != null;

  void dispose() {
    label.dispose();
    value.dispose();
    unit.dispose();
    min.dispose();
    max.dispose();
  }

  static _EditableLab fromParsed(ParsedLabValue v) => _EditableLab(
        rawLine: v.rawLine,
        label: v.analyteLabel,
        value: v.value.toString().replaceAll('.', ','),
        unit: v.unit,
        min: v.refMin?.toString().replaceAll('.', ',') ?? '',
        max: v.refMax?.toString().replaceAll('.', ',') ?? '',
        analyteKey: v.analyteKey,
      );
}

class _ReaderLabTab extends ConsumerStatefulWidget {
  const _ReaderLabTab({required this.startWithCamera, super.key});

  /// true → kamera, false → galeri/dosya.
  final bool startWithCamera;

  @override
  ConsumerState<_ReaderLabTab> createState() => _ReaderLabTabState();
}

class _ReaderLabTabState extends ConsumerState<_ReaderLabTab> {
  IntakeDocument? _doc;
  bool _busy = false;
  String? _statusTr;
  List<_EditableLab> _rows = [];
  String? _aiRaw;
  DateTime _takenAt = DateTime.now();

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _replaceRows(List<_EditableLab> next) {
    for (final row in _rows) {
      row.dispose();
    }
    _rows = next;
  }

  Future<void> _pick() async {
    final intake = ref.read(documentIntakeProvider);
    try {
      final IntakeDocument? doc;
      if (widget.startWithCamera) {
        if (!await _ensureCamera()) return;
        doc = await intake.fromCamera();
      } else {
        doc = await intake.fromFiles();
      }
      if (doc == null || !mounted) return;
      setState(() {
        _doc = doc;
        _replaceRows([]);
        _aiRaw = null;
        _statusTr = null;
      });
      if (doc.kind.supportsOnDeviceOcr) {
        await _runOcr();
      } else {
        setState(
          () => _statusTr = 'PDF seçildi. PDF\'in içindeki yazıyı telefon '
              'tek başına çözemiyor; okumak için aşağıdaki "Yapay zekaya '
              'okut" düğmesini kullan ya da sayfanın fotoğrafını çek.',
        );
      }
    } on IntakeFailure catch (e) {
      if (mounted) setState(() => _statusTr = e.messageTr);
    }
  }

  Future<bool> _ensureCamera() async {
    final service = ref.read(permissionServiceProvider);
    if (await service.status(AppPermission.camera) ==
        AppPermissionStatus.granted) {
      return true;
    }
    if (!mounted) return false;
    final ok = await showPermissionDialog(
      context,
      permissionInfo(AppPermission.camera),
    );
    if (!ok) return false;
    return await service.request(AppPermission.camera) ==
        AppPermissionStatus.granted;
  }

  Future<void> _runOcr() async {
    final doc = _doc;
    if (doc == null || !doc.kind.supportsOnDeviceOcr) return;
    setState(() {
      _busy = true;
      _statusTr = 'Metin okunuyor (telefonun içinde)…';
    });
    try {
      final result =
          await ref.read(scannerServiceProvider).recognizeText(doc.file);
      final parsed = parseLabLines(result.lines);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _replaceRows(parsed.map(_EditableLab.fromParsed).toList());
        _statusTr = parsed.isEmpty
            ? 'Tanıdığım bir tahlil değeri bulamadım. Daha net bir '
                'fotoğraf dene, "Yapay zekaya okut"u kullan ya da '
                'aşağıdan elle satır ekle.'
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
    final doc = _doc;
    if (doc == null) return;

    final consent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          doc.isPdf
              ? 'PDF yapay zekaya gönderilecek'
              : 'Tahlil fotoğrafı yapay zekaya gönderilecek',
        ),
        content: Text(
          'Bu ${doc.isPdf ? "belge" : "fotoğraf"} Anthropic Claude API '
          'sunucusuna gönderilecek. Üzerinde adın ve TC kimlik numaran '
          'yazıyor olabilir — istersen önce o alanları kapatıp yeniden '
          'çekebilirsin.\n\n'
          'Yapay zeka yalnızca değerleri OKUR, yorumlamaz. Okunan her '
          'değeri kaydetmeden önce düzeltip onaylarsın.',
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
      final prompt = ref.read(aiPromptBuilderProvider).buildLabVisionPrompt();
      final model =
          ref.read(preferencesProvider).aiModel ?? AiConfig.defaultModel;
      final service = ref.read(aiServiceProvider);
      final reply = doc.isPdf
          ? await service.sendDocument(
              systemPrompt: prompt,
              userText: 'Bu tahlil raporundaki değerleri oku.',
              document: doc.file,
              model: model,
            )
          : await service.sendVision(
              systemPrompt: prompt,
              userText: 'Bu tahlil raporundaki değerleri oku.',
              image: doc.file,
              model: model,
            );
      final parsed = parseAiLabReply(reply.text);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _aiRaw = reply.text;
        _replaceRows(parsed.map(_EditableLab.fromParsed).toList());
        _statusTr = parsed.isEmpty
            ? 'Yapay zeka da okunabilir değer bulamadı. Aşağıdan elle '
                'satır ekleyebilirsin.'
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

  void _addEmptyRow() {
    setState(() {
      _rows = [
        ..._rows,
        _EditableLab(rawLine: 'elle eklendi', label: '', value: '', unit: ''),
      ];
    });
  }

  Future<void> _save() async {
    final db = ref.read(databaseProvider);
    final keep = _rows.where((row) => row.include && row.isValid).toList();

    for (final row in keep) {
      final label = row.label.text.trim();
      final value = parseLocaleNumber(row.value.text)!;
      await db.into(db.labResultRows).insert(
            LabResultRowsCompanion.insert(
              analyte: row.analyteKey ??
                  'custom_${_ManualLabTabState.normalizeKey(label)}',
              analyteLabel: label,
              value: value,
              unit: row.unit.text.trim(),
              refMin: Value(parseLocaleNumber(row.min.text)),
              refMax: Value(parseLocaleNumber(row.max.text)),
              origin: Value(_doc?.isPdf == true ? 'pdf' : 'ocr'),
              confirmedByUser: const Value(true),
              note: const Value('Belgeden okundu, kullanıcı onayladı'),
              takenAt: _takenAt,
            ),
          );
    }

    final potassium =
        keep.where((row) => row.analyteKey == 'lab_potassium').firstOrNull;
    if (mounted && potassium != null) {
      await evaluateAndDispatchAlerts(
        context: context,
        ref: ref,
        serumPotassium: parseLocaleNumber(potassium.value.text)!,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final p = context.palette;
    final conn = ref.watch(aiConnectionProvider).value;
    final aiReady = conn == AiConnectionState.ok;
    final doc = _doc;
    final keepCount = _rows.where((row) => row.include && row.isValid).length;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.all(r.pagePadding),
      children: [
        if (doc != null) ...[
          _DocumentPreview(doc: doc),
          SizedBox(height: r.gapMd),
        ],
        NeuButton(
          label: _busy
              ? 'İşleniyor…'
              : doc == null
                  ? (widget.startWithCamera
                      ? 'Tahlil kağıdını çek'
                      : 'Dosya ya da görsel seç')
                  : (widget.startWithCamera ? 'Yeniden çek' : 'Başka dosya'),
          icon: widget.startWithCamera
              ? Icons.document_scanner_outlined
              : Icons.folder_open_outlined,
          expanded: true,
          loading: _busy,
          color: p.accents.lab,
          onPressed: _busy ? null : _pick,
        ),
        if (doc != null && doc.kind.supportsOnDeviceOcr) ...[
          SizedBox(height: r.gapSm),
          NeuButton(
            label: 'Telefonla tekrar oku',
            icon: Icons.refresh_rounded,
            filled: false,
            expanded: true,
            color: p.accents.lab,
            onPressed: _busy ? null : _runOcr,
          ),
        ],
        if (doc != null) ...[
          SizedBox(height: r.gapSm),
          if (aiReady)
            NeuButton(
              label: 'Yapay zekaya okut (daha iyi sonuç)',
              icon: Icons.auto_awesome_rounded,
              filled: false,
              expanded: true,
              color: p.accents.appointment,
              onPressed: _busy ? null : _runAi,
            )
          else
            NeuCard(
              surface: Surface.flat,
              child: Text(
                doc.isPdf
                    ? 'PDF okumak için yapay zeka bağlantısı gerekiyor: '
                        'Ayarlar > Yapay Zeka Bağlantısı.'
                    : 'Yapay zeka bağlantısı kurulursa okuma belirgin '
                        'biçimde iyileşir (Ayarlar > Yapay Zeka).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
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
        if (_rows.isNotEmpty) ...[
          SizedBox(height: r.gapLg),
          Text(
            'Okunan değerler (${_rows.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: r.gapXs),
          Text(
            'Her alanı düzeltebilirsin. Okuma virgülü, birimi ya da '
            'aralığı yanlış almış olabilir — kaydettiğin şey burada '
            'gördüğündür.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: r.gapSm),
          for (final row in _rows) ...[
            _EditableLabCard(
              row: row,
              onChanged: () => setState(() {}),
              onRemove: () => setState(() {
                _rows = [..._rows]..remove(row);
                row.dispose();
              }),
            ),
            SizedBox(height: r.gapSm),
          ],
        ],
        if (doc != null) ...[
          SizedBox(height: r.gapSm),
          NeuButton(
            label: 'Satır ekle',
            icon: Icons.add_rounded,
            filled: false,
            compact: true,
            expanded: true,
            color: p.accents.lab,
            onPressed: _addEmptyRow,
          ),
        ],
        if (_rows.isNotEmpty) ...[
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
                if (picked != null) setState(() => _takenAt = picked);
              },
            ),
          ),
          SizedBox(height: r.gapMd),
          NeuButton(
            label: keepCount == 0
                ? 'Kaydedilecek değer yok'
                : '$keepCount değeri kaydet',
            icon: Icons.check_rounded,
            expanded: true,
            color: p.accents.lab,
            onPressed: keepCount == 0 ? null : _save,
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
                child: SelectableText(
                  _aiRaw!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: r.gapLg),
        Text(
          kOcrDisclaimerTr,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.doc});

  final IntakeDocument doc;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final p = context.palette;
    if (!doc.isPdf) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          doc.file,
          height: r.s(170),
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    return NeuCard(
      surface: Surface.flat,
      child: Row(
        children: [
          AccentTile(
            icon: Icons.picture_as_pdf_outlined,
            color: p.accents.appointment,
          ),
          SizedBox(width: r.gapMd),
          Expanded(
            child: Text(
              doc.nameTr,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableLabCard extends StatelessWidget {
  const _EditableLabCard({
    required this.row,
    required this.onChanged,
    required this.onRemove,
  });

  final _EditableLab row;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final p = context.palette;
    final valid = row.isValid;

    return NeuCard(
      surface: Surface.flat,
      color: row.include
          ? null
          : p.backgroundDeep.withValues(alpha: p.isDark ? 0.5 : 0.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Checkbox(
                value: row.include,
                onChanged: (v) {
                  row.include = v ?? false;
                  onChanged();
                },
              ),
              Expanded(
                child: TextField(
                  controller: row.label,
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    labelText: 'Tahlil adı',
                    isDense: true,
                  ),
                ),
              ),
              TapIcon(
                icon: Icons.delete_outline_rounded,
                semanticLabel: 'Satırı sil',
                onPressed: onRemove,
              ),
            ],
          ),
          SizedBox(height: r.gapSm),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: NumberField(
                  controller: row.value,
                  hintText: 'sonuç',
                  onChanged: (_) => onChanged(),
                ),
              ),
              SizedBox(width: r.gapSm),
              Expanded(
                child: TextField(
                  controller: row.unit,
                  decoration: const InputDecoration(
                    hintText: 'birim',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: r.gapSm),
          Row(
            children: [
              Expanded(
                child: NumberField(controller: row.min, hintText: 'alt sınır'),
              ),
              SizedBox(width: r.gapSm),
              Expanded(
                child: NumberField(controller: row.max, hintText: 'üst sınır'),
              ),
            ],
          ),
          if (!valid) ...[
            SizedBox(height: r.gapXs),
            Text(
              'Ad ve sonuç dolu olmadan kaydedilmez.',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: p.warning),
            ),
          ],
          SizedBox(height: r.gapXs),
          Text(
            'ham: ${row.rawLine}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

/// Yapay zekanın "Analit | değer | birim | aralık" satırlarını çözer.
///
/// Ayrı bir fonksiyon: ekrandan bağımsız olduğu için test edilebiliyor.
List<ParsedLabValue> parseAiLabReply(String text) {
  final out = <ParsedLabValue>[];
  for (final line in text.split('\n')) {
    final parts = line.split('|').map((s) => s.trim()).toList();
    if (parts.length < 3) continue;
    final value = parseLocaleNumber(parts[1]);
    if (value == null) continue;
    if (parts[0].isEmpty) continue;

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

    String? key;
    var best = 0;
    final norm = parts[0].toLowerCase();
    for (final e in kLabAliases.entries) {
      if (norm.contains(e.key) && e.key.length > best) {
        key = e.value.key;
        best = e.key.length;
      }
    }

    out.add(
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
  return out;
}
class _ManualLabTab extends ConsumerStatefulWidget {
  const _ManualLabTab({super.key});

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

