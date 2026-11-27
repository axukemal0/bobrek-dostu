import 'dart:ui';

import 'package:material_ui/material_ui.dart' hide Text;

import 'app_colors.dart';
import 'motion.dart';
import '../i18n/text.dart';
import '../i18n/i18n.dart';

/// Yüzey derinliği — tasarım dilinin tek hiyerarşisi.
///
/// Önceden her kart hem kabartmalı hem buzlu camdı; sonuç, hiçbir şeyin
/// öne çıkmadığı düz bir gürültüydü (ve düz krem zemin üzerinde görünmeyen
/// bir bulanıklık için her karede GPU harcanıyordu). Artık üç kademe var ve
/// her kademenin bir işi var:
enum Surface {
  /// İçerik yüzeyi: hafif tonlu dolgu, saç teli kenar, gölge yok.
  /// Listelerdeki ve sayfalardaki kartların varsayılanı budur.
  flat,

  /// Dokunulabilir yüzey: yumuşak çift gölgeyle zeminden kalkar.
  /// Yalnız basılabilen şeyler bu kademeyi hak eder.
  raised,

  /// Üstte duran kabuk: alt gezinme çubuğu, alt sayfa başlığı.
  /// Arkasından gerçekten içerik aktığı için bulanıklık burada anlamlı.
  floating,
}

/// Uygulamanın kart yüzeyi.
class NeuCard extends StatelessWidget {
  const NeuCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
    this.radius = 20,
    this.surface = Surface.flat,
    this.selected = false,
    this.color,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;

  /// Dokunulabilir kartlar [Surface.raised] olarak verilir; [onTap] varsa
  /// ve kademe belirtilmemişse otomatik yükseltilir.
  final Surface surface;

  /// Seçili durum (filtre, sekme, seçenek kartı).
  final bool selected;

  final Color? color;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final level = onTap != null && surface == Surface.flat
        ? Surface.raised
        : surface;

    final bg = color ??
        (selected
            ? p.primarySoft
            : level == Surface.flat
                ? p.surface
                : p.surface);

    final content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: level == Surface.raised
            ? [
                BoxShadow(
                  color: p.shadowDark,
                  offset: const Offset(2, 4),
                  blurRadius: 12,
                ),
                BoxShadow(
                  color: p.shadowLight,
                  offset: const Offset(-2, -3),
                  blurRadius: 10,
                ),
              ]
            : null,
        border: Border.all(
          color: selected
              ? p.primary.withValues(alpha: 0.65)
              : p.divider.withValues(alpha: level == Surface.flat ? 0.75 : 0.3),
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return semanticLabel == null
          ? content
          : Semantics(label: semanticLabel, child: content);
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      selected: selected,
      child: Pressable(onTap: onTap, radius: radius, child: content),
    );
  }
}

/// Tonlu içerik yüzeyi — vurgulanmış ama basılmayan bloklar için.
///
/// Eski `GlassCard` buydu; artık `BackdropFilter` kullanmıyor. Düz krem
/// zemin üzerinde bulanıklığın görünür bir etkisi yoktu, karşılığında her
/// kart tam bir GPU geçişi istiyordu. Görünüm aynı kalsın diye tonlu dolgu
/// ve açık bir üst kenar ışığı bırakıldı.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
    this.radius = 22,
    this.tint,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final Color? tint;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // DİKKAT: BoxDecoration'da `gradient` verilirse `color` YOK SAYILIR.
    // Önceki sürümde ikisi birden verilmişti; kutu yarı saydam kalıyor ve
    // kendi gölgesi kartın İÇİNDEN görünüyordu — cihazda çamur rengi bir
    // kutu olarak çıkıyordu. Bu yüzden ton rengi burada zeminle birleştirilip
    // tamamen opak hâle getiriliyor ve parıltı gradyanın içine katılıyor.
    final base = tint ?? Color.alphaBlend(p.surfaceGlass, p.background);
    final sheen = Color.alphaBlend(
      p.isDark ? const Color(0x14FFFFFF) : const Color(0x59FFFFFF),
      base,
    );

    final body = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: p.glassBorder, width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [sheen, base],
        ),
        boxShadow: [
          BoxShadow(
            color: p.shadowDark.withValues(alpha: 0.4),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    final wrapped =
        onTap == null ? body : Pressable(onTap: onTap, radius: radius, child: body);

    return semanticLabel == null
        ? wrapped
        : Semantics(label: semanticLabel, button: onTap != null, child: wrapped);
  }
}

/// Gerçekten üstte duran, arkasından içerik akan kabuk — buzlu cam BURADA
/// anlamlı. Uygulamada yalnız alt gezinme çubuğu ve alt sayfa başlığı
/// bu sınıfı kullanır.
class GlassBar extends StatelessWidget {
  const GlassBar({
    required this.child,
    this.blur = 16,
    this.borderSide = BorderSide.none,
    this.borderRadius,
    super.key,
  });

  final Widget child;
  final double blur;
  final BorderSide borderSide;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = borderRadius ?? BorderRadius.zero;
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.surfaceGlass,
            borderRadius: radius,
            border: borderSide == BorderSide.none
                ? null
                : Border(
                    top: borderSide,
                  ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Dokunulduğunda hafifçe içe basılan sarmalayıcı.
///
/// Ölçek bir denetleyiciyle sürülür; `setState` ile her dokunuşta ağaç
/// yeniden kurulmaz. Devre dışıyken hiç jest dinleyicisi takılmaz.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.onTap,
    required this.child,
    this.radius = 16,
    this.onLongPress,
    super.key,
  });

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double radius;
  final Widget child;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 130),
    reverseDuration: const Duration(milliseconds: 190),
    lowerBound: 0.0,
    upperBound: 1.0,
  );
  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.975).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null && widget.onLongPress == null) {
      return widget.child;
    }
    final reduce = context.motion.reduceMotion;

    return GestureDetector(
      onTapDown: reduce ? null : (_) => _c.forward(),
      onTapUp: reduce ? null : (_) => _c.reverse(),
      onTapCancel: reduce ? null : () => _c.reverse(),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: reduce
          ? widget.child
          : ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

enum NeuTone { primary, accent, danger, neutral }

/// Uygulamanın tek buton biçimi. En küçük dokunma alanı 48dp.
class NeuButton extends StatelessWidget {
  const NeuButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = true,
    this.tone = NeuTone.primary,
    this.color,
    this.expanded = false,
    this.compact = false,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;
  final NeuTone tone;

  /// Bölüm rengi ([AppAccents]). Verildiğinde [tone] yerine bu kullanılır.
  ///
  /// Her ekranın birincil eylemi o bölümün rengini taşısın diye var:
  /// ilaç sayfasındaki "Aldım" mor, sıvı sayfasındaki "Ekle" camgöbeği
  /// olur. Önceden her dolu buton aynı yeşildi ve renk hiçbir iş
  /// yapmıyordu.
  final Color? color;
  final bool expanded;
  final bool compact;

  /// Yüklenirken buton kilitlenir ve yerinde bir gösterge döner — etiket
  /// yerinde kalır, böylece buton zıplamaz.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null && !loading;
    final base = color ??
        switch (tone) {
          NeuTone.primary => p.primary,
          NeuTone.accent => p.accent,
          NeuTone.danger => p.danger,
          NeuTone.neutral => p.textSecondary,
        };

    // Devre dışı buton soluk bir dolguya boyanıp üstüne beyaz yazı
    // yazılınca okunmuyordu. Kapalı durumda butonu nötr bir yüzeye
    // çevirip yazıyı koyu tutuyoruz: kontrast korunur, "basılamaz"
    // olduğu yine bellidir.
    final bg = !enabled
        ? p.backgroundDeep
        : filled
            ? base
            : p.surface;
    // Dolgunun ÜSTÜNDEKİ yazı rengi dolgunun parlaklığından türetilir.
    // Sabit `onPrimary` kullanmak bölüm renkleri gelince kırılıyordu:
    // koyu temada açık mor dolgunun üstündeki koyu yeşil yazı
    // okunmuyordu.
    final fg = !enabled
        ? p.textMuted
        : filled
            ? p.onAccent(base)
            : base;

    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          SizedBox(
            width: compact ? 16 : 18,
            height: compact ? 16 : 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: compact ? 18 : 20, color: fg),
          const SizedBox(width: 9),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
          ),
        ),
      ],
    );

    final body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Container(
        width: expanded ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 22,
          vertical: compact ? 11 : 14,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          // Kapalı durumda da kenar çizgisi olsun ki buton kaybolmasın.
          border: !enabled
              ? Border.all(color: p.divider, width: 1.2)
              : filled
                  ? null
                  : Border.all(
                      color: base.withValues(alpha: 0.55),
                      width: 1.4,
                    ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: p.shadowDark,
                    offset: const Offset(2, 3),
                    blurRadius: 10,
                  ),
                  BoxShadow(
                    color: p.shadowLight,
                    offset: const Offset(-2, -2),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Center(child: child),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: loading ? tf('{0}, yükleniyor', [label]) : label,
      child: Pressable(
        onTap: enabled ? onPressed : null,
        radius: 16,
        child: body,
      ),
    );
  }
}

/// İçe basılmış (inset) alan — giriş kutuları için.
class NeuInset extends StatelessWidget {
  const NeuInset({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    this.radius = 14,
    this.hasError = false,
    this.focused = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool hasError;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final borderColor = hasError
        ? p.danger
        : focused
            ? p.primary
            : p.divider.withValues(alpha: 0.7);
    return AnimatedContainer(
      duration: context.motion.fast,
      padding: padding,
      decoration: BoxDecoration(
        color: p.isDark
            ? p.backgroundDeep
            : p.backgroundDeep.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor,
          width: hasError || focused ? 1.6 : 1,
        ),
      ),
      child: child,
    );
  }
}
