import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'motion.dart';

/// Kabartmalı (neumorphic) kart. Yumuşak çift gölge.
class NeuCard extends StatelessWidget {
  const NeuCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
    this.radius = 22,
    this.depth = 1.0,
    this.pressed = false,
    this.color,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;

  /// 0 = düz, 1 = normal kabartma, 1.6 = belirgin.
  final double depth;

  /// true ise içe basılmış (inset) görünür.
  final bool pressed;

  final Color? color;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final surface = color ?? p.surface;
    final d = depth.clamp(0.0, 3.0);

    final content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: pressed || d == 0
            ? null
            : [
                BoxShadow(
                  color: p.shadowDark,
                  offset: Offset(4 * d, 5 * d),
                  blurRadius: 14 * d,
                ),
                BoxShadow(
                  color: p.shadowLight,
                  offset: Offset(-3 * d, -4 * d),
                  blurRadius: 12 * d,
                ),
              ],
        border: pressed
            ? Border.all(color: p.divider.withValues(alpha: 0.5), width: 1)
            : null,
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
      child: _PressableWrapper(
        onTap: onTap!,
        radius: radius,
        child: content,
      ),
    );
  }
}

/// Buzlu cam (glassmorphism) kart.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
    this.radius = 24,
    this.blur = 18,
    this.tint,
    this.onTap,
    this.borderWidth = 1.2,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final double blur;
  final Color? tint;
  final VoidCallback? onTap;
  final double borderWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final body = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: p.shadowDark,
            offset: const Offset(0, 6),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter
            // Buzlu cam etkisi: arkadaki zemin bulanıklaşır.
            (
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: tint ?? p.surfaceGlass,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: p.glassBorder, width: borderWidth),
              gradient: p.isDark
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.30),
                        Colors.white.withValues(alpha: 0.04),
                      ],
                    ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );

    final wrapped = onTap == null
        ? body
        : _PressableWrapper(onTap: onTap!, radius: radius, child: body);

    return semanticLabel == null
        ? wrapped
        : Semantics(label: semanticLabel, button: onTap != null, child: wrapped);
  }
}

/// Dokunulduğunda hafifçe içe basılan sarmalayıcı.
class _PressableWrapper extends StatefulWidget {
  const _PressableWrapper({
    required this.onTap,
    required this.radius,
    required this.child,
  });

  final VoidCallback onTap;
  final double radius;
  final Widget child;

  @override
  State<_PressableWrapper> createState() => _PressableWrapperState();
}

class _PressableWrapperState extends State<_PressableWrapper> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _down && !motion.reduceMotion ? 0.975 : 1.0,
        duration: motion.fast,
        curve: motion.enter,
        child: widget.child,
      ),
    );
  }
}

/// Kabartmalı ana buton. Minimum dokunma alanı 48dp.
class NeuButton extends StatelessWidget {
  const NeuButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = true,
    this.tone = NeuTone.primary,
    this.expanded = false,
    this.compact = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;
  final NeuTone tone;
  final bool expanded;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null;
    final base = switch (tone) {
      NeuTone.primary => p.primary,
      NeuTone.accent => p.accent,
      NeuTone.danger => p.danger,
      NeuTone.neutral => p.textSecondary,
    };

    final bg = filled
        ? (enabled ? base : base.withValues(alpha: 0.35))
        : p.surface;
    final fg = filled
        ? p.onPrimary
        : (enabled ? base : base.withValues(alpha: 0.45));

    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
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

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: _PressableWrapper(
        onTap: enabled ? onPressed! : () {},
        radius: 16,
        child: ConstrainedBox(
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
              border: filled
                  ? null
                  : Border.all(
                      color: enabled
                          ? base.withValues(alpha: 0.55)
                          : p.divider,
                      width: 1.4,
                    ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: p.shadowDark,
                        offset: const Offset(3, 4),
                        blurRadius: 12,
                      ),
                      BoxShadow(
                        color: p.shadowLight,
                        offset: const Offset(-2, -3),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

enum NeuTone { primary, accent, danger, neutral }

/// İçe basılmış (inset) alan — giriş kutuları için.
class NeuInset extends StatelessWidget {
  const NeuInset({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    this.radius = 14,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.isDark
            ? p.backgroundDeep
            : p.backgroundDeep.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: p.divider.withValues(alpha: 0.6)),
      ),
      child: child,
    );
  }
}
