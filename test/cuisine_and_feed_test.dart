import 'package:bobrek_dostu/clinical/cuisine_score.dart';
import 'package:bobrek_dostu/core/services/reading_service.dart';
import 'package:bobrek_dostu/core/services/scanner_service.dart';
import 'package:bobrek_dostu/features/nutrition/meal_vision_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mutfak uygunluk puanı', () {
    test('ızgara/balık genelde uygun', () {
      expect(adviseCuisine('fish').suitability, CuisineSuitability.good);
      expect(adviseCuisine('grill').suitability, CuisineSuitability.good);
    });

    test('Türk mutfağı seçerek uygun', () {
      final a = adviseCuisine('turkish');
      expect(a.suitability, CuisineSuitability.moderate);
      expect(a.tipsTr, isNotEmpty);
    });

    test('fast food / kebap dikkatli', () {
      expect(adviseCuisine('kebab').suitability, CuisineSuitability.caution);
      expect(adviseCuisine('pizza').suitability, CuisineSuitability.caution);
      expect(adviseCuisine('chinese').suitability, CuisineSuitability.caution);
    });

    test('çoklu etikette EN DÜŞÜK puan kullanılır (güvenli taraf)', () {
      final a = adviseCuisine('kebab;turkish');
      expect(a.suitability, CuisineSuitability.caution);
    });

    test('etiket yoksa bilinmiyor döner ve menü fotoğrafı önerir', () {
      final a = adviseCuisine(null);
      expect(a.suitability, CuisineSuitability.unknown);
      expect(a.tipsTr.join(), contains('fotoğraf'));
    });

    test('kafe için özel açıklama verilir', () {
      final a = adviseCuisine(null, amenity: 'cafe');
      expect(a.reasonTr, contains('Kafe'));
    });

    test('tanınmayan etiket bilinmiyor döner, sayı uydurmaz', () {
      final a = adviseCuisine('martian_fusion');
      expect(a.suitability, CuisineSuitability.unknown);
      expect(a.reasonTr, contains('martian_fusion'));
    });

    test('menü doğrulanmadı uyarısı tanımlı', () {
      expect(kMenuNotVerifiedTr, contains('Menü doğrulanmadı'));
    });
  });

  group('RSS ayrıştırma', () {
    test('RSS 2.0 öğeleri okunur', () {
      const xml = '''
<?xml version="1.0"?>
<rss version="2.0"><channel>
<title>Kanal</title>
<item>
  <title>Böbrek sağlığı haberi</title>
  <description>&lt;p&gt;Kısa &amp;amp; özet&lt;/p&gt;</description>
  <link>https://example.org/a</link>
  <pubDate>Mon, 23 Nov 2026 11:55:00 GMT</pubDate>
</item>
</channel></rss>
''';
      final items = parseFeed(xml, 'Kanal');
      expect(items.length, 1);
      expect(items.first.title, 'Böbrek sağlığı haberi');
      expect(items.first.summary, 'Kısa & özet');
      expect(items.first.link, 'https://example.org/a');
      expect(items.first.publishedAt?.year, 2026);
      expect(items.first.publishedAt?.month, 11);
      expect(items.first.publishedAt?.day, 23);
    });

    test('Atom girdileri ve href bağlantısı okunur', () {
      const xml = '''
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom">
<entry>
  <title>Atom başlığı</title>
  <summary>Özet metin</summary>
  <link href="https://example.org/b"/>
  <published>2026-11-20T10:00:00Z</published>
</entry>
</feed>
''';
      final items = parseFeed(xml, 'Atom');
      expect(items.length, 1);
      expect(items.first.title, 'Atom başlığı');
      expect(items.first.link, 'https://example.org/b');
      expect(items.first.publishedAt?.day, 20);
    });

    test('bozuk XML boş liste döner, çökmez', () {
      expect(parseFeed('<<<not xml', 'x'), isEmpty);
      expect(parseFeed('', 'x'), isEmpty);
    });

    test('başlıksız öğe atlanır', () {
      const xml = '<rss><channel><item><link>x</link></item></channel></rss>';
      expect(parseFeed(xml, 'x'), isEmpty);
    });

    test('RFC 822 ve ISO tarihleri çözülür', () {
      expect(parseFeedDate('Mon, 23 Nov 2026 11:55:00 GMT')?.day, 23);
      expect(parseFeedDate('2026-11-23T11:55:00Z')?.day, 23);
      expect(parseFeedDate('anlamsız'), isNull);
    });

    test('doğrulanmış kaynaklar tanımlı ve HTTPS', () {
      expect(kVerifiedFeeds, isNotEmpty);
      for (final f in kVerifiedFeeds) {
        expect(f.url, startsWith('https://'));
      }
    });

    test('yerleşik içerikler kaynak ve bağlantı taşır', () {
      expect(kBuiltinArticles.length, greaterThanOrEqualTo(5));
      for (final a in kBuiltinArticles) {
        expect(a.sourceName, isNotEmpty);
        expect(a.link, startsWith('https://'));
        expect(a.body.length, greaterThan(100));
      }
    });
  });

  group('Tahlil OCR satır ayrıştırma', () {
    test('analit, değer ve aralık yakalanır', () {
      final parsed = parseLabLines([
        'Hemoglobin 10,8 g/dL (12,0 - 16,0)',
        'Potasyum 5,4 mEq/L 3,5 - 5,1',
        'alakasız satır',
      ]);
      expect(parsed.length, 2);

      final hb = parsed.firstWhere((p) => p.analyteKey == 'lab_hemoglobin');
      expect(hb.value, closeTo(10.8, 1e-9));
      expect(hb.refMin, closeTo(12.0, 1e-9));
      expect(hb.refMax, closeTo(16.0, 1e-9));

      final k = parsed.firstWhere((p) => p.analyteKey == 'lab_potassium');
      expect(k.value, closeTo(5.4, 1e-9));
    });

    test('en uzun analit adı tercih edilir (hemoglobin > hb)', () {
      final parsed = parseLabLines(['Hemoglobin 11,2']);
      expect(parsed.first.analyteLabel, 'Hemoglobin');
    });

    test('aynı analit tekrarlanırsa ilki tutulur', () {
      final parsed = parseLabLines([
        'Kreatinin 2,1 mg/dL',
        'Kreatinin 2,4 mg/dL',
      ]);
      expect(parsed.length, 1);
      expect(parsed.first.value, closeTo(2.1, 1e-9));
    });

    test('tanınmayan satırlar atlanır, uydurma yapılmaz', () {
      expect(parseLabLines(['Hasta adı: Ahmet', 'Tarih: 23.11.2026']), isEmpty);
    });
  });

  group('Yemek fotoğrafı yanıtı ayrıştırma', () {
    test('değerler ve sapma okunur', () {
      const text = '''
YEMEK: Mercimek çorbası
PORSİYON: 250 g
GÜVEN: orta
KALORİ: 190 kcal (± 40)
PROTEİN: 10 g (± 3)
SODYUM: 1050 mg (± 400)
POTASYUM: 450 mg (± 150)
FOSFOR: 175 mg (± 60)
NOT: Tuz miktarını göremiyorum, lokanta çorbası daha tuzlu olur.
''';
      // Eski düz metin biçimi hâlâ desteklenir (model JSON vermezse).
      final a = parseMealAnalysis(text);
      final e = a.items.single;
      expect(e.name, 'Mercimek çorbası');
      expect(e.portionG, closeTo(250, 1e-9));
      expect(e.confidence, AiConfidence.medium);
      expect(e.kcal!.value, closeTo(190, 1e-9));
      expect(e.kcal!.plusMinus, closeTo(40, 1e-9));
      expect(e.sodium!.value, closeTo(1050, 1e-9));
      expect(a.noteTr, contains('Tuz'));
      expect(e.hasAnyValue, isTrue);
    });

    test('sapma yoksa null kalır', () {
      final e = parseMealAnalysis('KALORİ: 300 kcal').items.single;
      expect(e.kcal!.value, closeTo(300, 1e-9));
      expect(e.kcal!.plusMinus, isNull);
      expect(e.kcal!.formatted('kcal'), '≈ 300 kcal');
    });

    test('güven belirtilmezse unknown', () {
      expect(parseMealAnalysis('YEMEK: x').confidence, AiConfidence.unknown);
    });

    test('düşük güven tanınır', () {
      expect(
        parseMealAnalysis('GÜVEN: düşük').confidence,
        AiConfidence.low,
      );
    });

    test('boş yanıt değersiz döner, sayı uydurmaz', () {
      final a = parseMealAnalysis('Bu fotoğrafta yemek görmüyorum.');
      expect(a.isEmpty, isTrue);
      expect(a.kcal, isNull);
    });

    test('sapmalı biçim metni ± içerir', () {
      const v = EstimatedValue(value: 1050, plusMinus: 400);
      expect(v.formatted('mg'), '≈ 1050 ± 400 mg');
    });
  });
}
