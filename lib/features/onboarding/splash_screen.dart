import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/brand/brand_mark.dart';
import '../../core/config/app_config.dart';
import '../../core/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/motion.dart';
import '../../core/widgets/responsive.dart';

/// Açılış ekranı: amblem yerine oturur, kap dolar, sınır çizgisi çizilir.
///
/// Önemli: açılış işleri (veritabanı, yerleşik içerik) animasyon BAŞLAR
/// başlamaz paralel yürür. Eskiden animasyonun bitmesi beklenip sonra
/// veritabanına gidiliyordu; soğuk açılış bu yüzden gereksiz uzundu.
/// Artık toplam süre = max(animasyon, hazırlık).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Future<bool> _ready;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Hazırlık hemen başlasın.
    _ready = _prepare();
    _c = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.duration != null) return;
    final reduce = context.motion.reduceMotion;
    _c.duration = reduce ? Duration.zero : AppMotion.splashDuration;
    _c.forward().whenComplete(_go);
  }

  /// Yönlendirme için gereken her şeyi yükler.
  Future<bool> _prepare() async {
    final db = ref.read(databaseProvider);
    final prefsJson = await db.readJsonSetting(kPreferencesKey);
    final completed = AppPreferences.fromJson(prefsJson).onboardingCompleted;
    await ref.read(readingServiceProvider).seedBuiltinArticles();
    return completed;
  }

  Future<void> _go() async {
    if (_navigated) return;
    _navigated = true;
    final completed = await _ready;
    if (!mounted) return;
    context.go(completed ? Routes.home : Routes.onboarding);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final text = Theme.of(context).textTheme;

    // Yazı amblemden biraz sonra, animasyon sürerken belirir.
    final wordmark = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );

    return Scaffold(
      backgroundColor: p.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.background, p.backgroundDeep],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'app-mark',
                child: RepaintBoundary(
                  child: CustomPaint(
                    size: Size.square(r.s(140)),
                    painter: _SplashMarkPainter(_c, p),
                  ),
                ),
              ),
              SizedBox(height: r.gapLg),
              FadeTransition(
                opacity: wordmark,
                child: Column(
                  children: [
                    Text(
                      AppConfig.appName,
                      style: text.displaySmall?.copyWith(
                        fontSize: r.s(30),
                        color: p.textPrimary,
                      ),
                    ),
                    SizedBox(height: r.gapXs),
                    Text(
                      'Sakin bir takip, net bilgiler',
                      style: text.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashMarkPainter extends CustomPainter {
  _SplashMarkPainter(this.animation, this.palette)
      : super(repaint: animation);

  final Animation<double> animation;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    BrandMarkPainter(
      palette: palette,
      progress: animation.value,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_SplashMarkPainter old) => old.palette != palette;
}
