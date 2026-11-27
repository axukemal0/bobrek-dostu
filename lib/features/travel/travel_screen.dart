import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' hide Text;
import 'package:share_plus/share_plus.dart';

import '../../core/config/ai_config.dart';
import '../../clinical/settings.dart';
import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/ai_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/responsive.dart';
import '../../core/i18n/text.dart';

class TravelScreen extends ConsumerStatefulWidget {
  const TravelScreen({super.key});

  @override
  ConsumerState<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends ConsumerState<TravelScreen> {
  final _destination = TextEditingController();
  int _days = 3;
  final Set<String> _options = {'Yolda yenecekler', 'Restoran önerileri'};
  bool _busy = false;
  String? _plan;
  String? _errorTr;

  static const List<String> allOptions = [
    'Yolda yenecekler',
    'Restoran önerileri',
    'Sıvı ve ilaç saatleri',
    'Hazırlık listesi',
    'Diyaliz / kontrol ayarlaması',
  ];

  @override
  void dispose() {
    _destination.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final dest = _destination.text.trim();
    if (dest.isEmpty) return;

    final consent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plan yapay zeka ile üretilecek'),
        content: Text(
          'Şunlar Anthropic Claude API sunucusuna gönderilecek: '
          'gidilecek yer ("$dest"), gün sayısı, hastalık durumun, '
          'sıvı limitin, sodyum hedefin, alerjilerin ve sevmediğin '
          'yemekler.\n\n'
          'Adın, telefon numaran ve acil durum kişilerin '
          'gönderilmez.\n\n'
          'Yapay zeka belirli bir restoran veya otel adı uydurmaması '
          'için özel olarak uyarılır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Üret'),
          ),
        ],
      ),
    );
    if (consent != true) return;

    setState(() {
      _busy = true;
      _errorTr = null;
      _plan = null;
    });

    try {
      final settings = ref.read(clinicalSettingsProvider);
      final profile = ref.read(profileProvider).value;
      final prompt = ref.read(aiPromptBuilderProvider).buildTravelPrompt(
            settings: settings,
            profile: profile,
            destination: dest,
            days: _days,
          );
      final model =
          ref.read(preferencesProvider).aiModel ?? AiConfig.defaultModel;

      final reply = await ref.read(aiServiceProvider).sendChat(
            systemPrompt: prompt,
            messages: [
              (
                role: 'user',
                text: 'Şu bölümleri istiyorum: '
                    '${_options.join(", ")}. '
                    'İstemediğim bölümleri yazma.',
              ),
            ],
            model: model,
            maxTokens: 3000,
          );

      if (!mounted) return;
      setState(() {
        _busy = false;
        _plan = reply.text;
      });
    } on AiFailure catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _errorTr = e.messageTr;
        });
      }
    }
  }

  Future<void> _savePlan() async {
    final plan = _plan;
    if (plan == null) return;
    final db = ref.read(databaseProvider);
    await db.into(db.travelPlanRows).insert(
          TravelPlanRowsCompanion.insert(
            destination: _destination.text.trim(),
            startsAt: DateTime.now(),
            days: _days,
            planMarkdown: plan,
            options: Value(jsonEncode(_options.toList())),
          ),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan kaydedildi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final conn = ref.watch(aiConnectionProvider).value;
    final saved = ref.watch(travelPlansProvider).value ?? const [];
    final settings = ref.watch(clinicalSettingsProvider);
    final fluidLimit = settings.resolve('fluid_ml');

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(title: const Text('Seyahat planlayıcı')),
      body: SafeArea(
        child: PageBody(
          children: [
            if (conn != AiConnectionState.ok)
              EmptyState(
                title: 'Yapay zeka bağlantısı gerekiyor',
                message: 'Seyahat planı yapay zeka tarafından '
                    'üretilir. Kayıtlı planlarını aşağıda yine '
                    'görebilir ve paylaşabilirsin.',
                icon: Icons.key_off_outlined,
                action: NeuButton(
                  label: 'Bağlantıyı kur',
                  icon: Icons.key_outlined,
                  onPressed: () => context.push(Routes.aiConnection),
                ),
              )
            else ...[
              NeuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LabeledField(
                      label: 'Nereye gidiyorsun?',
                      child: TextField(
                        controller: _destination,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Örn. Gaziantep, Trabzon, Antalya…',
                        ),
                      ),
                    ),
                    SizedBox(height: r.gapMd),
                    LabeledField(
                      label: 'Kaç gün?',
                      child: Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _days.toDouble(),
                              min: 1,
                              max: 21,
                              divisions: 20,
                              label: '$_days gün',
                              onChanged: (v) =>
                                  setState(() => _days = v.round()),
                            ),
                          ),
                          SizedBox(
                            width: r.s(56),
                            child: Text(
                              '$_days gün',
                              textAlign: TextAlign.end,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: r.gapMd),
                    LabeledField(
                      label: 'Hangi bölümler olsun?',
                      child: MultiChipSelector(
                        options: allOptions,
                        selected: _options,
                        onToggle: (o) => setState(() {
                          if (!_options.remove(o)) _options.add(o);
                        }),
                      ),
                    ),
                    SizedBox(height: r.gapMd),
                    Container(
                      padding: EdgeInsets.all(r.gapSm),
                      decoration: BoxDecoration(
                        color: p.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Plan şu bilgilere göre yazılır: '
                        '${settings.treatmentMode.labelTr}, '
                        'sıvı ${fluidLimit.isCleared || !fluidLimit.hasValue ? "limiti yok" : "limiti ${fluidLimit.formatted()} mL/gün"}, '
                        'sodyum hedefi '
                        '${settings.resolve("sodium_mg").formatted()} mg/gün.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    SizedBox(height: r.gapMd),
                    NeuButton(
                      label: _busy ? 'Plan üretiliyor…' : 'Plan üret',
                      icon: Icons.auto_awesome_rounded,
                      tone: NeuTone.accent,
                      expanded: true,
                      onPressed: _busy || _destination.text.trim().isEmpty
                          ? null
                          : _generate,
                    ),
                  ],
                ),
              ),

              if (_errorTr != null)
                NeuCard(
                  color: p.danger.withValues(alpha: 0.09),
                  child: Text(
                    _errorTr!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),

              if (_plan != null)
                NeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_destination.text.trim()} · $_days gün',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                          ),
                          TapIcon(
                            icon: Icons.volume_up_outlined,
                            semanticLabel: 'Planı sesli oku',
                            onPressed: () => ref
                                .read(ttsServiceProvider)
                                .speak(_plan!),
                          ),
                        ],
                      ),
                      SizedBox(height: r.gapSm),
                      SelectableText(
                        _plan!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: r.gapMd),
                      Row(
                        children: [
                          Expanded(
                            child: NeuButton(
                              label: 'Kaydet',
                              icon: Icons.save_outlined,
                              compact: true,
                              expanded: true,
                              onPressed: _savePlan,
                            ),
                          ),
                          SizedBox(width: r.gapSm),
                          Expanded(
                            child: NeuButton(
                              label: 'Paylaş',
                              icon: Icons.ios_share_rounded,
                              filled: false,
                              compact: true,
                              expanded: true,
                              onPressed: () => SharePlus.instance.share(
                                ShareParams(
                                  text: 'Seyahat planı — '
                                      '${_destination.text.trim()}\n\n$_plan',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: r.gapSm),
                      const MedicalDisclaimerBanner(compact: true),
                    ],
                  ),
                ),
            ],

            if (saved.isNotEmpty) ...[
              SectionHeader(
                title: 'Kayıtlı planlar (${saved.length})',
                icon: Icons.bookmark_outline_rounded,
              ),
              for (final planRow in saved)
                Padding(
                  padding: EdgeInsets.only(bottom: r.gapSm),
                  child: NeuCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    planRow.destination,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Text(
                                    '${planRow.days} gün · '
                                    '${_fmt(planRow.createdAt)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall,
                                  ),
                                ],
                              ),
                            ),
                            TapIcon(
                              icon: Icons.ios_share_rounded,
                              semanticLabel: 'Planı paylaş',
                              onPressed: () => SharePlus.instance.share(
                                ShareParams(
                                  text: 'Seyahat planı — '
                                      '${planRow.destination}\n\n'
                                      '${planRow.planMarkdown}',
                                ),
                              ),
                            ),
                            TapIcon(
                              icon: Icons.delete_outline_rounded,
                              semanticLabel: 'Planı sil',
                              onPressed: () async {
                                final db = ref.read(databaseProvider);
                                await (db.delete(db.travelPlanRows)
                                      ..where(
                                        (t) => t.id.equals(planRow.id),
                                      ))
                                    .go();
                              },
                            ),
                          ],
                        ),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(
                            'Planı göster',
                            style:
                                Theme.of(context).textTheme.titleSmall,
                          ),
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: r.gapSm),
                              child: SelectableText(
                                planRow.planMarkdown,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium,
                              ),
                            ),
                          ],
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

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';
}
