import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPage;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' hide Text;

import '../../features/ai/ai_chat_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/emergency/emergency_screen.dart';
import '../../features/fluid/fluid_screen.dart';
import '../../features/health/health_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/more_screen.dart';
import '../../features/labs/labs_screen.dart';
import '../../features/medications/medications_screen.dart';
import '../../features/nutrition/diet_plan_screen.dart';
import '../../features/nutrition/nutrition_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/places/places_screen.dart';
import '../../features/reading/reading_screen.dart';
import '../../features/report/report_screen.dart';
import '../../features/settings/ai_connection_screen.dart';
import '../../features/settings/caregiver_screen.dart';
import '../../features/settings/clinical_settings_screen.dart';
import '../../features/settings/permissions_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/sources_screen.dart';
import '../../features/travel/travel_screen.dart';
import '../../features/weight/weight_screen.dart';
import '../widgets/app_shell.dart';
import '../i18n/text.dart';

class Routes {
  const Routes._();

  static const splash = '/';
  static const onboarding = '/kurulum';
  static const home = '/ana-sayfa';
  static const nutrition = '/besin';
  static const fluid = '/sivi';
  static const medications = '/ilac';
  static const more = '/daha';

  static const labs = '/tahlil';
  static const calendar = '/takvim';
  static const weight = '/kilo';
  static const health = '/saglik-verisi';
  static const ai = '/yapay-zeka';
  static const places = '/yakinda';
  static const travel = '/seyahat';
  static const reading = '/okuma';
  static const emergency = '/acil';
  static const report = '/rapor';
  static const dietPlan = '/diyet-plani';
  static const caregiver = '/yakin-modu';

  static const settings = '/ayarlar';
  static const clinicalSettings = '/ayarlar/klinik';
  static const aiConnection = '/ayarlar/yapay-zeka';
  static const sources = '/ayarlar/kaynaklar';
  static const permissions = '/ayarlar/izinler';
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    routes: [
      GoRoute(
        path: Routes.splash,
        pageBuilder: (context, state) =>
            _screenPage(const SplashScreen(), state),
      ),
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (context, state) =>
            _screenPage(const OnboardingScreen(), state),
      ),

      // Alt navigasyonlu kabuk (tek elle kullanım).
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            pageBuilder: (context, state) =>
                _fadePage(const HomeScreen(), state),
          ),
          GoRoute(
            path: Routes.nutrition,
            pageBuilder: (context, state) =>
                _fadePage(const NutritionScreen(), state),
          ),
          GoRoute(
            path: Routes.fluid,
            pageBuilder: (context, state) =>
                _fadePage(const FluidScreen(), state),
          ),
          GoRoute(
            path: Routes.medications,
            pageBuilder: (context, state) =>
                _fadePage(const MedicationsScreen(), state),
          ),
          GoRoute(
            path: Routes.more,
            pageBuilder: (context, state) =>
                _fadePage(const MoreScreen(), state),
          ),
        ],
      ),

      // Tam ekran sayfalar.
      GoRoute(
        path: Routes.labs,
        pageBuilder: (context, state) =>
            _screenPage(const LabsScreen(), state),
      ),
      GoRoute(
        path: Routes.calendar,
        pageBuilder: (context, state) =>
            _screenPage(const CalendarScreen(), state),
      ),
      GoRoute(
        path: Routes.weight,
        pageBuilder: (context, state) =>
            _screenPage(const WeightScreen(), state),
      ),
      GoRoute(
        path: Routes.health,
        pageBuilder: (context, state) =>
            _screenPage(const HealthScreen(), state),
      ),
      GoRoute(
        path: Routes.ai,
        pageBuilder: (context, state) =>
            _screenPage(const AiChatScreen(), state),
      ),
      GoRoute(
        path: Routes.places,
        pageBuilder: (context, state) =>
            _screenPage(const PlacesScreen(), state),
      ),
      GoRoute(
        path: Routes.travel,
        pageBuilder: (context, state) =>
            _screenPage(const TravelScreen(), state),
      ),
      GoRoute(
        path: Routes.reading,
        pageBuilder: (context, state) =>
            _screenPage(const ReadingScreen(), state),
      ),
      GoRoute(
        path: Routes.emergency,
        pageBuilder: (context, state) =>
            _screenPage(const EmergencyScreen(), state),
      ),
      GoRoute(
        path: Routes.report,
        pageBuilder: (context, state) =>
            _screenPage(const ReportScreen(), state),
      ),
      GoRoute(
        path: Routes.dietPlan,
        pageBuilder: (context, state) =>
            _screenPage(const DietPlanScreen(), state),
      ),
      GoRoute(
        path: Routes.caregiver,
        pageBuilder: (context, state) =>
            _screenPage(const CaregiverScreen(), state),
      ),
      GoRoute(
        path: Routes.settings,
        pageBuilder: (context, state) =>
            _screenPage(const SettingsScreen(), state),
        routes: [
          GoRoute(
            path: 'klinik',
            pageBuilder: (context, state) =>
                _screenPage(const ClinicalSettingsScreen(), state),
          ),
          GoRoute(
            path: 'yapay-zeka',
            pageBuilder: (context, state) =>
                _screenPage(const AiConnectionScreen(), state),
          ),
          GoRoute(
            path: 'kaynaklar',
            pageBuilder: (context, state) =>
                _screenPage(const SourcesScreen(), state),
          ),
          GoRoute(
            path: 'izinler',
            pageBuilder: (context, state) =>
                _screenPage(const PermissionsScreen(), state),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.explore_off_outlined, size: 48),
              const SizedBox(height: 12),
              Text(
                'Sayfa bulunamadı',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                state.uri.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('Ana sayfaya dön'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});


/// İtilen tam ekran sayfalar.
///
/// iOS'ta SOLDAN KAYDIRARAK GERİ GİTME jesti `CupertinoPageRoute`'un
/// kendi jest algılayıcısına bağlıdır. `MaterialPage` + tema geçişi
/// kombinasyonu bu jesti güvenilir biçimde taşımıyordu (cihazda
/// çalışmıyordu), bu yüzden iOS'ta sayfa tipi doğrudan `CupertinoPage`
/// seçiliyor: kaydırarak geri gitme, kenardan sürükleme sırasında
/// sayfanın parallaks kayması ve iptal animasyonu birlikte gelir.
/// Android'de Material geçişi korunur.
Page<void> _screenPage(Widget child, GoRouterState state) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return CupertinoPage<void>(key: state.pageKey, child: child);
  }
  return MaterialPage<void>(key: state.pageKey, child: child);
}

/// Sekme geçişleri yumuşak fade ile.
CustomTransitionPage<void> _fadePage(Widget child, GoRouterState state) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (context, animation, secondary, child) {
        final media = MediaQuery.maybeOf(context);
        final reduce = media?.disableAnimations ?? false;
        if (reduce) return child;
        // Sekme geçişi: içeri gelen sayfa hafifçe büyüyerek ve
        // yukarı kayarak belirir, giden sayfa yerinde soluklaşır.
        // Tek başına fade "bir şey değişti" demiyordu; ölçek değişimi
        // yön duygusu veriyor ama 0,985 → 1 kadar küçük bir fark
        // olduğu için göz yormuyor.
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.022),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
