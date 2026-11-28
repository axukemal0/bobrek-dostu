@Tags(['live'])
library;

// Bu dosya bir TEŞHİS aracı: çıktısını insan okuyor, o yüzden print
// kullanıyor. Servislerin o an gerçekten ne döndürdüğünü görmek için.
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:bobrek_dostu/core/db/database.dart';
import 'package:bobrek_dostu/core/services/api_client.dart';
import 'package:bobrek_dostu/core/services/places_service.dart';

/// Gerçek ağa çıkar — `flutter test --tags live` ile elle çalıştırılır.
/// Kullanıcının "Haritalar çalışmıyor" bildirimini doğrulamak için.
void main() {
  test('yakındaki mekanlar gerçek servisten geliyor', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final service = PlacesService(ApiClient(db: db));
    final sw = Stopwatch()..start();
    final result = await service.nearbyRestaurants(
      latitude: 41.0082,
      longitude: 28.9784,
    );
    sw.stop();
    print('SONUÇ: ${result.places.length} mekan, '
        '${sw.elapsedMilliseconds} ms, yedek kaynak: ${result.limited}');
    for (final p in result.places.take(5)) {
      print('  · ${p.name}');
    }
    expect(result.places, isNotEmpty);

    // İkinci arama: sigorta atmışsa Overpass hiç denenmemeli.
    final sw2 = Stopwatch()..start();
    final again = await service.nearbyRestaurants(
      latitude: 41.0151,
      longitude: 28.9795,
    );
    sw2.stop();
    print('İKİNCİ: ${again.places.length} mekan, '
        '${sw2.elapsedMilliseconds} ms, yedek: ${again.limited}');
    expect(again.places, isNotEmpty);

    await db.close();
  }, timeout: const Timeout(Duration(seconds: 90)));
}
