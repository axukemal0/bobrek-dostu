/// Çeviri arama noktası.
///
/// Neden BuildContext yok: metinlerin önemli bir bölümü widget ağacının
/// dışında üretiliyor — PDF raporu, bildirim gövdeleri, klinik
/// değerlendirici, çözümleyici hata mesajları. Bunların hiçbirinde
/// context yok. Bu yüzden etkin dil tek bir genel değişkende tutulur ve
/// dil değiştiğinde uygulama kökü yeniden kurulur (bkz. lib/app.dart,
/// `KeyedSubtree`). Dil değişimi nadir bir olaydır; tüm ağacı yeniden
/// kurmanın bedeli önemsizdir ve her yerin tutarlı olmasını garantiler.
library;

import 'languages.dart';
import 'translations/index.dart';

class I18n {
  const I18n._();

  static AppLanguage _active = AppLanguage.tr;
  static Map<String, String> _table = const <String, String>{};

  static AppLanguage get active => _active;

  /// Etkin dili değiştirir. Yalnız dil sağlayıcısı çağırır.
  static void use(AppLanguage language) {
    _active = language;
    _table = translationsFor(language);
  }

  /// Çevirisi olmayan metinler (hata ayıklama için).
  static Iterable<String> missingAmong(Iterable<String> sources) =>
      _table.isEmpty
          ? const <String>[]
          : sources.where((s) => !_table.containsKey(s));

  static int get entryCount => _table.length;
}

/// Türkçe kaynak metni etkin dile çevirir.
///
/// Çeviri yoksa metnin KENDİSİ döner. Bu kasıtlı: eksik çeviri, bozuk
/// arayüzden iyidir.
String t(String source) {
  final table = I18n._table;
  if (table.isEmpty) return source;
  return table[source] ?? source;
}

/// Ara değerli metin: `tf('Günde {0} mL', [900])`.
///
/// Şablon önce çevrilir, sonra `{0}`, `{1}` … yerine değerler konur.
/// Çeviri yoksa Türkçe şablon kullanılır — yer tutucular yine dolar.
/// Yer tutucuların SIRASI dile göre değişebilir; bu yüzden numaralıdır,
/// çevirmen sırayı değiştirebilir.
String tf(String template, List<Object?> args) {
  final text = t(template);
  if (args.isEmpty || !text.contains('{')) return text;

  final out = StringBuffer();
  var i = 0;
  while (i < text.length) {
    if (text.codeUnitAt(i) == 0x7B /* { */) {
      final end = text.indexOf('}', i + 1);
      if (end > i) {
        final index = int.tryParse(text.substring(i + 1, end));
        if (index != null) {
          out.write(index >= 0 && index < args.length ? '${args[index]}' : '');
          i = end + 1;
          continue;
        }
      }
    }
    out.writeCharCode(text.codeUnitAt(i));
    i++;
  }
  return out.toString();
}
