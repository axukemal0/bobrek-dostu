/// Uygulamanın konuştuğu diller.
///
/// Taban dil TÜRKÇE'dir: bütün metinler kaynakta Türkçe yazılıdır ve
/// çeviri sözlükleri bu Türkçe metni ANAHTAR olarak kullanır. Bunun iki
/// pratik sonucu var:
///  * Çevirisi olmayan bir metin sessizce Türkçe görünür — boş kutu ya da
///    "missing_key" çıkmaz.
///  * Kaynaktaki Türkçe metin değiştirilirse o metin yine Türkçe görünür,
///    yani yanlış bir eski çeviri gösterilmez.
library;

import 'dart:ui' show Locale;

enum AppLanguage {
  tr('tr', 'Türkçe'),
  en('en', 'English'),
  es('es', 'Español'),
  ar('ar', 'العربية', rightToLeft: true),
  fr('fr', 'Français'),
  de('de', 'Deutsch'),
  ru('ru', 'Русский', latinScript: false),
  pt('pt', 'Português'),
  hi('hi', 'हिन्दी', latinScript: false),
  zh('zh', '中文（简体）', latinScript: false);

  const AppLanguage(
    this.code,
    this.nativeName, {
    this.rightToLeft = false,
    this.latinScript = true,
  });

  /// ISO 639-1 kodu. Kaydedilen değer budur.
  final String code;

  /// Dilin kendi adı. Dil seçiciyi hangi dilde açarsan aç okunur kalır.
  final String nativeName;

  /// Sağdan sola yazılır (şu an yalnız Arapça).
  final bool rightToLeft;

  /// Gömülü yazı tipleriyle (Nunito, Playfair) yazılabilir mi?
  ///
  /// DİKKAT: `tools/subset_fonts.sh` yazı tiplerini Latin + Türkçe
  /// kümesine indirir (972 KB -> 252 KB). Kiril, Arap, Devanagari ve CJK
  /// glifleri gömülü dosyalarda YOKTUR. Bu diller için gömülü yazı tipi
  /// kullanılmaz; sistemin kendi yazı tipine bırakılır (iOS'ta SF Pro,
  /// SF Arabic, Kohinoor Devanagari, PingFang SC — hepsi iyi görünür).
  /// Karışık yazı tipi yerine o dilde tutarlı tek yazı tipi tercih edildi.
  final bool latinScript;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) {
    for (final l in values) {
      if (l.code == code) return l;
    }
    return AppLanguage.tr;
  }
}
