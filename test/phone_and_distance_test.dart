import 'package:bobrek_dostu/core/services/food_service.dart';
import 'package:bobrek_dostu/core/services/places_service.dart';
import 'package:bobrek_dostu/core/services/sms_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Telefon numarası normalleştirme (WhatsApp)', () {
    test('baştaki 0 Türkiye koduyla değiştirilir', () {
      expect(normalizePhoneForWhatsApp('0532 123 45 67'), '905321234567');
      expect(normalizePhoneForWhatsApp('0532-123-45-67'), '905321234567');
    });

    test('+90 biçimi korunur', () {
      expect(normalizePhoneForWhatsApp('+90 532 123 45 67'), '905321234567');
    });

    test('00 ile başlayan uluslararası biçim', () {
      expect(normalizePhoneForWhatsApp('0090 532 123 45 67'), '905321234567');
    });

    test('kodsuz 10 haneli cep numarasına 90 eklenir', () {
      expect(normalizePhoneForWhatsApp('5321234567'), '905321234567');
    });

    test('zaten 90 ile başlıyorsa iki kez eklenmez', () {
      expect(normalizePhoneForWhatsApp('905321234567'), '905321234567');
    });

    test('sabit hat numarası', () {
      expect(normalizePhoneForWhatsApp('0212 000 00 00'), '902120000000');
    });

    test('parantez ve eğik çizgi temizlenir', () {
      expect(normalizePhoneForWhatsApp('(0532) 123/45/67'), '905321234567');
    });
  });

  group('Kuş uçuşu mesafe (haversine)', () {
    test('aynı nokta sıfır', () {
      expect(haversineMeters(39.92, 32.85, 39.92, 32.85), closeTo(0, 0.01));
    });

    test('bilinen mesafe: Ankara Kızılay - Çankaya ~3 km', () {
      // Kızılay (39.9208, 32.8541) -> Çankaya (39.8900, 32.8600)
      final d = haversineMeters(39.9208, 32.8541, 39.8900, 32.8600);
      expect(d, greaterThan(3000));
      expect(d, lessThan(3700));
    });

    test('1 derece enlem ~111 km', () {
      final d = haversineMeters(39.0, 32.0, 40.0, 32.0);
      expect(d, greaterThan(110000));
      expect(d, lessThan(112000));
    });

    test('simetrik', () {
      final a = haversineMeters(39.92, 32.85, 41.01, 28.98);
      final b = haversineMeters(41.01, 28.98, 39.92, 32.85);
      expect(a, closeTo(b, 0.01));
    });

    test('Ankara - İstanbul ~350 km', () {
      final d = haversineMeters(39.9208, 32.8541, 41.0082, 28.9784);
      expect(d, greaterThan(340000));
      expect(d, lessThan(360000));
    });
  });

  group('Türkçe arama normalleştirme (besin)', () {
    test('büyük I ve İ aynı sonuca iner', () {
      expect(normalizeTr('İSPANAK'), 'ispanak');
      expect(normalizeTr('ıspanak'), 'ispanak');
      expect(normalizeTr('Ispanak'), 'ispanak');
    });

    test('diğer Türkçe karakterler', () {
      expect(normalizeTr('Çorba'), 'corba');
      expect(normalizeTr('Şeftali'), 'seftali');
      expect(normalizeTr('Yoğurt'), 'yogurt');
      expect(normalizeTr('Üzüm'), 'uzum');
      expect(normalizeTr('Börek'), 'borek');
    });

    test('boşluklar kırpılır', () {
      expect(normalizeTr('  Simit  '), 'simit');
    });
  });
}
