import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/config/ai_config.dart';
import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/document_intake.dart';
import '../../core/services/permission_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/responsive.dart';
import '../home/home_screen.dart' show showPermissionDialog;

class DietPlanScreen extends ConsumerStatefulWidget {
  const DietPlanScreen({super.key});

  @override
  ConsumerState<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends ConsumerState<DietPlanScreen> {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final plans = ref.watch(dietPlansProvider).value ?? const [];
    final active = plans.where((pl) => pl.active).toList();

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(title: const Text('Diyet planı')),
      floatingActionButtonLocation:
          ShellFabLocation(BottomBarInset.of(context)),
      floatingActionButton: SectionFab(
        label: 'Plan ekle',
        tone: p.accents.energy,
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => const _PlanSheet(),
        ),
      ),
      body: SafeArea(
        child: PageBody(
          hasFab: true,
          children: [
            GlassCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AccentTile(
                    icon: Icons.restaurant_menu_rounded,
                    color: p.accents.energy,
                  ),
                  SizedBox(width: r.gapMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diyetisyeninin planı',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: r.gapXs),
                        Text(
                          'Kağıdın fotoğrafını çekip ekleyebilir, metnini '
                          'yazabilir ya da yapay zekaya okutabilirsin. '
                          'Her gün uyumunu işaretlersin; doktor raporunda '
                          'bu oran görünür.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (active.isEmpty)
              const EmptyState(
                title: 'Aktif plan yok',
                message: 'Diyetisyeninin verdiği planı ekleyerek günlük '
                    'uyumunu takip edebilirsin.',
                icon: Icons.restaurant_menu_outlined,
              )
            else
              for (final plan in active) _PlanCard(plan: plan),
            if (plans.any((pl) => !pl.active)) ...[
              const SectionHeader(
                title: 'Arşiv',
                icon: Icons.archive_outlined,
              ),
              for (final plan in plans.where((pl) => !pl.active))
                NeuCard(
                  surface: Surface.flat,
                  margin: EdgeInsets.only(bottom: r.gapSm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      TapIcon(
                        icon: Icons.unarchive_outlined,
                        semanticLabel: 'Planı yeniden etkinleştir',
                        onPressed: () async {
                          final db = ref.read(databaseProvider);
                          await (db.update(db.dietPlanRows)
                                ..where((t) => t.id.equals(plan.id)))
                              .write(
                            const DietPlanRowsCompanion(active: Value(true)),
                          );
                        },
                      ),
                      TapIcon(
                        icon: Icons.delete_outline_rounded,
                        semanticLabel: 'Planı sil',
                        onPressed: () async {
                          final db = ref.read(databaseProvider);
                          await (db.delete(db.dietAdherenceRows)
                                ..where((t) => t.planId.equals(plan.id)))
                              .go();
                          await (db.delete(db.dietPlanRows)
                                ..where((t) => t.id.equals(plan.id)))
                              .go();
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PLAN KARTI
// ---------------------------------------------------------------------------
class _PlanCard extends ConsumerStatefulWidget {
  const _PlanCard({required this.plan});

  final DietPlanRow plan;

  @override
  ConsumerState<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends ConsumerState<_PlanCard> {
  int _todayPercent = 100;
  List<DietAdherenceRow> _history = const [];
  bool _savedJustNow = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final rows = await (db.select(db.dietAdherenceRows)
          ..where((t) => t.planId.equals(widget.plan.id))
          ..orderBy([(t) => OrderingTerm.desc(t.day)])
          ..limit(30))
        .get();
    if (!mounted) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayRow = rows.where((h) => h.day == today).firstOrNull;
    setState(() {
      _history = rows;
      if (todayRow != null) {
        _todayPercent = todayRow.percent;
        _savedJustNow = true;
      }
    });
  }

  /// Bugünün uyumunu kaydeder.
  ///
  /// DİKKAT — ESKİ HATA: her dokunuşta bir SnackBar gösteriliyordu.
  /// SnackBar'lar kuyruğa giriyor, biri kapanınca diğeri açılıyordu:
  /// kullanıcı yüzdeyi birkaç kez ayarlayınca ekranın altında bitmeyen
  /// bir bildirim dizisi oluşuyor, hatta başka sayfaya geçince orada
  /// beliriyordu — üstelik yazdığı oran ARTIK GEÇERLİ OLMAYAN eski
  /// değerdi. Artık bildirim yok: sonuç kartın kendi içinde, tek bir
  /// satırda ve her zaman güncel gösteriliyor.
  Future<void> _mark() async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);

    final existing = await (db.select(db.dietAdherenceRows)
          ..where((t) => t.planId.equals(widget.plan.id))
          ..where((t) => t.day.equals(day)))
        .getSingleOrNull();

    if (existing == null) {
      await db.into(db.dietAdherenceRows).insert(
            DietAdherenceRowsCompanion.insert(
              planId: widget.plan.id,
              day: day,
              percent: _todayPercent,
            ),
          );
    } else {
      await (db.update(db.dietAdherenceRows)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        DietAdherenceRowsCompanion(percent: Value(_todayPercent)),
      );
    }
    if (mounted) {
      await HapticFeedback.lightImpact();
      if (!mounted) return;
      setState(() => _savedJustNow = true);
    }
    await _load();
  }

  Color _toneFor(int percent, AppPalette p) => percent >= 80
      ? p.success
      : percent >= 50
          ? p.warning
          : p.danger;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final motion = context.motion;
    final tone = p.accents.energy;
    final avg = _history.isEmpty
        ? null
        : _history.map((h) => h.percent).reduce((a, b) => a + b) /
            _history.length;
    final attachment = widget.plan.attachmentPath;

    return NeuCard(
      margin: EdgeInsets.only(bottom: r.gapMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.plan.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TapIcon(
                icon: Icons.archive_outlined,
                semanticLabel: 'Planı arşivle',
                onPressed: () async {
                  final db = ref.read(databaseProvider);
                  await (db.update(db.dietPlanRows)
                        ..where((t) => t.id.equals(widget.plan.id)))
                      .write(
                    const DietPlanRowsCompanion(active: Value(false)),
                  );
                },
              ),
            ],
          ),

          // --- diyetisyenin kağıdı ---
          if (attachment != null) ...[
            SizedBox(height: r.gapSm),
            _AttachmentTile(
              path: attachment,
              kind: widget.plan.attachmentKind ?? 'image',
            ),
          ],

          if (widget.plan.content.trim().isNotEmpty) ...[
            SizedBox(height: r.gapSm),
            Container(
              padding: EdgeInsets.all(r.gapMd),
              decoration: BoxDecoration(
                color: p.backgroundDeep.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.divider),
              ),
              child: SelectableText(
                widget.plan.content,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],

          SizedBox(height: r.gapSm),
          NeuButton(
            label: 'Bu plan hakkında soru sor',
            icon: Icons.chat_bubble_outline_rounded,
            filled: false,
            compact: true,
            expanded: true,
            color: p.accents.appointment,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) => _PlanQaSheet(plan: widget.plan),
            ),
          ),

          // --- günlük uyum ---
          SizedBox(height: r.gapLg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bugünün uyumu',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              AnimatedDefaultTextStyle(
                duration: motion.normal,
                curve: motion.enter,
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      color: _toneFor(_todayPercent, p),
                    ),
                child: Text('%$_todayPercent'),
              ),
            ],
          ),
          Slider(
            value: _todayPercent.toDouble(),
            min: 0,
            max: 100,
            divisions: 10,
            label: '%$_todayPercent',
            activeColor: _toneFor(_todayPercent, p),
            onChanged: (v) => setState(() {
              _todayPercent = v.round();
              _savedJustNow = false;
            }),
          ),
          NeuButton(
            label: _savedJustNow ? 'Bugün işaretlendi' : 'Bugünü işaretle',
            icon:
                _savedJustNow ? Icons.check_circle_rounded : Icons.check_rounded,
            compact: true,
            expanded: true,
            color: tone,
            onPressed: _mark,
          ),
          AnimatedSize(
            duration: motion.normal,
            curve: motion.enter,
            child: _savedJustNow
                ? Padding(
                    padding: EdgeInsets.only(top: r.gapXs),
                    child: Text(
                      'Bugün %$_todayPercent olarak kayıtlı. Kaydırıp '
                      'tekrar işaretlersen güncellenir.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: p.textSecondary),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),

          if (avg != null) ...[
            SizedBox(height: r.gapMd),
            Divider(color: p.divider, height: 1),
            SizedBox(height: r.gapMd),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Son ${_history.length} günün ortalaması',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  '%${avg.round()}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: _toneFor(avg.round(), p)),
                ),
              ],
            ),
            SizedBox(height: r.gapSm),
            _AdherenceStrip(history: _history, toneOf: (v) => _toneFor(v, p)),
          ],
        ],
      ),
    );
  }
}

/// Son günlerin uyum çubukları.
///
/// Tek günlük kayıtta eskiden ortada yalnız bir çubuk kalıyor ve bir
/// çizim hatası gibi duruyordu. Artık şerit her zaman 14 günlük bir
/// ızgara çiziyor: kaydı olmayan günler soluk bir yuva olarak görünür,
/// yani "henüz işaretlemedin" bilgisi de resmin parçası olur.
class _AdherenceStrip extends StatelessWidget {
  const _AdherenceStrip({required this.history, required this.toneOf});

  final List<DietAdherenceRow> history;
  final Color Function(int) toneOf;

  static const int days = 14;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final motion = context.motion;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final byDay = {for (final h in history) h.day: h.percent};
    final height = r.s(52);

    return SizedBox(
      height: height + r.s(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = days - 1; i >= 0; i--)
            Expanded(
              child: Builder(
                builder: (context) {
                  final day = today.subtract(Duration(days: i));
                  final percent = byDay[day];
                  return Semantics(
                    label: percent == null
                        ? '${day.day}.${day.month}: kayıt yok'
                        : '${day.day}.${day.month}: yüzde $percent',
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: r.s(2)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: height,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: p.backgroundDeep
                                        .withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: motion.slow,
                                  curve: motion.emphasized,
                                  height: percent == null
                                      ? 0
                                      : (height * percent / 100)
                                          .clamp(4.0, height),
                                  decoration: BoxDecoration(
                                    color: percent == null
                                        ? Colors.transparent
                                        : toneOf(percent),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: r.s(3)),
                          Text(
                            '${day.day}',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontSize: r.s(9),
                                      color: day == today
                                          ? p.textPrimary
                                          : p.textMuted,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Eklenen kağıdın küçük önizlemesi; dokununca tam ekran açılır.
class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.path, required this.kind});

  final String path;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final file = File(path);

    if (!file.existsSync()) {
      return NeuCard(
        surface: Surface.flat,
        child: Text(
          'Eklenen dosya bulunamadı (silinmiş olabilir). Planı '
          'yeniden ekleyebilirsin.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    if (kind == 'pdf') {
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
                'Diyetisyenin PDF\'i eklendi',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
      );
    }

    return Pressable(
      radius: 14,
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: EdgeInsets.all(r.gapSm),
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              InteractiveViewer(
                maxScale: 5,
                child: Center(child: Image.file(file)),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: TapIcon(
                  icon: Icons.close_rounded,
                  semanticLabel: 'Kapat',
                  color: Colors.white,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          file,
          height: r.s(160),
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PLAN HAKKINDA SORU SORMA
// ---------------------------------------------------------------------------
class _PlanQaSheet extends ConsumerStatefulWidget {
  const _PlanQaSheet({required this.plan});

  final DietPlanRow plan;

  @override
  ConsumerState<_PlanQaSheet> createState() => _PlanQaSheetState();
}

class _PlanQaSheetState extends ConsumerState<_PlanQaSheet> {
  final _question = TextEditingController();
  bool _busy = false;
  String? _answer;
  String? _errorTr;

  static const List<String> _suggestions = [
    'Bu planda günde kaç öğün var?',
    'Planda potasyumu yüksek olabilecek neler var?',
    'Kahvaltıda ne yazıyor?',
    'Kaçınmam gereken neler yazıyor?',
  ];

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  Future<void> _ask(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _answer = null;
      _errorTr = null;
    });
    try {
      final prefs = ref.read(preferencesProvider);
      final prompt = ref.read(aiPromptBuilderProvider).buildDietPlanQaPrompt(
            planTitle: widget.plan.title,
            planContent: widget.plan.content,
            settings: ref.read(clinicalSettingsProvider),
            expertMode:
                ref.read(profileProvider).value?.expertMode ?? false,
          );
      final reply = await ref.read(aiServiceProvider).sendChat(
        systemPrompt: prompt,
        messages: [(role: 'user', text: text.trim())],
        model: prefs.aiModel ?? AiConfig.defaultModel,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _answer = reply.text;
      });
    } on AiFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorTr = e.messageTr;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorTr = 'Beklenmedik hata: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final p = context.palette;
    final conn = ref.watch(aiConnectionProvider).value;
    final ready = conn == AiConnectionState.ok;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => ListView(
        controller: controller,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          r.pagePadding,
          r.gapMd,
          r.pagePadding,
          MediaQuery.viewInsetsOf(context).bottom + r.gapLg,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Planın hakkında soru sor',
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
          NeuCard(
            surface: Surface.flat,
            child: Text(
              'Sorduğunda planın METNİ ve sorun Anthropic Claude '
              'API\'sine gider. Adın, telefon numaran ve doktorunun '
              'bilgileri GİTMEZ. Yapay zeka planı değiştiremez; yalnız '
              'planda yazanı açıklar.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (widget.plan.content.trim().isEmpty) ...[
            SizedBox(height: r.gapMd),
            NeuCard(
              color: p.accentSoft.withValues(alpha: 0.5),
              child: Text(
                'Bu planın METNİ boş — yalnız kağıdın fotoğrafı var. '
                'Soru sorabilmek için planı düzenleyip "metne çevir" '
                'ile yazıya dökmen gerekiyor.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          if (!ready) ...[
            SizedBox(height: r.gapMd),
            NeuCard(
              color: p.accentSoft.withValues(alpha: 0.5),
              child: Text(
                'Yapay zeka bağlantısı kurulu değil. Ayarlar > Yapay '
                'Zeka Bağlantısı bölümünden anahtarını ekleyebilirsin.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          SizedBox(height: r.gapMd),
          TextField(
            controller: _question,
            minLines: 2,
            maxLines: 5,
            enabled: ready && !_busy,
            decoration: const InputDecoration(
              labelText: 'Sorun',
              hintText: 'Örn. Akşam öğününde ne yazıyor?',
              alignLabelWithHint: true,
            ),
          ),
          SizedBox(height: r.gapSm),
          Wrap(
            spacing: r.gapSm,
            runSpacing: r.gapSm,
            children: [
              for (final s in _suggestions)
                ActionChip(
                  label: Text(s),
                  onPressed: ready && !_busy
                      ? () {
                          _question.text = s;
                          _ask(s);
                        }
                      : null,
                ),
            ],
          ),
          SizedBox(height: r.gapMd),
          NeuButton(
            label: 'Sor',
            icon: Icons.send_rounded,
            expanded: true,
            loading: _busy,
            color: p.accents.appointment,
            onPressed: ready && !_busy ? () => _ask(_question.text) : null,
          ),
          if (_errorTr != null) ...[
            SizedBox(height: r.gapMd),
            NeuCard(
              color: p.danger.withValues(alpha: 0.12),
              child: Text(
                _errorTr!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          if (_answer != null) ...[
            SizedBox(height: r.gapMd),
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    _answer!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: r.gapSm),
                  const MedicalDisclaimerBanner(compact: true),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PLAN EKLEME
// ---------------------------------------------------------------------------
class _PlanSheet extends ConsumerStatefulWidget {
  const _PlanSheet();

  @override
  ConsumerState<_PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends ConsumerState<_PlanSheet> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  IntakeDocument? _doc;
  bool _busy = false;
  String? _statusTr;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
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

  Future<void> _attach({required bool camera}) async {
    final intake = ref.read(documentIntakeProvider);
    try {
      final IntakeDocument? doc;
      if (camera) {
        if (!await _ensureCamera()) return;
        doc = await intake.fromCamera();
      } else {
        doc = await intake.fromFiles();
      }
      if (doc == null || !mounted) return;
      setState(() {
        _doc = doc;
        _statusTr = null;
        if (_title.text.trim().isEmpty) {
          final now = DateTime.now();
          _title.text = 'Diyetisyen planı — '
              '${now.day.toString().padLeft(2, '0')}.'
              '${now.month.toString().padLeft(2, '0')}.${now.year}';
        }
      });
    } on IntakeFailure catch (e) {
      if (mounted) setState(() => _statusTr = e.messageTr);
    }
  }

  /// Kağıdı metne çevirir: görselde önce telefonun kendi OCR'ı denenir,
  /// PDF'te ve "daha iyi olsun" denildiğinde yapay zeka kullanılır.
  Future<void> _transcribe({required bool useAi}) async {
    final doc = _doc;
    if (doc == null) return;

    if (useAi) {
      final consent = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kağıt yapay zekaya gönderilecek'),
          content: Text(
            'Eklediğin ${doc.isPdf ? "PDF" : "fotoğraf"} Anthropic Claude '
            'API sunucusuna gönderilip metne çevrilecek. Üzerinde adın '
            'yazıyorsa görünür olacaktır — istersen önce o kısmı '
            'kapatıp yeniden çekebilirsin.\n\n'
            'Yapay zeka planı DEĞİŞTİRMEZ, yalnız yazıyı okur. Çıkan '
            'metni kaydetmeden önce düzeltebilirsin.',
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
    }

    setState(() {
      _busy = true;
      _statusTr =
          useAi ? 'Yapay zeka okuyor…' : 'Metin okunuyor (telefonun içinde)…';
    });

    try {
      String text;
      if (useAi) {
        final prompt =
            ref.read(aiPromptBuilderProvider).buildDietPlanVisionPrompt();
        final model =
            ref.read(preferencesProvider).aiModel ?? AiConfig.defaultModel;
        final service = ref.read(aiServiceProvider);
        final reply = doc.isPdf
            ? await service.sendDocument(
                systemPrompt: prompt,
                userText: 'Bu beslenme planını metne çevir.',
                document: doc.file,
                model: model,
              )
            : await service.sendVision(
                systemPrompt: prompt,
                userText: 'Bu beslenme planını metne çevir.',
                image: doc.file,
                model: model,
              );
        text = reply.text;
      } else {
        final result =
            await ref.read(scannerServiceProvider).recognizeText(doc.file);
        text = result.fullText;
      }

      if (!mounted) return;
      setState(() {
        _busy = false;
        if (text.trim().isEmpty) {
          _statusTr = 'Okunabilir yazı bulunamadı. Kağıdı daha yakından '
              've düz çekmeyi dene, ya da metni elle yaz.';
        } else {
          _content.text = text.trim();
          _statusTr = 'Okundu. Aşağıdaki metni kontrol edip '
              'düzeltebilirsin.';
        }
      });
    } on AiFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _statusTr = e.messageTr;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _statusTr = 'Okunamadı: $e';
      });
    }
  }

  Future<void> _save() async {
    final doc = _doc;
    String? storedPath;
    if (doc != null) {
      storedPath = (await ref
              .read(documentIntakeProvider)
              .persist(doc, folder: 'diyet_planlari'))
          .path;
    }
    if (!mounted) return;
    final db = ref.read(databaseProvider);
    await db.into(db.dietPlanRows).insert(
          DietPlanRowsCompanion.insert(
            title: _title.text.trim(),
            content: _content.text.trim(),
            attachmentPath: Value(storedPath),
            attachmentKind:
                Value(doc == null ? null : (doc.isPdf ? 'pdf' : 'image')),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final p = context.palette;
    final doc = _doc;
    final conn = ref.watch(aiConnectionProvider).value;
    final aiReady = conn == AiConnectionState.ok;
    final canSave = _title.text.trim().isNotEmpty &&
        (_content.text.trim().isNotEmpty || doc != null);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => ListView(
        controller: controller,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          r.pagePadding,
          r.gapMd,
          r.pagePadding,
          MediaQuery.viewInsetsOf(context).bottom + r.gapLg,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Diyet planı ekle',
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
          SizedBox(height: r.gapMd),

          // --- kağıdı ekle ---
          Text(
            'Diyetisyenin kağıdı',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          SizedBox(height: r.gapXs),
          Text(
            'İstersen yalnız kağıdı ekle, metni hiç yazma. Uyum takibi '
            'yine çalışır.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: r.gapSm),
          if (doc != null) ...[
            if (!doc.isPdf)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  doc.file,
                  height: r.s(160),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              NeuCard(
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
              ),
            SizedBox(height: r.gapSm),
          ],
          Row(
            children: [
              Expanded(
                child: NeuButton(
                  label: doc == null ? 'Fotoğrafını çek' : 'Yeniden çek',
                  icon: Icons.photo_camera_outlined,
                  filled: false,
                  compact: true,
                  expanded: true,
                  color: p.accents.energy,
                  onPressed: _busy ? null : () => _attach(camera: true),
                ),
              ),
              SizedBox(width: r.gapSm),
              Expanded(
                child: NeuButton(
                  label: 'Dosya seç',
                  icon: Icons.folder_open_outlined,
                  filled: false,
                  compact: true,
                  expanded: true,
                  color: p.accents.energy,
                  onPressed: _busy ? null : () => _attach(camera: false),
                ),
              ),
            ],
          ),
          if (doc != null) ...[
            SizedBox(height: r.gapSm),
            if (doc.kind.supportsOnDeviceOcr)
              NeuButton(
                label: 'Telefonla metne çevir',
                icon: Icons.text_fields_rounded,
                filled: false,
                compact: true,
                expanded: true,
                loading: _busy,
                color: p.accents.lab,
                onPressed: _busy ? null : () => _transcribe(useAi: false),
              ),
            if (aiReady) ...[
              SizedBox(height: r.gapSm),
              NeuButton(
                label: 'Yapay zekaya okut (daha iyi sonuç)',
                icon: Icons.auto_awesome_rounded,
                filled: false,
                compact: true,
                expanded: true,
                loading: _busy,
                color: p.accents.appointment,
                onPressed: _busy ? null : () => _transcribe(useAi: true),
              ),
            ],
          ],
          if (_statusTr != null) ...[
            SizedBox(height: r.gapSm),
            NeuCard(
              surface: Surface.flat,
              color: p.accentSoft.withValues(alpha: 0.5),
              child: Text(
                _statusTr!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],

          SizedBox(height: r.gapLg),
          TextField(
            controller: _title,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Plan adı',
              hintText: 'Örn. Diyetisyen planı — Kasım',
            ),
          ),
          SizedBox(height: r.gapMd),
          TextField(
            controller: _content,
            maxLines: 14,
            minLines: 6,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Plan metni (isteğe bağlı)',
              hintText: 'Kahvaltı: ...\nÖğle: ...\nAkşam: ...\n'
                  'Kaçınılacaklar: ...',
              alignLabelWithHint: true,
            ),
          ),
          SizedBox(height: r.gapLg),
          NeuButton(
            label: 'Kaydet',
            icon: Icons.check_rounded,
            expanded: true,
            color: p.accents.energy,
            onPressed: canSave ? _save : null,
          ),
        ],
      ),
    );
  }
}
