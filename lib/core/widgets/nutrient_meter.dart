import 'package:material_ui/material_ui.dart';

import '../../clinical/evaluator.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/motion.dart';
import 'responsive.dart';

/// Bir besin öğesinin günlük durumu: ad, değer/hedef ve ince bir ölçek.
///
/// Önceden bunlar yan yana beş halkaydı. 440 pt'lik bir telefonda beşincisi
/// ekrandan taşıyor, yatay kaydırmayla erişiliyordu — kartın kendisi de
/// tıklanabilir olduğu için jestler çakışıyordu ve kullanıcı potasyumu
/// görmek için kaydırması gerektiğini anlamıyordu. Böbrek hastası için
/// beş değerin BİRLİKTE görünmesi işin özü, o yüzden hepsi tek bakışta
/// sığan yatay ölçeklere çevrildi. Hedef de artık görünüyor.
class NutrientMeter extends StatelessWidget {
  const NutrientMeter({required this.total, super.key});

  final NutrientTotal total;

  /// Sayıyı birimine göre makul ondalıkla yazar.
  /// (Enerjide "0,0 kcal" yazmak anlamsızdı.)
  static String formatValue(double v, String unit) {
    final decimals = switch (unit) {
      'kcal' => 0,
      'mg' => 0,
      'mL' => 0,
      _ => v >= 100 ? 0 : 1,
    };
    return v.toStringAsFixed(decimals).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final text = Theme.of(context).textTheme;

    final ratio = total.ratio;
    final over = total.isOverTarget;
    final near = ratio != null && ratio >= 0.85 && !over;

    // Renk hem KATEGORİ hem DURUM taşır: hedefin içindeyken besinin kendi
    // rengi (potasyumu fosfordan tek bakışta ayırmak için), eşiğe
    // yaklaşınca kehribar, aşınca kırmızı. Anlam renge emanet edilmez —
    // adı ve sayısı zaten yanında yazıyor.
    final barColor = over
        ? p.danger
        : near
            ? p.warning
            : p.accents.forNutrient(total.key);

    final valueText = StringBuffer()
      ..write(total.isPartial ? 'en az ' : '')
      ..write(formatValue(total.value, total.unit));

    return Semantics(
      label: '${total.labelTr}: $valueText ${total.unit}'
          '${total.hasTarget ? ", hedef ${formatValue(total.target!, total.unit)}" : ", hedef yok"}'
          '${over ? ", hedef aşıldı" : ""}',
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.only(bottom: r.gapSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: p.accents.forNutrient(total.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      total.labelTr,
                      style: text.bodyMedium?.copyWith(color: p.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: r.gapXs),
                  Text(
                    valueText.toString(),
                    style: AppTypography.numericSmall(
                      p,
                      size: 15,
                      color: over ? p.danger : p.textPrimary,
                    ),
                  ),
                  Text(
                    total.hasTarget
                        ? ' / ${formatValue(total.target!, total.unit)} ${total.unit}'
                        : ' ${total.unit}',
                    style: AppTypography.numericSmall(p, size: 13),
                  ),
                ],
              ),
              SizedBox(height: r.gapXs * 0.6),
              _Bar(
                ratio: ratio,
                color: barColor,
                track: p.accents
                    .forNutrient(total.key)
                    .withValues(alpha: p.isDark ? 0.22 : 0.16),
              ),
              if (!total.hasTarget)
                Padding(
                  padding: EdgeInsets.only(top: r.gapXs * 0.5),
                  child: Text('hedef girilmemiş', style: text.labelSmall),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.ratio, required this.color, required this.track});

  final double? ratio;
  final Color color;

  /// Boş kanalın rengi — besinin kendi renginin soluk hâli. Veri sıfırken
  /// bile satırın hangi besine ait olduğu görünsün diye.
  final Color track;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;

    // Hedef yoksa ölçek doldurulmaz; boş bir kanal gösterilir.
    if (ratio == null) {
      return Container(
        height: 7,
        decoration: BoxDecoration(
          color: track,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
      );
    }

    final clamped = ratio!.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 7,
        color: track,
        child: Align(
          alignment: Alignment.centerLeft,
          child: LayoutBuilder(
            builder: (context, c) => AnimatedContainer(
              duration: motion.normal,
              curve: motion.enter,
              width: c.maxWidth * clamped,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
