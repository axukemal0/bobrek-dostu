import 'package:bobrek_dostu/clinical/evaluator.dart';
import 'package:bobrek_dostu/clinical/settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const settings70kg = ClinicalSettings(bodyWeightKg: 70);

  group('Besin toplamları', () {
    test('porsiyona göre ölçeklenir', () {
      final e = FoodEntryValues(
        grams: 200,
        kcalPer100g: 100,
        proteinPer100g: 5,
        sodiumMgPer100g: 300,
        potassiumMgPer100g: 250,
        phosphorusMgPer100g: 80,
        fluidMlPer100g: 60,
      );
      expect(e.kcal, 200);
      expect(e.proteinG, 10);
      expect(e.sodiumMg, 600);
      expect(e.potassiumMg, 500);
      expect(e.phosphorusMg, 160);
      expect(e.fluidMl, 120);
    });

    test('bilinmeyen (null) değer SIFIR SAYILMAZ, ayrı sayılır', () {
      final daily = computeDailyNutrition(
        entries: const [
          FoodEntryValues(grams: 100, kcalPer100g: 200, proteinPer100g: 10),
          // potasyum ve fosfor etiketlenmemiş paketli ürün
          FoodEntryValues(grams: 100, kcalPer100g: 150),
        ],
        settings: settings70kg,
      );

      expect(daily.energy.value, 350);
      expect(daily.energy.unknownItemCount, 0);

      expect(daily.protein.value, 10);
      expect(daily.protein.unknownItemCount, 1);
      expect(daily.protein.isPartial, isTrue);

      expect(daily.potassium.value, 0);
      expect(daily.potassium.unknownItemCount, 2);
    });

    test('protein hedefi g/kg × kilo olarak hesaplanır', () {
      final daily = computeDailyNutrition(
        entries: const [],
        settings: settings70kg,
      );
      // Varsayılan 0,8 g/kg/gün × 70 kg = 56 g
      expect(daily.protein.target, closeTo(56, 1e-9));
    });

    test('diyaliz hastasında protein varsayılanı 1,0 g/kg olur', () {
      const dialysis = ClinicalSettings(
        bodyWeightKg: 70,
        treatmentMode: TreatmentMode.hemodialysis,
      );
      expect(dialysis.resolve('protein_g_per_kg').value, 1.0);
      expect(dialysis.dailyAbsolute('protein_g_per_kg'), closeTo(70, 1e-9));
    });

    test('kilo girilmemişse g/kg hedefi hesaplanamaz', () {
      const noWeight = ClinicalSettings();
      expect(noWeight.dailyAbsolute('protein_g_per_kg'), isNull);
    });

    test('potasyum hedefi varsayılan olarak YOK (bireyselleştirilir)', () {
      final daily = computeDailyNutrition(
        entries: const [
          FoodEntryValues(grams: 100, potassiumMgPer100g: 5000),
        ],
        settings: settings70kg,
      );
      expect(daily.potassium.target, isNull);
      expect(daily.potassium.hasTarget, isFalse);
      // Hedef yoksa "aşım" da olmaz.
      expect(daily.potassium.isOverTarget, isFalse);
      expect(daily.potassium.ratio, isNull);
    });

    test('sodyum hedefi KDIGO varsayılanı 2000 mg', () {
      final daily = computeDailyNutrition(
        entries: const [],
        settings: settings70kg,
      );
      expect(daily.sodium.target, 2000);
    });

    test('hedef aşımı yakalanır', () {
      final daily = computeDailyNutrition(
        entries: const [
          FoodEntryValues(grams: 100, sodiumMgPer100g: 2500),
        ],
        settings: settings70kg,
      );
      expect(daily.sodium.isOverTarget, isTrue);
      expect(daily.exceeded.map((n) => n.key), contains('sodium'));
      expect(nutrientExceededAdviceTr(daily.sodium), contains('500 mg aştın'));
    });

    test('enerji hedefi aralığın ÜST sınırıdır', () {
      final daily = computeDailyNutrition(
        entries: const [],
        settings: settings70kg,
      );
      // 25-35 kcal/kg × 70 = 1750-2450; hedef 2450
      expect(daily.energy.target, closeTo(2450, 1e-9));
    });

    test('yemekten gelen sıvı toplanır', () {
      final daily = computeDailyNutrition(
        entries: const [
          FoodEntryValues(grams: 250, fluidMlPer100g: 85),
          FoodEntryValues(grams: 150, fluidMlPer100g: 90),
        ],
        settings: settings70kg,
      );
      expect(daily.fluidFromFoodMl, closeTo(212.5 + 135, 1e-9));
    });
  });

  group('Klinik ayar çözümlemesi', () {
    test('kullanıcı değeri varsayılanı ezer ve isCustom olur', () {
      final s = ClinicalSettings(
        bodyWeightKg: 70,
        overrides: {
          'sodium_mg': ClinicalOverride(value: 1500, updatedAt: DateTime(2026)),
        },
      );
      final r = s.resolve('sodium_mg');
      expect(r.value, 1500);
      expect(r.isCustom, isTrue);
      expect(r.formatted(), '1500');
    });

    test('bilerek boşaltma "limit yok" demektir', () {
      const s = ClinicalSettings(
        overrides: {'fluid_ml': ClinicalOverride(isCleared: true)},
      );
      final r = s.resolve('fluid_ml');
      expect(r.isCleared, isTrue);
      expect(r.value, isNull);
      expect(r.formatted(), 'Limit yok');
    });

    test('aralık değerleri biçimlenir', () {
      const s = ClinicalSettings();
      expect(s.resolve('lab_hemoglobin').formatted(), '10.0 - 11.5');
      expect(s.resolve('lab_egfr').formatted(), '≥ 60');
      expect(s.resolve('lab_uacr').formatted(), '≤ 30');
      // Varsayılanı olmayan aralık: laboratuvar aralığı kullanılır.
      expect(s.resolve('lab_phosphate').formatted(), 'Laboratuvar aralığı');
    });

    test('bilinmeyen anahtar hata fırlatır', () {
      const s = ClinicalSettings();
      expect(() => s.resolve('olmayan_anahtar'), throwsArgumentError);
    });

    test('JSON turu veriyi korur', () {
      final s = ClinicalSettings(
        bodyWeightKg: 72.5,
        dryWeightKg: 70,
        hasResidualUrine: false,
        treatmentMode: TreatmentMode.hemodialysis,
        overrides: {
          'sodium_mg': ClinicalOverride(
            value: 1800,
            noteTr: 'tahlile göre',
            updatedAt: DateTime(2026, 11, 23),
          ),
          'fluid_ml': const ClinicalOverride(isCleared: true),
        },
      );
      final back = ClinicalSettings.fromJson(s.toJson());
      expect(back.bodyWeightKg, 72.5);
      expect(back.dryWeightKg, 70);
      expect(back.hasResidualUrine, isFalse);
      expect(back.treatmentMode, TreatmentMode.hemodialysis);
      expect(back.resolve('sodium_mg').value, 1800);
      expect(back.resolve('sodium_mg').noteTr, 'tahlile göre');
      expect(back.resolve('fluid_ml').isCleared, isTrue);
    });
  });
}
