import 'package:bobrek_dostu/features/nutrition/meal_vision_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Yemek fotoğrafı — JSON yanıtı', () {
    const reply = '''
Fotoğrafı inceledim.
{
  "tabak": "Ev yemeği tabağı",
  "guven": "orta",
  "not": "Tuz miktarı fotoğraftan görülemez.",
  "kalemler": [
    {"ad": "Pirinç pilavı", "porsiyon_g": 180, "guven": "orta",
     "kcal": 234, "kcal_pm": 40, "protein": 4.3, "protein_pm": 1,
     "sodyum": 310, "sodyum_pm": 200, "potasyum": 50, "fosfor": 60},
    {"ad": "Izgara tavuk", "porsiyon_g": 120, "guven": "yüksek",
     "kcal": 198, "kcal_pm": 30, "protein": 28.0, "protein_pm": 3,
     "sodyum": 420, "sodyum_pm": 250, "potasyum": 310, "fosfor": 240}
  ]
}
''';

    final a = parseMealAnalysis(reply);

    test('kalemler ayrı ayrı okunur', () {
      expect(a.items, hasLength(2));
      expect(a.items.first.name, 'Pirinç pilavı');
      expect(a.items[1].name, 'Izgara tavuk');
    });

    test('açıklama metni arasındaki JSON bulunur', () {
      expect(a.dishNameTr, 'Ev yemeği tabağı');
      expect(a.noteTr, contains('Tuz'));
      expect(a.confidence, AiConfidence.medium);
    });

    test('kalem güveni ayrı tutulur', () {
      expect(a.items.first.confidence, AiConfidence.medium);
      expect(a.items[1].confidence, AiConfidence.high);
    });

    test('toplamlar kalemlerden hesaplanır', () {
      expect(a.kcal!.value, closeTo(432, 0.01));
      expect(a.protein!.value, closeTo(32.3, 0.01));
      expect(a.sodium!.value, closeTo(730, 0.01));
      // sapmalar da toplanır
      expect(a.kcal!.plusMinus, closeTo(70, 0.01));
    });

    test('beyan edilmeyen besin null kalır, sıfır olmaz', () {
      // Hiçbir kalemde "potasyum_pm" yok; değer var ama sapma yok.
      expect(a.potassium!.value, closeTo(360, 0.01));
      expect(a.potassium!.plusMinus, isNull);
    });

    test('porsiyon değişince değerler orantılı ölçeklenir', () {
      final half = a.items.first.withPortion(90);
      expect(half.portionG, 90);
      expect(half.kcal!.value, closeTo(117, 0.01));
      expect(half.protein!.value, closeTo(2.15, 0.01));
      expect(half.kcal!.plusMinus, closeTo(20, 0.01));
    });

    test('kalem çıkarılınca toplam düşer', () {
      final onlyRice = a.withItems([a.items.first]);
      expect(onlyRice.kcal!.value, closeTo(234, 0.01));
      expect(onlyRice.totalPortionG, closeTo(180, 0.01));
    });
  });

  group('Yemek fotoğrafı — dayanıklılık', () {
    test('boş kalem listesi: uydurmaz', () {
      final a = parseMealAnalysis(
        '{"guven":"düşük","not":"Fotoğrafta yemek göremedim.","kalemler":[]}',
      );
      expect(a.isEmpty, isTrue);
    });

    test('bozuk JSON düz metne düşer', () {
      const flat = '''
YEMEK: Mercimek çorbası
PORSİYON: 250
GÜVEN: orta
KALORİ: 180 kcal (± 40)
PROTEİN: 9 g (± 2)
SODYUM: 600 mg (± 300)
NOT: Tuz görünmüyor.
''';
      final a = parseMealAnalysis(flat);
      expect(a.items, hasLength(1));
      expect(a.items.first.name, 'Mercimek çorbası');
      expect(a.items.first.portionG, closeTo(250, 0.01));
      expect(a.kcal!.value, closeTo(180, 0.01));
      expect(a.kcal!.plusMinus, closeTo(40, 0.01));
      expect(a.noteTr, contains('Tuz'));
    });

    test('tamamen alakasız metin boş sonuç verir', () {
      final a = parseMealAnalysis('Üzgünüm, bu konuda yardımcı olamam.');
      expect(a.isEmpty, isTrue);
    });

    test('porsiyonu bilinmeyen kalemde ölçekleme değerleri bozmaz', () {
      final a = parseMealAnalysis(
        '{"kalemler":[{"ad":"Çorba","kcal":100}]}',
      );
      final scaled = a.items.first.withPortion(200);
      expect(scaled.kcal!.value, closeTo(100, 0.01));
      expect(scaled.portionG, 200);
    });
  });
}
