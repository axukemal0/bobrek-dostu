import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../clinical/definitions.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/responsive.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  int _months = 3;
  bool _busy = false;
  String? _statusTr;

  Future<void> _run({required bool share}) async {
    setState(() {
      _busy = true;
      _statusTr = 'Rapor hazırlanıyor…';
    });
    try {
      final service = ref.read(reportServiceProvider);
      final window = Duration(days: _months * 30);
      if (share) {
        await service.shareReport(window: window);
      } else {
        await service.printReport(window: window);
      }
      if (mounted) {
        setState(() {
          _busy = false;
          _statusTr = null;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _statusTr = 'Rapor oluşturulamadı: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final labs = ref.watch(labResultsProvider).value ?? const [];
    final vitals = ref.watch(vitalsProvider).value ?? const [];
    final meds = ref.watch(medicationsProvider).value ?? const [];

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(title: const Text('Doktor raporu')),
      body: SafeArea(
        child: PageBody(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tek dokunuşla PDF',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: r.gapSm),
                  Text(
                    'Tahliller, tansiyon, kilo, ilaç uyumu, sıvı ve '
                    'besin özeti, grafikler ve kendi klinik ayarların '
                    'tek bir PDF\'te toplanır. Rapor telefonda '
                    'oluşturulur, hiçbir sunucuya gitmez.',
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
                      ButtonSegment(value: 1, label: Text('Son 1 ay')),
                      ButtonSegment(value: 3, label: Text('Son 3 ay')),
                    ],
                    selected: {_months},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) =>
                        setState(() => _months = s.first),
                  ),
                  SizedBox(height: r.gapMd),
                  NeuButton(
                    label: _busy ? 'Hazırlanıyor…' : 'PDF oluştur ve paylaş',
                    icon: Icons.ios_share_rounded,
                    expanded: true,
                    onPressed: _busy ? null : () => _run(share: true),
                  ),
                  SizedBox(height: r.gapSm),
                  NeuButton(
                    label: 'Önizle / yazdır',
                    icon: Icons.print_outlined,
                    filled: false,
                    expanded: true,
                    onPressed: _busy ? null : () => _run(share: false),
                  ),
                ],
              ),
            ),

            if (_statusTr != null)
              NeuCard(
                color: p.accentSoft.withValues(alpha: 0.5),
                child: Text(
                  _statusTr!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

            // --- içerik özeti ---
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Raporda ne olacak?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: r.gapSm),
                  for (final item in <({String label, String detail})>[
                    (
                      label: 'Hasta bilgileri',
                      detail: 'Ad, yaş, boy/kilo, durum, kuru ağırlık, '
                          'ek hastalıklar, alerjiler, hekim',
                    ),
                    (
                      label: 'Klinik ayarların',
                      detail: 'Her hedef ve alarm eşiği, yanında '
                          '"hekim ayarı" veya doğrulama durumu',
                    ),
                    (
                      label: 'Laboratuvar (${labs.length} kayıt)',
                      detail: 'Analit bazında ilk/son değer, değişim, '
                          'laboratuvar aralığı',
                    ),
                    (
                      label: 'Kan basıncı',
                      detail: 'Ortalama, en yüksek/düşük, eşik aşan '
                          'ölçüm sayısı ve sistolik grafiği',
                    ),
                    (
                      label: 'Kilo ve sıvı yükü (${vitals.length} ölçüm)',
                      detail: 'Kilo grafiği ve diyaliz arası kilo artışı',
                    ),
                    (
                      label: 'İlaç uyumu (${meds.length} ilaç)',
                      detail: 'Alınan/atlanan doz oranı ve ilaç listesi',
                    ),
                    (
                      label: 'Besin ve sıvı',
                      detail: 'Günlük ortalamalar, hedeflerle kıyas',
                    ),
                    (
                      label: 'Kaynaklar',
                      detail: 'Uygulamanın kullandığı tüm kılavuzlar, '
                          'yıl ve bağlantılarıyla',
                    ),
                  ])
                    Padding(
                      padding: EdgeInsets.only(bottom: r.gapSm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: r.s(16),
                            color: p.primary,
                          ),
                          SizedBox(width: r.gapSm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall,
                                ),
                                Text(
                                  item.detail,
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
                ],
              ),
            ),

            NeuCard(
              color: p.backgroundDeep.withValues(alpha: 0.45),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dürüstlük notu',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: r.gapSm),
                  Text(
                    'Rapor yalnızca GİRDİĞİN verilere dayanır: '
                    'kaydetmediğin öğünler besin ortalamasını düşürür, '
                    'işaretlemediğin ilaç dozları "işaretlenmedi" '
                    'olarak görünür (alınmamış sayılmaz). '
                    'Besin değerleri yaklaşıktır. '
                    'Her sayfanın altında şu uyarı yer alır: '
                    '"$kMedicalDisclaimerTr"',
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
}
