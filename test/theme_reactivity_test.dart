import 'package:bobrek_dostu/core/providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regresyon: sistem teması değişince palet ANINDA dönmeli.
///
/// Eski kod `PlatformDispatcher.instance.platformBrightness` değerini bir
/// `Provider` gövdesinde tek seferlik okuyordu; telefonu karanlıktan
/// aydınlığa alınca uygulama kapatılıp açılana kadar eski palette kalıyordu.

/// Tercihleri veritabanına gitmeden sabitler.
class _FixedPrefs extends PreferencesNotifier {
  _FixedPrefs(this.value);

  final AppPreferences value;

  @override
  AppPreferences build() => value;
}

ProviderContainer _containerWith(AppPreferences prefs) {
  final container = ProviderContainer(
    overrides: [preferencesProvider.overrideWith(() => _FixedPrefs(prefs))],
  );
  // Provider'ın gözlemciyi kurup canlı kalması için dinleyici gerekir.
  container.listen(paletteProvider, (_, _) {});
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sistem teması değişince palet yeniden hesaplanır',
      (tester) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;

    final container = _containerWith(const AppPreferences());
    addTearDown(container.dispose);

    expect(container.read(paletteProvider).isDark, isFalse,
        reason: 'açık temayla başlamalı');

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pump();

    expect(container.read(paletteProvider).isDark, isTrue,
        reason: 'sistem karanlığa geçince palet de geçmeli');

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pump();

    expect(container.read(paletteProvider).isDark, isFalse,
        reason: 'aydınlığa dönünce palet de dönmeli');
  });

  testWidgets('"sistemi izle" kapalıyken sistem teması paleti değiştirmez',
      (tester) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;

    // Kullanıcı kendi seçimini yapmış: sistemi izleme, açık temada kal.
    final container = _containerWith(
      const AppPreferences(followSystemDark: false, darkMode: false),
    );
    addTearDown(container.dispose);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pump();

    expect(container.read(paletteProvider).isDark, isFalse);
  });

  testWidgets('yüksek kontrast ayarı sistem temasıyla birlikte çalışır',
      (tester) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;

    final container = _containerWith(
      const AppPreferences(highContrast: true),
    );
    addTearDown(container.dispose);

    final light = container.read(paletteProvider);
    expect(light.isDark, isFalse);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pump();

    final dark = container.read(paletteProvider);
    expect(dark.isDark, isTrue);
    // Yüksek kontrast koyu temada da korunmalı (metin zeminle aynı olmasın).
    expect(dark.textPrimary, isNot(equals(light.textPrimary)));
  });
}
