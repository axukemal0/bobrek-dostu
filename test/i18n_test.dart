import 'dart:io';

import 'package:bobrek_dostu/core/i18n/i18n.dart';
import 'package:bobrek_dostu/core/i18n/languages.dart';
import 'package:bobrek_dostu/core/i18n/translations/index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => I18n.use(AppLanguage.tr));

  group('Çeviri arama', () {
    test('Türkçede metin olduğu gibi döner', () {
      I18n.use(AppLanguage.tr);
      expect(t('Kaydet'), 'Kaydet');
    });

    test('çevirisi olmayan metin Türkçe kalır, boş kutu olmaz', () {
      I18n.use(AppLanguage.en);
      const nonsense = 'bu metnin çevirisi yok · 9f3a';
      expect(t(nonsense), nonsense);
    });

    test('her dil yüklenebilir', () {
      for (final language in AppLanguage.values) {
        I18n.use(language);
        expect(I18n.active, language);
        expect(() => t('Kaydet'), returnsNormally);
      }
    });
  });

  group('Ara değerli metin', () {
    test('yer tutucular sırayla dolar', () {
      expect(tf('Günde {0} mL, {1} öğün', [900, 3]), 'Günde 900 mL, 3 öğün');
    });

    test('çevirmen sırayı değiştirebilir', () {
      // Yer tutucular numaralı olduğu için çeviride yer değiştirebilir.
      expect(tf('{1} / {0}', ['a', 'b']), 'b / a');
    });

    test('eksik argüman boş bırakılır, patlamaz', () {
      expect(tf('{0} ve {5}', ['tek']), 'tek ve ');
    });

    test('süslü parantez metnin kendisiyse korunur', () {
      expect(tf('JSON {anahtar} biçimi', ['x']), 'JSON {anahtar} biçimi');
    });

    test('argüman yoksa şablon aynen döner', () {
      expect(tf('Sade metin', const []), 'Sade metin');
    });
  });

  group('Sözlük dosyaları', () {
    test('anahtar da değer de boş değil', () {
      for (final language in AppLanguage.values) {
        final table = translationsFor(language);
        for (final entry in table.entries) {
          expect(entry.key.trim(), isNotEmpty, reason: language.code);
          expect(
            entry.value.trim(),
            isNotEmpty,
            reason: '${language.code}: "${entry.key}" boş çevrilmiş',
          );
        }
      }
    });

    test('Türkçenin sözlüğü yoktur — kaynak metnin kendisi kullanılır', () {
      expect(translationsFor(AppLanguage.tr), isEmpty);
    });

    test('dil kodları benzersiz ve iki harfli', () {
      final codes = AppLanguage.values.map((l) => l.code).toList();
      expect(codes.toSet().length, codes.length);
      for (final c in codes) {
        expect(c.length, 2, reason: c);
      }
    });

    test('kod çözümleme bilinmeyende Türkçeye düşer', () {
      expect(AppLanguage.fromCode('en'), AppLanguage.en);
      expect(AppLanguage.fromCode('xx'), AppLanguage.tr);
      expect(AppLanguage.fromCode(null), AppLanguage.tr);
    });
  });

  group('BEKÇİ — Text bağlantısı', () {
    // Çeviri, Material'ın Text'ini gizleyip yerine kendi Text'imizi
    // koymaya dayanıyor (bkz. lib/core/i18n/text.dart). Bir dosya bunu
    // yapmayı unutursa oradaki metinler SESSİZCE Türkçe kalır — ekranda
    // hata çıkmaz, kimse fark etmez. Bu test onu yakalar.
    final textCall = RegExp(r'(?<![A-Za-z0-9_.$])Text\s*\(');
    // Yorumlarda geçen `Text(` sayılmamalı: bu dosyaların çoğunda
    // çeviri düzeneği YORUMLA anlatılıyor.
    String withoutComments(String src) => src
        .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
        .replaceAll(RegExp(r'//[^\n]*'), '');

    test('Text( kullanan her dosya çeviren Text\'i içe aktarır', () {
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('.g.dart')) continue;
        if (entity.path.contains('/i18n/')) continue;

        final src = entity.readAsStringSync();
        if (!textCall.hasMatch(withoutComments(src))) continue;

        final hidesMaterialText =
            src.contains("material_ui/material_ui.dart' hide Text") ||
                src.contains('material_ui/material_ui.dart\' hide ') &&
                    RegExp(r"material_ui\.dart' hide [^;]*\bText\b")
                        .hasMatch(src);
        final importsOurText =
            RegExp(r"import '[^']*core/i18n/text\.dart';").hasMatch(src) ||
                RegExp(r"import '(\.\./)*i18n/text\.dart';").hasMatch(src);

        if (!hidesMaterialText || !importsOurText) {
          offenders.add(
            '${entity.path} '
            '(${hidesMaterialText ? "" : "hide Text yok "}'
            '${importsOurText ? "" : "text.dart içe aktarılmamış"})',
          );
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Bu dosyalarda metinler çevrilmeden kalır:\n'
            '${offenders.join("\n")}',
      );
    });
  });
}
