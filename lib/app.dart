import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/config/app_config.dart';
import 'core/i18n/i18n.dart';
import 'core/i18n/languages.dart';
import 'core/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_typography.dart';
import 'core/theme/motion.dart';
import 'core/widgets/common.dart' show KeyboardDismissBar;
import 'features/settings/lock_gate.dart';

class BobrekDostuApp extends ConsumerStatefulWidget {
  const BobrekDostuApp({super.key});

  @override
  ConsumerState<BobrekDostuApp> createState() => _BobrekDostuAppState();
}

class _BobrekDostuAppState extends ConsumerState<BobrekDostuApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _runSmartNotifications(),
    );
  }

  /// Akıllı bildirimleri hesaplar ve günlük özeti zamanlar.
  ///
  /// Arka plan görevi yerine açılış/öne geliş tetiklemesi kullanılır
  /// (bkz. lib/core/services/smart_notifications.dart).
  Future<void> _runSmartNotifications() async {
    final prefs = ref.read(preferencesProvider);
    await ref
        .read(smartNotificationsProvider)
        .runOnForeground(
          smartEnabled: prefs.smartNotifications,
          dailySummaryEnabled: prefs.dailySummary,
          mealReminderEnabled: prefs.mealMarkReminder,
          mealReminderHour: prefs.mealMarkReminderHour,
        );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _runSmartNotifications();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // NOT: Sistem teması değişimi artık `systemBrightnessProvider` tarafından
  // dinleniyor (bkz. core/providers.dart). Burada `setState` çağırmak işe
  // yaramıyordu: widget yeniden çiziliyor ama provider önbellekten aynı
  // paleti döndürüyordu.

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    final palette = ref.watch(paletteProvider);
    final router = ref.watch(routerProvider);

    // Sözlük widget ağacının dışından da okunuyor (rapor, bildirim,
    // klinik değerlendirici), bu yüzden çizimden ÖNCE ayarlanır.
    // PreferencesNotifier de ayarlıyor; burası soğuk açılışta ilk
    // çizimin doğru dilde olmasını garanti eder.
    I18n.use(prefs.language);
    final language = prefs.language;

    // DİL DEĞİŞİNCE BÜTÜN AĞAÇ YENİDEN KURULUR.
    //
    // Gerekli, çünkü metinlerin çoğu `const Text(...)`. Flutter aynı
    // const widget örneğini gördüğünde onu yeniden ÇİZMEZ; sözlük
    // değişse bile ekranda eski dil kalırdı. Anahtar değişince eleman
    // ağacı baştan kurulur ve her metin yeniden çevrilir. Dil değişimi
    // nadir bir olaydır, bedeli bir karelik yeniden kurulumdur.
    // Açık sayfa korunur: konumu go_router tutuyor, widget ağacı değil.
    return KeyedSubtree(
      key: ValueKey(language),
      child: MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: AppTheme.build(palette),

        // Material ve Cupertino'nun KENDİ metinleri (tarih seçici,
        // kopyala-yapıştır menüsü, "Tamam/İptal") ve yazım yönü.
        // Arapça seçilince bütün yerleşim sağdan sola döner.
        locale: language.locale,
        supportedLocales: AppLanguage.values.map((l) => l.locale),
        // material_ui kendi çevirilerini getiriyor; ayrıca
        // flutter_localizations paketine gerek yok. Bu liste Material,
        // Widgets ve Cupertino katmanlarının üçünü birden kapsar.
        localizationsDelegates: GlobalMaterialLocalizations.delegates,

        builder: (context, child) {
          final media = MediaQuery.of(context);

          // "Hareketi azalt": uygulama ayarı VEYA sistem ayarı.
          final reduceMotion = prefs.reduceMotion || media.disableAnimations;

          // Metin ölçeği: sistem ölçeği × uygulama kademesi,
          // taşmayı önlemek için sınırlanır.
          final scale = AppTypography.clampedScale(
            media.textScaler.scale(1),
            prefs.textScaleStep,
          );

          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(scale),
              // Dokunma alanlarını küçültmemek için.
              boldText: media.boldText,
            ),
            child: AppPaletteScope(
              palette: palette,
              child: AppMotionScope(
                motion: AppMotion(reduceMotion: reduceMotion),
                // Sayısal klavyeyi kapatan "Bitti" çubuğu (yalnız iOS).
                child: KeyboardDismissBar(
                  child: LockGate(child: child ?? const SizedBox.shrink()),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
