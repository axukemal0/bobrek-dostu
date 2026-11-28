/// Dil değişimini widget ağacına duyuran kapsam.
///
/// NEDEN GEREKLİ: çeviren [Text] bir `StatelessWidget` ve ekranlardaki
/// çağrıların çoğu `const Text('Ayarlar')`. Flutter bir widget'ın AYNI
/// örneğini yeniden gördüğünde o dalı yeniden çizmez — `const` ifadeler
/// derleme zamanında teklenir, yani her çizimde tıpatıp aynı örnektir.
/// Sonuç: dil değişiyor, sözlük değişiyor, ama o metinlerin `build`'i
/// hiç çağrılmadığı için ekranda eski dil kalıyordu. Simülatörde
/// İngilizceden Arapçaya geçişte görüldü: sayfanın çoğu Arapçaya döndü,
/// başlık "Settings" olarak kaldı; uygulamayı kapatıp açınca düzeldi.
///
/// ÇÖZÜM: Flutter'ın kendi düzeneği. Bir eleman bir [InheritedWidget]'a
/// BAĞIMLILIK kaydederse, o kalıtım değiştiğinde eleman doğrudan kirli
/// işaretlenir — ara katmanların yeniden çizilmesine gerek kalmaz,
/// widget örneğinin aynı olması da engel değildir. Theme ve
/// Localizations de böyle çalışır.
///
/// Çeviriyi yine de genel [I18n] yapıyor; buradaki dil yalnız "ne
/// zaman yeniden çizilecek" sorusunu yanıtlıyor. Sözlük widget ağacının
/// dışından da okunuyor (PDF raporu, bildirimler, klinik değerlendirici)
/// ve oralarda context yok.
library;

import 'package:material_ui/material_ui.dart';

import 'languages.dart';

class I18nScope extends InheritedWidget {
  const I18nScope({required this.language, required super.child, super.key});

  final AppLanguage language;

  /// Çağıran elemanı dil değişimine abone eder.
  ///
  /// Dönen değer çoğu yerde kullanılmaz; çağrının kendisi bağımlılığı
  /// kaydeder. Kapsam yoksa null döner: testler ve ağaç dışı çizimler
  /// bu yüzden patlamaz.
  static AppLanguage? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<I18nScope>()?.language;

  @override
  bool updateShouldNotify(I18nScope oldWidget) =>
      oldWidget.language != language;
}
