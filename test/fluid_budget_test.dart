import 'package:bobrek_dostu/clinical/evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sıvı bütçesi', () {
    test('limit varsa kalan doğru hesaplanır', () {
      final b = computeFluidBudget(consumedMl: 400, limitMl: 1000);
      expect(b.hasLimit, isTrue);
      expect(b.remainingMl, 600);
      expect(b.ratio, closeTo(0.4, 1e-9));
      expect(b.isOverLimit, isFalse);
      expect(b.overshootMl, 0);
    });

    test('limit yoksa hedefsiz döner (null oran)', () {
      final b = computeFluidBudget(consumedMl: 2500, limitMl: null);
      expect(b.hasLimit, isFalse);
      expect(b.remainingMl, isNull);
      expect(b.ratio, isNull);
      expect(b.isOverLimit, isFalse);
    });

    test('limit 0 verilirse "limit yok" sayılır', () {
      final b = computeFluidBudget(consumedMl: 100, limitMl: 0);
      expect(b.hasLimit, isFalse);
      expect(b.ratio, isNull);
    });

    test('aşım miktarı ve oranı doğru', () {
      final b = computeFluidBudget(consumedMl: 1250, limitMl: 1000);
      expect(b.isOverLimit, isTrue);
      expect(b.overshootMl, 250);
      expect(b.remainingMl, -250);
      expect(b.ratio, closeTo(1.25, 1e-9));
    });

    test('negatif tüketim sıfıra çekilir', () {
      final b = computeFluidBudget(consumedMl: -50, limitMl: 1000);
      expect(b.consumedMl, 0);
    });

    test('tam limitte aşım sayılmaz', () {
      final b = computeFluidBudget(consumedMl: 1000, limitMl: 1000);
      expect(b.isOverLimit, isFalse);
      expect(b.remainingMl, 0);
      expect(b.ratio, 1.0);
    });
  });

  group('Sıvı uyarı metni — limite saygı', () {
    test('limit VARKEN sıcak havada "daha çok iç" DENMEZ', () {
      final b = computeFluidBudget(consumedMl: 300, limitMl: 1000);
      final text = fluidAdviceTr(b, hotWeather: true);
      // Kalan miktarı söyler.
      expect(text, contains('700'));
      expect(text, contains('limitin 1000 mL'));
      // Teşvik eden ifadeler bulunmamalı.
      for (final forbidden in ['bol su', 'bol sıvı', 'daha fazla su iç']) {
        expect(
          text.toLowerCase().contains(forbidden),
          isFalse,
          reason: '"$forbidden" ifadesi limit varken kullanılmamalı',
        );
      }
    });

    test('limit YOKKEN sıcak havada serbest içme söylenebilir', () {
      final b = computeFluidBudget(consumedMl: 500, limitMl: null);
      final text = fluidAdviceTr(b, hotWeather: true);
      expect(text, contains('Hava sıcak'));
      expect(text, contains('limiti girilmemiş'));
    });

    test('aşım durumunda buz/sakız önerisi verir', () {
      final b = computeFluidBudget(consumedMl: 1300, limitMl: 1000);
      final text = fluidAdviceTr(b);
      expect(text, contains('300 mL aştın'));
      expect(text.toLowerCase(), contains('buz'));
    });

    test('limite yaklaşınca uyarır', () {
      final b = computeFluidBudget(consumedMl: 950, limitMl: 1000);
      expect(fluidAdviceTr(b), contains('çok yaklaştın'));
    });
  });
}
