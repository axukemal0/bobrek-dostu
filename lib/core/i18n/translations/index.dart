/// Dil -> sözlük eşlemesi.
///
/// Sözlük dosyaları ELLE YAZILMAZ: `tools/i18n_build.py` üretir.
/// Anahtar, kaynaktaki Türkçe metnin çalışma zamanındaki değeridir.
library;

import '../languages.dart';
import 'ar.dart' as ar;
import 'de.dart' as de;
import 'en.dart' as en;
import 'es.dart' as es;
import 'fr.dart' as fr;
import 'hi.dart' as hi;
import 'pt.dart' as pt;
import 'ru.dart' as ru;
import 'zh.dart' as zh;

/// Türkçe için sözlük yoktur: kaynak metnin kendisi kullanılır.
Map<String, String> translationsFor(AppLanguage language) =>
    switch (language) {
      AppLanguage.tr => const <String, String>{},
      AppLanguage.en => en.table,
      AppLanguage.es => es.table,
      AppLanguage.ar => ar.table,
      AppLanguage.fr => fr.table,
      AppLanguage.de => de.table,
      AppLanguage.ru => ru.table,
      AppLanguage.pt => pt.table,
      AppLanguage.hi => hi.table,
      AppLanguage.zh => zh.table,
    };
