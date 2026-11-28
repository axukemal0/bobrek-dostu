import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../db/database.dart';
import '../i18n/i18n.dart';

/// Dış servis hatalarının sade Türkçe karşılığı.
class ServiceFailure implements Exception {
  const ServiceFailure(this.messageTr, {this.isOffline = false, this.statusCode});

  final String messageTr;
  final bool isOffline;
  final int? statusCode;

  @override
  String toString() => 'ServiceFailure($messageTr)';
}

/// OSM / Overpass / Nominatim / Open-Meteo için ortak istemci.
///
/// Kullanım politikalarına uyum:
///  * Her istekte kimliklendirici User-Agent (kişisel bilgi içermez).
///  * Yanıtlar veritabanında önbelleğe alınır (gereksiz istek olmaz).
///  * Nominatim için istekler arasında en az 1 saniye beklenir.
///  * Hata durumunda üstel geri çekilme (exponential backoff).
class ApiClient {
  ApiClient({required this.db, http.Client? client})
      : _client = client ?? http.Client();

  final AppDatabase db;
  final http.Client _client;

  /// Nominatim'in kabul ettiği azami hız: saniyede 1 istek.
  DateTime _lastNominatimCall = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _nominatimMinInterval = Duration(seconds: 1);

  Map<String, String> get _headers => {
        'User-Agent': AppConfig.userAgent,
        'Accept': 'application/json',
      };

  /// Önbellekli GET. [maxAge] boyunca ağa hiç çıkmaz.
  ///
  /// Ağ başarısız olursa ve önbellekte eski bir kopya varsa onu döner
  /// ([staleOk] true ise) — çevrimdışı kullanım için.
  Future<String> cachedGet(
    Uri uri, {
    Duration maxAge = const Duration(hours: 1),
    bool staleOk = true,
    Duration timeout = const Duration(seconds: 20),
    bool rateLimitNominatim = false,
  }) async {
    final key = uri.toString();
    final cached = await db.cacheGet(key, maxAge);
    if (cached != null) return cached;

    try {
      if (rateLimitNominatim) await _throttleNominatim();
      final body = await _getWithRetry(uri, timeout: timeout);
      await db.cachePut(key, body);
      return body;
    } on ServiceFailure catch (_) {
      if (staleOk) {
        final stale = await db.cacheGetStale(key);
        if (stale != null) return stale;
      }
      rethrow;
    }
  }

  Future<String> _getWithRetry(
    Uri uri, {
    required Duration timeout,
    int attempts = 3,
  }) async {
    Object? lastError;
    for (var i = 0; i < attempts; i++) {
      if (i > 0) {
        // Üstel geri çekilme: 0.8s, 1.6s
        await Future<void>.delayed(Duration(milliseconds: 800 * (1 << (i - 1))));
      }
      try {
        final res = await _client.get(uri, headers: _headers).timeout(timeout);
        if (res.statusCode == 200) {
          return utf8.decode(res.bodyBytes);
        }
        // 429/5xx geçicidir: tekrar dene.
        if (res.statusCode == 429 || res.statusCode >= 500) {
          lastError = ServiceFailure(
            _statusMessage(res.statusCode),
            statusCode: res.statusCode,
          );
          continue;
        }
        throw ServiceFailure(
          _statusMessage(res.statusCode),
          statusCode: res.statusCode,
        );
      } on TimeoutException {
        lastError = const ServiceFailure(
          'Sunucu zamanında yanıt vermedi. Bağlantını kontrol et.',
          isOffline: true,
        );
      } on http.ClientException catch (e) {
        lastError = ServiceFailure(
          tf('İnternete ulaşılamadı ({0}).', [e.message]),
          isOffline: true,
        );
      }
    }
    if (lastError is ServiceFailure) throw lastError;
    throw const ServiceFailure('Beklenmeyen bir ağ hatası oluştu.');
  }

  static String _statusMessage(int code) => switch (code) {
        400 => 'İstek geçersiz (400). Bu bir uygulama hatası olabilir.',
        403 => 'Sunucu bu isteği reddetti (403).',
        404 => 'Aradığın kayıt bulunamadı (404).',
        429 => 'Sunucu çok yoğun, istek sınırına takıldık (429). '
            'Biraz sonra tekrar dene.',
        >= 500 => tf(
                    'Sunucu şu an hizmet veremiyor ({0}). Bu ücretsiz bir '
                    'açık servis; biraz sonra tekrar dene.',
                    [code],
                  ),
        _ => tf('Sunucu beklenmedik bir yanıt verdi ({0}).', [code]),
      };

  Future<void> _throttleNominatim() async {
    final elapsed = DateTime.now().difference(_lastNominatimCall);
    if (elapsed < _nominatimMinInterval) {
      await Future<void>.delayed(_nominatimMinInterval - elapsed);
    }
    _lastNominatimCall = DateTime.now();
  }

  /// Overpass aynalarının TOPTAN düştüğünü işaretleyen önbellek
  /// anahtarı ve sigortanın açık kalma süresi.
  static const String _overpassDownKey = 'overpass:down';
  static const Duration _overpassCooldown = Duration(minutes: 15);

  /// Overpass POST isteği — aynaları sırayla dener.
  ///
  /// Overpass'ın genel sunucusu sık "at capacity" döner; bu normaldir
  /// ve kullanıcıya dürüstçe söylenir.
  /// [perMirrorTimeout] tek bir sunucuya tanınan süre, [totalBudget]
  /// ise tüm denemelerin toplam üst sınırıdır.
  ///
  /// DİKKAT — ESKİ HATA: sunucu başına 35 saniye vardı, toplam sınır
  /// yoktu. Üç sunucu birden sessiz kaldığında kullanıcı 105 saniye
  /// bekleyip hata görüyordu; ekran donmuş sanılıyordu. Artık toplam
  /// süre sınırlı: bütçe dolunca kalan sunucular hiç denenmez ve
  /// varsa eski önbellek gösterilir.
  ///
  /// Süreler 28 Kasım 2026'da kısaltıldı. Overpass aynalarının hepsi
  /// birden ölü olabiliyor (o gün öyleydi) ve böyle bir günde 40
  /// saniyelik bütçe, kullanıcıyı ÇALIŞAN yedek kaynaktan (Nominatim)
  /// 40 saniye uzak tutuyor. Overpass burada zorunlu değil, daha
  /// zengin veri veren İSTEĞE BAĞLI kaynak; beklemeye değmez.
  Future<String> overpassQuery(
    String query, {
    Duration maxAge = const Duration(hours: 6),
    Duration perMirrorTimeout = const Duration(seconds: 6),
    Duration totalBudget = const Duration(seconds: 12),
  }) async {
    final key = 'overpass:${query.hashCode}';
    final cached = await db.cacheGet(key, maxAge);
    if (cached != null) return cached;

    // SİGORTA: bütün aynalar az önce ölüyse hiç deneme.
    //
    // Overpass ağının tamamı aynı anda ölü olabiliyor. Böyle bir günde
    // her arama, kullanıcıyı çalışan yedek kaynaktan bütçe kadar
    // (şu an 12 sn) uzak tutuyor — hem de her seferinde yeniden.
    // Son toptan başarısızlığın üstünden [_overpassCooldown] geçmediyse
    // doğrudan hata veriyoruz; çağıran Nominatim'e düşüyor.
    if (await db.cacheGet(_overpassDownKey, _overpassCooldown) != null) {
      throw const ServiceFailure(
        'Mekan sunucuları az önce yanıt vermedi; yedek kaynak '
        'kullanılıyor.',
      );
    }

    final deadline = DateTime.now().add(totalBudget);
    final errors = <String>[];
    for (final mirror in Endpoints.overpassMirrors) {
      final left = deadline.difference(DateTime.now());
      if (left <= Duration.zero) {
        errors.add('kalan sunucular denenmedi: süre doldu');
        break;
      }
      final slice = left < perMirrorTimeout ? left : perMirrorTimeout;
      try {
        final res = await _client
            .post(
              Uri.parse(mirror),
              headers: {
                'User-Agent': AppConfig.userAgent,
                'Content-Type': 'application/x-www-form-urlencoded',
              },
              body: {'data': query},
            )
            .timeout(slice);

        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          final body = utf8.decode(res.bodyBytes);
          // Overpass hata metnini 200 ile de dönebilir.
          if (body.trimLeft().startsWith('{')) {
            await db.cachePut(key, body);
            // Çalıştı: varsa sigortayı indir.
            await db.cacheDelete(_overpassDownKey);
            return body;
          }
          errors.add(tf('{0}: beklenmeyen yanıt biçimi', [mirror]));
          continue;
        }
        errors.add('$mirror: HTTP ${res.statusCode}');
      } on TimeoutException {
        errors.add(tf('{0}: zaman aşımı', [mirror]));
      } on http.ClientException catch (e) {
        errors.add('$mirror: ${e.message}');
      }
    }

    // Hepsi düştü: sigortayı at ki sonraki arama beklemesin.
    await db.cachePut(_overpassDownKey, DateTime.now().toIso8601String());

    final stale = await db.cacheGetStale(key);
    if (stale != null) return stale;

    throw ServiceFailure(
      'Yakındaki mekanları getiren açık servis (Overpass) şu an '
      'yanıt vermiyor. Bu ücretsiz bir topluluk servisidir ve '
      'yoğun saatlerde doluyor. Birkaç dakika sonra tekrar dene.',
      isOffline: errors.every((e) => e.contains('zaman aşımı')),
    );
  }

  void dispose() => _client.close();
}
