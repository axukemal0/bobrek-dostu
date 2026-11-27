/// Metnini kendiliğinden çeviren [Text].
///
/// NEDEN BÖYLE: uygulamada 700'den fazla `Text(...)` çağrısı var ve
/// çoğu `const`. Her çağrıyı `Text(t('...'))` yapmak hem 700 dokunuş
/// demekti hem de `const` zincirlerini kırıyordu (bir `const` liste
/// içindeki widget sabit olmayan bir ifade alamaz). Onun yerine
/// Material'ın `Text`'i gizlenir ve yerine bu sınıf konur:
///
/// ```dart
/// import 'package:material_ui/material_ui.dart' hide Text;
/// import '../../core/i18n/text.dart';
/// ```
///
/// Böylece `const Text('Kaydet')` olduğu gibi kalır; çeviri çizim
/// anında yapılır. Dil değişince uygulama kökü yeniden kurulduğu için
/// (bkz. lib/app.dart) bütün metinler aynı anda yenilenir.
///
/// Kullanıcının KENDİ yazdığı metinler için [Text.verbatim] kullan:
/// sözlükte rastlantıyla eşleşen bir not çevrilmesin.
///
/// `test/i18n_test.dart` içindeki bekçi testi, `Text(` kullanan her
/// dosyanın bu dosyayı içe aktardığını doğrular — biri unutulursa
/// sessizce Türkçe kalmaz, test kırılır.
library;

import 'package:material_ui/material_ui.dart' hide Text;
import 'package:material_ui/material_ui.dart' as m show Text;

import 'i18n.dart';

class Text extends StatelessWidget {
  const Text(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : _translate = true;

  /// Çevirmeden gösterir: kullanıcının yazdığı notlar, ilaç adları,
  /// besin adları gibi veriler için.
  const Text.verbatim(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : _translate = false;

  final String data;
  final bool _translate;

  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    final label = semanticsLabel;
    return m.Text(
      _translate ? t(data) : data,
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: label == null ? null : t(label),
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}
