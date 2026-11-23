import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Metin boyutu kademeleri (erişilebilirlik ayarı).
enum TextScaleStep { normal, large, extraLarge }

extension TextScaleStepX on TextScaleStep {
  String get labelTr => switch (this) {
        TextScaleStep.normal => 'Normal',
        TextScaleStep.large => 'Büyük',
        TextScaleStep.extraLarge => 'Çok büyük',
      };

  /// Uygulama içi ek ölçek. Sistemin kendi ölçeği bunun üzerine biner;
  /// toplam ölçek [AppTypography.clampedScale] ile sınırlanır.
  double get factor => switch (this) {
        TextScaleStep.normal => 1.0,
        TextScaleStep.large => 1.18,
        TextScaleStep.extraLarge => 1.38,
      };
}

class AppTypography {
  const AppTypography._();

  static const String serif = 'PlayfairDisplay';
  static const String sans = 'Nunito';

  /// Sistem ölçeği + uygulama ölçeği birleşimini makul sınırda tutar.
  /// Taşmayı önlemek için üst sınır 2.0.
  static double clampedScale(double systemScale, TextScaleStep step) {
    final combined = systemScale * step.factor;
    return combined.clamp(0.85, 2.0);
  }

  static TextTheme textTheme(AppPalette p) {
    final primary = p.textPrimary;
    final secondary = p.textSecondary;

    return TextTheme(
      // Başlıklar: serif, lüks his.
      displayLarge: TextStyle(
        fontFamily: serif,
        fontSize: 40,
        fontWeight: FontWeight.w600,
        height: 1.15,
        letterSpacing: -0.5,
        color: primary,
      ),
      displayMedium: TextStyle(
        fontFamily: serif,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.18,
        letterSpacing: -0.3,
        color: primary,
      ),
      displaySmall: TextStyle(
        fontFamily: serif,
        fontSize: 27,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: primary,
      ),
      headlineLarge: TextStyle(
        fontFamily: serif,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.22,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontFamily: serif,
        fontSize: 21,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontFamily: serif,
        fontSize: 19,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: primary,
      ),
      // Gövde: çok okunaklı sans.
      titleLarge: TextStyle(
        fontFamily: sans,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.32,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontFamily: sans,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontFamily: sans,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.4,
        letterSpacing: 0.1,
        color: secondary,
      ),
      bodyLarge: TextStyle(
        fontFamily: sans,
        fontSize: 16.5,
        fontWeight: FontWeight.w500,
        height: 1.52,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontFamily: sans,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: secondary,
      ),
      bodySmall: TextStyle(
        fontFamily: sans,
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        height: 1.45,
        color: p.textMuted,
      ),
      labelLarge: TextStyle(
        fontFamily: sans,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 0.2,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontFamily: sans,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: secondary,
      ),
      labelSmall: TextStyle(
        fontFamily: sans,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: p.textMuted,
      ),
    );
  }

  /// Büyük sayılar için (halka ortası, ölçüm değeri).
  static TextStyle numeric(AppPalette p, {double size = 28}) => TextStyle(
        fontFamily: serif,
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: 1.05,
        letterSpacing: -0.5,
        color: p.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
