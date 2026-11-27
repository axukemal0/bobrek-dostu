import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoPageTransitionsBuilder;
import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData build(AppPalette p) {
    final text = AppTypography.textTheme(p);

    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primarySoft,
      onPrimaryContainer: p.textPrimary,
      secondary: p.accent,
      onSecondary: p.onPrimary,
      secondaryContainer: p.accentSoft,
      onSecondaryContainer: p.textPrimary,
      error: p.danger,
      onError: p.onPrimary,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      outline: p.divider,
      outlineVariant: p.divider,
      surfaceContainerHighest: p.backgroundDeep,
      shadow: p.shadowDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      textTheme: text,
      fontFamily: AppTypography.sans,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      iconTheme: IconThemeData(color: p.textSecondary, size: 22),
      dividerTheme: DividerThemeData(
        color: p.divider,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: p.textPrimary),
        titleTextStyle: text.headlineMedium,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.isDark
            ? p.backgroundDeep
            : p.backgroundDeep.withValues(alpha: 0.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: text.bodyMedium?.copyWith(color: p.textMuted),
        labelStyle: text.labelMedium,
        floatingLabelStyle: text.labelMedium?.copyWith(color: p.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.danger, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : p.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? p.primarySoft
              : p.backgroundDeep,
        ),
        trackOutlineColor: WidgetStateProperty.all(p.divider),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.primary,
        inactiveTrackColor: p.primarySoft,
        thumbColor: p.primary,
        overlayColor: p.primary.withValues(alpha: 0.12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.backgroundDeep.withValues(alpha: 0.6),
        selectedColor: p.primarySoft,
        labelStyle: text.labelMedium!,
        side: BorderSide(color: p.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.isDark ? p.surface : p.textPrimary,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: p.isDark ? p.textPrimary : p.surface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.primarySoft,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelSmall!.copyWith(
            color: s.contains(WidgetState.selected)
                ? p.primary
                : p.textSecondary,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color:
                s.contains(WidgetState.selected) ? p.primary : p.textSecondary,
          ),
        ),
      ),
      // M3'ün varsayılanı seçili bölümü `secondaryContainer` ile boyar;
      // bizim paletimizde o renk SICAK KAHVE bir ton (accentSoft) ve
      // koyu temada "Hedef | Alarm | Lab" çubuğu çamurlu bir blok gibi
      // görünüyordu. Seçili bölüm artık birincil rengin yumuşak
      // dolgusu, yazısı da birincil renk.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? p.primarySoft
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? (p.isDark ? p.primary : p.success)
                : p.textSecondary,
          ),
          overlayColor:
              WidgetStateProperty.all(p.primary.withValues(alpha: 0.10)),
          side: WidgetStateProperty.all(BorderSide(color: p.divider)),
          textStyle: WidgetStateProperty.resolveWith(
            (s) => text.labelLarge!.copyWith(
              fontWeight:
                  s.contains(WidgetState.selected) ? FontWeight.w800 : null,
            ),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minVerticalPadding: 12,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.primarySoft,
        circularTrackColor: p.primarySoft,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.textPrimary,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: text.bodySmall?.copyWith(color: p.surface),
      ),
      // DİKKAT: `builders` verildiğinde Flutter'ın varsayılan haritasının
      // TAMAMI değişir; listelenmeyen platform ZoomPageTransitions'a düşer.
      // Yalnız Android yazılıydı, bu yüzden iPhone'da sayfalar zoom ile
      // açılıyor ve SOLDAN KAYDIRARAK GERİ GİTME jesti çalışmıyordu —
      // iOS'ta bu jest kas hafızasıdır, kaybolmamalı.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
