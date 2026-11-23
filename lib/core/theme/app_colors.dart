import 'package:material_ui/material_ui.dart';

/// Renk paleti. Sıcak krem/bej zemin, yumuşak yeşil-altın vurgu.
///
/// Kontrast: gövde metni ve ikincil metin için zemine karşı
/// WCAG AA (≥4.5:1) hedeflenmiştir. Yüksek kontrast modunda
/// metin renkleri koyulaştırılır (≥7:1, AAA'ya yakın).
@immutable
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.backgroundDeep,
    required this.surface,
    required this.surfaceGlass,
    required this.glassBorder,
    required this.shadowDark,
    required this.shadowLight,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.accent,
    required this.accentSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.danger,
    required this.warning,
    required this.success,
    required this.info,
    required this.divider,
  });

  final Brightness brightness;

  /// Ana zemin (sıcak krem).
  final Color background;

  /// Kenarlarda/alt katmanda kullanılan daha doygun bej.
  final Color backgroundDeep;

  /// Kabartmalı kart yüzeyi.
  final Color surface;

  /// Buzlu cam kart dolgusu (yarı saydam).
  final Color surfaceGlass;
  final Color glassBorder;

  /// Neumorphism gölgeleri.
  final Color shadowDark;
  final Color shadowLight;

  final Color primary;
  final Color onPrimary;
  final Color primarySoft;

  final Color accent;
  final Color accentSoft;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  final Color danger;
  final Color warning;
  final Color success;
  final Color info;
  final Color divider;

  bool get isDark => brightness == Brightness.dark;

  /// Sıcak krem — varsayılan tema.
  static const AppPalette warmLight = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF6F1E7),
    backgroundDeep: Color(0xFFEBE2D1),
    surface: Color(0xFFFBF8F1),
    surfaceGlass: Color(0xCCFBF8F1),
    glassBorder: Color(0x66FFFFFF),
    shadowDark: Color(0x1A5C5242),
    shadowLight: Color(0xCCFFFFFF),
    primary: Color(0xFF3C6B54),
    onPrimary: Color(0xFFFBF8F1),
    primarySoft: Color(0xFFDCE8E0),
    accent: Color(0xFF8A6A20),
    accentSoft: Color(0xFFF2E6CA),
    textPrimary: Color(0xFF2A2621),
    textSecondary: Color(0xFF574F44),
    textMuted: Color(0xFF7A7164),
    danger: Color(0xFF9E3528),
    warning: Color(0xFF8A5B12),
    success: Color(0xFF2F6349),
    info: Color(0xFF2F5668),
    divider: Color(0x33837860),
  );

  /// Yüksek kontrast (aynı sıcaklık, daha koyu metin ve net kenarlar).
  static const AppPalette highContrastLight = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFFDFAF3),
    backgroundDeep: Color(0xFFEFE7D7),
    surface: Color(0xFFFFFFFF),
    surfaceGlass: Color(0xF2FFFFFF),
    glassBorder: Color(0xFF8C8372),
    shadowDark: Color(0x33463E30),
    shadowLight: Color(0xFFFFFFFF),
    primary: Color(0xFF1F4A36),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFD2E3D8),
    accent: Color(0xFF6B4D0C),
    accentSoft: Color(0xFFF5E8C8),
    textPrimary: Color(0xFF14120F),
    textSecondary: Color(0xFF332F28),
    textMuted: Color(0xFF4A443A),
    danger: Color(0xFF7E2318),
    warning: Color(0xFF6B4409),
    success: Color(0xFF1C4A34),
    info: Color(0xFF1C3D4C),
    divider: Color(0xFF8C8372),
  );

  /// Gece modu — sıcaklığı koruyan koyu kahve/antrasit.
  static const AppPalette warmDark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF1C1A17),
    backgroundDeep: Color(0xFF141311),
    surface: Color(0xFF26231F),
    surfaceGlass: Color(0xCC2B2823),
    glassBorder: Color(0x1FFFFFFF),
    shadowDark: Color(0x66000000),
    shadowLight: Color(0x0DFFFFFF),
    primary: Color(0xFF8FC2A6),
    onPrimary: Color(0xFF12201A),
    primarySoft: Color(0xFF2A3A32),
    accent: Color(0xFFD9B56A),
    accentSoft: Color(0xFF3A3225),
    textPrimary: Color(0xFFF2EDE2),
    textSecondary: Color(0xFFC9C1B2),
    textMuted: Color(0xFF9E968A),
    danger: Color(0xFFE88E80),
    warning: Color(0xFFDCB166),
    success: Color(0xFF8FC2A6),
    info: Color(0xFF91BACE),
    divider: Color(0x33FFFFFF),
  );

  /// Gece + yüksek kontrast.
  static const AppPalette highContrastDark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0C0B0A),
    backgroundDeep: Color(0xFF000000),
    surface: Color(0xFF1C1A17),
    surfaceGlass: Color(0xF21C1A17),
    glassBorder: Color(0xFFB5AC9B),
    shadowDark: Color(0x99000000),
    shadowLight: Color(0x14FFFFFF),
    primary: Color(0xFFB2E0C6),
    onPrimary: Color(0xFF05100B),
    primarySoft: Color(0xFF24352C),
    accent: Color(0xFFF0D291),
    accentSoft: Color(0xFF3D3425),
    textPrimary: Color(0xFFFFFCF5),
    textSecondary: Color(0xFFE4DDCF),
    textMuted: Color(0xFFC6BEB0),
    danger: Color(0xFFFFB0A2),
    warning: Color(0xFFF2C77E),
    success: Color(0xFFB2E0C6),
    info: Color(0xFFAFD3E5),
    divider: Color(0xFFB5AC9B),
  );

  static AppPalette resolve({
    required bool dark,
    required bool highContrast,
  }) {
    if (dark) return highContrast ? highContrastDark : warmDark;
    return highContrast ? highContrastLight : warmLight;
  }
}

/// Palete her yerden erişim.
class AppPaletteScope extends InheritedWidget {
  const AppPaletteScope({
    required this.palette,
    required super.child,
    super.key,
  });

  final AppPalette palette;

  static AppPalette of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppPaletteScope>();
    return scope?.palette ?? AppPalette.warmLight;
  }

  @override
  bool updateShouldNotify(AppPaletteScope oldWidget) =>
      oldWidget.palette != palette;
}

extension PaletteContext on BuildContext {
  AppPalette get palette => AppPaletteScope.of(this);
}
