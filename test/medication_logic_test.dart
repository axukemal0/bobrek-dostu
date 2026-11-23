import 'package:bobrek_dostu/features/medications/medication_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Saat çözümleme', () {
    test('virgülle ayrılmış saatler', () {
      final t = parseTimes('08:00,20:00');
      expect(t.length, 2);
      expect(t[0].hour, 8);
      expect(t[1].hour, 20);
    });

    test('nokta da ayırıcı olarak kabul edilir', () {
      expect(parseTimes('08.30').first.minute, 30);
    });

    test('sıralanır', () {
      final t = parseTimes('22:00, 08:00, 14:30');
      expect(t.map((x) => x.hour).toList(), [8, 14, 22]);
    });

    test('tek sayı saat sayılır', () {
      final t = parseTimes('9');
      expect(t.first.hour, 9);
      expect(t.first.minute, 0);
    });

    test('geçersiz parçalar atlanır', () {
      final t = parseTimes('08:00, abc, 99:99, 25:00, 12:61, 20:00');
      expect(t.length, 2);
    });

    test('boş metin boş liste', () {
      expect(parseTimes(''), isEmpty);
      expect(parseTimes('   '), isEmpty);
    });
  });

  group('Gün çözümleme', () {
    test('null her gün demektir', () {
      expect(parseWeekdays(null), {1, 2, 3, 4, 5, 6, 7});
      expect(parseWeekdays(''), {1, 2, 3, 4, 5, 6, 7});
    });

    test('belirli günler', () {
      expect(parseWeekdays('1,3,5'), {1, 3, 5});
    });

    test('aralık dışı değerler atlanır, hepsi atlanırsa her gün', () {
      expect(parseWeekdays('0,8,9'), {1, 2, 3, 4, 5, 6, 7});
      expect(parseWeekdays('2,0,4'), {2, 4});
    });
  });
}
