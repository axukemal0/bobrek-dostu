import 'package:bobrek_dostu/clinical/definitions.dart';
import 'package:bobrek_dostu/clinical/evaluator.dart';
import 'package:bobrek_dostu/clinical/settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const s = ClinicalSettings(bodyWeightKg: 70);

  group('Kan basıncı eşikleri', () {
    test('180/110 hipertansif kriz aralığı — acil', () {
      final a = evaluateBloodPressure(
        systolic: 180,
        diastolic: 110,
        settings: s,
      );
      expect(a.level, AlertLevel.urgent);
      expect(a.shouldNotifyEmergencyContacts, isTrue);
      expect(a.messageTr, contains('112'));
    });

    test('150/120 — diyastolik eşiği tek başına tetikler', () {
      final a = evaluateBloodPressure(
        systolic: 150,
        diastolic: 120,
        settings: s,
      );
      expect(a.level, AlertLevel.urgent);
    });

    test('179/119 kriz aralığının ALTINDA — acil değil', () {
      final a = evaluateBloodPressure(
        systolic: 179,
        diastolic: 119,
        settings: s,
      );
      expect(a.level, isNot(AlertLevel.urgent));
      expect(a.level, AlertLevel.info); // hedefin (120) üstünde
    });

    test('85/55 düşük tansiyon uyarısı', () {
      final a = evaluateBloodPressure(
        systolic: 85,
        diastolic: 55,
        settings: s,
      );
      expect(a.level, AlertLevel.warning);
      expect(a.definitionKey, 'bp_systolic_low');
      expect(a.verification, Verification.startingPoint);
    });

    test('115/70 hedef aralıkta', () {
      final a = evaluateBloodPressure(
        systolic: 115,
        diastolic: 70,
        settings: s,
      );
      expect(a.level, AlertLevel.none);
    });

    test('125/80 hedefin üstünde ama alarm değil', () {
      final a = evaluateBloodPressure(
        systolic: 125,
        diastolic: 80,
        settings: s,
      );
      expect(a.level, AlertLevel.info);
      expect(a.shouldNotifyEmergencyContacts, isFalse);
    });

    test('kullanıcı eşiği değiştirince kural da değişir', () {
      const custom = ClinicalSettings(
        overrides: {
          'bp_systolic_high': ClinicalOverride(value: 160),
        },
      );
      final a = evaluateBloodPressure(
        systolic: 165,
        diastolic: 95,
        settings: custom,
      );
      expect(a.level, AlertLevel.urgent);
    });
  });

  group('Serum potasyum kademeleri', () {
    test('4,5 normal', () {
      expect(
        evaluateSerumPotassium(mEqPerL: 4.5, settings: s).level,
        AlertLevel.none,
      );
    });

    test('5,2 hafif kademe (bilgi)', () {
      final a = evaluateSerumPotassium(mEqPerL: 5.2, settings: s);
      expect(a.level, AlertLevel.info);
      expect(a.definitionKey, 'potassium_mild');
    });

    test('5,7 orta kademe (uyarı + SMS sinyali)', () {
      final a = evaluateSerumPotassium(mEqPerL: 5.7, settings: s);
      expect(a.level, AlertLevel.warning);
      expect(a.shouldNotifyEmergencyContacts, isTrue);
    });

    test('6,4 ağır kademe (acil)', () {
      final a = evaluateSerumPotassium(mEqPerL: 6.4, settings: s);
      expect(a.level, AlertLevel.urgent);
      expect(a.messageTr, contains('112'));
    });

    test('3,2 hipokalemi', () {
      final a = evaluateSerumPotassium(mEqPerL: 3.2, settings: s);
      expect(a.level, AlertLevel.warning);
      expect(a.definitionKey, 'potassium_low');
    });

    test('her kademe KDIGO/EKG çekincesini içerir', () {
      for (final v in [5.2, 5.7, 6.4]) {
        final a = evaluateSerumPotassium(mEqPerL: v, settings: s);
        expect(a.messageTr, contains('EKG'));
        expect(a.verification, Verification.unverified);
      }
    });

    test('sınır değerler kademeyi tetiklemez (kesin eşit)', () {
      // >5.0 kuralı: tam 5.0 hafif kademeye girmez.
      expect(
        evaluateSerumPotassium(mEqPerL: 5.0, settings: s).level,
        AlertLevel.none,
      );
    });
  });

  group('Tek eşikli ölçümler', () {
    test('nabız 130 üst eşiği aşar', () {
      final a = evaluateSingleThreshold(
        measured: 130,
        definitionKey: 'heart_rate_high',
        settings: s,
        displayLabelTr: 'Nabız',
      );
      expect(a.level, AlertLevel.urgent);
      expect(a.messageTr, contains('başlangıç değeri'));
    });

    test('SpO2 %88 alt eşiğin altında', () {
      final a = evaluateSingleThreshold(
        measured: 88,
        definitionKey: 'spo2_urgent',
        settings: s,
        displayLabelTr: 'SpO2',
      );
      expect(a.level, AlertLevel.urgent);
    });

    test('SpO2 %97 normal', () {
      final a = evaluateSingleThreshold(
        measured: 97,
        definitionKey: 'spo2_warn',
        settings: s,
        displayLabelTr: 'SpO2',
      );
      expect(a.level, AlertLevel.none);
    });

    test('ateş 38,5 uyarı verir ama SMS tetiklemez', () {
      final a = evaluateSingleThreshold(
        measured: 38.5,
        definitionKey: 'temperature_high_c',
        settings: s,
        displayLabelTr: 'Ateş',
      );
      expect(a.level, AlertLevel.warning);
      expect(a.shouldNotifyEmergencyContacts, isFalse);
    });

    test('eşik silinmişse alarm çalışmaz', () {
      const cleared = ClinicalSettings(
        overrides: {'heart_rate_high': ClinicalOverride(isCleared: true)},
      );
      final a = evaluateSingleThreshold(
        measured: 200,
        definitionKey: 'heart_rate_high',
        settings: cleared,
        displayLabelTr: 'Nabız',
      );
      expect(a.level, AlertLevel.none);
    });
  });

  group('İdrar çıkışı — anürik hastada alarm kapalı', () {
    test('rezidüel idrarı olan hastada 300 mL uyarı verir', () {
      const withUrine = ClinicalSettings(
        treatmentMode: TreatmentMode.hemodialysis,
        hasResidualUrine: true,
      );
      final a = evaluateUrineOutput(ml: 300, settings: withUrine);
      expect(a.level, AlertLevel.urgent);
    });

    test('anürik diyaliz hastasında alarm devre dışı', () {
      const anuric = ClinicalSettings(
        treatmentMode: TreatmentMode.hemodialysis,
        hasResidualUrine: false,
      );
      final a = evaluateUrineOutput(ml: 0, settings: anuric);
      expect(a.level, AlertLevel.none);
      expect(a.messageTr, contains('alarm kapalı'));
    });

    test('diyaliz dışı hastada rezidüel bayrağı alarmı kapatmaz', () {
      const preDialysis = ClinicalSettings(
        treatmentMode: TreatmentMode.stage4,
        hasResidualUrine: false,
      );
      final a = evaluateUrineOutput(ml: 200, settings: preDialysis);
      expect(a.level, AlertLevel.urgent);
    });
  });

  group('Diyaliz arası kilo artışı (IDWG)', () {
    test('%4 eşiğinde uyarı yok', () {
      final r = computeIdwg(
        currentKg: 72.8,
        dryWeightKg: 70,
        thresholdPercent: 4,
      )!;
      expect(r.gainKg, closeTo(2.8, 1e-9));
      expect(r.percent, closeTo(4.0, 1e-9));
      expect(r.isOverThreshold, isFalse);
      expect(r.level, AlertLevel.none);
    });

    test('%5 eşiği aşar — uyarı', () {
      final r = computeIdwg(
        currentKg: 73.5,
        dryWeightKg: 70,
        thresholdPercent: 4,
      )!;
      expect(r.percent, closeTo(5.0, 1e-9));
      expect(r.isOverThreshold, isTrue);
      expect(r.level, AlertLevel.warning);
    });

    test('%8 eşiğin 1,5 katından fazla — acil', () {
      final r = computeIdwg(
        currentKg: 75.6,
        dryWeightKg: 70,
        thresholdPercent: 4,
      )!;
      expect(r.percent, closeTo(8.0, 1e-9));
      expect(r.level, AlertLevel.urgent);
    });

    test('kuru ağırlığın altında negatif artış', () {
      final r = computeIdwg(
        currentKg: 69,
        dryWeightKg: 70,
        thresholdPercent: 4,
      )!;
      expect(r.gainKg, closeTo(-1, 1e-9));
      expect(r.percent, lessThan(0));
      expect(r.isOverThreshold, isFalse);
    });

    test('kuru ağırlık 0 veya negatifse hesaplanmaz', () {
      expect(
        computeIdwg(currentKg: 70, dryWeightKg: 0, thresholdPercent: 4),
        isNull,
      );
      expect(
        computeIdwg(currentKg: 70, dryWeightKg: -5, thresholdPercent: 4),
        isNull,
      );
    });

    test('kullanıcı eşiği %4,5 yaparsa %4,2 artış geçer', () {
      final r = computeIdwg(
        currentKg: 72.94,
        dryWeightKg: 70,
        thresholdPercent: 4.5,
      )!;
      expect(r.percent, closeTo(4.2, 0.01));
      expect(r.isOverThreshold, isFalse);
    });
  });

  group('Acil belirti taraması (AI\'dan bağımsız)', () {
    test('göğüs ağrısı yakalanır', () {
      final a = detectRedFlags('Sabahtan beri göğüs ağrım var');
      expect(a, isNotNull);
      expect(a!.level, AlertLevel.urgent);
      expect(a.messageTr, contains('112'));
      expect(a.messageTr, contains('göğüs ağrısı'));
    });

    test('birden çok belirti birlikte listelenir', () {
      final a = detectRedFlags(
        'Nefes darlığı ve çarpıntı var, biraz da bilinç bulanıklığı',
      );
      expect(a, isNotNull);
      expect(a!.messageTr, contains('nefes darlığı'));
      expect(a.messageTr, contains('çarpıntı'));
    });

    test('idrarın kesilmesi yakalanır', () {
      expect(detectRedFlags('iki gündür idrar çıkmıyor'), isNotNull);
    });

    test('masum metin bayrak kaldırmaz', () {
      expect(detectRedFlags('Bugün ne yemeliyim?'), isNull);
      expect(detectRedFlags('Potasyumu nasıl düşürürüm'), isNull);
    });

    test('boş metin güvenli', () {
      expect(detectRedFlags(''), isNull);
    });
  });
}
