import 'package:bobrek_dostu/features/nutrition/nutrition_label_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Etiket çözümleyici — iki sütunlu Türk etiketi', () {
    // Market ürünlerinde en sık karşılaşılan düzen.
    const label = '''
BESİN DEĞERLERİ          100 g'da      Porsiyonda (30 g)
Enerji                   1850 kJ / 442 kcal    555 kJ / 133 kcal
Yağ                      18,0 g        5,4 g
  doymuş yağ             8,5 g         2,6 g
Karbonhidrat             60,0 g        18,0 g
  şeker                  25,0 g        7,5 g
Lif                      2,0 g         0,6 g
Protein                  7,0 g         2,1 g
Tuz                      0,85 g        0,26 g
''';

    final parsed = parseNutritionLabel(label);

    test('kJ değil kcal alınır', () {
      expect(parsed['kcal']!.value, closeTo(442, 0.5));
    });

    test('100 g sütunu seçilir, porsiyon sütunu değil', () {
      expect(parsed['protein']!.value, closeTo(7.0, 0.01));
      expect(parsed['protein']!.basis, NutrientBasis.per100);
      expect(parsed['carbs']!.value, closeTo(60.0, 0.01));
    });

    test('tuz sodyuma çevrilir ve türetme açıkça belirtilir', () {
      final sodium = parsed['sodium']!;
      // 0,85 g tuz ÷ 2,5 = 0,34 g sodyum = 340 mg
      expect(sodium.value, closeTo(340, 1));
      expect(sodium.unit, 'mg');
      expect(sodium.derivationTr, isNotNull);
      expect(sodium.derivationTr, contains('Tuz'));
    });

    test('"doymuş yağ" satırı "yağ" alanını ezmez', () {
      expect(parsed['fat']!.value, closeTo(18.0, 0.01));
      expect(parsed['saturatedFat']!.value, closeTo(8.5, 0.01));
    });

    test('porsiyon ağırlığı yakalanır', () {
      expect(parsed.portionG, closeTo(30, 0.01));
    });

    test('potasyum ve fosfor beyan edilmediği için eksik raporlanır', () {
      expect(parsed['potassium'], isNull);
      expect(parsed['phosphorus'], isNull);
      expect(parsed.missingCriticalTr, contains('potasyum'));
      expect(parsed.missingCriticalTr, contains('fosfor'));
      expect(parsed.missingCriticalTr, isNot(contains('sodyum/tuz')));
    });
  });

  group('Etiket çözümleyici — tek sütun', () {
    test('yalnız 100 g sütunu', () {
      const label = '''
Beslenme bilgileri (100 ml'de)
Enerji 46 kcal
Protein 3,2 g
Karbonhidrat 4,7 g
Tuz 0,10 g
''';
      final p = parseNutritionLabel(label);
      expect(p['kcal']!.value, closeTo(46, 0.5));
      expect(p['protein']!.value, closeTo(3.2, 0.01));
      expect(p['sodium']!.value, closeTo(40, 1));
      expect(p.basis, NutrientBasis.per100);
    });

    test('yalnız porsiyon sütunu — sütun porsiyon olarak işaretlenir', () {
      const label = '''
Bir porsiyonda (250 ml)
Enerji 115 kcal
Protein 8,0 g
Tuz 0,25 g
''';
      final p = parseNutritionLabel(label);
      expect(p['protein']!.basis, NutrientBasis.perPortion);
      expect(p.basis, NutrientBasis.perPortion);
      expect(p.portionG, closeTo(250, 0.01));
    });
  });

  group('Etiket çözümleyici — birimler ve sayı biçimleri', () {
    test('sodyum doğrudan mg olarak yazılmışsa çevrilmez', () {
      final p = parseNutritionLabel('Sodyum 120 mg\nPotasyum 310 mg');
      expect(p['sodium']!.value, closeTo(120, 0.01));
      expect(p['sodium']!.derivationTr, isNull);
      expect(p['potassium']!.value, closeTo(310, 0.01));
    });

    test('mineral gram yazılmışsa mg ye çevrilir', () {
      final p = parseNutritionLabel('Fosfor 0,22 g');
      expect(p['phosphorus']!.value, closeTo(220, 0.5));
      expect(p['phosphorus']!.derivationTr, contains('mg'));
    });

    test('yalnız kJ varsa kcal e çevrilir ve işaretlenir', () {
      final p = parseNutritionLabel("100 g'da\nEnerji 1200 kJ");
      expect(p['kcal']!.value, closeTo(286.8, 0.5));
      expect(p['kcal']!.confidence, LabelConfidence.medium);
      expect(p['kcal']!.derivationTr, contains('kJ'));
    });

    test('binlik ayırıcı nokta sayıyı bozmaz', () {
      final p = parseNutritionLabel("100 g'da\nEnerji 1.850 kJ / 442 kcal");
      expect(p['kcal']!.value, closeTo(442, 0.5));
    });

    test('ondalık virgül okunur', () {
      final p = parseNutritionLabel("100 g'da\nProtein 12,345 g");
      expect(p['protein']!.value, closeTo(12.345, 0.001));
    });

    test('değer alt satıra düşmüşse yakalanır ama güven düşer', () {
      final p = parseNutritionLabel("100 g'da\nProtein\n7,0 g");
      expect(p['protein']!.value, closeTo(7.0, 0.01));
      expect(p['protein']!.confidence, isNot(LabelConfidence.high));
    });
  });

  group('Etiket çözümleyici — dayanıklılık', () {
    test('boş metin boş sonuç verir, patlamaz', () {
      final p = parseNutritionLabel('');
      expect(p.isEmpty, isTrue);
      expect(p.basis, NutrientBasis.unknown);
    });

    test('alakasız metinden değer uydurmaz', () {
      final p = parseNutritionLabel('Son kullanma tarihi 12.2027\nParti no 4471');
      expect(p['kcal'], isNull);
      expect(p['protein'], isNull);
      expect(p['sodium'], isNull);
    });

    test('Türkçe büyük harfli etiket de okunur', () {
      final p = parseNutritionLabel("100 G'DA\nPROTEİN 9,0 G\nTUZ 1,00 G");
      expect(p['protein']!.value, closeTo(9.0, 0.01));
      expect(p['sodium']!.value, closeTo(400, 1));
    });

    test('sütun belirsizse değer yine okunur ama düşük güvenle', () {
      final p = parseNutritionLabel('Protein 7,0 g');
      expect(p['protein']!.value, closeTo(7.0, 0.01));
      expect(p['protein']!.basis, NutrientBasis.unknown);
      expect(p['protein']!.confidence, LabelConfidence.low);
    });
  });
}
