import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Açılış animasyonu: bir damla ve içinden çizilerek büyüyen yaprak.
///
/// [progress] 0 -> 1 arasında animasyon ilerlemesi.
/// "Hareketi azalt" açıkken çağıran taraf progress'i doğrudan 1 verir.
class DropLeafPainter extends CustomPainter {
  DropLeafPainter({
    required this.progress,
    required this.palette,
  });

  final double progress;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2;

    // Faz 1 (0 - 0.45): damla konturu çizilir.
    final dropT = (progress / 0.45).clamp(0.0, 1.0);
    // Faz 2 (0.35 - 0.8): yaprak gövdesi ve damarlar.
    final leafT = ((progress - 0.35) / 0.45).clamp(0.0, 1.0);
    // Faz 3 (0.7 - 1.0): yumuşak dolgu ve parıltı.
    final fillT = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);

    final dropPath = _dropPath(center, r * 0.92);

    // --- damla dolgusu (yumuşakça belirir) ---
    if (fillT > 0) {
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.primarySoft.withValues(alpha: 0.85 * fillT),
            palette.accentSoft.withValues(alpha: 0.55 * fillT),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r));
      canvas.drawPath(dropPath, fillPaint);
    }

    // --- damla konturu (çizilme efekti) ---
    _drawPartialPath(
      canvas,
      dropPath,
      dropT,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.055
        ..strokeCap = StrokeCap.round
        ..color = palette.primary,
    );

    // --- yaprak ---
    if (leafT > 0) {
      final leafPath = _leafPath(center, r * 0.58);
      if (fillT > 0) {
        canvas.drawPath(
          leafPath,
          Paint()..color = palette.primary.withValues(alpha: 0.16 * fillT),
        );
      }
      _drawPartialPath(
        canvas,
        leafPath,
        leafT,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.042
          ..strokeCap = StrokeCap.round
          ..color = palette.primary,
      );

      // orta damar
      final veinStart = center + Offset(0, r * 0.40);
      final veinEnd = center + Offset(0, -r * 0.44);
      final veinPath = Path()
        ..moveTo(veinStart.dx, veinStart.dy)
        ..quadraticBezierTo(
          center.dx + r * 0.05,
          center.dy,
          veinEnd.dx,
          veinEnd.dy,
        );
      _drawPartialPath(
        canvas,
        veinPath,
        leafT,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.028
          ..strokeCap = StrokeCap.round
          ..color = palette.accent.withValues(alpha: 0.9),
      );

      // yan damarlar
      for (var i = 0; i < 3; i++) {
        final t = 0.18 + i * 0.22;
        final localT = ((leafT - 0.35 - i * 0.14) / 0.3).clamp(0.0, 1.0);
        if (localT <= 0) continue;
        final y = center.dy + r * 0.34 - r * 0.62 * t;
        final span = r * 0.20 * (1 - t * 0.45);
        for (final dir in [-1.0, 1.0]) {
          final p = Path()
            ..moveTo(center.dx, y)
            ..quadraticBezierTo(
              center.dx + dir * span * 0.7,
              y - span * 0.1,
              center.dx + dir * span,
              y - span * 0.55,
            );
          _drawPartialPath(
            canvas,
            p,
            localT,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 0.022
              ..strokeCap = StrokeCap.round
              ..color = palette.accent.withValues(alpha: 0.7),
          );
        }
      }
    }

    // --- parıltı ---
    if (fillT > 0.4) {
      final glint = ((fillT - 0.4) / 0.6).clamp(0.0, 1.0);
      canvas.drawCircle(
        center + Offset(-r * 0.28, -r * 0.30),
        r * 0.10 * glint,
        Paint()..color = Colors.white.withValues(alpha: 0.55 * glint),
      );
    }
  }

  /// Damla biçimi: üstte sivri, altta yuvarlak.
  Path _dropPath(Offset c, double r) {
    final path = Path();
    final top = Offset(c.dx, c.dy - r);
    path.moveTo(top.dx, top.dy);
    path.cubicTo(
      c.dx + r * 0.72, c.dy - r * 0.34,
      c.dx + r, c.dy + r * 0.26,
      c.dx, c.dy + r,
    );
    path.cubicTo(
      c.dx - r, c.dy + r * 0.26,
      c.dx - r * 0.72, c.dy - r * 0.34,
      top.dx, top.dy,
    );
    path.close();
    return path;
  }

  /// Yaprak biçimi: iki yay, uçları sivri.
  Path _leafPath(Offset c, double r) {
    final path = Path();
    final tip = Offset(c.dx, c.dy - r * 0.78);
    final base = Offset(c.dx, c.dy + r * 0.70);
    path.moveTo(base.dx, base.dy);
    path.quadraticBezierTo(
      c.dx + r * 0.78, c.dy - r * 0.02,
      tip.dx, tip.dy,
    );
    path.quadraticBezierTo(
      c.dx - r * 0.78, c.dy - r * 0.02,
      base.dx, base.dy,
    );
    path.close();
    return path;
  }

  /// Bir yolun ilk [t] oranını çizer (çizilme animasyonu).
  void _drawPartialPath(Canvas canvas, Path path, double t, Paint paint) {
    if (t <= 0) return;
    if (t >= 1) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      final len = metric.length * t;
      if (len <= 0) continue;
      canvas.drawPath(metric.extractPath(0, len), paint);
    }
  }

  @override
  bool shouldRepaint(DropLeafPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.palette != palette;
}

/// Hazır kullanım: belirli boyutta animasyonlu damla-yaprak.
class DropLeafMark extends StatefulWidget {
  const DropLeafMark({
    this.size = 120,
    this.animate = true,
    this.duration = const Duration(milliseconds: 2200),
    this.onCompleted,
    super.key,
  });

  final double size;
  final bool animate;
  final Duration duration;
  final VoidCallback? onCompleted;

  @override
  State<DropLeafMark> createState() => _DropLeafMarkState();
}

class _DropLeafMarkState extends State<DropLeafMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _c.addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onCompleted?.call();
      });
      _c.forward();
    } else {
      _c.value = 1;
      // Animasyon kapalıyken de akışın devam etmesi gerekir.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.onCompleted?.call(),
      );
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: DropLeafPainter(
            progress: Curves.easeInOutCubic.transform(_c.value),
            palette: p,
          ),
        ),
      ),
    );
  }
}
