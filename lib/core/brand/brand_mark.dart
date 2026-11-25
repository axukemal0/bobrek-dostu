import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Böbrek Dostu amblemi — "ölçülü kap".
///
/// Tek geometri, tek logo: uygulama ikonu (Android + iOS), açılış ekranı,
/// kilit ekranı, onboarding ve rapor başlığı hep bu dosyadaki yollardan
/// çizilir. İkon PNG'leri de `tools/gen_icons.dart` ile aynı boyayıcıdan
/// üretilir, yani hiçbir yerde farklı bir logo oluşamaz.
///
/// Anlam: böbrek silüeti aynı zamanda ölçekli bir kap. İçindeki yeşil sıvı
/// günün kalan bütçesi (sıvı, potasyum, fosfor, sodyum), üstündeki ince altın
/// çizgi ise kullanıcının kendi belirlediği sınır — uygulamanın çekirdek
/// fikri. Malzemesi uygulamanın kendi tasarım dili: yumuşak kabartma gölgesi,
/// cam parıltısı, tek altın vurgu.
class BrandGeometry {
  const BrandGeometry._();

  // --- silüet parametreleri (birim kare) ---
  //
  // Böbrek biçimi: dolgun bir elips + sol kenarın ortasında YEREL bir
  // çukur (hilum). Çukur y ekseninde Gauss ile sınırlanır, böylece
  // yalnız orta bölge içeri girer; lob uçları dışbükey kalır.
  // (Yay kaydırmasıyla kurulan biçim hilal çıkıyordu, elipsten daire
  // çıkarmak ise "ısırılmış" görünüyordu; bu kuruluş ikisini de çözüyor.)

  /// Temel elips.
  static const double _a = 0.365;
  static const double _b = 0.410;

  /// Hilum: derinlik ve dikey yayılım.
  static const double _dimpleDepth = 0.200;
  static const double _dimpleSpread = 0.215;

  /// Hilumun dikey konumu (0 = tam orta).
  static const double _dimpleY = -0.055;

  /// Üst lobu alt lobdan biraz dolgun yapar.
  static const double _upperLobe = 0.020;

  /// Böbrek anatomik olarak hafif eğik durur.
  static const double _tilt = -0.05;

  /// Gölgeye yer bırakan kenar payı.
  static const double _margin = 0.055;

  /// Varsayılan sıvı seviyesi (0 boş, 1 tam) — "bugün yerin var".
  static const double defaultLevel = 0.46;

  /// Altın sınır çizgisinin seviyesi.
  static const double thresholdLevel = 0.800;

  static final Map<double, BrandShape> _cache = <double, BrandShape>{};

  /// Belirli bir kutu boyutu için silüet. Yol bir kez hesaplanır, saklanır;
  /// her karede yeniden üretilmez.
  static BrandShape shape(double s) {
    if (_cache.length > 24) _cache.clear();
    return _cache.putIfAbsent(s, () => _build(s));
  }

  static BrandShape _build(double s, {int samples = 384}) {
    final pts = <Offset>[];

    for (var i = 0; i < samples; i++) {
      final t = i / samples * 2 * math.pi;
      final lobe = 1 + _upperLobe * -math.sin(t);
      var x = _a * math.cos(t);
      final y = _b * math.sin(t) * lobe;

      // yalnız sol kenarda ve yalnız orta yükseklikte etkili çukur
      final gate = math.max(0.0, -math.cos(t));
      final dy = (y - _dimpleY) / _dimpleSpread;
      x += _dimpleDepth * math.exp(-dy * dy) * gate;

      pts.add(Offset(x, y));
    }

    final ct = math.cos(_tilt);
    final st = math.sin(_tilt);
    for (var i = 0; i < pts.length; i++) {
      final q = pts[i];
      pts[i] = Offset(q.dx * ct - q.dy * st, q.dx * st + q.dy * ct);
    }

    final even = _resample(pts, samples);
    _smooth(even, window: 5, passes: 1);

    var minX = double.infinity, maxX = -double.infinity;
    var minY = double.infinity, maxY = -double.infinity;
    for (final q in even) {
      if (q.dx < minX) minX = q.dx;
      if (q.dx > maxX) maxX = q.dx;
      if (q.dy < minY) minY = q.dy;
      if (q.dy > maxY) maxY = q.dy;
    }
    final avail = s * (1 - 2 * _margin);
    final k = math.min(avail / (maxX - minX), avail / (maxY - minY));
    final offX = (s - (maxX - minX) * k) / 2 - minX * k;
    final offY = (s - (maxY - minY) * k) / 2 - minY * k;

    final path = Path();
    for (var i = 0; i < even.length; i++) {
      final px = even[i].dx * k + offX;
      final py = even[i].dy * k + offY;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();

    return BrandShape(
      path,
      Rect.fromLTRB(minX * k + offX, minY * k + offY,
          maxX * k + offX, maxY * k + offY),
    );
  }

  /// Kapalı çokgeni eşit yay uzunluğunda [n] noktaya yeniden örnekler.
  static List<Offset> _resample(List<Offset> pts, int n) {
    final count = pts.length;
    final cum = List<double>.filled(count + 1, 0);
    for (var i = 0; i < count; i++) {
      cum[i + 1] = cum[i] + (pts[(i + 1) % count] - pts[i]).distance;
    }
    final total = cum[count];
    final out = <Offset>[];
    var seg = 0;
    for (var i = 0; i < n; i++) {
      final target = total * i / n;
      while (seg < count - 1 && cum[seg + 1] < target) {
        seg++;
      }
      final segLen = cum[seg + 1] - cum[seg];
      final f = segLen <= 1e-12 ? 0.0 : (target - cum[seg]) / segLen;
      final a = pts[seg];
      final b = pts[(seg + 1) % count];
      out.add(Offset(a.dx + (b.dx - a.dx) * f, a.dy + (b.dy - a.dy) * f));
    }
    return out;
  }

  /// Kapalı çokgen üzerinde kayan ortalama — köşeleri yumuşatır.
  static void _smooth(List<Offset> pts, {required int window, required int passes}) {
    final n = pts.length;
    final half = window ~/ 2;
    for (var pass = 0; pass < passes; pass++) {
      final out = List<Offset>.filled(n, Offset.zero);
      for (var i = 0; i < n; i++) {
        var sx = 0.0, sy = 0.0;
        for (var j = -half; j <= half; j++) {
          final q = pts[(i + j + n) % n];
          sx += q.dx;
          sy += q.dy;
        }
        out[i] = Offset(sx / window, sy / window);
      }
      for (var i = 0; i < n; i++) {
        pts[i] = out[i];
      }
    }
  }

  /// Verilen doluluk oranı için sıvı yüzeyinin y değeri.
  static double levelY(double s, double level) {
    final b = shape(s).bounds;
    return b.bottom - level.clamp(0.0, 1.0) * b.height;
  }

  /// Sıvı gövdesi: yüzeyi hafif menisküslü, altı taşan dikdörtgen.
  static Path liquid(double s, double level) {
    final y = levelY(s, level);
    final dip = s * 0.014;
    return Path()
      ..moveTo(-s * 0.1, y + dip)
      ..quadraticBezierTo(s * 0.5, y - dip, s * 1.1, y + dip)
      ..lineTo(s * 1.1, s * 1.2)
      ..lineTo(-s * 0.1, s * 1.2)
      ..close();
  }

  /// Cam parıltısı: silüetin sol üstünden geçen yumuşak ışık şeridi.
  static Path specular(double s) {
    final b = shape(s).bounds;
    Offset at(double fx, double fy) =>
        Offset(b.left + b.width * fx, b.top + b.height * fy);
    final p0 = at(0.30, 0.60);
    final c0 = at(0.24, 0.22);
    final p1 = at(0.68, 0.08);
    final c1 = at(0.44, 0.26);
    final p2 = at(0.46, 0.62);
    return Path()
      ..moveTo(p0.dx, p0.dy)
      ..quadraticBezierTo(c0.dx, c0.dy, p1.dx, p1.dy)
      ..quadraticBezierTo(c1.dx, c1.dy, p2.dx, p2.dy)
      ..close();
  }

  /// Altın sınır çizgisinin uçları — silüetin dışına az miktarda taşar.
  static (Offset, Offset) thresholdLine(double s) {
    final b = shape(s).bounds;
    final y = levelY(s, thresholdLevel);
    // Kabın içine kırpılır: ölçekli bir kapta "azami dolum" çizgisi gibi.
    final over = b.width * 0.06;
    return (Offset(b.left - over, y), Offset(b.right + over, y));
  }
}

/// Hesaplanmış silüet ve sınırları.
@immutable
class BrandShape {
  const BrandShape(this.path, this.bounds);
  final Path path;
  final Rect bounds;
}

/// Amblemin çizim yoğunluğu. Küçük boyutlarda ayrıntı düşer ama biçim
/// aynı kalır — aynı logonun küçük ölçek sürümüdür, farklı bir logo değil.
enum BrandDetail {
  /// 16–28 px: yalnız silüet.
  minimal,

  /// 28–64 px: silüet + sıvı seviyesi.
  compact,

  /// 64 px ve üstü: silüet + sıvı + altın sınır + cam parıltısı.
  full,
}

/// Tek amblem boyayıcısı. [progress] yalnızca açılış animasyonunda 1'den
/// küçüktür; gerisi için 1 verilir ve tek karede çizilir.
class BrandMarkPainter extends CustomPainter {
  BrandMarkPainter({
    required this.palette,
    this.progress = 1.0,
    this.detail = BrandDetail.full,
    this.level = BrandGeometry.defaultLevel,
    this.monochrome,
    this.withShadow = true,
  });

  final AppPalette palette;
  final double progress;
  final BrandDetail detail;
  final double level;

  /// Verilirse tüm amblem bu tek renkle çizilir (bildirim ikonu, filigran).
  final Color? monochrome;

  final bool withShadow;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    if (s <= 0) return;

    final p = progress.clamp(0.0, 1.0);

    // Faz 1 (0.00–0.45): silüet belirir ve yerine oturur.
    final shapeT = Curves.easeOutCubic.transform((p / 0.45).clamp(0.0, 1.0));
    // Faz 2 (0.22–0.82): sıvı yükselir.
    final riseT = Curves.easeOutCubic
        .transform(((p - 0.22) / 0.60).clamp(0.0, 1.0));
    // Faz 3 (0.60–1.00): altın sınır çizgisi soldan sağa çizilir.
    final lineT = Curves.easeOutCubic
        .transform(((p - 0.60) / 0.40).clamp(0.0, 1.0));
    // Faz 4 (0.72–1.00): cam parıltısı.
    final glintT = ((p - 0.72) / 0.28).clamp(0.0, 1.0);

    if (shapeT <= 0) return;

    final mono = monochrome;
    final shape = BrandGeometry.shape(s).path;

    canvas.save();
    // Hafif ölçek: amblem yerine otururken büyür.
    final scale = 0.94 + 0.06 * shapeT;
    canvas.translate(s / 2, s / 2);
    canvas.scale(scale);
    canvas.translate(-s / 2, -s / 2);

    if (mono != null) {
      _paintMonochrome(canvas, s, shape, mono, riseT);
      canvas.restore();
      return;
    }

    // --- yumuşak kabartma gölgesi (uygulamanın kart malzemesi) ---
    if (withShadow && detail == BrandDetail.full) {
      canvas.save();
      canvas.translate(s * 0.022, s * 0.030);
      canvas.drawPath(
        shape,
        Paint()
          ..color = palette.shadowDark.withValues(alpha: 0.55 * shapeT)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.045),
      );
      canvas.restore();
    }

    // --- kabın gövdesi: soluk, yarı saydam cam ---
    // Boş kısım "delik" gibi görünmemeli: koyu temada da zeminden belirgin
    // biçimde ayrışan, hafif yeşile çalan bir cam gövde.
    final bodyTop = palette.isDark
        ? Color.lerp(palette.surface, palette.primary, 0.26)!
        : Color.lerp(palette.surface, palette.primarySoft, 0.70)!;
    final bodyBottom = palette.isDark
        ? Color.lerp(palette.surface, palette.primary, 0.14)!
        : Color.lerp(palette.primarySoft, palette.accentSoft, 0.30)!;
    canvas.drawPath(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bodyTop.withValues(alpha: shapeT),
            bodyBottom.withValues(alpha: shapeT),
          ],
        ).createShader(Rect.fromLTWH(0, 0, s, s)),
    );

    // --- sıvı: günün kalan bütçesi ---
    if (detail != BrandDetail.minimal && riseT > 0) {
      canvas.save();
      canvas.clipPath(shape);
      final shown = level * riseT;
      canvas.drawPath(
        BrandGeometry.liquid(s, shown),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(palette.primary, palette.accentSoft, 0.26)!,
              palette.primary,
            ],
          ).createShader(Rect.fromLTWH(0, 0, s, s)),
      );
      canvas.restore();
    }

    // --- altın sınır çizgisi: kullanıcının kendi belirlediği eşik ---
    if (detail == BrandDetail.full && lineT > 0) {
      final (a, b) = BrandGeometry.thresholdLine(s);
      canvas.save();
      canvas.clipPath(shape);
      canvas.drawLine(
        a,
        Offset(a.dx + (b.dx - a.dx) * lineT, a.dy),
        Paint()
          ..strokeWidth = s * 0.026
          ..color = palette.accent,
      );
      canvas.restore();
    }

    // --- kenar konturu ---
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.028
        ..color = palette.primary.withValues(alpha: 0.92 * shapeT),
    );

    // --- cam parıltısı ---
    if (detail == BrandDetail.full && glintT > 0) {
      canvas.save();
      canvas.clipPath(shape);
      canvas.drawPath(
        BrandGeometry.specular(s),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.30 * glintT)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.018),
      );
      canvas.restore();
    }

    canvas.restore();
  }

  void _paintMonochrome(
    Canvas canvas,
    double s,
    Path shape,
    Color color,
    double riseT,
  ) {
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.075
        ..color = color,
    );
    if (detail != BrandDetail.minimal) {
      canvas.save();
      canvas.clipPath(shape);
      canvas.drawPath(
        BrandGeometry.liquid(s, level * riseT),
        Paint()..color = color,
      );
      canvas.restore();
    }
    if (detail == BrandDetail.full) {
      final (a, b) = BrandGeometry.thresholdLine(s);
      canvas.save();
      canvas.clipPath(shape);
      canvas.drawLine(a, b, Paint()..strokeWidth = s * 0.055..color = color);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(BrandMarkPainter old) =>
      old.progress != progress ||
      old.palette != palette ||
      old.detail != detail ||
      old.level != level ||
      old.monochrome != monochrome ||
      old.withShadow != withShadow;
}

/// Hareketsiz amblem. Denetleyici kurmaz, tek karede çizer — listelerde ve
/// kilit ekranında kullanılan ucuz sürüm.
class BrandMark extends StatelessWidget {
  const BrandMark({
    this.size = 96,
    this.detail,
    this.level = BrandGeometry.defaultLevel,
    this.monochrome,
    this.withShadow = true,
    super.key,
  });

  final double size;
  final BrandDetail? detail;
  final double level;
  final Color? monochrome;
  final bool withShadow;

  /// Boyuta göre uygun ayrıntı seviyesi.
  static BrandDetail detailFor(double size) {
    if (size < 28) return BrandDetail.minimal;
    if (size < 64) return BrandDetail.compact;
    return BrandDetail.full;
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(size),
          painter: BrandMarkPainter(
            palette: context.palette,
            detail: detail ?? detailFor(size),
            level: level,
            monochrome: monochrome,
            withShadow: withShadow,
          ),
        ),
      ),
    );
  }
}

/// Açılış ekranındaki canlandırılmış amblem.
///
/// Sıra: silüet yerine oturur → sıvı yükselir (günün bütçesi dolar) →
/// altın sınır çizgisi soldan sağa çizilir → cam parıltısı geçer.
/// Eski sürümdeki "yolu metrikle parça parça çizme" yöntemi her karede
/// `Path.computeMetrics()` çağırıyordu; bu sürüm yalnızca birkaç sayı
/// değiştirir, yol tek kez hesaplanır.
class AnimatedBrandMark extends StatefulWidget {
  const AnimatedBrandMark({
    this.size = 132,
    this.duration = const Duration(milliseconds: 1100),
    this.animate = true,
    this.onCompleted,
    super.key,
  });

  final double size;
  final Duration duration;
  final bool animate;
  final VoidCallback? onCompleted;

  @override
  State<AnimatedBrandMark> createState() => _AnimatedBrandMarkState();
}

class _AnimatedBrandMarkState extends State<AnimatedBrandMark>
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
      WidgetsBinding.instance
          .addPostFrameCallback((_) => widget.onCompleted?.call());
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _AnimatedBrandPainter(_c, palette),
        ),
      ),
    );
  }
}

/// Denetleyiciyi doğrudan `repaint` olarak alır: her karede widget ağacı
/// yeniden kurulmaz, yalnız boyama yinelenir.
class _AnimatedBrandPainter extends CustomPainter {
  _AnimatedBrandPainter(this.animation, this.palette) : super(repaint: animation);

  final Animation<double> animation;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    BrandMarkPainter(
      palette: palette,
      progress: animation.value,
      detail: BrandDetail.full,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_AnimatedBrandPainter old) => old.palette != palette;
}
