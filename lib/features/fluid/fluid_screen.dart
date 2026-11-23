import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../clinical/evaluator.dart';
import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/speech_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/responsive.dart';

/// Sıvı bütçesi ekranı.
///
/// KRİTİK KURAL: "Su iç" hatırlatmaları ASLA varsayılan açık değildir
/// ve limit varken hiçbir metin daha fazla içmeye teşvik etmez.
class FluidScreen extends ConsumerStatefulWidget {
  const FluidScreen({super.key});

  @override
  ConsumerState<FluidScreen> createState() => _FluidScreenState();
}

class _FluidScreenState extends ConsumerState<FluidScreen> {
  bool _listening = false;
  String? _voiceText;

  static const List<({String label, int ml, IconData icon, String kind})>
      quickAdds = [
    (label: 'Su', ml: 200, icon: Icons.water_drop_outlined, kind: 'drink'),
    (label: 'Çay bardağı', ml: 100, icon: Icons.emoji_food_beverage_outlined, kind: 'drink'),
    (label: 'Kahve fincanı', ml: 80, icon: Icons.coffee_outlined, kind: 'drink'),
    (label: 'Çorba kasesi', ml: 200, icon: Icons.soup_kitchen_outlined, kind: 'soup'),
    (label: 'Ayran', ml: 200, icon: Icons.local_drink_outlined, kind: 'drink'),
    (label: 'Meyve (bir porsiyon)', ml: 120, icon: Icons.apple_rounded, kind: 'food'),
  ];

  Future<void> _add(String label, int ml, String kind) async {
    final db = ref.read(databaseProvider);
    final day = ref.read(selectedDayProvider);
    final now = DateTime.now();
    await db.into(db.fluidLogRows).insert(
          FluidLogRowsCompanion.insert(
            label: label,
            ml: ml,
            kind: Value(kind),
            consumedAt: DateTime(
              day.year,
              day.month,
              day.day,
              now.hour,
              now.minute,
            ),
          ),
        );
  }

  Future<void> _voiceAdd() async {
    final stt = ref.read(sttServiceProvider);
    if (_listening) {
      await stt.stop();
      setState(() => _listening = false);
      return;
    }
    final ok = await stt.listen(
      onResult: (text, isFinal) async {
        setState(() => _voiceText = text);
        if (!isFinal) return;
        setState(() => _listening = false);
        final cmd = parseVoiceCommand(text);
        if (cmd.kind == VoiceCommandKind.fluid && cmd.fluidMl != null) {
          await _add(cmd.label ?? 'Sıvı', cmd.fluidMl!, 'drink');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${cmd.fluidMl} mL ${cmd.label ?? "sıvı"} eklendi.',
                ),
              ),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Anlayamadım: "$text". '
                'Örnek: "250 mililitre çay içtim" veya "iki bardak su".',
              ),
            ),
          );
        }
      },
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ses tanıma başlatılamadı. Mikrofon izni ve Türkçe ses '
            'tanıma paketi gerekiyor.',
          ),
        ),
      );
      return;
    }
    setState(() => _listening = true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final settings = ref.watch(clinicalSettingsProvider);
    final fluidsAsync = ref.watch(fluidLogsForDayProvider);
    final foods = ref.watch(foodLogsForDayProvider).value ?? const [];
    final weather = ref.watch(weatherProvider).value;
    final limit = settings.resolve('fluid_ml');

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: fluidsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Okunamadı: $e')),
          data: (logs) {
            final fromDrinks = logs.fold<int>(0, (a, b) => a + b.ml);
            final fromFood = foods
                .map((f) => f.fluidMl ?? 0)
                .fold<double>(0, (a, b) => a + b)
                .round();
            final budget = computeFluidBudget(
              consumedMl: fromDrinks + fromFood,
              limitMl: limit.isCleared ? null : limit.value?.round(),
            );

            return PageBody(
              children: [
                Text(
                  'Sıvı bütçesi',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),

                // --- halka ---
                NeuCard(
                  child: Column(
                    children: [
                      ProgressRing(
                        ratio: budget.ratio,
                        label: 'Sıvı',
                        valueText: '${budget.consumedMl}',
                        unitText: 'mL',
                        size: r.s(160),
                        noTargetHintTr: 'limit yok',
                      ),
                      SizedBox(height: r.gapMd),
                      if (budget.hasLimit)
                        Text(
                          budget.isOverLimit
                              ? 'Limitini ${budget.overshootMl} mL aştın'
                              : 'Kalan ${budget.remainingMl} mL '
                                  '(limit ${budget.limitMl} mL)',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: budget.isOverLimit
                                    ? p.danger
                                    : p.textPrimary,
                              ),
                        )
                      else
                        Column(
                          children: [
                            Text(
                              'Limit girilmemiş',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                            SizedBox(height: r.gapXs),
                            Text(
                              'Doktor olarak limitini Klinik Ayarlar\'dan '
                              'girebilirsin ya da "limit yok" olarak '
                              'bırakabilirsin.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                            SizedBox(height: r.gapSm),
                            NeuButton(
                              label: 'Limit ayarla',
                              icon: Icons.tune_rounded,
                              compact: true,
                              filled: false,
                              onPressed: () =>
                                  context.push(Routes.clinicalSettings),
                            ),
                          ],
                        ),
                      SizedBox(height: r.gapMd),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(r.gapSm),
                        decoration: BoxDecoration(
                          color: p.backgroundDeep.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          fluidAdviceTr(
                            budget,
                            hotWeather: weather?.isHot ?? false,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      if (fromFood > 0) ...[
                        SizedBox(height: r.gapSm),
                        Text(
                          'İçecekler: $fromDrinks mL · '
                          'Yemekten gelen: $fromFood mL',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                      SizedBox(height: r.gapXs),
                      SourceFootnote(
                        sourceIds: limit.definition.sourceIds,
                        onTap: () => context.push(Routes.sources),
                      ),
                    ],
                  ),
                ),

                // --- hızlı ekleme ---
                SectionHeader(
                  title: 'Hızlı ekle',
                  icon: Icons.add_circle_outline_rounded,
                  trailing: TapIcon(
                    icon: _listening
                        ? Icons.mic_rounded
                        : Icons.mic_none_rounded,
                    semanticLabel: _listening
                        ? 'Dinlemeyi durdur'
                        : 'Sesle kayıt ekle',
                    color: _listening ? p.danger : null,
                    onPressed: _voiceAdd,
                  ),
                ),
                if (_listening || _voiceText != null)
                  NeuCard(
                    color: p.accentSoft.withValues(alpha: 0.5),
                    child: Row(
                      children: [
                        Icon(
                          Icons.hearing_rounded,
                          color: p.accent,
                          size: r.s(18),
                        ),
                        SizedBox(width: r.gapSm),
                        Expanded(
                          child: Text(
                            _listening
                                ? (_voiceText?.isEmpty ?? true
                                    ? 'Dinliyorum… Örnek: "250 mililitre '
                                        'çay içtim"'
                                    : _voiceText!)
                                : 'Son duyduğum: $_voiceText',
                            style:
                                Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                Wrap(
                  spacing: r.gapSm,
                  runSpacing: r.gapSm,
                  children: [
                    for (final q in quickAdds)
                      SizedBox(
                        width: r.isCompact ? double.infinity : r.s(168),
                        child: NeuCard(
                          onTap: () => _add(q.label, q.ml, q.kind),
                          semanticLabel: '${q.label} ${q.ml} mL ekle',
                          padding: EdgeInsets.all(r.gapSm),
                          child: Row(
                            children: [
                              Icon(q.icon, color: p.primary, size: r.s(20)),
                              SizedBox(width: r.gapSm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      q.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${q.ml} mL',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                NeuButton(
                  label: 'Başka miktar ekle',
                  icon: Icons.edit_outlined,
                  filled: false,
                  expanded: true,
                  onPressed: () => _showCustomSheet(context),
                ),

                // --- hatırlatma ayarı ---
                _ReminderCard(hasLimit: budget.hasLimit),

                // --- kayıtlar ---
                SectionHeader(
                  title: 'Bugünün kayıtları (${logs.length})',
                  icon: Icons.list_alt_rounded,
                ),
                if (logs.isEmpty)
                  const EmptyState(
                    title: 'Kayıt yok',
                    message: 'Yukarıdan hızlı ekle ya da mikrofonla '
                        'söyleyerek kaydet.',
                    icon: Icons.water_drop_outlined,
                  )
                else
                  for (final log in logs)
                    Padding(
                      padding: EdgeInsets.only(bottom: r.gapSm),
                      child: NeuCard(
                        padding: EdgeInsets.symmetric(
                          horizontal: r.gapMd,
                          vertical: r.gapSm,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                  Text(
                                    _hm(log.consumedAt),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${log.ml} mL',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                            TapIcon(
                              icon: Icons.delete_outline_rounded,
                              semanticLabel: '${log.label} kaydını sil',
                              onPressed: () async {
                                final db = ref.read(databaseProvider);
                                await (db.delete(db.fluidLogRows)
                                      ..where((t) => t.id.equals(log.id)))
                                    .go();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showCustomSheet(BuildContext context) {
    final labelC = TextEditingController();
    final mlC = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sıvı ekle',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: labelC,
              decoration: const InputDecoration(
                labelText: 'Ne içtin?',
                hintText: 'Örn. maden suyu',
              ),
            ),
            const SizedBox(height: 12),
            NumberField(
              controller: mlC,
              suffix: 'mL',
              allowDecimal: false,
              hintText: '250',
            ),
            const SizedBox(height: 20),
            NeuButton(
              label: 'Kaydet',
              icon: Icons.check_rounded,
              expanded: true,
              onPressed: () async {
                final ml = parseLocaleInt(mlC.text);
                if (ml == null || ml <= 0) return;
                await _add(
                  labelC.text.trim().isEmpty ? 'Sıvı' : labelC.text.trim(),
                  ml,
                  'drink',
                );
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

/// "Su iç" hatırlatması ayarı — varsayılan KAPALI.
class _ReminderCard extends ConsumerWidget {
  const _ReminderCard({required this.hasLimit});

  final bool hasLimit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final p = context.palette;
    final r = Responsive.fromContext(context);

    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            value: prefs.waterReminders,
            onChanged: (v) async {
              if (v && hasLimit) {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Emin misin?'),
                    content: const Text(
                      'Sıvı LİMİTİN var. Hatırlatmayı açarsan uygulama '
                      'sana düzenli olarak sıvı almayı hatırlatır — '
                      'bu, limiti aşmaya yol açabilir.\n\n'
                      'Hatırlatma metinleri her zaman kalan miktarı '
                      'söyler ve limitin üstüne teşvik etmez; yine de '
                      'bu ayarı açmak senin kararın.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Vazgeç'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Yine de aç'),
                      ),
                    ],
                  ),
                );
                if (ok != true) return;
              }
              await ref
                  .read(preferencesProvider.notifier)
                  .update((pr) => pr.copyWith(waterReminders: v));
            },
            title: const Text('Sıvı hatırlatması'),
            subtitle: Text(
              hasLimit
                  ? 'Sıvı limitin olduğu için varsayılan olarak KAPALI. '
                      'Açarsan hatırlatmalar kalan miktarı söyler.'
                  : 'Varsayılan olarak KAPALI. Limit girmediysen '
                      'açabilirsin.',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          SizedBox(height: r.gapXs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.shield_outlined,
                size: r.s(15),
                color: p.primary,
              ),
              SizedBox(width: r.gapXs),
              Expanded(
                child: Text(
                  'Uygulama, sıvı limiti olan bir hastaya hiçbir '
                  'yerde "bol su iç" demez. Sıcak hava uyarıları da '
                  'limitine göre yazılır.',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
