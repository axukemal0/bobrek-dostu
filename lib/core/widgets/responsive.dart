import 'package:material_ui/material_ui.dart';

/// Ekran genişliğine göre ölçek. SABİT PİKSEL KULLANILMAZ:
/// bütün boşluk ve ölçüler bu sınıftan geçer.
///
/// Referans genişlik 390 dp (orta boy telefon). 360x640'ta küçülür,
/// tablette büyür ama içerik sütunu [maxContentWidth] ile sınırlanır
/// (tablette satırların aşırı uzaması okunabilirliği bozar).
class Responsive {
  const Responsive({
    required this.width,
    required this.height,
    required this.scale,
    required this.isCompact,
    required this.isTablet,
    required this.columns,
  });

  static const double referenceWidth = 390;

  final double width;
  final double height;
  final double scale;
  final bool isCompact;
  final bool isTablet;

  /// Izgara sütun sayısı.
  final int columns;

  factory Responsive.of(BoxConstraints c) {
    final w = c.maxWidth.isFinite ? c.maxWidth : referenceWidth;
    final h = c.maxHeight.isFinite ? c.maxHeight : 800.0;
    final raw = w / referenceWidth;
    // Çok küçük ekranda 0.88'in altına inmeyiz (okunabilirlik),
    // tablette 1.22'nin üstüne çıkmayız (dev metin olmasın).
    final double s = raw.clamp(0.88, 1.22).toDouble();
    return Responsive(
      width: w,
      height: h,
      scale: s,
      isCompact: w < 360,
      isTablet: w >= 600,
      columns: w >= 980 ? 3 : (w >= 600 ? 2 : 1),
    );
  }

  factory Responsive.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Responsive.of(
      BoxConstraints(maxWidth: size.width, maxHeight: size.height),
    );
  }

  /// Ölçeklenmiş değer.
  double s(double v) => v * scale;

  /// Boşluk kademeleri.
  double get gapXs => s(6);
  double get gapSm => s(10);
  double get gapMd => s(16);
  double get gapLg => s(24);
  double get gapXl => s(34);

  /// Yatay sayfa kenar boşluğu.
  double get pagePadding => isTablet ? s(28) : s(18);

  /// İçerik sütunu üst sınırı.
  double get maxContentWidth => 720;

  EdgeInsets get pageInsets => EdgeInsets.symmetric(horizontal: pagePadding);
}

/// Sayfaları ortalayan ve genişliği sınırlayan sarmalayıcı.
class ContentColumn extends StatelessWidget {
  const ContentColumn({required this.child, this.maxWidth, super.key});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? r.maxContentWidth),
        child: child,
      ),
    );
  }
}

/// Esnek ızgara: telefonda tek sütun, tablette 2-3 sütun.
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    required this.children,
    this.spacing,
    this.forceSingleColumn = false,
    super.key,
  });

  final List<Widget> children;
  final double? spacing;
  final bool forceSingleColumn;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final r = Responsive.of(constraints);
        final gap = spacing ?? r.gapMd;
        final cols = forceSingleColumn ? 1 : r.columns;

        if (cols == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: gap),
                children[i],
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += cols) {
          final slice = children.sublist(
            i,
            (i + cols).clamp(0, children.length),
          );
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < cols; j++) ...[
                  if (j > 0) SizedBox(width: gap),
                  Expanded(
                    child: j < slice.length
                        ? slice[j]
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              rows[i],
            ],
          ],
        );
      },
    );
  }
}
