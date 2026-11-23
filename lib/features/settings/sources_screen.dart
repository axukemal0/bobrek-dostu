import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../clinical/definitions.dart';
import '../../clinical/drug_safety.dart';
import '../../clinical/sources.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/responsive.dart';

/// Kaynaklar ekranı: uygulamadaki her klinik değerin dayandığı
/// kaynak adı + yıl + URL.
class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);

    // Her kaynağın hangi değerlerde kullanıldığını topla.
    final usage = <String, List<String>>{};
    for (final def in kAllDefinitions) {
      for (final id in def.sourceIds) {
        usage.putIfAbsent(id, () => []).add(def.labelTr);
      }
    }
    for (final risk in kAllDrugRisks) {
      for (final id in risk.sourceIds) {
        usage.putIfAbsent(id, () => []);
      }
    }

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(title: const Text('Kaynaklar')),
      body: SafeArea(
        child: PageBody(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Değerler nereden geliyor?',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: r.gapSm),
                  Text(
                    'Uygulamadaki her klinik eşik ve hedef, aşağıdaki '
                    'kaynaklardan birine dayanır. Doğrulayamadığımız '
                    'değerler "doğrulanmadı", kılavuzun sayı vermediği '
                    'değerler "bireyselleştirilir" olarak işaretlidir.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: r.gapSm),
                  Row(
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        size: r.s(15),
                        color: p.textMuted,
                      ),
                      SizedBox(width: r.gapXs),
                      Expanded(
                        child: Text(
                          'Bağlantılar son kez '
                          '$kSourcesLastCheckedTr tarihinde kontrol edildi.',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- doğrulama etiketleri açıklaması ---
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Etiketler ne demek?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: r.gapSm),
                  for (final v in Verification.values)
                    Padding(
                      padding: EdgeInsets.only(bottom: r.gapSm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VerificationChip(verification: v, dense: true),
                          SizedBox(width: r.gapSm),
                          Expanded(
                            child: Text(
                              v.explanationTr,
                              style:
                                  Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SectionHeader(
              title: 'Kaynak listesi',
              icon: Icons.menu_book_outlined,
            ),

            for (final s in kClinicalSources)
              NeuCard(
                margin: EdgeInsets.only(bottom: r.gapSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: r.gapSm,
                            vertical: r.s(3),
                          ),
                          decoration: BoxDecoration(
                            color: p.primarySoft,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            s.tier.labelTr,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: p.success,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${s.year}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                    SizedBox(height: r.gapSm),
                    Text(
                      s.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (s.noteTr != null) ...[
                      SizedBox(height: r.gapSm),
                      Text(
                        s.noteTr!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if ((usage[s.id] ?? []).isNotEmpty) ...[
                      SizedBox(height: r.gapSm),
                      Text(
                        'Kullanıldığı değerler: '
                        '${usage[s.id]!.toSet().join(", ")}',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: p.textMuted),
                      ),
                    ],
                    SizedBox(height: r.gapSm),
                    InkWell(
                      onTap: () => _open(s.url),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: r.gapXs),
                        child: Row(
                          children: [
                            Icon(
                              Icons.open_in_new_rounded,
                              size: r.s(15),
                              color: p.info,
                            ),
                            SizedBox(width: r.gapXs),
                            Expanded(
                              child: Text(
                                s.url,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: p.info,
                                      decoration: TextDecoration.underline,
                                      decorationColor: p.info,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // --- ilaç veri seti uyarısı ---
            NeuCard(
              color: p.danger.withValues(alpha: p.isDark ? 0.14 : 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: p.danger),
                      SizedBox(width: r.gapSm),
                      Expanded(
                        child: Text(
                          'İlaç veri seti hakkında',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: p.danger),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.gapSm),
                  Text(
                    kDrugDatasetDisclaimerTr,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: r.gapSm),
                  Text(
                    'Veri setinde ${kNsaidRisks.length} NSAİİ etken '
                    'maddesi ve ${kHerbalRisks.length} bitkisel ürün / '
                    'riskli madde bulunuyor.',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),

            // --- besin verisi ---
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Besin değerleri hakkında',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: r.gapSm),
                  Text(
                    'Yerel besin tablosu TürKomp ve USDA FoodData '
                    'Central temel alınarak derlenmiştir; karışık '
                    'yemeklerde tarif bazlı tahmin kullanılmıştır. '
                    'Tüm değerler YAKLAŞIKTIR. Porsiyon, pişirme '
                    'yöntemi ve tarif değiştikçe — özellikle sodyum — '
                    'kat kat farklı olabilir.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: r.gapSm),
                  const ApproximateBadge(
                    labelTr: 'her besin değeri yaklaşıktır',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
