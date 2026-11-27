import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' hide Text;

import '../../clinical/sources.dart';
import '../../core/config/ai_config.dart';
import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/document_intake.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/scanner_service.dart' show kOcrDisclaimerTr;
import '../../core/theme/app_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/responsive.dart';
import '../home/home_screen.dart' show showPermissionDialog;
import 'diet_plan_parser.dart';
import '../../core/i18n/text.dart';
import '../../core/i18n/i18n.dart';

// ===========================================================================
// DİYET PLANI VE UYUM
// ===========================================================================
//
// Uyum ölçümü yeniden kuruldu. Eskiden tek bir 0-100 kaydırıcısı vardı:
// "%70" neyin yüzdesiydi belli değildi, tahmine dayanıyordu ve doktora
// hiçbir şey söylemiyordu. Yerine iki ölçü geldi:
//
//  1. ÖĞÜN ÖĞÜN İŞARETLEME — plan öğünlere ayrılır, her öğün için
//     "Uydum / Kısmen / Uymadım". Günün yüzdesi bunlardan HESAPLANIR.
//     Doktor hangi öğünün düştüğünü görür; bu klinik olarak işe yarar.
//  2. KAÇINMA SAYACI — kaçınılacaklar çipe dönüşür, kullanıcı yalnız
//     YEDİĞİNİ işaretler. İyi günde sıfır dokunuş.
//
// Kaçınma listesi üç yerden beslenir: planın kendi metni, uygulamanın
// KAYNAKLI hazır listesi (bkz. kAvoidLibrary) ve kullanıcının elle ya
// da fotoğraftan eklediği maddeler. Hepsi silinebilir.

/// Plan metninden öğünleri ve kaçınılacakları veritabanına yazar.
///
/// Var olan öğünleri silmez; yalnız EKSİK olanları ekler. Kullanıcı
/// kendi öğünlerini düzenlediyse yeniden çözümleme onları ezmesin.
Future<({int meals, int avoid})> seedPlanStructure({
  required AppDatabase db,
  required int planId,
  required String text,
}) async {
  final parsed = parseDietPlan(text);

  final existingMeals = await db.mealsOfPlan(planId);
  final existingNames =
      existingMeals.map((m) => foldTr(m.name)).toSet();
  var position = existingMeals.length;
  var addedMeals = 0;
  for (final meal in parsed.meals) {
    if (!existingNames.add(foldTr(meal.name))) continue;
    await db.into(db.dietMealRows).insert(
          DietMealRowsCompanion.insert(
            planId: planId,
            name: meal.name,
            detail: Value(meal.detail),
            timeHint: Value(meal.timeHint),
            position: Value(position++),
          ),
        );
    addedMeals++;
  }

  final existingAvoid = await db.activeAvoidItems();
  final existingLabels =
      existingAvoid.map((a) => foldTr(a.label)).toSet();
  var avoidPosition = existingAvoid.length;
  var addedAvoid = 0;
  for (final label in parsed.avoid) {
    if (!existingLabels.add(foldTr(label))) continue;
    await db.into(db.dietAvoidItemRows).insert(
          DietAvoidItemRowsCompanion.insert(
            label: label,
            origin: 'plan',
            position: Value(avoidPosition++),
          ),
        );
    addedAvoid++;
  }

  return (meals: addedMeals, avoid: addedAvoid);
}

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
                          'Kağıdın fotoğrafını ekle, metne çevir, öğünlere '
                          'ayır. Her öğün için "uydum / kısmen / uymadım" '
                          'işaretlersin; günün yüzdesi bundan hesaplanır.',
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
                        onPressed: () => _deletePlan(plan.id),
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

  Future<void> _deletePlan(int planId) async {
    final db = ref.read(databaseProvider);
    final meals = await db.mealsOfPlan(planId);
    for (final meal in meals) {
      await (db.delete(db.dietMealMarkRows)
            ..where((t) => t.mealId.equals(meal.id)))
          .go();
    }
    await (db.delete(db.dietMealRows)..where((t) => t.planId.equals(planId)))
        .go();
    await (db.delete(db.dietAdherenceRows)
          ..where((t) => t.planId.equals(planId)))
        .go();
    await (db.delete(db.dietPlanRows)..where((t) => t.id.equals(planId))).go();
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
  List<DietMealRow> _meals = const [];
  Map<int, MealMark> _marks = const {};
  List<DietAvoidItemRow> _avoid = const [];
  Set<int> _slips = const {};
  List<DietAdherenceRow> _history = const [];
  bool _loading = true;
  bool _planTextOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  DateTime get _today => AppDatabase.dayOf(DateTime.now());

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final meals = await db.mealsOfPlan(widget.plan.id);
    final marks = await db.mealMarksForDay(
      meals.map((m) => m.id).toList(growable: false),
      _today,
    );
    final avoid = await db.activeAvoidItems();
    final slips = await db.slipsForDay(_today);
    final history = await (db.select(db.dietAdherenceRows)
          ..where((t) => t.planId.equals(widget.plan.id))
          ..orderBy([(t) => OrderingTerm.desc(t.day)])
          ..limit(30))
        .get();
    if (!mounted) return;
    setState(() {
      _meals = meals;
      _marks = {
        for (final m in marks)
          if (MealMark.fromCode(m.status) != null)
            m.mealId: MealMark.fromCode(m.status)!,
      };
      _avoid = avoid;
      _slips = slips.map((s) => s.itemId).toSet();
      _history = history;
      _loading = false;
    });
  }

  int? get _todayPercent => adherencePercent(_marks.values);

  Future<void> _setMark(DietMealRow meal, MealMark mark) async {
    final db = ref.read(databaseProvider);
    // Aynı işarete tekrar dokunmak işareti KALDIRIR: yanlışlıkla
    // basıldığında geri alacak bir yol olmalı.
    final next = _marks[meal.id] == mark ? null : mark;
    await db.setMealMark(
      mealId: meal.id,
      day: _today,
      status: next?.code,
    );

    final updated = Map<int, MealMark>.from(_marks);
    if (next == null) {
      updated.remove(meal.id);
    } else {
      updated[meal.id] = next;
    }
    await db.writeAdherence(
      planId: widget.plan.id,
      day: _today,
      percent: adherencePercent(updated.values),
    );
    await HapticFeedback.selectionClick();
    await _load();
  }

  Future<void> _toggleSlip(DietAvoidItemRow item) async {
    await ref
        .read(databaseProvider)
        .toggleSlip(itemId: item.id, day: _today);
    await HapticFeedback.selectionClick();
    await _load();
  }

  Future<void> _extractFromPlan() async {
    final db = ref.read(databaseProvider);
    final added = await seedPlanStructure(
      db: db,
      planId: widget.plan.id,
      text: widget.plan.content,
    );
    await _load();
    if (!mounted) return;
    if (added.meals == 0 && added.avoid == 0) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Öğün bulunamadı'),
          content: const Text(
            'Plan metninde "Kahvaltı:", "Öğle:" gibi öğün başlıkları '
            'bulamadım. Öğünleri "Öğünleri düzenle" ekranından elle '
            'ekleyebilir ya da kağıdın fotoğrafını okutabilirsin.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    }
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
    final percent = _todayPercent;
    final attachment = widget.plan.attachmentPath;
    final avg = _history.isEmpty
        ? null
        : _history.map((h) => h.percent).reduce((a, b) => a + b) /
            _history.length;

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

          if (attachment != null) ...[
            SizedBox(height: r.gapSm),
            _AttachmentTile(
              path: attachment,
              kind: widget.plan.attachmentKind ?? 'image',
            ),
          ],

          if (widget.plan.content.trim().isNotEmpty) ...[
            SizedBox(height: r.gapSm),
            // Plan metni artık katlanır: öğün listesi asıl iş, uzun
            // metin her açılışta ekranı doldurmasın.
            _Collapsible(
              open: _planTextOpen,
              title: 'Planın metni',
              onToggle: () => setState(() => _planTextOpen = !_planTextOpen),
              child: Container(
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

          // ---------------- BUGÜNÜN ÖĞÜNLERİ ----------------
          SizedBox(height: r.gapLg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bugünün öğünleri',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (percent != null)
                AnimatedDefaultTextStyle(
                  duration: motion.normal,
                  curve: motion.enter,
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: _toneFor(percent, p),
                      ),
                  child: Text('%$percent'),
                ),
            ],
          ),
          SizedBox(height: r.gapXs),
          Text(
            percent == null
                ? 'Her öğünü işaretledikçe günün yüzdesi kendiliğinden '
                    'hesaplanır. İşaretlemediğin öğün hesaba katılmaz.'
                : tf(
                    '{0}/{1} öğün işaretlendi. Aynı düğmeye tekrar '
                    'dokunursan işaret kalkar.',
                    [_marks.length, _meals.length],
                  ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: r.gapSm),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_meals.isEmpty)
            NeuCard(
              surface: Surface.flat,
              color: p.accentFill(tone, opacity: p.isDark ? 0.12 : 0.07),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Henüz öğün tanımlı değil',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: r.gapXs),
                  Text(
                    'Plan metninden otomatik çıkarabilir, kağıdın '
                    'fotoğrafını okutabilir ya da elle yazabilirsin.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: r.gapSm),
                  if (widget.plan.content.trim().isNotEmpty)
                    NeuButton(
                      label: 'Plan metninden çıkar',
                      icon: Icons.auto_fix_high_rounded,
                      compact: true,
                      expanded: true,
                      color: tone,
                      onPressed: _extractFromPlan,
                    ),
                  SizedBox(height: r.gapXs),
                  NeuButton(
                    label: 'Öğünleri düzenle',
                    icon: Icons.edit_outlined,
                    filled: false,
                    compact: true,
                    expanded: true,
                    color: tone,
                    onPressed: _openMealEditor,
                  ),
                ],
              ),
            )
          else ...[
            for (final meal in _meals)
              Padding(
                padding: EdgeInsets.only(bottom: r.gapXs),
                child: _MealRow(
                  meal: meal,
                  mark: _marks[meal.id],
                  onMark: (m) => _setMark(meal, m),
                ),
              ),
            SizedBox(height: r.gapXs),
            NeuButton(
              label: 'Öğünleri düzenle',
              icon: Icons.tune_rounded,
              filled: false,
              compact: true,
              expanded: true,
              color: tone,
              onPressed: _openMealEditor,
            ),
          ],

          // ---------------- KAÇINILACAKLAR ----------------
          SizedBox(height: r.gapLg),
          Text(
            'Bugün kaçındıkların',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          SizedBox(height: r.gapXs),
          Text(
            _avoid.isEmpty
                ? 'Kaçınman gerekenleri listeye ekle; sonra yalnız '
                    'YEDİĞİN günlerde dokunursun.'
                : _slips.isEmpty
                    ? 'Bugün hiçbirine dokunmadın — temiz gün. '
                        'Yediysen üstüne dokun.'
                    : tf('Bugün {0} madde işaretledin.', [_slips.length]),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _avoid.isEmpty
                      ? null
                      : (_slips.isEmpty ? p.success : p.warning),
                ),
          ),
          SizedBox(height: r.gapSm),
          if (_avoid.isNotEmpty)
            Wrap(
              spacing: r.gapSm,
              runSpacing: r.gapSm,
              children: [
                for (final item in _avoid)
                  _AvoidChip(
                    item: item,
                    eaten: _slips.contains(item.id),
                    onTap: () => _toggleSlip(item),
                  ),
              ],
            ),
          SizedBox(height: r.gapSm),
          NeuButton(
            label: _avoid.isEmpty
                ? 'Kaçınılacakları ekle'
                : 'Listeyi düzenle',
            icon: _avoid.isEmpty ? Icons.add_rounded : Icons.tune_rounded,
            filled: _avoid.isEmpty,
            compact: true,
            expanded: true,
            color: p.accents.sodium,
            onPressed: _openAvoidEditor,
          ),

          // ---------------- GEÇMİŞ ----------------
          if (avg != null) ...[
            SizedBox(height: r.gapLg),
            Divider(color: p.divider, height: 1),
            SizedBox(height: r.gapMd),
            Row(
              children: [
                Expanded(
                  child: Text(
                    tf('İşaretlenen {0} günün ortalaması', [_history.length]),
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

  Future<void> _openMealEditor() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _MealEditorSheet(plan: widget.plan),
    );
    await _load();
  }

  Future<void> _openAvoidEditor() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _AvoidEditorSheet(),
    );
    await _load();
  }
}

/// Başlığa dokununca açılan/kapanan alan.
class _Collapsible extends StatelessWidget {
  const _Collapsible({
    required this.open,
    required this.title,
    required this.onToggle,
    required this.child,
  });

  final bool open;
  final String title;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final motion = context.motion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: open,
          child: Pressable(
            radius: 10,
            onTap: onToggle,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: r.gapXs),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: open ? 0.25 : 0,
                    duration: motion.fast,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: r.s(20),
                      color: p.textSecondary,
                    ),
                  ),
                  SizedBox(width: r.gapXs),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: motion.normal,
          curve: motion.enter,
          alignment: Alignment.topCenter,
          child: open ? child : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Tek bir öğün satırı: ad, saat ve üç durumlu işaret.
class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.meal,
    required this.mark,
    required this.onMark,
  });

  final DietMealRow meal;
  final MealMark? mark;
  final ValueChanged<MealMark> onMark;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final detail = meal.detail?.replaceAll('\n', ' · ');

    return NeuCard(
      surface: Surface.flat,
      padding: EdgeInsets.symmetric(
        horizontal: r.gapMd,
        vertical: r.gapSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.timeHint == null
                          ? meal.name
                          : '${meal.name} · ${meal.timeHint}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (detail != null && detail.isNotEmpty) ...[
                      SizedBox(height: r.s(2)),
                      Text(
                        detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: p.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: r.gapSm),
          Row(
            children: [
              for (final m in MealMark.values) ...[
                Expanded(
                  child: _MarkButton(
                    mark: m,
                    selected: mark == m,
                    onTap: () => onMark(m),
                  ),
                ),
                if (m != MealMark.missed) SizedBox(width: r.gapXs),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MarkButton extends StatelessWidget {
  const _MarkButton({
    required this.mark,
    required this.selected,
    required this.onTap,
  });

  final MealMark mark;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final motion = context.motion;
    final (Color tone, IconData icon) = switch (mark) {
      MealMark.full => (p.success, Icons.check_rounded),
      MealMark.partial => (p.warning, Icons.remove_rounded),
      MealMark.missed => (p.danger, Icons.close_rounded),
    };

    return Semantics(
      button: true,
      selected: selected,
      label: mark.labelTr,
      child: Pressable(
        radius: 12,
        onTap: onTap,
        child: AnimatedContainer(
          duration: motion.fast,
          curve: motion.enter,
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
            color: selected
                ? p.accentFill(tone, opacity: p.isDark ? 0.28 : 0.16)
                : p.backgroundDeep.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? tone : p.divider,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? tone : p.textMuted,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  mark.labelTr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected ? tone : p.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kaçınma çipi. Dokunursan "bugün yedim" olur.
class _AvoidChip extends StatelessWidget {
  const _AvoidChip({
    required this.item,
    required this.eaten,
    required this.onTap,
  });

  final DietAvoidItemRow item;
  final bool eaten;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final motion = context.motion;
    final tone = eaten ? p.danger : p.textSecondary;

    return Semantics(
      button: true,
      selected: eaten,
      label: eaten
          ? tf('{0}, bugün yedim olarak işaretli', [item.label])
          : '${item.label}, yediysen dokun',
      child: Pressable(
        radius: 12,
        onTap: onTap,
        child: AnimatedContainer(
          duration: motion.fast,
          curve: motion.enter,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: eaten
                ? p.danger.withValues(alpha: p.isDark ? 0.22 : 0.12)
                : p.backgroundDeep.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: eaten ? p.danger : p.divider,
              width: eaten ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                eaten
                    ? Icons.error_outline_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: tone,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: tone,
                        fontWeight:
                            eaten ? FontWeight.w800 : FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ÖĞÜN DÜZENLEYİCİ
// ---------------------------------------------------------------------------
class _MealEditorSheet extends ConsumerStatefulWidget {
  const _MealEditorSheet({required this.plan});

  final DietPlanRow plan;

  @override
  ConsumerState<_MealEditorSheet> createState() => _MealEditorSheetState();
}

class _MealEditorSheetState extends ConsumerState<_MealEditorSheet> {
  List<DietMealRow> _meals = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final meals =
        await ref.read(databaseProvider).mealsOfPlan(widget.plan.id);
    if (!mounted) return;
    setState(() {
      _meals = meals;
      _loading = false;
    });
  }

  Future<void> _addMeals(List<String> names) async {
    final db = ref.read(databaseProvider);
    var position = _meals.length;
    final existing = _meals.map((m) => foldTr(m.name)).toSet();
    for (final name in names) {
      final clean = name.trim();
      if (clean.isEmpty) continue;
      if (!existing.add(foldTr(clean))) continue;
      await db.into(db.dietMealRows).insert(
            DietMealRowsCompanion.insert(
              planId: widget.plan.id,
              name: clean,
              position: Value(position++),
            ),
          );
    }
    await _load();
  }

  Future<void> _rename(DietMealRow meal) async {
    final controller = TextEditingController(text: meal.name);
    final detail = TextEditingController(text: meal.detail ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğünü düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Öğün adı'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: detail,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'İçerik (isteğe bağlı)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (saved == true && controller.text.trim().isNotEmpty) {
      final db = ref.read(databaseProvider);
      await (db.update(db.dietMealRows)..where((t) => t.id.equals(meal.id)))
          .write(
        DietMealRowsCompanion(
          name: Value(controller.text.trim()),
          detail: Value(
            detail.text.trim().isEmpty ? null : detail.text.trim(),
          ),
        ),
      );
      await _load();
    }
    controller.dispose();
    detail.dispose();
  }

  Future<void> _remove(DietMealRow meal) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.dietMealMarkRows)
          ..where((t) => t.mealId.equals(meal.id)))
        .go();
    await (db.delete(db.dietMealRows)..where((t) => t.id.equals(meal.id)))
        .go();
    await _load();
  }

  /// `onReorderItem` yeni indeksi ZATEN düzeltilmiş verir; eski
  /// `onReorder`daki "newIndex > oldIndex ise bir eksilt" düzeltmesi
  /// burada YAPILMAMALI, yoksa öğe bir sıra yukarı kayar.
  Future<void> _move(int oldIndex, int newIndex) async {
    final list = [..._meals];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    final db = ref.read(databaseProvider);
    for (var i = 0; i < list.length; i++) {
      await (db.update(db.dietMealRows)
            ..where((t) => t.id.equals(list[i].id)))
          .write(DietMealRowsCompanion(position: Value(i)));
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final p = context.palette;
    final tone = p.accents.energy;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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
                  'Öğünler',
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
          SizedBox(height: r.gapXs),
          Text(
            'Bunlar SENİN öğünlerin. Doktorun verdiği listeyi okutabilir, '
            'üstüne ekleyip çıkarabilir, sırasını değiştirebilirsin.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: r.gapMd),

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_meals.isEmpty)
            NeuCard(
              surface: Surface.flat,
              child: Text(
                'Henüz öğün yok. Aşağıdaki düğmelerle ekleyebilirsin.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _meals.length,
              onReorderItem: _move,
              itemBuilder: (context, i) {
                final meal = _meals[i];
                return Padding(
                  key: ValueKey(meal.id),
                  padding: EdgeInsets.only(bottom: r.gapXs),
                  child: NeuCard(
                    surface: Surface.flat,
                    padding: EdgeInsets.symmetric(
                      horizontal: r.gapSm,
                      vertical: r.gapXs,
                    ),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: Padding(
                            padding: EdgeInsets.all(r.gapXs),
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              color: p.textMuted,
                              size: r.s(20),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal.timeHint == null
                                    ? meal.name
                                    : '${meal.name} · ${meal.timeHint}',
                                style:
                                    Theme.of(context).textTheme.titleSmall,
                              ),
                              if (meal.detail != null)
                                Text(
                                  meal.detail!.replaceAll('\n', ' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall,
                                ),
                            ],
                          ),
                        ),
                        TapIcon(
                          icon: Icons.edit_outlined,
                          semanticLabel: tf(
                                           '{0} öğününü düzenle',
                                           [meal.name],
                                         ),
                          onPressed: () => _rename(meal),
                        ),
                        TapIcon(
                          icon: Icons.delete_outline_rounded,
                          semanticLabel: tf('{0} öğününü sil', [meal.name]),
                          onPressed: () => _remove(meal),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          SizedBox(height: r.gapMd),
          NeuButton(
            label: 'Görselden öğünleri oku',
            icon: Icons.document_scanner_outlined,
            expanded: true,
            compact: true,
            color: tone,
            onPressed: () async {
              final picked = await showScanPicker(
                context: context,
                ref: ref,
                titleTr: 'Öğün listesini okut',
                hintTr: 'Doktorun/diyetisyenin verdiği kağıdı çek ya da '
                    'dosyadan seç. Bulunan öğün başlıkları aşağıda '
                    'listelenir; hangilerini ekleyeceğini sen seçersin.',
                extract: (text) => parseDietPlan(text)
                    .meals
                    .map((m) => m.name)
                    .toList(growable: false),
                fallback: (text) => text
                    .split('\n')
                    .map((l) => l.trim())
                    .where((l) => l.length >= 3 && l.length <= 40)
                    .toList(growable: false),
              );
              if (picked != null) await _addMeals(picked);
            },
          ),
          SizedBox(height: r.gapXs),
          NeuButton(
            label: 'Plan metninden çıkar',
            icon: Icons.auto_fix_high_rounded,
            filled: false,
            compact: true,
            expanded: true,
            color: tone,
            onPressed: widget.plan.content.trim().isEmpty
                ? null
                : () async {
                    await seedPlanStructure(
                      db: ref.read(databaseProvider),
                      planId: widget.plan.id,
                      text: widget.plan.content,
                    );
                    await _load();
                  },
          ),
          SizedBox(height: r.gapXs),
          NeuButton(
            label: 'Standart öğünleri ekle',
            icon: Icons.playlist_add_rounded,
            filled: false,
            compact: true,
            expanded: true,
            color: tone,
            onPressed: () => _addMeals(kDefaultMealNames),
          ),
          SizedBox(height: r.gapXs),
          NeuButton(
            label: 'Elle öğün ekle',
            icon: Icons.add_rounded,
            filled: false,
            compact: true,
            expanded: true,
            color: tone,
            onPressed: () async {
              final name = await promptForText(
                context: context,
                titleTr: 'Öğün ekle',
                labelTr: 'Öğün adı',
                hintTr: 'Örn. Diyaliz sonrası',
              );
              if (name != null) await _addMeals([name]);
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// KAÇINILACAKLAR DÜZENLEYİCİ
// ---------------------------------------------------------------------------
class _AvoidEditorSheet extends ConsumerStatefulWidget {
  const _AvoidEditorSheet();

  @override
  ConsumerState<_AvoidEditorSheet> createState() => _AvoidEditorSheetState();
}

class _AvoidEditorSheetState extends ConsumerState<_AvoidEditorSheet> {
  List<DietAvoidItemRow> _items = const [];
  bool _loading = true;
  bool _libraryOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final items = await ref.read(databaseProvider).activeAvoidItems();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _add(
    List<String> labels, {
    required String origin,
    String? sourceId,
    String? reason,
  }) async {
    final db = ref.read(databaseProvider);
    var position = _items.length;
    final existing = _items.map((i) => foldTr(i.label)).toSet();
    for (final label in labels) {
      final clean = label.trim();
      if (clean.isEmpty) continue;
      if (!existing.add(foldTr(clean))) continue;
      await db.into(db.dietAvoidItemRows).insert(
            DietAvoidItemRowsCompanion.insert(
              label: clean,
              origin: origin,
              sourceId: Value(sourceId),
              reason: Value(reason),
              position: Value(position++),
            ),
          );
    }
    await _load();
  }

  Future<void> _remove(DietAvoidItemRow item) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.dietSlipRows)..where((t) => t.itemId.equals(item.id)))
        .go();
    await (db.delete(db.dietAvoidItemRows)
          ..where((t) => t.id.equals(item.id)))
        .go();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final p = context.palette;
    final tone = p.accents.sodium;
    final inList = _items.map((i) => foldTr(i.label)).toSet();

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
                  'Kaçınılacaklar',
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
          SizedBox(height: r.gapXs),
          Text(
            'Liste tamamen senin: ekle, çıkar. Hazır listedeki her '
            'maddenin yanında hangi kılavuza dayandığı yazar.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: r.gapMd),

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_items.isEmpty)
            NeuCard(
              surface: Surface.flat,
              child: Text(
                'Liste boş. Aşağıdan hazır listeden seçebilir, kağıdı '
                'okutabilir ya da elle yazabilirsin.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            for (final item in _items)
              Padding(
                padding: EdgeInsets.only(bottom: r.gapXs),
                child: _AvoidListTile(item: item, onRemove: () => _remove(item)),
              ),

          SizedBox(height: r.gapMd),
          NeuButton(
            label: 'Görselden okut',
            icon: Icons.document_scanner_outlined,
            expanded: true,
            compact: true,
            color: tone,
            onPressed: () async {
              final picked = await showScanPicker(
                context: context,
                ref: ref,
                titleTr: 'Kaçınılacakları okut',
                hintTr: 'Diyetisyenin verdiği kağıdı çek ya da dosyadan '
                    'seç. Bulunan maddeler aşağıda listelenir; '
                    'ekleyeceklerini sen seçersin.',
                extract: (text) {
                  final parsed = parseDietPlan(text);
                  if (parsed.avoid.isNotEmpty) return parsed.avoid;
                  return dedupeAvoid(
                    text.split('\n').expand(splitAvoidItems),
                  );
                },
                fallback: (text) =>
                    dedupeAvoid(text.split('\n').expand(splitAvoidItems)),
              );
              if (picked != null) await _add(picked, origin: 'scan');
            },
          ),
          SizedBox(height: r.gapXs),
          NeuButton(
            label: 'Elle ekle',
            icon: Icons.add_rounded,
            filled: false,
            compact: true,
            expanded: true,
            color: tone,
            onPressed: () async {
              final label = await promptForText(
                context: context,
                titleTr: 'Kaçınılacak ekle',
                labelTr: 'Madde',
                hintTr: 'Örn. hazır kek',
              );
              if (label != null) await _add([label], origin: 'manual');
            },
          ),

          SizedBox(height: r.gapLg),
          _Collapsible(
            open: _libraryOpen,
            title: 'Hazır listeden ekle (kaynaklı)',
            onToggle: () => setState(() => _libraryOpen = !_libraryOpen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: r.gapXs),
                NeuCard(
                  surface: Surface.flat,
                  color: p.accentSoft.withValues(alpha: 0.45),
                  child: Text(
                    'Bu liste bir TALİMAT DEĞİLDİR, başlangıç listesidir '
                    've KAPSAMLI DEĞİLDİR. Potasyum maddeleri '
                    '"bireyselleştirilir" etiketlidir: kılavuzlar '
                    'potasyum için herkese geçerli bir sayı vermez — '
                    'yalnız serum potasyumun yüksekse ve hekimin '
                    'söylediyse anlamlıdır.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                for (final group in kAvoidGroupLabels.entries) ...[
                  SizedBox(height: r.gapMd),
                  Text(
                    group.value,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: r.gapXs),
                  for (final item
                      in kAvoidLibrary.where((i) => i.group == group.key))
                    Padding(
                      padding: EdgeInsets.only(bottom: r.gapXs),
                      child: _LibraryTile(
                        item: item,
                        added: inList.contains(foldTr(item.label)),
                        onAdd: () => _add(
                          [item.label],
                          origin: 'library',
                          sourceId: item.sourceId,
                          reason: item.reasonTr,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvoidListTile extends StatelessWidget {
  const _AvoidListTile({required this.item, required this.onRemove});

  final DietAvoidItemRow item;
  final VoidCallback onRemove;

  static String originLabel(String origin) => switch (origin) {
        'plan' => 'plandan',
        'library' => 'hazır liste',
        'scan' => 'görselden',
        _ => 'elle',
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final source =
        item.sourceId == null ? null : sourceById(item.sourceId!);

    return NeuCard(
      surface: Surface.flat,
      padding: EdgeInsets.symmetric(
        horizontal: r.gapMd,
        vertical: r.gapSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                SizedBox(height: r.s(2)),
                Text(
                  source == null
                      ? originLabel(item.origin)
                      : '${originLabel(item.origin)} · '
                          '${source.name} (${source.year})',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: p.textMuted),
                ),
                if (item.reason != null) ...[
                  SizedBox(height: r.s(2)),
                  Text(
                    item.reason!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          TapIcon(
            icon: Icons.delete_outline_rounded,
            semanticLabel: tf('{0} maddesini listeden çıkar', [item.label]),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.item,
    required this.added,
    required this.onAdd,
  });

  final AvoidLibraryItem item;
  final bool added;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);

    return NeuCard(
      surface: Surface.flat,
      padding: EdgeInsets.symmetric(
        horizontal: r.gapMd,
        vertical: r.gapSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                SizedBox(height: r.s(3)),
                Text(
                  item.reasonTr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(height: r.gapXs),
                Row(
                  children: [
                    Flexible(
                      child: VerificationChip(
                        verification: item.verification,
                        dense: true,
                      ),
                    ),
                    SizedBox(width: r.gapSm),
                    Expanded(
                      flex: 2,
                      child: SourceFootnote(sourceIds: [item.sourceId]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: r.gapSm),
          if (added)
            Padding(
              padding: EdgeInsets.only(top: r.gapXs),
              child: Icon(
                Icons.check_circle_rounded,
                color: p.success,
                size: r.s(22),
              ),
            )
          else
            TapIcon(
              icon: Icons.add_circle_outline_rounded,
              semanticLabel: tf('{0} maddesini listeye ekle', [item.label]),
              color: p.primary,
              onPressed: onAdd,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ORTAK YARDIMCILAR
// ---------------------------------------------------------------------------

/// Tek satırlık metin soran küçük pencere.
Future<String?> promptForText({
  required BuildContext context,
  required String titleTr,
  required String labelTr,
  String? hintTr,
}) async {
  final controller = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titleTr),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: labelTr, hintText: hintTr),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Ekle'),
        ),
      ],
    ),
  );
  final text = controller.text.trim();
  controller.dispose();
  return ok == true && text.isNotEmpty ? text : null;
}

/// Fotoğraf/dosya okutup çıkan maddeleri SEÇTİRİR.
///
/// Okuma hata yapabildiği için hiçbir şey doğrudan eklenmez: ne
/// bulunduysa onay listesi olarak gösterilir.
Future<List<String>?> showScanPicker({
  required BuildContext context,
  required WidgetRef ref,
  required String titleTr,
  required String hintTr,
  required List<String> Function(String text) extract,
  required List<String> Function(String text) fallback,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _ScanPickerSheet(
      titleTr: titleTr,
      hintTr: hintTr,
      extract: extract,
      fallback: fallback,
    ),
  );
}

class _ScanPickerSheet extends ConsumerStatefulWidget {
  const _ScanPickerSheet({
    required this.titleTr,
    required this.hintTr,
    required this.extract,
    required this.fallback,
  });

  final String titleTr;
  final String hintTr;
  final List<String> Function(String text) extract;
  final List<String> Function(String text) fallback;

  @override
  ConsumerState<_ScanPickerSheet> createState() => _ScanPickerSheetState();
}

class _ScanPickerSheetState extends ConsumerState<_ScanPickerSheet> {
  IntakeDocument? _doc;
  bool _busy = false;
  String? _statusTr;
  List<String> _found = const [];
  final Set<String> _selected = {};

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

  Future<void> _pick({required bool camera}) async {
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
        _found = const [];
        _selected.clear();
        _statusTr = null;
      });
      if (doc.kind.supportsOnDeviceOcr) {
        await _read(useAi: false);
      } else {
        setState(
          () => _statusTr = 'PDF seçildi. PDF\'i telefon tek başına '
              'çözemiyor; "Yapay zekaya okut" düğmesini kullan.',
        );
      }
    } on IntakeFailure catch (e) {
      if (mounted) setState(() => _statusTr = e.messageTr);
    }
  }

  Future<void> _read({required bool useAi}) async {
    final doc = _doc;
    if (doc == null) return;

    if (useAi) {
      final consent = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Yapay zekaya gönderilecek'),
          content: Text(
            tf(
              'Seçtiğin {0} Anthropic Claude API sunucusuna '
              'gönderilip yazısı okunacak. Üzerinde adın yazıyorsa '
              'görünür olur.\n\nOkunan hiçbir şey doğrudan eklenmez; '
              'listeden sen seçersin.',
              [doc.isPdf ? 'PDF' : 'fotoğraf'],
            ),
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
                userText: 'Bu kağıttaki yazıyı metne çevir.',
                document: doc.file,
                model: model,
              )
            : await service.sendVision(
                systemPrompt: prompt,
                userText: 'Bu kağıttaki yazıyı metne çevir.',
                image: doc.file,
                model: model,
              );
        text = reply.text;
      } else {
        final result =
            await ref.read(scannerServiceProvider).recognizeText(doc.file);
        text = result.fullText;
      }

      var found = widget.extract(text);
      if (found.isEmpty) found = widget.fallback(text);
      found = found.take(40).toList(growable: false);

      if (!mounted) return;
      setState(() {
        _busy = false;
        _found = found;
        _selected
          ..clear()
          ..addAll(found);
        _statusTr = found.isEmpty
            ? 'Okunabilir bir madde bulamadım. Daha net bir fotoğraf '
                'dene ya da elle ekle.'
            : null;
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
        _statusTr = tf('Okunamadı: {0}', [e]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final p = context.palette;
    final conn = ref.watch(aiConnectionProvider).value;
    final aiReady = conn == AiConnectionState.ok;
    final doc = _doc;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(
          r.pagePadding,
          r.gapMd,
          r.pagePadding,
          r.gapLg,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.titleTr,
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
          SizedBox(height: r.gapXs),
          Text(widget.hintTr, style: Theme.of(context).textTheme.bodySmall),
          SizedBox(height: r.gapMd),

          if (doc != null && !doc.isPdf) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                doc.file,
                height: r.s(150),
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: r.gapSm),
          ],

          Row(
            children: [
              Expanded(
                child: NeuButton(
                  label: doc == null ? 'Fotoğraf çek' : 'Yeniden çek',
                  icon: Icons.photo_camera_outlined,
                  compact: true,
                  expanded: true,
                  color: p.accents.lab,
                  onPressed: _busy ? null : () => _pick(camera: true),
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
                  color: p.accents.lab,
                  onPressed: _busy ? null : () => _pick(camera: false),
                ),
              ),
            ],
          ),
          if (doc != null && aiReady) ...[
            SizedBox(height: r.gapSm),
            NeuButton(
              label: 'Yapay zekaya okut (daha iyi sonuç)',
              icon: Icons.auto_awesome_rounded,
              filled: false,
              compact: true,
              expanded: true,
              loading: _busy,
              color: p.accents.appointment,
              onPressed: _busy ? null : () => _read(useAi: true),
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

          if (_found.isNotEmpty) ...[
            SizedBox(height: r.gapLg),
            Text(
              'Bulunanlar (${_found.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: r.gapXs),
            Text(
              'Okuma hata yapmış olabilir — eklemek istemediklerinin '
              'işaretini kaldır.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            for (final item in _found)
              CheckboxListTile(
                value: _selected.contains(item),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selected.add(item);
                  } else {
                    _selected.remove(item);
                  }
                }),
                title: Text(item),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            SizedBox(height: r.gapMd),
            NeuButton(
              label: _selected.isEmpty
                  ? 'Seçili madde yok'
                  : '${_selected.length} maddeyi ekle',
              icon: Icons.check_rounded,
              expanded: true,
              color: p.accents.energy,
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.pop(
                        context,
                        _found.where(_selected.contains).toList(),
                      ),
            ),
          ],

          SizedBox(height: r.gapLg),
          Text(
            kOcrDisclaimerTr,
            style: Theme.of(context).textTheme.labelSmall,
          ),
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
    // Etiket için AYRILAN yükseklik sabit tutuluyor ve yazı o kutuya
    // sığdırılıyor. Önceden toplam yükseklik "çubuk + 16" diye
    // veriliyordu; gün numarasının satır yüksekliği bunu birkaç piksel
    // aşınca Flutter "BOTTOM OVERFLOWED" şeridini çiziyordu. Büyük
    // yazı ölçeğinde fark daha da büyürdü.
    final labelHeight = r.s(14);
    const gap = 3.0;

    return SizedBox(
      height: height + gap + labelHeight,
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
                        ? tf('{0}.{1}: kayıt yok', [day.day, day.month])
                        : tf(
                            '{0}.{1}: yüzde {2}',
                            [day.day, day.month, percent],
                          ),
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
                          const SizedBox(height: gap),
                          SizedBox(
                            height: labelHeight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${day.day}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontSize: r.s(9),
                                      height: 1,
                                      color: day == today
                                          ? p.textPrimary
                                          : p.textMuted,
                                    ),
                              ),
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
          _title.text = tf(
                          'Diyetisyen planı — {0}.{1}.{2}',
                          [
                            now.day.toString().padLeft(2, '0'),
                            now.month.toString().padLeft(2, '0'),
                            now.year,
                          ],
                        );
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
            tf(
              'Eklediğin {0} Anthropic Claude API sunucusuna '
              'gönderilip metne çevrilecek. Üzerinde adın yazıyorsa '
              'görünür olacaktır — istersen önce o kısmı kapatıp '
              'yeniden çekebilirsin.\n\nYapay zeka planı DEĞİŞTİRMEZ, '
              'yalnız yazıyı okur. Çıkan metni kaydetmeden önce '
              'düzeltebilirsin.',
              [doc.isPdf ? 'PDF' : 'fotoğraf'],
            ),
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
        _statusTr = tf('Okunamadı: {0}', [e]);
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
    final planId = await db.into(db.dietPlanRows).insert(
          DietPlanRowsCompanion.insert(
            title: _title.text.trim(),
            content: _content.text.trim(),
            attachmentPath: Value(storedPath),
            attachmentKind:
                Value(doc == null ? null : (doc.isPdf ? 'pdf' : 'image')),
          ),
        );

    // Plan metni varsa öğünler ve kaçınılacaklar hemen çıkarılır:
    // kullanıcı planı kaydettiği anda işaretlemeye başlayabilsin.
    // Bulunamazsa sorun değil, "Öğünleri düzenle" elle eklemeye açık.
    final seeded = _content.text.trim().isEmpty
        ? (meals: 0, avoid: 0)
        : await seedPlanStructure(
            db: db,
            planId: planId,
            text: _content.text.trim(),
          );

    if (!mounted) return;
    Navigator.pop(context);
    if (seeded.meals > 0 || seeded.avoid > 0) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              tf(
                'Plandan {0} öğün ve {1} kaçınılacak madde çıkarıldı.',
                [seeded.meals, seeded.avoid],
              ),
            ),
          ),
        );
    }
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
