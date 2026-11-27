
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' hide Text;

import '../../clinical/evaluator.dart';
import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/nutrient_meter.dart';
import '../../core/widgets/responsive.dart';
import 'add_food_sheet.dart';
import '../../core/i18n/text.dart';
import '../../core/i18n/i18n.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final day = ref.watch(selectedDayProvider);
    final settings = ref.watch(clinicalSettingsProvider);
    final logsAsync = ref.watch(foodLogsForDayProvider);

    return Scaffold(
      backgroundColor: p.background,
      floatingActionButtonLocation:
          ShellFabLocation(BottomBarInset.of(context)),
      floatingActionButton: SectionFab(
        label: 'Yemek ekle',
        tone: p.accents.energy,
        onPressed: () => showAddFoodSheet(context, ref),
      ),
      body: SafeArea(
        child: logsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: EdgeInsets.all(r.gapLg),
              child: Text(tf('Kayıtlar okunamadı: {0}', [e])),
            ),
          ),
          data: (logs) {
            final nutrition = computeDailyNutrition(
              entries: [
                for (final f in logs)
                  FoodEntryValues(
                    grams: 100,
                    kcalPer100g: f.kcal,
                    proteinPer100g: f.proteinG,
                    sodiumMgPer100g: f.sodiumMg,
                    potassiumMgPer100g: f.potassiumMg,
                    phosphorusMgPer100g: f.phosphorusMg,
                  ),
              ],
              settings: settings,
            );

            return PageBody(
              hasFab: true,
              children: [
                _DayNav(day: day),

                // --- halkalar ---
                NeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Günün toplamı',
                              style:
                                  Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const ApproximateBadge(
                            tooltipTr:
                                'Değerler yaklaşıktır; TürKomp/USDA '
                                'temelli yerel tablo ve etiket '
                                'verisinden gelir.',
                          ),
                        ],
                      ),
                      SizedBox(height: r.gapMd),
                      Wrap(
                        spacing: r.gapMd,
                        runSpacing: r.gapMd,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final n in nutrition.all)
                            Column(
                              children: [
                                ProgressRing(
                                  ratio: n.ratio,
                                  label: n.labelTr,
                                  // Birimine göre ondalık: "0,0 kcal" ya da
                                  // "0,0 mg" yazmak anlamsızdı.
                                  valueText: NutrientMeter.formatValue(
                                    n.value,
                                    n.unit,
                                  ),
                                  // Her besinin kendi rengi — ana
                                  // sayfadaki ölçeklerle aynı dil.
                                  tone: p.accents.forNutrient(n.key),
                                  unitText: n.unit,
                                  size: r.s(88),
                                ),
                                SizedBox(height: r.gapXs),
                                Text(
                                  n.labelTr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall,
                                ),
                                if (n.hasTarget)
                                  Text(
                                    'hedef ${n.target!.round()}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: p.textMuted),
                                  )
                                else
                                  Text(
                                    'hedef yok',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: p.textMuted,
                                          fontStyle: FontStyle.italic,
                                        ),
                                  ),
                                if (n.isPartial)
                                  Text(
                                    tf(
                                      '{0} öğe bilinmiyor',
                                      [n.unknownItemCount],
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: p.warning),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- hedef aşımı yumuşak uyarı ---
                for (final n in nutrition.exceeded)
                  NeuCard(
                    color: p.warning.withValues(alpha: p.isDark ? 0.14 : 0.08),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: p.warning,
                          size: r.s(20),
                        ),
                        SizedBox(width: r.gapSm),
                        Expanded(
                          child: Text(
                            nutrientExceededAdviceTr(n),
                            style:
                                Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                // --- diyet planı kısayolu ---
                NeuCard(
                  onTap: () => context.push(Routes.dietPlan),
                  child: Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu_outlined,
                        color: p.accent,
                      ),
                      SizedBox(width: r.gapSm),
                      Expanded(
                        child: Text(
                          'Diyet planı ve uyum takibi',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: p.textMuted,
                      ),
                    ],
                  ),
                ),

                // --- kayıt listesi ---
                SectionHeader(
                  title: tf('Kayıtlar ({0})', [logs.length]),
                  icon: Icons.list_alt_rounded,
                ),
                if (logs.isEmpty)
                  const EmptyState(
                    title: 'Bugün kayıt yok',
                    message: 'Sağ alttaki "Yemek ekle" ile arama yapabilir, '
                        'barkod okutabilir, etiket veya yemek fotoğrafı '
                        'çekebilirsin.',
                    icon: Icons.restaurant_outlined,
                  )
                else
                  for (final log in logs)
                    Padding(
                      padding: EdgeInsets.only(bottom: r.gapSm),
                      child: _FoodLogTile(log: log),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Gün gezinme çubuğu.
class _DayNav extends ConsumerWidget {
  const _DayNav({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = Responsive.fromContext(context);
    final today = DateTime.now();
    final isToday = day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;

    return NeuCard(
      padding: EdgeInsets.symmetric(horizontal: r.gapSm, vertical: r.gapXs),
      child: Row(
        children: [
          TapIcon(
            icon: Icons.chevron_left_rounded,
            semanticLabel: 'Önceki gün',
            onPressed: () =>
                ref.read(selectedDayProvider.notifier).shift(-1),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  isToday ? 'Bugün' : _weekdayTr(day),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  _fmt(day),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          TapIcon(
            icon: Icons.chevron_right_rounded,
            semanticLabel: 'Sonraki gün',
            onPressed: isToday
                ? null
                : () => ref.read(selectedDayProvider.notifier).shift(1),
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';

  static String _weekdayTr(DateTime d) => const [
        'Pazartesi',
        'Salı',
        'Çarşamba',
        'Perşembe',
        'Cuma',
        'Cumartesi',
        'Pazar',
      ][d.weekday - 1];
}

class _FoodLogTile extends ConsumerWidget {
  const _FoodLogTile({required this.log});

  final FoodLogRow log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final r = Responsive.fromContext(context);

    final chips = <({String label, double? value, String unit})>[
      (label: 'kcal', value: log.kcal, unit: ''),
      (label: 'protein', value: log.proteinG, unit: 'g'),
      (label: 'Na', value: log.sodiumMg, unit: 'mg'),
      (label: 'K', value: log.potassiumMg, unit: 'mg'),
      (label: 'P', value: log.phosphorusMg, unit: 'mg'),
    ];

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
                      log.label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '${log.grams.round()} g · '
                      '${_hm(log.consumedAt)}'
                      '${log.mealType == null ? "" : " · ${log.mealType}"}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              if (log.origin == 'ai')
                Padding(
                  padding: EdgeInsets.only(right: r.gapXs),
                  child: Tooltip(
                    message: tf(
                               'Yapay zeka tahmini{0}',
                               [log.confidence == null ? '' : ' (${log.confidence})'],
                             ),
                    triggerMode: TooltipTriggerMode.tap,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: r.s(16),
                      color: p.accent,
                    ),
                  ),
                ),
              TapIcon(
                icon: Icons.delete_outline_rounded,
                semanticLabel: tf('{0} kaydını sil', [log.label]),
                onPressed: () async {
                  final db = ref.read(databaseProvider);
                  await (db.delete(db.foodLogRows)
                        ..where((t) => t.id.equals(log.id)))
                      .go();
                },
              ),
            ],
          ),
          SizedBox(height: r.gapSm),
          Wrap(
            spacing: r.gapXs,
            runSpacing: r.gapXs,
            children: [
              for (final c in chips)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.value == null
                        ? p.danger.withValues(alpha: 0.08)
                        : p.backgroundDeep.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: c.value == null
                          ? p.danger.withValues(alpha: 0.3)
                          : p.divider,
                    ),
                  ),
                  child: Text(
                    c.value == null
                        ? '${c.label}: bilinmiyor'
                        : '${c.label} '
                            '${c.value! < 10 ? c.value!.toStringAsFixed(1) : c.value!.round()}'
                            '${c.unit}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: c.value == null ? p.danger : p.textSecondary,
                        ),
                  ),
                ),
            ],
          ),
          if (log.note?.isNotEmpty == true) ...[
            SizedBox(height: r.gapSm),
            Text(
              log.note!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  static String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}
