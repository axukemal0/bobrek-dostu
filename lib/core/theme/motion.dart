import 'package:material_ui/material_ui.dart';

/// Hareket ayarları.
///
/// Süreler bilinçli olarak kısa: bu bir "işini gör" uygulaması, kullanıcı
/// akışın içinde. Geçişler durumu anlatır, gösteri yapmaz. "Hareketi azalt"
/// açıkken tüm süreler sıfırlanır ve kayma/ölçek devre dışı kalır.
@immutable
class AppMotion {
  const AppMotion({required this.reduceMotion});

  final bool reduceMotion;

  /// Açılış animasyonunun süresi. Hazırlık işleriyle paralel yürür,
  /// bu yüzden soğuk açılışa eklenen gerçek gecikme bundan azdır.
  static const Duration splashDuration = Duration(milliseconds: 1100);

  Duration get instant => Duration.zero;

  /// Dokunma geri bildirimi.
  Duration get fast =>
      reduceMotion ? Duration.zero : const Duration(milliseconds: 130);

  /// Durum değişimi, açılıp kapanan alanlar, sayfa geçişi.
  Duration get normal =>
      reduceMotion ? Duration.zero : const Duration(milliseconds: 210);

  /// Sayfa boyu değişimler (alt sayfa açılışı gibi).
  Duration get slow =>
      reduceMotion ? Duration.zero : const Duration(milliseconds: 320);

  Curve get enter => Curves.easeOutCubic;
  Curve get exit => Curves.easeInCubic;
  Curve get emphasized => Curves.easeOutQuint;

  /// Hafifçe geri yaylanan eğri — yalnız "oldu" anlarında (kaydedildi,
  /// işaretlendi) kullanılır. Gezinmede kullanılmaz: her yerde yaylanan
  /// bir arayüz oyuncak gibi durur.
  Curve get settle => reduceMotion ? Curves.linear : Curves.easeOutBack;

  /// Kart giriş animasyonu için kayma mesafesi.
  double get slideOffset => reduceMotion ? 0 : 12;

  /// Listede i. öğenin gecikmesi. En fazla [cap] öğe gecikir; sonrakiler
  /// birlikte gelir, yoksa uzun listelerde kullanıcı sayfanın dolmasını
  /// izlemek zorunda kalır.
  Duration stagger(int i, {int cap = 6}) => reduceMotion
      ? Duration.zero
      : Duration(milliseconds: 26 * (i < cap ? i : cap));
}

class AppMotionScope extends InheritedWidget {
  const AppMotionScope({
    required this.motion,
    required super.child,
    super.key,
  });

  final AppMotion motion;

  static AppMotion of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<AppMotionScope>();
    return s?.motion ?? const AppMotion(reduceMotion: false);
  }

  @override
  bool updateShouldNotify(AppMotionScope oldWidget) =>
      oldWidget.motion.reduceMotion != motion.reduceMotion;
}

extension MotionContext on BuildContext {
  AppMotion get motion => AppMotionScope.of(this);
}
