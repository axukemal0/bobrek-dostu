import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/config/app_config.dart';
import '../../core/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/motion.dart';
import '../../core/widgets/drop_leaf_logo.dart';
import '../../core/widgets/responsive.dart';

/// Açılış ekranı: damla-yaprak çizim animasyonu.
///
/// "Hareketi azalt" açıkken animasyon atlanır ve işaret doğrudan
/// tamamlanmış hâlde görünür.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;
  bool _showText = false;

  Future<void> _go() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    final db = ref.read(databaseProvider);
    final prefsJson = await db.readJsonSetting(kPreferencesKey);
    final completed =
        AppPreferences.fromJson(prefsJson).onboardingCompleted;

    // Okuma sayfası için yerleşik içerikleri hazırla.
    await ref.read(readingServiceProvider).seedBuiltinArticles();

    if (!mounted) return;
    context.go(completed ? Routes.home : Routes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final motion = context.motion;
    final r = Responsive.fromContext(context);

    return Scaffold(
      backgroundColor: p.background,
      body: Container(
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
                child: DropLeafMark(
                  size: r.s(132),
                  animate: !motion.reduceMotion,
                  duration: motion.splash,
                  onCompleted: () {
                    if (mounted) setState(() => _showText = true);
                    _go();
                  },
                ),
              ),
              SizedBox(height: r.gapLg),
              AnimatedOpacity(
                opacity: _showText || motion.reduceMotion ? 1 : 0,
                duration: motion.normal,
                curve: motion.enter,
                child: Column(
                  children: [
                    Text(
                      AppConfig.appName,
                      style: AppTypography.numeric(p, size: r.s(30)),
                    ),
                    SizedBox(height: r.gapXs),
                    Text(
                      'Sakin bir takip, net bilgiler',
                      style: Theme.of(context).textTheme.bodySmall,
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
