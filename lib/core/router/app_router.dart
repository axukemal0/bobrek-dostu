import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

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
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
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
        builder: (context, state) => const LabsScreen(),
      ),
      GoRoute(
        path: Routes.calendar,
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: Routes.weight,
        builder: (context, state) => const WeightScreen(),
      ),
      GoRoute(
        path: Routes.health,
        builder: (context, state) => const HealthScreen(),
      ),
      GoRoute(
        path: Routes.ai,
        builder: (context, state) => const AiChatScreen(),
      ),
      GoRoute(
        path: Routes.places,
        builder: (context, state) => const PlacesScreen(),
      ),
      GoRoute(
        path: Routes.travel,
        builder: (context, state) => const TravelScreen(),
      ),
      GoRoute(
        path: Routes.reading,
        builder: (context, state) => const ReadingScreen(),
      ),
      GoRoute(
        path: Routes.emergency,
        builder: (context, state) => const EmergencyScreen(),
      ),
      GoRoute(
        path: Routes.report,
        builder: (context, state) => const ReportScreen(),
      ),
      GoRoute(
        path: Routes.dietPlan,
        builder: (context, state) => const DietPlanScreen(),
      ),
      GoRoute(
        path: Routes.caregiver,
        builder: (context, state) => const CaregiverScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'klinik',
            builder: (context, state) => const ClinicalSettingsScreen(),
          ),
          GoRoute(
            path: 'yapay-zeka',
            builder: (context, state) => const AiConnectionScreen(),
          ),
          GoRoute(
            path: 'kaynaklar',
            builder: (context, state) => const SourcesScreen(),
          ),
          GoRoute(
            path: 'izinler',
            builder: (context, state) => const PermissionsScreen(),
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

/// Sekme geçişleri yumuşak fade ile.
CustomTransitionPage<void> _fadePage(Widget child, GoRouterState state) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (context, animation, secondary, child) {
        final media = MediaQuery.maybeOf(context);
        final reduce = media?.disableAnimations ?? false;
        if (reduce) return child;
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.015),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
