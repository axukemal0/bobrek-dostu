import 'package:material_ui/material_ui.dart';

/// Hareket ayarları. "Hareketi azalt" açıkken tüm süreler sıfırlanır
/// ve parallax/ölçek animasyonları devre dışı kalır.
@immutable
class AppMotion {
  const AppMotion({required this.reduceMotion});

  final bool reduceMotion;

  Duration get instant => Duration.zero;
  Duration get fast =>
      reduceMotion ? Duration.zero : const Duration(milliseconds: 180);
  Duration get normal =>
      reduceMotion ? Duration.zero : const Duration(milliseconds: 320);
  Duration get slow =>
      reduceMotion ? Duration.zero : const Duration(milliseconds: 520);
  Duration get splash =>
      reduceMotion ? const Duration(milliseconds: 400) : const Duration(milliseconds: 2400);

  Curve get enter => Curves.easeOutCubic;
  Curve get exit => Curves.easeInCubic;
  Curve get emphasized => Curves.easeOutQuint;

  /// Parallax kaydırma çarpanı — azaltılmış modda 0.
  double get parallax => reduceMotion ? 0 : 0.18;

  /// Kart giriş animasyonu için kayma mesafesi.
  double get slideOffset => reduceMotion ? 0 : 18;
}

class AppMotionScope extends InheritedWidget {
  const AppMotionScope({
    required this.motion,
    required super.child,
    super.key,
  });

  final AppMotion motion;

  static AppMotion of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<AppMotionScope>();
    return s?.motion ?? const AppMotion(reduceMotion: false);
  }

  @override
  bool updateShouldNotify(AppMotionScope oldWidget) =>
      oldWidget.motion.reduceMotion != motion.reduceMotion;
}

extension MotionContext on BuildContext {
  AppMotion get motion => AppMotionScope.of(this);
}

/// Listedeki kartları sırayla, yumuşak biçimde içeri alan sarmalayıcı.
class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({
    required this.index,
    required this.child,
    super.key,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    if (motion.reduceMotion) return child;

    final delayMs = (index * 55).clamp(0, 440);
    return _DelayedFadeSlide(
      delay: Duration(milliseconds: delayMs),
      duration: motion.normal,
      offset: motion.slideOffset,
      curve: motion.enter,
      child: child,
    );
  }
}

class _DelayedFadeSlide extends StatefulWidget {
  const _DelayedFadeSlide({
    required this.delay,
    required this.duration,
    required this.offset,
    required this.curve,
    required this.child,
  });

  final Duration delay;
  final Duration duration;
  final double offset;
  final Curve curve;
  final Widget child;

  @override
  State<_DelayedFadeSlide> createState() => _DelayedFadeSlideState();
}

class _DelayedFadeSlideState extends State<_DelayedFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (!_disposed && mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(parent: _c, curve: widget.curve);
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - anim.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
