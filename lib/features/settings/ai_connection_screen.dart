import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/ai_config.dart';
import '../../core/providers.dart';
import '../../core/services/ai_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/responsive.dart';

/// Yapay Zeka Bağlantısı ekranı.
///
/// Anahtar yalnızca cihazda, flutter_secure_storage içinde şifreli
/// saklanır. Kodda ve depoda anahtar YOKTUR.
class AiConnectionScreen extends ConsumerStatefulWidget {
  const AiConnectionScreen({super.key});

  @override
  ConsumerState<AiConnectionScreen> createState() =>
      _AiConnectionScreenState();
}

class _AiConnectionScreenState extends ConsumerState<AiConnectionScreen> {
  final _key = TextEditingController();
  bool _obscure = true;
  bool _testing = false;
  AiTestResult? _result;
  bool _guideOpen = false;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _testAndSave() async {
    setState(() {
      _testing = true;
      _result = null;
    });
    final model =
        ref.read(preferencesProvider).aiModel ?? AiConfig.defaultModel;
    final result = await ref
        .read(aiConnectionProvider.notifier)
        .saveAndTest(_key.text.trim(), model: model);
    if (!mounted) return;
    setState(() {
      _testing = false;
      _result = result;
      if (result.ok) _key.clear();
    });
  }

  Future<void> _retest() async {
    setState(() {
      _testing = true;
      _result = null;
    });
    final model =
        ref.read(preferencesProvider).aiModel ?? AiConfig.defaultModel;
    final result =
        await ref.read(aiConnectionProvider.notifier).retest(model: model);
    if (!mounted) return;
    setState(() {
      _testing = false;
      _result = result;
    });
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anahtarı sil'),
        content: const Text(
          'Kayıtlı Anthropic anahtarı telefondan silinecek. '
          'Yapay zeka özellikleri kapanır; uygulamanın geri kalanı '
          'çalışmaya devam eder. Anahtarı Anthropic hesabından '
          'silmez — orada hâlâ geçerli olur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(aiConnectionProvider.notifier).deleteKey();
    if (mounted) setState(() => _result = null);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final conn = ref.watch(aiConnectionProvider);
    final prefs = ref.watch(preferencesProvider);
    final state = conn.value ?? AiConnectionState.noKey;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(title: const Text('Yapay Zeka Bağlantısı')),
      body: SafeArea(
        child: PageBody(
          children: [
            // --- durum kartı ---
            GlassCard(
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(r.gapSm),
                    decoration: BoxDecoration(
                      color: switch (state) {
                        AiConnectionState.ok => p.primarySoft,
                        AiConnectionState.failed =>
                          p.danger.withValues(alpha: 0.15),
                        _ => p.backgroundDeep,
                      },
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      switch (state) {
                        AiConnectionState.ok => Icons.verified_rounded,
                        AiConnectionState.failed => Icons.error_outline_rounded,
                        AiConnectionState.untested =>
                          Icons.help_outline_rounded,
                        AiConnectionState.noKey => Icons.key_off_outlined,
                      },
                      size: r.s(26),
                      color: switch (state) {
                        AiConnectionState.ok => p.success,
                        AiConnectionState.failed => p.danger,
                        _ => p.textMuted,
                      },
                    ),
                  ),
                  SizedBox(width: r.gapMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          switch (state) {
                            AiConnectionState.ok => 'Bağlantı kurulu',
                            AiConnectionState.failed => 'Bağlantı başarısız',
                            AiConnectionState.untested =>
                              'Anahtar var, test edilmedi',
                            AiConnectionState.noKey => 'Anahtar yok',
                          },
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: r.s(3)),
                        Text(
                          switch (state) {
                            AiConnectionState.ok =>
                              'Yapay zeka özellikleri kullanılabilir.',
                            AiConnectionState.failed =>
                              'Aşağıdaki mesaja bak ve tekrar dene.',
                            AiConnectionState.untested =>
                              '"Bağlantıyı test et" ile doğrula.',
                            AiConnectionState.noKey =>
                              'Yapay zeka özellikleri kapalı; uygulamanın '
                                  'geri kalanı normal çalışır.',
                          },
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- anahtar girişi ---
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LabeledField(
                    label: state == AiConnectionState.noKey
                        ? 'Anthropic API anahtarı'
                        : 'Yeni anahtar (değiştirmek için)',
                    hint: 'Anahtar "sk-ant-" ile başlar. '
                        'Yalnızca bu telefonda, şifreli olarak saklanır.',
                    child: TextField(
                      controller: _key,
                      obscureText: _obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: 'sk-ant-...',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: _obscure ? 'Göster' : 'Gizle',
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  SizedBox(height: r.gapMd),
                  NeuButton(
                    label: _testing
                        ? 'Test ediliyor…'
                        : (_key.text.trim().isEmpty
                            ? 'Bağlantıyı test et'
                            : 'Kaydet ve test et'),
                    icon: Icons.network_check_rounded,
                    expanded: true,
                    onPressed: _testing
                        ? null
                        : (_key.text.trim().isEmpty
                            ? (state == AiConnectionState.noKey
                                ? null
                                : _retest)
                            : _testAndSave),
                  ),
                  SizedBox(height: r.gapSm),
                  Text(
                    'Test, hesabındaki model listesini sorar. '
                    'TOKEN HARCAMAZ — istediğin kadar çalıştırabilirsin.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  if (state != AiConnectionState.noKey) ...[
                    SizedBox(height: r.gapSm),
                    TextButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Kayıtlı anahtarı sil'),
                      style: TextButton.styleFrom(foregroundColor: p.danger),
                    ),
                  ],
                ],
              ),
            ),

            // --- test sonucu ---
            if (_result != null)
              NeuCard(
                color: _result!.ok
                    ? p.primarySoft
                    : p.danger.withValues(alpha: p.isDark ? 0.16 : 0.09),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _result!.ok
                              ? Icons.check_circle_outline_rounded
                              : Icons.error_outline_rounded,
                          color: _result!.ok ? p.success : p.danger,
                        ),
                        SizedBox(width: r.gapSm),
                        Expanded(
                          child: Text(
                            _result!.ok ? 'Test başarılı' : 'Test başarısız',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color:
                                      _result!.ok ? p.success : p.danger,
                                ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: r.gapSm),
                    Text(
                      _result!.messageTr,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_result!.availableModels.isNotEmpty) ...[
                      SizedBox(height: r.gapSm),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        title: Text(
                          'Erişebildiğin modeller '
                          '(${_result!.availableModels.length})',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        children: [
                          for (final m in _result!.availableModels)
                            Padding(
                              padding: EdgeInsets.only(bottom: r.gapXs),
                              child: Text(
                                m,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

            // --- model seçimi ---
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Model',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: r.gapXs),
                  Text(
                    'Model adı tek bir yapılandırma dosyasında tutulur '
                    '(lib/core/config/ai_config.dart) — buradan '
                    'seçebilir ya da kodda değiştirebilirsin.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: r.gapMd),
                  for (final m in AiConfig.models)
                    RadioListTile<String>(
                      value: m.id,
                      // ignore: deprecated_member_use
                      groupValue: prefs.aiModel ?? AiConfig.defaultModel,
                      // ignore: deprecated_member_use
                      onChanged: (v) {
                        if (v == null) return;
                        ref
                            .read(preferencesProvider.notifier)
                            .update((p) => p.copyWith(aiModel: v));
                      },
                      title: Text(m.labelTr),
                      subtitle: Text(
                        '${m.noteTr}\n${m.id}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      isThreeLine: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),

            // --- "Anahtarı nasıl alırım?" rehberi ---
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: () => setState(() => _guideOpen = !_guideOpen),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: r.gapXs),
                      child: Row(
                        children: [
                          Icon(Icons.help_outline_rounded, color: p.accent),
                          SizedBox(width: r.gapSm),
                          Expanded(
                            child: Text(
                              'Anahtarı nasıl alırım?',
                              style:
                                  Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Icon(
                            _guideOpen
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: r.gapSm),
                        for (final step in _guideSteps.indexed)
                          Padding(
                            padding: EdgeInsets.only(bottom: r.gapSm),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: r.s(24),
                                  height: r.s(24),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: p.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${step.$1 + 1}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: p.onPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                SizedBox(width: r.gapSm),
                                Expanded(
                                  child: Text(
                                    step.$2,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: r.gapSm),
                        NeuButton(
                          label: 'Anthropic konsolunu aç',
                          icon: Icons.open_in_new_rounded,
                          filled: false,
                          expanded: true,
                          onPressed: () => _open(AiConfig.apiKeysUrl),
                        ),
                        SizedBox(height: r.gapSm),
                        Container(
                          padding: EdgeInsets.all(r.gapSm),
                          decoration: BoxDecoration(
                            color: p.accentSoft.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Ücret: Anthropic kullandığın kadar '
                            'ücretlendirir. Kısa sorular kuruş '
                            'mertebesindedir; fotoğraf analizi daha '
                            'pahalıdır. Konsolda aylık harcama limiti '
                            'koyabilirsin — ilk kez kullanıyorsan '
                            'bunu yapman önerilir.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    crossFadeState: _guideOpen
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                  ),
                ],
              ),
            ),

            // --- veri gönderme onayı ---
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Yapay zekaya ne gönderilsin?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: r.gapXs),
                  Text(
                    'Yalnızca yapay zeka özelliklerini kullandığında, '
                    'seçtiğin veriler Anthropic Claude API\'sine '
                    'gönderilir. Adın, telefon numaran, doktorunun '
                    'bilgileri ve acil durum kişilerin HİÇBİR ZAMAN '
                    'gönderilmez.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: r.gapSm),
                  SwitchListTile.adaptive(
                    value: prefs.aiShareClinicalSettings,
                    onChanged: (v) => ref
                        .read(preferencesProvider.notifier)
                        .update((p) => p.copyWith(
                              aiShareClinicalSettings: v,
                            )),
                    title: const Text('Klinik ayarlarım'),
                    subtitle: const Text(
                      'Diyet hedefleri ve alarm eşikleri. '
                      'Kapatırsan öneriler genel kalır.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile.adaptive(
                    value: prefs.aiShareLabs,
                    onChanged: (v) => ref
                        .read(preferencesProvider.notifier)
                        .update((p) => p.copyWith(aiShareLabs: v)),
                    title: const Text('Son tahlillerim'),
                    subtitle: const Text('En son 20 tahlil sonucu.'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile.adaptive(
                    value: prefs.aiShareMedications,
                    onChanged: (v) => ref
                        .read(preferencesProvider.notifier)
                        .update(
                          (p) => p.copyWith(aiShareMedications: v),
                        ),
                    title: const Text('İlaç listem'),
                    subtitle: const Text('Ad, doz ve saatler.'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            NeuCard(
              color: p.backgroundDeep.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, size: r.s(17)),
                      SizedBox(width: r.gapSm),
                      Expanded(
                        child: Text(
                          'Anahtar nerede duruyor?',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.gapSm),
                  Text(
                    'Anahtar Android\'in şifreli anahtar deposunda '
                    '(Keystore destekli EncryptedSharedPreferences) '
                    'tutulur. Uygulama kodunda veya yedek dosyasında '
                    'YER ALMAZ. JSON yedeğine de dahil edilmez.',
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

  static const List<String> _guideSteps = [
    'platform.claude.com adresine git ve hesap aç '
        '(e-posta ile ücretsiz kayıt).',
    'Hesabına kredi yükle: sol menüden "Billing" (Faturalandırma) → '
        '"Add credits". Anahtar, kredi olmadan istek gönderemez.',
    'Sol menüden "API keys" (API anahtarları) bölümüne gir.',
    '"Create key" (Anahtar oluştur) düğmesine bas, bir isim ver '
        '(örn. "telefon").',
    'Anahtar bir kez gösterilir. "Copy" ile kopyala — '
        'sonradan bir daha göremezsin.',
    'Bu ekrandaki alana yapıştır (göz ikonuyla doğru '
        'yapıştırdığını kontrol edebilirsin) ve "Kaydet ve test et"e bas.',
    'Yararlı: konsolda "Limits" bölümünden aylık harcama sınırı koy. '
        'Böylece beklenmedik fatura olmaz.',
  ];

  static Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
