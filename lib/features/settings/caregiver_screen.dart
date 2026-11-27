import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' hide Text;
import 'package:share_plus/share_plus.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/responsive.dart';
import '../../core/i18n/text.dart';

/// Yakın modu — v1'de uzak senkronizasyon YOK.
/// Özet cihazda üretilir, kullanıcı paylaşır.
class CaregiverScreen extends ConsumerStatefulWidget {
  const CaregiverScreen({super.key});

  @override
  ConsumerState<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends ConsumerState<CaregiverScreen> {
  int _days = 7;
  bool _busy = false;
  String? _summary;

  Future<void> _build() async {
    setState(() => _busy = true);
    final text = await ref
        .read(caregiverServiceProvider)
        .buildShareSummary(window: Duration(days: _days));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _summary = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final contacts =
        ref.watch(emergencyContactsProvider).value ?? const [];
    final sync = ref.watch(syncRepositoryProvider);

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(title: const Text('Yakın modu')),
      body: SafeArea(
        child: PageBody(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yakınlarını haberdar et',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: r.gapSm),
                  Text(
                    'İlaç uyumun, tansiyonun, kilon ve varsa uyarıların '
                    'tek bir özette toplanır. Özet TELEFONDA üretilir; '
                    'kimseye otomatik gönderilmez — paylaşmak senin '
                    'elinde.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Hangi dönem?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: r.gapSm),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('Günlük')),
                      ButtonSegment(value: 7, label: Text('Haftalık')),
                    ],
                    selected: {_days},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) =>
                        setState(() => _days = s.first),
                  ),
                  SizedBox(height: r.gapMd),
                  NeuButton(
                    label: _busy ? 'Hazırlanıyor…' : 'Özeti oluştur',
                    icon: Icons.summarize_outlined,
                    expanded: true,
                    onPressed: _busy ? null : _build,
                  ),
                ],
              ),
            ),

            if (_summary != null)
              NeuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Özet',
                            style:
                                Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TapIcon(
                          icon: Icons.volume_up_outlined,
                          semanticLabel: 'Özeti sesli oku',
                          onPressed: () =>
                              ref.read(ttsServiceProvider).speak(_summary!),
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
                        _summary!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    SizedBox(height: r.gapMd),
                    NeuButton(
                      label: 'Paylaş (WhatsApp, SMS, e-posta…)',
                      icon: Icons.ios_share_rounded,
                      expanded: true,
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(text: _summary!),
                      ),
                    ),
                    if (contacts.isNotEmpty) ...[
                      SizedBox(height: r.gapSm),
                      NeuButton(
                        label: 'Acil kişilere SMS olarak hazırla',
                        icon: Icons.sms_outlined,
                        filled: false,
                        expanded: true,
                        onPressed: () => ref
                            .read(smsServiceProvider)
                            .openComposer(
                              phoneNumbers:
                                  contacts.map((c) => c.phone).toList(),
                              message: _summary!,
                            ),
                      ),
                    ],
                  ],
                ),
              ),

            // --- v1 sınırı ---
            NeuCard(
              color: p.info.withValues(alpha: p.isDark ? 0.14 : 0.07),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud_off_outlined, color: p.info),
                      SizedBox(width: r.gapSm),
                      Expanded(
                        child: Text(
                          'Uzak senkronizasyon yok (v1)',
                          style:
                              Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.gapSm),
                  Text(
                    'Bu sürümde sunucu yoktur: yakınların uygulamayı '
                    'kendi telefonlarından açıp verilerini '
                    'göremez. Paylaşım, yukarıdaki özet metniyle '
                    'yapılır.\n\n'
                    'Kodda gelecekte bir arka uç (örn. Firebase) '
                    'eklenebilmesi için SyncRepository arayüzü '
                    'bırakılmıştır; şu anki uygulaması hiçbir yere '
                    'veri göndermez.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: r.gapSm),
                  Text(
                    'Durum: ${sync.isEnabled ? "açık" : "kapalı"}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
