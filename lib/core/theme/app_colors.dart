import 'package:material_ui/material_ui.dart';

/// Renk paleti. Sıcak krem/bej zemin, yumuşak yeşil-altın vurgu.
///
/// Kontrast: gövde metni ve ikincil metin için zemine karşı
/// WCAG AA (≥4.5:1) hedeflenmiştir. Yüksek kontrast modunda
/// metin renkleri koyulaştırılır (≥7:1, AAA'ya yakın).

/// Takip edilen her alanın kendi rengi.
///
/// Bu süs değil, **bilgi**: uygulama beş ayrı besin bütçesi tutuyor ve
/// hepsi tek yeşille çizildiğinde ekranı tarayan biri potasyumu fosfordan
/// ayırt edemiyordu. Renk burada yön bulma ve kategori işi yapıyor —
/// "Operate" yüzeyinde rengin asıl görevi budur.
///
/// Kurallar:
///  * Her BÖLÜMÜN tek bir rengi vardır ve o bölümdeki birincil eylem
///    (FAB, "Kaydet", "Aldım") o renkle boyanır. Önceki sürümde her
///    buton aynı yeşildi; ekranlar birbirinin aynı çıkıyor ve renk
///    "burası neresi" sorusuna hiç cevap vermiyordu. Renk artık yön
///    bulma işi yapıyor: ilaç sayfasındaki mor buton, sıvı sayfasındaki
///    camgöbeği butonla karışmaz.
///  * Bölüm rengi SAYFA BAŞINA tektir. Bir ekranda iki farklı vurgu
///    rengi dolu buton olmaz.
///  * Kırmızı/kehribar anlamlarına dokunulmaz (tehlike, uyarı).
///  * Renk tek başına bilgi taşımaz: her ölçeğin yanında adı ve sayısı
///    yazar, aşım ayrıca kırmızıya döner.
///  * Beş besin rengi yalnız besin ekranında yan yana gelir; altı bölüm
///    rengi yalnız ana ekran/gezinme çubuğunda. İki küme kendi içinde
///    ayırt edilebilir, kümeler arası benzerlik sorun değildir.
///
/// Tüm değerler WCAG AA (metin için ≥4,5:1) hesaplanarak seçildi; yüksek
/// kontrast temalarında ≥7:1'e çekilir.
@immutable
class AppAccents {
  const AppAccents({
    required this.energy,
    required this.protein,
    required this.sodium,
    required this.potassium,
    required this.phosphorus,
    required this.fluid,
    required this.medication,
    required this.lab,
    required this.weight,
    required this.activity,
    required this.appointment,
  });

  final Color energy;
  final Color protein;
  final Color sodium;
  final Color potassium;
  final Color phosphorus;
  final Color fluid;
  final Color medication;
  final Color lab;
  final Color weight;
  final Color activity;
  final Color appointment;

  /// Besin anahtarına göre renk (`evaluator.dart` içindeki anahtarlar).
  Color forNutrient(String key) => switch (key) {
        'energy' || 'kcal' => energy,
        'protein' => protein,
        'sodium' => sodium,
        'potassium' => potassium,
        'phosphorus' => phosphorus,
        'fluid' => fluid,
        _ => medication,
      };

  /// Bölüm anahtarına göre renk (yönlendirme yolları ve kart karoları).
  Color forSection(String key) => switch (key) {
        'home' => medication, // yalnız geri dönüş; ana sayfa primary kullanır
        'nutrition' || 'food' || 'diet' => energy,
        'fluid' => fluid,
        'medication' || 'meds' => medication,
        'lab' || 'labs' => lab,
        'weight' || 'vitals' => weight,
        'activity' || 'health' => activity,
        'appointment' || 'calendar' => appointment,
        _ => lab,
      };

  static const AppAccents light = AppAccents(
    energy: Color(0xFF8A6520),
    protein: Color(0xFF9C5033),
    sodium: Color(0xFF3D5C8C),
    potassium: Color(0xFF7D3A72),
    phosphorus: Color(0xFF4F6124),
    fluid: Color(0xFF0F6579),
    medication: Color(0xFF70409A),
    lab: Color(0xFF3C47A0),
    weight: Color(0xFF8A5230),
    activity: Color(0xFF4F6B1E),
    appointment: Color(0xFF9E3B5C),
  );

  static const AppAccents dark = AppAccents(
    energy: Color(0xFFE9C06B),
    protein: Color(0xFFF0A184),
    sodium: Color(0xFF8FB6E8),
    potassium: Color(0xFFE0A2D6),
    phosphorus: Color(0xFFB9CC74),
    fluid: Color(0xFF63C9E0),
    medication: Color(0xFFD4A3EC),
    lab: Color(0xFF9BA7F2),
    weight: Color(0xFFEDA87A),
    activity: Color(0xFFAFD36E),
    appointment: Color(0xFFF2A0B6),
  );

  static const AppAccents highContrastLight = AppAccents(
    energy: Color(0xFF6F511A),
    protein: Color(0xFF85442B),
    sodium: Color(0xFF395683),
    potassium: Color(0xFF7D3A72),
    phosphorus: Color(0xFF4A5B22),
    fluid: Color(0xFF0E5D70),
    medication: Color(0xFF6F3F98),
    lab: Color(0xFF3C47A0),
    weight: Color(0xFF7B492B),
    activity: Color(0xFF455D1A),
    appointment: Color(0xFF913654),
  );

  /// Koyu temanın renkleri siyah zeminde zaten ≥9:1 çıkıyor.
  static const AppAccents highContrastDark = dark;
}

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
    required this.accents,
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

  /// Takip alanlarının renkleri (besinler, sıvı, ilaç, tahlil, kilo).
  final AppAccents accents;

  bool get isDark => brightness == Brightness.dark;

  /// Bir vurgu renginin ÜSTÜNE yazılacak metin/ikon rengi.
  ///
  /// Koyu temada vurgular açık tonlardır (üstüne koyu yazılır), açık
  /// temada koyudur (üstüne beyaz). Sabit bir `onPrimary` kullanmak
  /// bölüm renkleri gelince kırılıyordu: mor dolgunun üstündeki krem
  /// yazı açık temada okunmuyordu. Bu yüzden karar parlaklıkla verilir.
  Color onAccent(Color accent) =>
      accent.computeLuminance() > 0.45
          ? const Color(0xFF14120F)
          : const Color(0xFFFFFFFF);

  /// Vurgu renginin zemine karışan yumuşak dolgusu (kart, karo, rozet).
  Color accentFill(Color accent, {double? opacity}) =>
      accent.withValues(alpha: opacity ?? (isDark ? 0.18 : 0.11));

  /// Vurgu renginin ince kenarı.
  Color accentEdge(Color accent) =>
      accent.withValues(alpha: isDark ? 0.34 : 0.28);

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
    primary: Color(0xFF2F6B4F),
    onPrimary: Color(0xFFFBF8F1),
    primarySoft: Color(0xFFD8E8DE),
    accent: Color(0xFF8A6520),
    accentSoft: Color(0xFFF4E6C6),
    textPrimary: Color(0xFF2A2621),
    textSecondary: Color(0xFF574F44),
    textMuted: Color(0xFF7A7164),
    danger: Color(0xFF9E3528),
    warning: Color(0xFF8A5B12),
    success: Color(0xFF2F6349),
    info: Color(0xFF2F5668),
    divider: Color(0x33837860),
    accents: AppAccents.light,
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
    accents: AppAccents.highContrastLight,
  );

  /// Gece modu — sıcaklığı koruyan koyu kahve/antrasit.
  static const AppPalette warmDark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF1B1A18),
    backgroundDeep: Color(0xFF121210),
    surface: Color(0xFF28251F),
    surfaceGlass: Color(0xCC2E2A24),
    glassBorder: Color(0x1FFFFFFF),
    shadowDark: Color(0x66000000),
    shadowLight: Color(0x0DFFFFFF),
    primary: Color(0xFF86CBA6),
    onPrimary: Color(0xFF0E1D16),
    primarySoft: Color(0xFF2C3E34),
    accent: Color(0xFFE2BE76),
    accentSoft: Color(0xFF3E3527),
    textPrimary: Color(0xFFF2EDE2),
    textSecondary: Color(0xFFC9C1B2),
    textMuted: Color(0xFF9E968A),
    danger: Color(0xFFE88E80),
    warning: Color(0xFFDCB166),
    success: Color(0xFF8FC2A6),
    info: Color(0xFF91BACE),
    divider: Color(0x33FFFFFF),
    accents: AppAccents.dark,
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
    accents: AppAccents.highContrastDark,
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
