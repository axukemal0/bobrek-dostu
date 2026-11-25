import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/motion.dart';

/// Hedef halkası (sıvı bütçesi, besin öğeleri).
///
/// [ratio] null ise "hedef yok" demektir: halka ince ve nötr çizilir,
/// hiçbir renk "aşım" ima etmez.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.ratio,
    required this.label,
    required this.valueText,
    this.unitText,
    this.size = 120,
    this.strokeWidth,
    this.tone,
    this.noTargetHintTr = 'hedef yok',
    super.key,
  });

  /// 0..1+ doluluk. 1'in üstü aşım demektir. null => hedef yok.
  final double? ratio;
  final String label;
  final String valueText;
  final String? unitText;
  final double size;
  final double? strokeWidth;
  final Color? tone;
  final String noTargetHintTr;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final motion = context.motion;
    final stroke = strokeWidth ?? size * 0.095;

    final Color color;
    if (ratio == null) {
      // Hedef yokken de alanın kendi rengi kalsın (soluk): kart boş da
      // olsa neye ait olduğu belli olsun.
      color = (tone ?? p.textMuted).withValues(alpha: 0.55);
    } else if (ratio! > 1.0) {
      color = p.danger;
    } else if (ratio! >= 0.9) {
      color = p.warning;
    } else {
      color = tone ?? p.primary;
    }

    final semantic = ratio == null
        ? '$label: $valueText ${unitText ?? ''}, hedef belirtilmemiş'
        : '$label: $valueText ${unitText ?? ''}, '
              'hedefin yüzde ${(ratio! * 100).round()}\'i';

    return Semantics(
      label: semantic,
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: (ratio ?? 0).clamp(0.0, 1.35)),
          duration: motion.slow,
          curve: motion.emphasized,
          // Halka kendi katmanında kalsın: etrafındaki sayfa değişince
          // yeniden rasterleştirilmesin.
          builder: (context, animated, _) => RepaintBoundary(
            child: CustomPaint(
              painter: _RingPainter(
                ratio: ratio == null ? null : animated,
                color: color,
                trackColor: p.isDark
                    ? p.backgroundDeep
                    : p.backgroundDeep.withValues(alpha: 0.85),
                overflowColor: p.danger,
                strokeWidth: stroke,
                dashed: ratio == null,
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(stroke + size * 0.06),
                  child: FittedBox(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          valueText,
                          style: AppTypography.numeric(p, size: size * 0.26),
                        ),
                        if (unitText != null)
                          Text(
                            unitText!,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: p.textMuted),
                          ),
                        if (ratio == null)
                          Text(
                            noTargetHintTr,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: p.textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.ratio,
    required this.color,
    required this.trackColor,
    required this.overflowColor,
    required this.strokeWidth,
    required this.dashed,
  });

  final double? ratio;
  final Color color;
  final Color trackColor;
  final Color overflowColor;
  final double strokeWidth;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    const start = -math.pi / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    if (dashed) {
      // Hedef yok: ince, kesiksiz nötr halka.
      //
      // Önceden bu durum kesik kesik çiziliyordu; cihazda bozuk bir çizim
      // gibi görünüyordu ve aynı ekrandaki besin ölçeklerinin "hedef yok"
      // gösterimiyle (kenarlıklı boş kanal) çelişiyordu. Artık ikisi de
      // aynı şeyi söylüyor: dolu olmayan, sakin bir kanal.
      canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 0.5
          ..color = color,
      );
      return;
    }

    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final r = ratio ?? 0;
    final main = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    final clamped = r.clamp(0.0, 1.0);
    if (clamped > 0) {
      canvas.drawArc(rect, start, math.pi * 2 * clamped, false, main);
    }

    // Aşım: dışa doğru ikinci, daha ince bir yay.
    if (r > 1.0) {
      final overflow = (r - 1.0).clamp(0.0, 1.0);
      final outer = rect.inflate(strokeWidth * 0.1);
      canvas.drawArc(
        outer,
        start,
        math.pi * 2 * overflow,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 0.42
          ..strokeCap = StrokeCap.round
          ..color = overflowColor,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.ratio != ratio ||
      old.color != color ||
      old.dashed != dashed ||
      old.strokeWidth != strokeWidth;
}
