/// Uygulama geneli sabitler. Tek noktadan değiştirilir.
library;

class AppConfig {
  const AppConfig._();

  /// Uygulama adı — değiştirilebilir.
  static const String appName = 'Böbrek Dostu';
  static const String appVersion = '1.0.0';

  /// OpenStreetMap / Nominatim / Overpass kullanım politikası gereği
  /// her isteğe kimliklendirici bir User-Agent gönderilir.
  /// Kişisel bilgi İÇERMEZ.
  static const String userAgent =
      'BobrekDostu/$appVersion (kisisel saglik uygulamasi)';

  /// Güncelleme denetiminin okuduğu depo ("sahip/depo").
  ///
  /// Uygulama mağazada olmadığı için yeni sürümler buradaki
  /// GitHub "Releases" sayfasından duyurulur. Depo adresi değişirse
  /// yalnız burası değiştirilir.
  static const String githubRepo = 'axukemal0/bobrek-dostu';

  /// flutter_map için tile paketi kimliği (OSM politikası).
  static const String tileUserAgentPackage = 'com.bobrekdostu.app';

  /// Acil çağrı numarası (Türkiye).
  static const String emergencyNumber = '112';
}

/// Dış servis adresleri. Hiçbiri API anahtarı gerektirmez
/// (Claude API hariç — o kullanıcının kendi anahtarıyla çalışır).
class Endpoints {
  const Endpoints._();

  // Hava / UV / hava kalitesi — Open-Meteo (anahtarsız).
  static const String openMeteoForecast =
      'https://api.open-meteo.com/v1/forecast';
  static const String openMeteoAirQuality =
      'https://air-quality-api.open-meteo.com/v1/air-quality';

  // Geocoding — Nominatim (OSM).
  static const String nominatimSearch =
      'https://nominatim.openstreetmap.org/search';
  static const String nominatimReverse =
      'https://nominatim.openstreetmap.org/reverse';

  // Yakın mekan — Overpass API.
  //
  // DİKKAT — ESKİ HATA (27 Kasım 2026'da ölçüldü): sıralama yanlıştı ve
  // "Yakındaki restoranlar" ekranı pratikte hiç çalışmıyordu.
  //   overpass-api.de      -> HTTP 502, "all query workers are busy"
  //   overpass.kumi.systems-> bağlantıyı kabul edip HİÇ yanıt vermiyor
  //   overpass.private.coffee -> aynı şekilde sessiz
  //   overpass.osm.ch      -> HTTP 200, yarım saniyede
  // Uygulama üç ölü sunucuyu 35'er saniye beklediği için kullanıcı
  // ~70 saniye sonra hata görüyordu. Çalışan sunucu başa alındı.
  // Ölüler listeden SİLİNMEDİ: bunlar gönüllü topluluk sunucularıdır,
  // bakımdan sonra geri gelirler; sadece en sona atıldılar.
  static const List<String> overpassMirrors = [
    'https://overpass.osm.ch/api/interpreter',
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];

  // Rota süresi / mesafe — OSRM demo sunucusu.
  static const String osrmDriving =
      'https://router.project-osrm.org/route/v1/driving';
  static const String osrmWalking =
      'https://router.project-osrm.org/route/v1/foot';

  // Barkod ürün verisi — Open Food Facts.
  static const String openFoodFacts =
      'https://world.openfoodfacts.org/api/v2/product';

  // OSM harita döşemeleri.
  static const String osmTiles =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}
