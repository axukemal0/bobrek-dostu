import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:bobrek_dostu/core/db/database.dart';
import 'package:bobrek_dostu/core/services/api_client.dart';
import 'package:bobrek_dostu/core/services/places_service.dart';

/// "Haritalar çalışmıyor" hatasının testi.
///
/// Overpass aynası veritabanı boşken bile HTTP 200 ve geçerli JSON
/// döndürebiliyor. 28 Kasım 2026'da overpass.osm.ch tam olarak bunu
/// yapıyordu: yarım saniyede "başarılı" yanıt, sıfır eleman. Hata
/// fırlatılmadığı için Nominatim yedeği devreye girmiyor, kullanıcı
/// boş liste görüyordu — ekran bozuk değil, sadece hep boştu.

/// İstenen adrese göre hazır yanıt veren sahte istemci.
class _FakeClient extends http.BaseClient {
  _FakeClient(this.handler);

  final http.Response Function(http.BaseRequest request) handler;
  final List<String> seen = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    seen.add(request.url.host);
    final res = handler(request);
    return http.StreamedResponse(
      Stream.value(res.bodyBytes),
      res.statusCode,
      headers: res.headers,
      request: request,
    );
  }
}

/// http.Response varsayılan olarak Latin-1 ile kodluyor; Türkçe
/// harfler patlıyor. Gövdeyi UTF-8 bayt olarak veriyoruz.
http.Response _json(String body, [int code = 200]) => http.Response.bytes(
      utf8.encode(body),
      code,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// Nominatim'in `format=json` yanıtının gerçek alanları: ayrıştırıcı
/// `class` ve `osm_id` olmadan satırı atıyor.
String _nominatimBody() => jsonEncode([
      {
        'osm_type': 'node',
        'osm_id': 1,
        'class': 'amenity',
        'type': 'restaurant',
        'name': 'Test Lokantası',
        'display_name': 'Test Lokantası, Fatih, İstanbul',
        'lat': '41.0090',
        'lon': '28.9790',
        'extratags': <String, String>{},
        'address': <String, String>{},
      }
    ]);

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('Overpass boş liste dönerse Nominatim yedeğine düşülür', () async {
    // Gerçek arızanın birebir taklidi: 200, geçerli JSON, sıfır eleman.
    final client = _FakeClient((req) {
      if (req.url.host.contains('overpass')) {
        return _json(jsonEncode({'version': 0.6, 'elements': <dynamic>[]}));
      }
      return _json(_nominatimBody());
    });

    final service = PlacesService(ApiClient(db: db, client: client));
    final result = await service.nearbyRestaurants(
      latitude: 41.0082,
      longitude: 28.9784,
    );

    expect(
      result.places,
      isNotEmpty,
      reason: 'boş Overpass yanıtı başarı sayıldı, yedek hiç çalışmadı',
    );
    expect(result.limited, isTrue,
        reason: 'yedek kaynaktan geldiği kullanıcıya söylenmeli');
    expect(client.seen.any((h) => h.contains('nominatim')), isTrue);
  });

  test('Overpass veri dönerse yedeğe düşülmez', () async {
    final client = _FakeClient((req) {
      if (req.url.host.contains('overpass')) {
        return _json(
          jsonEncode({
            'elements': [
              {
                'type': 'node',
                'lat': 41.0090,
                'lon': 28.9790,
                'tags': {'name': 'Overpass Lokantası', 'amenity': 'restaurant'},
              }
            ]
          }),
        );
      }
      return _json('[]');
    });

    final service = PlacesService(ApiClient(db: db, client: client));
    final result = await service.nearbyRestaurants(
      latitude: 41.0082,
      longitude: 28.9784,
    );

    expect(result.places.single.name, 'Overpass Lokantası');
    expect(result.limited, isFalse);
    expect(client.seen.any((h) => h.contains('nominatim')), isFalse);
  });

  test('aynalar toptan düşünce sigorta atar, sonraki arama beklemez',
      () async {
    var overpassCalls = 0;
    final client = _FakeClient((req) {
      if (req.url.host.contains('overpass')) {
        overpassCalls++;
        return _json('gateway error', 502);
      }
      return _json(_nominatimBody());
    });

    final service = PlacesService(ApiClient(db: db, client: client));
    await service.nearbyRestaurants(latitude: 41.0082, longitude: 28.9784);
    final afterFirst = overpassCalls;
    expect(afterFirst, greaterThan(0));

    // Farklı konum: önbellek değil, sigorta devrede olmalı.
    await service.nearbyRestaurants(latitude: 41.0151, longitude: 28.9795);
    expect(
      overpassCalls,
      afterFirst,
      reason: 'sigorta atmasına rağmen ölü aynalar yeniden denendi',
    );
  });
}
