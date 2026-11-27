import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health/health.dart' show HealthConnectSdkStatus;
import 'package:material_ui/material_ui.dart' hide Text;

import '../../core/config/ai_config.dart';
import '../../core/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/health_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/responsive.dart';
import '../../core/widgets/trend_chart.dart';
import '../home/home_screen.dart' show showPermissionDialog;
import '../../core/i18n/text.dart';

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  HealthSnapshot? _snapshot;
  bool _loading = false;
  bool _permissionChecked = false;
  bool _hasPermission = false;
  HealthConnectSdkStatus? _sdkStatus;
  HealthKitStatus _hkStatus = HealthKitStatus.unsupported;
  String? _errorTr;
  String? _aiInterpretation;
  bool _aiBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    setState(() => _loading = true);
    final service = ref.read(healthServiceProvider);
    final hk = await service.healthKitStatus();
    // iOS'ta hak yoksa izin sormanın anlamı yok: çağrı izin ekranını
    // hiç açmadan sessizce başarısız olur ve kullanıcı "izin vermedim
    // mi?" diye kendi telefonunu kurcalamaya başlar.
    final status = Platform.isIOS ? null : await service.sdkStatus();
    final has = (Platform.isIOS && !hk.usable)
        ? false
        : await service.hasPermissions();
    if (!mounted) return;
    setState(() {
      _hkStatus = hk;
      _sdkStatus = status;
      _hasPermission = has;
      _permissionChecked = true;
      _loading = false;
    });
    if (has) await _load();
  }

  Future<void> _requestPermission() async {
    final info = permissionInfo(AppPermission.healthConnect);
    final ok = await showPermissionDialog(context, info);
    if (!ok) return;

    // Adım verisi için ayrıca aktivite tanıma izni gerekir.
    final permission = ref.read(permissionServiceProvider);
    if (await permission.status(AppPermission.activityRecognition) !=
        AppPermissionStatus.granted) {
      if (!mounted) return;
      final ok2 = await showPermissionDialog(
        context,
        permissionInfo(AppPermission.activityRecognition),
      );
      if (ok2) {
        await permission.request(AppPermission.activityRecognition);
      }
    }

    final granted =
        await ref.read(healthServiceProvider).requestPermissions();
    if (!mounted) return;
    setState(() => _hasPermission = granted);
    if (granted) {
      await _load();
    } else {
      setState(
        () => _errorTr = [
          '${HealthService.providerNameTr} izinleri verilmedi. '
              '${HealthService.providerNameTr} uygulamasından da izin '
              'verebilirsin.',
          ?HealthService.entitlementNoteTr,
        ].join('\n\n'),
      );
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorTr = null;
    });
    try {
      final snap = await ref.read(healthServiceProvider).fetch();
      if (!mounted) return;
      setState(() {
        _snapshot = snap;
        _loading = false;
      });
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorTr = 'Veri okunamadı: $e';
        });
      }
    }
  }

  Future<void> _interpret() async {
    final snap = _snapshot;
    if (snap == null) return;

    final consent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Veriler yapay zekaya gönderilecek'),
        content: const Text(
          'Aşağıdaki özet Anthropic Claude API sunucusuna '
          'gönderilecek: nabız, tansiyon, adım, uyku ve SpO₂ '
          'ölçümlerinin son 7 günlük özeti ile kendi alarm '
          'eşiklerin.\n\n'
          'Adın, telefon numaran ve acil durum kişilerin '
          'gönderilmez.',
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
      _aiBusy = true;
      _aiInterpretation = null;
    });

    try {
      final settings = ref.read(clinicalSettingsProvider);
      final profile = ref.read(profileProvider).value;
      final prompt =
          ref.read(aiPromptBuilderProvider).buildHealthInterpretPrompt(
                settings: settings,
                expertMode: profile?.expertMode ?? false,
              );
      final model =
          ref.read(preferencesProvider).aiModel ?? AiConfig.defaultModel;

      final data = StringBuffer()
        ..writeln('Son 7 günün verileri:')
        ..writeln('Adım (bugün): ${snap.steps ?? "yok"}');
      if (snap.restingHeartRate != null) {
        snap.restingHeartRate;
        data.writeln(
          'İstirahat nabzı: ${snap.restingHeartRate!.round()} /dk',
        );
      }
      if (snap.heartRates.isNotEmpty) {
        final values = snap.heartRates.map((s) => s.value).toList();
        data.writeln(
          'Nabız: ${values.length} ölçüm, '
          'ortalama ${(values.reduce((a, b) => a + b) / values.length).round()}, '
          'en düşük ${values.reduce((a, b) => a < b ? a : b).round()}, '
          'en yüksek ${values.reduce((a, b) => a > b ? a : b).round()} /dk',
        );
      }
      if (snap.bloodPressure.isNotEmpty) {
        data.writeln('Tansiyon ölçümleri:');
        for (final bp in snap.bloodPressure.take(14)) {
          data.writeln(
            '  ${_fmtDate(bp.at)}: '
            '${bp.value.round()}/${bp.extra?.round() ?? "?"} mmHg',
          );
        }
      }
      if (snap.spo2.isNotEmpty) {
        final values = snap.spo2.map((s) => s.value).toList();
        data.writeln(
          'SpO2: ortalama %${(values.reduce((a, b) => a + b) / values.length).round()}, '
          'en düşük %${values.reduce((a, b) => a < b ? a : b).round()}',
        );
      }
      if (snap.sleepSessions.isNotEmpty) {
        data.writeln('Uyku (son geceler, dakika):');
        for (final s in snap.sleepSessions.reversed.take(7)) {
          data.writeln('  ${_fmtDate(s.at)}: ${s.value.round()} dk');
        }
      }

      final reply = await ref.read(aiServiceProvider).sendChat(
            systemPrompt: prompt,
            messages: [(role: 'user', text: data.toString())],
            model: model,
          );
      if (!mounted) return;
      setState(() {
        _aiBusy = false;
        _aiInterpretation = reply.text;
      });
    } on AiFailure catch (e) {
      if (mounted) {
        setState(() {
          _aiBusy = false;
          _aiInterpretation = null;
          _errorTr = e.messageTr;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final settings = ref.watch(clinicalSettingsProvider);
    final conn = ref.watch(aiConnectionProvider).value;
    final snap = _snapshot;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: const Text('Akıllı saat verisi'),
        actions: [
          TapIcon(
            icon: Icons.refresh_rounded,
            semanticLabel: 'Yenile',
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: SafeArea(
        child: PageBody(
          children: [
            // --- Health Connect durumu ---
            if (!_permissionChecked || _loading)
              NeuCard(
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        '${HealthService.providerNameTr} kontrol '
                        'ediliyor…',
                      ),
                    ),
                  ],
                ),
              )
            else if (Platform.isIOS && !_hkStatus.usable)
              NeuCard(
                color: p.warning.withValues(alpha: p.isDark ? 0.16 : 0.09),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, color: p.warning),
                        SizedBox(width: r.gapSm),
                        Expanded(
                          child: Text(
                            _hkStatus.dataAvailable
                                ? 'Bu derleme Sağlık verisine erişemiyor'
                                : 'Bu cihaz Sağlık verisi tutmuyor',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: r.gapSm),
                    Text(
                      _hkStatus.dataAvailable
                          ? (HealthService.entitlementNoteTr ?? '')
                          : 'iPhone Sağlık verisi bu cihazda '
                              'kullanılamıyor. Ölçümlerini "Kilo, ödem '
                              've tansiyon" ekranından elle '
                              'girebilirsin.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: r.gapMd),
                    NeuButton(
                      label: 'Ölçümü elle gir',
                      icon: Icons.edit_outlined,
                      compact: true,
                      expanded: true,
                      color: p.accents.weight,
                      onPressed: () => context.push(Routes.weight),
                    ),
                  ],
                ),
              )
            else if (!Platform.isIOS &&
                _sdkStatus ==
                HealthConnectSdkStatus.sdkUnavailable)
              NeuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Connect bu cihazda yok',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: r.gapSm),
                    Text(
                      'Akıllı saat verisi Android\'in Health Connect '
                      'servisi üzerinden okunur. Bu cihaz desteklemiyor '
                      'ya da servis kurulu değil. Ölçümlerini '
                      '"Kilo, ödem ve tansiyon" ekranından elle '
                      'girebilirsin.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            else if (!Platform.isIOS &&
                _sdkStatus ==
                    HealthConnectSdkStatus
                        .sdkUnavailableProviderUpdateRequired)
              NeuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Health Connect güncellenmeli',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: r.gapSm),
                    NeuButton(
                      label: 'Health Connect\'i aç',
                      icon: Icons.system_update_outlined,
                      compact: true,
                      expanded: true,
                      onPressed: () => ref
                          .read(healthServiceProvider)
                          .installHealthConnect(),
                    ),
                  ],
                ),
              )
            else if (!_hasPermission)
              NeuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.watch_outlined, color: p.primary),
                        SizedBox(width: r.gapSm),
                        Expanded(
                          child: Text(
                            'Henüz izin verilmedi',
                            style:
                                Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: r.gapSm),
                    Text(
                      permissionInfo(AppPermission.healthConnect).whyTr,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: r.gapMd),
                    NeuButton(
                      label: '${HealthService.providerNameTr} izni ver',
                      icon: Icons.health_and_safety_outlined,
                      expanded: true,
                      onPressed: _requestPermission,
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

            // --- veriler ---
            if (snap != null && !snap.isEmpty) ...[
              AdaptiveGrid(
                children: [
                  _MetricCard(
                    icon: Icons.directions_walk_rounded,
                    label: 'Adım (bugün)',
                    value: snap.steps?.toString() ?? '—',
                    unit: 'adım',
                  ),
                  _MetricCard(
                    icon: Icons.favorite_outline_rounded,
                    label: 'İstirahat nabzı',
                    value: snap.restingHeartRate?.round().toString() ?? '—',
                    unit: '/dk',
                  ),
                  _MetricCard(
                    icon: Icons.bedtime_outlined,
                    label: 'Son uyku',
                    value: snap.sleepMinutes == null
                        ? '—'
                        : '${(snap.sleepMinutes! / 60).floor()}s '
                            '${snap.sleepMinutes! % 60}dk',
                    unit: '',
                  ),
                  _MetricCard(
                    icon: Icons.air_rounded,
                    label: 'SpO₂ (son)',
                    value: snap.spo2.isEmpty
                        ? '—'
                        : snap.spo2.last.value.round().toString(),
                    unit: '%',
                  ),
                ],
              ),

              if (snap.heartRates.length >= 2)
                NeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nabız',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: r.gapSm),
                      TrendChart(
                        points: [
                          for (final s in snap.heartRates)
                            (at: s.at, value: s.value),
                        ],
                        unit: '/dk',
                        decimals: 0,
                        refMin: settings.resolve('heart_rate_low').value,
                        refMax: settings.resolve('heart_rate_high').value,
                        height: r.s(190),
                      ),
                      SizedBox(height: r.gapXs),
                      Text(
                        'Gölgeli alan senin alarm eşiklerinin arasıdır.',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),

              if (snap.bloodPressure.length >= 2)
                NeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tansiyon (saatten)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: r.gapSm),
                      TrendChart(
                        points: [
                          for (final s in snap.bloodPressure)
                            (at: s.at, value: s.value),
                        ],
                        secondarySeries: [
                          for (final s in snap.bloodPressure)
                            if (s.extra != null)
                              (at: s.at, value: s.extra!),
                        ],
                        unit: 'mmHg',
                        decimals: 0,
                        targetLine:
                            settings.resolve('bp_systolic_target').value,
                        targetLabelTr: 'hedef sistolik',
                        height: r.s(200),
                      ),
                    ],
                  ),
                ),

              if (snap.spo2.length >= 2)
                NeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SpO₂',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: r.gapSm),
                      TrendChart(
                        points: [
                          for (final s in snap.spo2)
                            (at: s.at, value: s.value),
                        ],
                        unit: '%',
                        decimals: 0,
                        targetLine: settings.resolve('spo2_warn').value,
                        targetLabelTr: 'uyarı eşiği',
                        height: r.s(180),
                      ),
                    ],
                  ),
                ),

              // --- AI yorumu ---
              NeuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: p.accent),
                        SizedBox(width: r.gapSm),
                        Expanded(
                          child: Text(
                            'Yapay zekaya yorumlat',
                            style:
                                Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: r.gapSm),
                    Text(
                      conn == AiConnectionState.ok
                          ? 'Son 7 günün eğilimini özetler. '
                              'Teşhis koymaz, ilaç önermez.'
                          : 'Önce Ayarlar > Yapay Zeka Bağlantısı '
                              'bölümünden anahtarını eklemen gerekiyor.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    SizedBox(height: r.gapMd),
                    NeuButton(
                      label: _aiBusy
                          ? 'Yorumlanıyor…'
                          : (conn == AiConnectionState.ok
                              ? 'Yorumlat'
                              : 'Bağlantıyı kur'),
                      icon: Icons.psychology_outlined,
                      tone: NeuTone.accent,
                      expanded: true,
                      onPressed: _aiBusy
                          ? null
                          : (conn == AiConnectionState.ok
                              ? _interpret
                              : () => context.push(Routes.aiConnection)),
                    ),
                    if (_aiInterpretation != null) ...[
                      SizedBox(height: r.gapMd),
                      Container(
                        padding: EdgeInsets.all(r.gapMd),
                        decoration: BoxDecoration(
                          color: p.accentSoft.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _aiInterpretation!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      SizedBox(height: r.gapSm),
                      const MedicalDisclaimerBanner(compact: true),
                    ],
                  ],
                ),
              ),
            ] else if (_hasPermission && !_loading)
              EmptyState(
                title: 'Veri bulunamadı',
                message: Platform.isIOS
                    ? 'Sağlık uygulamasında son 7 güne ait kayıt yok. '
                        'Apple Watch\'unun iPhone\'la eşleşmiş ve '
                        'eşitlenmiş olduğunu, izin ekranında veri '
                        'türlerini açtığını kontrol et (Ayarlar > '
                        'Sağlık > Veri Erişimi ve Cihazlar > Böbrek '
                        'Dostu).'
                    : 'Health Connect\'te son 7 güne ait kayıt yok. '
                        'Saatini telefonla eşitlemeyi ve saatinin '
                        'uygulamasının Health Connect\'e yazma izni '
                        'olduğunu kontrol et.',
                icon: Icons.watch_off_outlined,
              ),

            // --- EKG dürüst açıklama ---
            NeuCard(
              color: p.info.withValues(alpha: p.isDark ? 0.14 : 0.07),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.monitor_heart_outlined, color: p.info),
                      SizedBox(width: r.gapSm),
                      Expanded(
                        child: Text(
                          'EKG verisi',
                          style:
                              Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.gapSm),
                  Text(
                    kEcgExplanationTr,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (snap != null && snap.ecgRecords.isNotEmpty) ...[
                    SizedBox(height: r.gapMd),
                    Text(
                      'Son kayıtlar (${snap.ecgRecords.length})',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SizedBox(height: r.gapXs),
                    for (final e in snap.ecgRecords.take(8))
                      Padding(
                        padding: EdgeInsets.only(bottom: r.gapXs),
                        child: Row(
                          children: [
                            Icon(
                              Icons.monitor_heart_outlined,
                              size: r.s(16),
                              color: p.info,
                            ),
                            SizedBox(width: r.gapSm),
                            Expanded(
                              child: Text(
                                '${_fmtDate(e.at)} · '
                                '${e.classificationTr}'
                                '${e.averageHeartRate == null ? "" : " · "
                                    "${e.averageHeartRate!.round()} /dk"}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: r.gapXs),
                    Text(
                      'Bu satırlar Apple\'ın kendi sınıflandırmasıdır; '
                      'uygulama üstüne yorum eklemez.',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
            ),

            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Doğruluk hakkında',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: r.gapXs),
                  Text(
                    'Akıllı saat ölçümleri TIBBİ CİHAZ DOĞRULUĞUNDA '
                    'DEĞİLDİR. Özellikle saatten alınan tansiyon ve '
                    'SpO₂ değerleri tek başına klinik karara temel '
                    'olmaz. Uygulama '
                    '${HealthService.providerNameTr}\'na hiçbir şey '
                    'YAZMAZ, yalnızca okur.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}';
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    return NeuCard(
      padding: EdgeInsets.all(r.gapMd),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(r.gapSm),
            decoration: BoxDecoration(
              color: p.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: p.primary, size: r.s(20)),
          ),
          SizedBox(width: r.gapSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: AppTypography.numeric(p, size: r.s(21)),
                      ),
                      if (unit.isNotEmpty) ...[
                        const SizedBox(width: 3),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            unit,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
