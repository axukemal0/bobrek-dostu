import 'dart:io';

import 'package:bobrek_dostu/core/i18n/i18n.dart';
import 'package:bobrek_dostu/core/i18n/languages.dart';
import 'package:bobrek_dostu/core/i18n/text.dart';
import 'package:bobrek_dostu/core/i18n/translations/index.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as m;

void main() {
  tearDown(() => I18n.use(AppLanguage.tr));

  group('Çeviren Text — uçtan uca', () {
    // En önemli test: düzeneğin GERÇEKTEN ekrana yansıdığını gösterir.
    // `const Text('Kaydet')` yazan kod değişmedi; çeviri çizim anında
    // yapılıyor. Bu kırılırsa bütün sözlük boşa gider.
    Future<void> show(WidgetTester tester, m.Widget child) =>
        tester.pumpWidget(
          m.Directionality(
            textDirection: m.TextDirection.ltr,
            child: child,
          ),
        );

    testWidgets('Türkçede kaynak metin görünür', (tester) async {
      I18n.use(AppLanguage.tr);
      await show(tester, const Text('Tekrar dene'));
      expect(find.text('Tekrar dene'), findsOneWidget);
    });

    testWidgets('İngilizcede çeviri görünür', (tester) async {
      I18n.use(AppLanguage.en);
      await show(tester, const Text('Tekrar dene'));
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Tekrar dene'), findsNothing);
    });

    testWidgets('Almanca ve Arapça da çalışır', (tester) async {
      I18n.use(AppLanguage.de);
      await show(tester, const Text('Tekrar dene'));
      expect(find.text('Erneut versuchen'), findsOneWidget);

      I18n.use(AppLanguage.ar);
      await show(tester, const Text('Tekrar dene'));
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });

    testWidgets('Text.verbatim çevirmez — kullanıcının kendi metni', (
      tester,
    ) async {
      I18n.use(AppLanguage.en);
      await show(tester, const Text.verbatim('Tekrar dene'));
      expect(find.text('Tekrar dene'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('çevirisi olmayan metin Türkçe görünür, boş kalmaz', (
      tester,
    ) async {
      I18n.use(AppLanguage.en);
      await show(tester, const Text('bu metnin çevirisi yok · 9f3a'));
      expect(find.text('bu metnin çevirisi yok · 9f3a'), findsOneWidget);
    });
  });

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

    // Aşağıdaki iki test, simülatörde yakalanan iki sessiz hatayı
    // geri gelmesin diye bekliyor. İkisinde de uygulama derleniyor,
    // test geçiyor, ekranda hata çıkmıyor — metin yalnızca Türkçe
    // kalıyor. Gözle bakmadan fark edilmiyor.

    test('Flutter\'ın kendi çizdiği String parametreleri t() ile sarılı', () {
      // hintText, labelText, semanticLabel, tooltip… Widget değil String
      // alır; metni Flutter kendi içinde çizer, çeviren Text'imize hiç
      // uğramaz. İngilizce arayüzde Türkçe ipucu metinleri böyle çıktı.
      const params = [
        'hintText', 'labelText', 'helperText', 'errorText', 'counterText',
        'prefixText', 'suffixText', 'semanticLabel', 'semanticsLabel',
        'tooltip',
      ];
      final pattern = RegExp(
        "(?<![A-Za-z0-9_])(${params.join('|')})\\s*:\\s*'((?:[^'\\\\]|\\\\.)*)'",
      );
      final turkish = RegExp('[çğıöşüÇĞİÖŞÜ]');
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('.g.dart')) continue;
        if (entity.path.contains('/i18n/')) continue;

        final src = withoutComments(entity.readAsStringSync());
        for (final m in pattern.allMatches(src)) {
          if (!turkish.hasMatch(m.group(2)!)) continue;
          offenders.add('${entity.path}  ${m.group(1)}: ${m.group(2)}');
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Bu parametreler t() ile sarılmalı, yoksa her dilde '
            'Türkçe kalır:\n${offenders.join("\n")}',
      );
    });

    test('Text içindeki ara değerli metinlerde Türkçe gömülü değil', () {
      // Sözlük anahtarı, metnin ÇALIŞMA ZAMANINDAKİ tam değeri. Araya
      // değer giren bir metin ('Kaynak: $x') hiçbir sözlükte yoktur;
      // çeviri sessizce atlanır. Böyle metinler tf() şablonuna
      // çevrilmeli: tf('Kaynak: {0}', [x]).
      final interpolated = RegExp(
        r"(?<![A-Za-z0-9_.$])Text\(\s*\n?\s*'((?:[^'\\]|\\.)*\$(?:[^'\\]|\\.)*)'",
      );
      // Ara değerin KENDİSİ Türkçe olabilir ama onu burada göremeyiz;
      // bu test yalnız düz yazı kısmındaki Türkçeyi yakalar.
      final turkish = RegExp('[çğıöşüÇĞİÖŞÜ]');
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('.g.dart')) continue;
        if (entity.path.contains('/i18n/')) continue;

        final src = withoutComments(entity.readAsStringSync());
        for (final m in interpolated.allMatches(src)) {
          final literal = m.group(1)!;
          // Ara değerlerin içindeki Dart ifadesini çıkar: değişken adı
          // Türkçe karakter içerebilir, bizi ilgilendiren düz yazı.
          final prose = literal.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '');
          if (!turkish.hasMatch(prose)) continue;
          offenders.add('${entity.path}  $literal');
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Bu metinler tf() şablonuna çevrilmeli, yoksa her dilde '
            'Türkçe kalır:\n${offenders.join("\n")}',
      );
    });
  });
}
