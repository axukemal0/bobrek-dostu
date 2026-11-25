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

  /// Tip ölçeği.
  ///
  /// Kural tek: **serif yalnız başlıklarda**. Etiketler, butonlar, gövde ve
  /// özellikle SAYILAR okunaklı sans ile yazılır. Önceden ölçüm değerleri de
  /// Playfair ile çiziliyordu; başlık yüzü veride hem okunurluğu düşürür hem
  /// de sütunlarda hizalanmaz (ve Playfair'de alt simge glifleri yok).
  /// "Lüks" his başlıklarda ve malzemede kalır, veride kesinlik kazanır.
  ///
  /// Kademeler arası oran ~1.2: iş uygulamasında abartılı sıçrama gürültüdür.
  static TextTheme textTheme(AppPalette p) {
    final primary = p.textPrimary;
    final secondary = p.textSecondary;

    return TextTheme(
      // --- başlıklar: serif ---
      displayLarge: TextStyle(
        fontFamily: serif,
        fontSize: 36,
        fontWeight: FontWeight.w600,
        height: 1.14,
        letterSpacing: -0.6,
        color: primary,
      ),
      displayMedium: TextStyle(
        fontFamily: serif,
        fontSize: 30,
        fontWeight: FontWeight.w600,
        height: 1.18,
        letterSpacing: -0.4,
        color: primary,
      ),
      displaySmall: TextStyle(
        fontFamily: serif,
        fontSize: 25,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.2,
        color: primary,
      ),
      headlineLarge: TextStyle(
        fontFamily: serif,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.24,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontFamily: serif,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.28,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontFamily: serif,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.32,
        color: primary,
      ),
      // --- arayüz ve gövde: sans ---
      titleLarge: TextStyle(
        fontFamily: sans,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.34,
        letterSpacing: -0.1,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontFamily: sans,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.36,
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
        fontSize: 16,
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
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.46,
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
        letterSpacing: 0.25,
        color: secondary,
      ),
      labelSmall: TextStyle(
        fontFamily: sans,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: p.textMuted,
      ),
    );
  }

  /// Ölçüm değerleri ve büyük sayılar.
  ///
  /// Sans + tablo rakamları: sayılar değişirken yerinden oynamaz, sütunlarda
  /// hizalanır. Grafik eksenleri, halka ortaları, laboratuvar tabloları.
  static TextStyle numeric(AppPalette p, {double size = 28, Color? color}) =>
      TextStyle(
        fontFamily: sans,
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.08,
        letterSpacing: -0.4,
        color: color ?? p.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Küçük sayısal etiketler (birim, tarih, sayaç).
  static TextStyle numericSmall(AppPalette p, {double size = 14, Color? color}) =>
      TextStyle(
        fontFamily: sans,
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: color ?? p.textSecondary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
