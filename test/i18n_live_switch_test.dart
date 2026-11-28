import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as m;

import 'package:bobrek_dostu/core/i18n/i18n.dart';
import 'package:bobrek_dostu/core/i18n/languages.dart';
import 'package:bobrek_dostu/core/i18n/scope.dart';
import 'package:bobrek_dostu/core/i18n/text.dart';

/// Dil ÇALIŞIRKEN değişince ekrandaki metin de değişmeli.
///
/// Simülatörde yakalanan hata: İngilizceden Arapçaya geçince sayfanın
/// çoğu Arapçaya döndü ama `const Text(...)` olanlar İngilizce kaldı;
/// uygulamayı kapatıp açınca düzeliyordu. Sebep: Flutter aynı const
/// widget örneğini yeniden çizmez, yani build'i hiç çağrılmaz.
/// Çözüm I18nScope: Text ona bağımlılık kaydediyor (bkz. scope.dart).
void main() {
  // Ekranlardaki gerçek biçim: const. Asıl sınanan da bu — const
  // olmayan bir Text zaten her çizimde yeniden çevrilirdi.
  const subject = Text('Ayarlar');

  m.Widget appWith(AppLanguage language) {
    I18n.use(language);
    return I18nScope(
      language: language,
      child: m.MaterialApp(
        locale: language.locale,
        home: m.Directionality(
          textDirection: language.rightToLeft
              ? m.TextDirection.rtl
              : m.TextDirection.ltr,
          child: subject,
        ),
      ),
    );
  }

  tearDown(() => I18n.use(AppLanguage.tr));

  testWidgets('const Text dil değişince yeniden çevrilir', (tester) async {
    await tester.pumpWidget(appWith(AppLanguage.en));
    expect(find.text('Settings'), findsOneWidget);

    await tester.pumpWidget(appWith(AppLanguage.ar));
    expect(
      find.text('الإعدادات'),
      findsOneWidget,
      reason: 'const Text eski dilde kaldı — dil değişimi ekrana yansımıyor',
    );
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('Türkçeye dönünce kaynak metin görünür', (tester) async {
    await tester.pumpWidget(appWith(AppLanguage.ar));
    expect(find.text('الإعدادات'), findsOneWidget);

    await tester.pumpWidget(appWith(AppLanguage.tr));
    expect(find.text('Ayarlar'), findsOneWidget);
  });

  testWidgets('kapsam yoksa patlamaz — ağaç dışı çizim', (tester) async {
    // Rapor ve bildirim metinleri kapsamsız çiziliyor; Text orada da
    // çalışmalı, yalnız dil değişimini kendiliğinden yakalayamaz.
    I18n.use(AppLanguage.en);
    await tester.pumpWidget(
      const m.Directionality(
        textDirection: m.TextDirection.ltr,
        child: subject,
      ),
    );
    expect(find.text('Settings'), findsOneWidget);
  });
}
