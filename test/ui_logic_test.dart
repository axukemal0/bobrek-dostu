import 'package:bobrek_dostu/features/home/home_screen.dart';
import 'package:bobrek_dostu/features/labs/labs_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Yapay zeka tahlil yanıtı çözümleme', () {
    test('boru işaretli satırlar okunur', () {
      final out = parseAiLabReply(
        'Hemoglobin | 11,2 | g/dL | 12,0-16,0\n'
        'Potasyum | 5,8 | mEq/L | 3,5-5,1',
      );
      expect(out, hasLength(2));
      expect(out.first.analyteLabel, 'Hemoglobin');
      expect(out.first.value, 11.2);
      expect(out.first.unit, 'g/dL');
      expect(out.first.refMin, 12.0);
      expect(out.first.refMax, 16.0);
      expect(out.first.analyteKey, 'lab_hemoglobin');
      expect(out.last.analyteKey, 'lab_potassium');
    });

    test('aralığı olmayan satır da alınır', () {
      final out = parseAiLabReply('Ferritin | 48 | ng/mL');
      expect(out, hasLength(1));
      expect(out.single.refMin, isNull);
      expect(out.single.refMax, isNull);
    });

    test('sayı içermeyen ve başlık satırları atlanır', () {
      final out = parseAiLabReply(
        'Analit | Değer | Birim | Aralık\n'
        'GÖREMEDİĞİM: alt satır\n'
        'Kreatinin | 2,4 | mg/dL',
      );
      expect(out, hasLength(1));
      expect(out.single.analyteLabel, 'Kreatinin');
    });

    test('en uzun eşleşme kazanır: "hemoglobin" > "hb"', () {
      final out = parseAiLabReply('Hemoglobin A1c | 6,1 | %');
      // "hemoglobin" eşleşir; kısa "hb" takma adı bunu ezemez.
      expect(out.single.analyteKey, 'lab_hemoglobin');
    });

    test('adı boş olan satır atlanır', () {
      final out = parseAiLabReply(' | 5,0 | mg/dL');
      expect(out, isEmpty);
    });

    test('ondalık nokta da kabul edilir', () {
      final out = parseAiLabReply('Albümin | 3.8 | g/dL');
      expect(out.single.value, 3.8);
    });
  });

  group('Selamlama', () {
    test('saat dilimlerine göre doğru selam', () {
      DateTime at(int h) => DateTime(2026, 11, 27, h);
      expect(Greeting.now(at: at(2)), Greeting.night);
      expect(Greeting.now(at: at(5)), Greeting.morning);
      expect(Greeting.now(at: at(10)), Greeting.morning);
      expect(Greeting.now(at: at(11)), Greeting.day);
      expect(Greeting.now(at: at(16)), Greeting.day);
      expect(Greeting.now(at: at(17)), Greeting.evening);
      expect(Greeting.now(at: at(20)), Greeting.evening);
      expect(Greeting.now(at: at(21)), Greeting.night);
      expect(Greeting.now(at: at(23)), Greeting.night);
    });

    test('ad varsa cümleye katılır, yalnız ilk ad', () {
      expect(
        Greeting.evening.sentenceFor('Kemal Aksu'),
        'İyi akşamlar, Kemal',
      );
    });

    test('ad yoksa selam tek başına kalır', () {
      expect(Greeting.morning.sentenceFor(null), 'Günaydın');
      expect(Greeting.morning.sentenceFor('   '), 'Günaydın');
    });
  });

  group('Türkçe tarih', () {
    test('gün ve ay adları Türkçe', () {
      expect(
        formatLongDate(DateTime(2026, 11, 27)),
        '27 Kasım, Cuma',
      );
      expect(
        formatLongDate(DateTime(2026, 1, 1)),
        '1 Ocak, Perşembe',
      );
    });
  });
}
