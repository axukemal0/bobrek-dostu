import 'package:drift/drift.dart' show Value;
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/responsive.dart';

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) => const _PlanSheet(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Plan ekle'),
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
      ),
      body: SafeArea(
        child: PageBody(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Diyetisyeninin planını buraya gir',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: r.gapXs),
                  Text(
                    'Planı serbest metin olarak yazabilirsin. '
                    'Her gün uyumunu yüzde olarak işaretlersin; '
                    'doktor raporunda bu oran görünür.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            if (active.isEmpty)
              const EmptyState(
                title: 'Aktif plan yok',
                message: 'Diyetisyeninin verdiği planı ekleyerek '
                    'günlük uyumunu takip edebilirsin.',
                icon: Icons.restaurant_menu_outlined,
              )
            else
              for (final plan in active)
                Padding(
                  padding: EdgeInsets.only(bottom: r.gapMd),
                  child: _PlanCard(plan: plan),
                ),

            if (plans.any((pl) => !pl.active)) ...[
              const SectionHeader(
                title: 'Arşiv',
                icon: Icons.archive_outlined,
              ),
              for (final plan in plans.where((pl) => !pl.active))
                Padding(
                  padding: EdgeInsets.only(bottom: r.gapSm),
                  child: NeuCard(
                    surface: Surface.flat,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.title,
                            style:
                                Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        TapIcon(
                          icon: Icons.delete_outline_rounded,
                          semanticLabel: 'Planı sil',
                          onPressed: () async {
                            final db = ref.read(databaseProvider);
                            await (db.delete(db.dietAdherenceRows)
                                  ..where(
                                    (t) => t.planId.equals(plan.id),
                                  ))
                                .go();
                            await (db.delete(db.dietPlanRows)
                                  ..where((t) => t.id.equals(plan.id)))
                                .go();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends ConsumerStatefulWidget {
  const _PlanCard({required this.plan});

  final DietPlanRow plan;

  @override
  ConsumerState<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends ConsumerState<_PlanCard> {
  int _todayPercent = 100;
  List<DietAdherenceRow> _history = const [];

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
    setState(() => _history = rows);
  }

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
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bugünün uyumu %$_todayPercent olarak kaydedildi.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final avg = _history.isEmpty
        ? null
        : _history.map((h) => h.percent).reduce((a, b) => a + b) /
            _history.length;

    return NeuCard(
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
          SizedBox(height: r.gapSm),
          Container(
            padding: EdgeInsets.all(r.gapSm),
            decoration: BoxDecoration(
              color: p.backgroundDeep.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              widget.plan.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          SizedBox(height: r.gapMd),
          Text(
            'Bugünün uyumu: %$_todayPercent',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Slider(
            value: _todayPercent.toDouble(),
            min: 0,
            max: 100,
            divisions: 10,
            label: '%$_todayPercent',
            onChanged: (v) => setState(() => _todayPercent = v.round()),
          ),
          NeuButton(
            label: 'Bugünü işaretle',
            icon: Icons.check_rounded,
            compact: true,
            expanded: true,
            onPressed: _mark,
          ),
          if (avg != null) ...[
            SizedBox(height: r.gapMd),
            Text(
              'Son ${_history.length} günün ortalaması: '
              '%${avg.round()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: r.gapSm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final h in _history.reversed)
                    Tooltip(
                      message: '${h.day.day}.${h.day.month}: %${h.percent}',
                      child: Container(
                        width: r.s(14),
                        height: r.s(44),
                        margin: EdgeInsets.only(right: r.s(3)),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: (r.s(44) * h.percent / 100).clamp(3, 44),
                          decoration: BoxDecoration(
                            color: h.percent >= 80
                                ? p.success
                                : (h.percent >= 50 ? p.accent : p.danger),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanSheet extends ConsumerStatefulWidget {
  const _PlanSheet();

  @override
  ConsumerState<_PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends ConsumerState<_PlanSheet> {
  final _title = TextEditingController();
  final _content = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
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
              'Diyet planı ekle',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: r.gapMd),
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
              maxLines: 12,
              minLines: 6,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Plan içeriği',
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
              onPressed: _title.text.trim().isEmpty ||
                      _content.text.trim().isEmpty
                  ? null
                  : () async {
                      final db = ref.read(databaseProvider);
                      await db.into(db.dietPlanRows).insert(
                            DietPlanRowsCompanion.insert(
                              title: _title.text.trim(),
                              content: _content.text.trim(),
                            ),
                          );
                      if (context.mounted) Navigator.pop(context);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
