import 'package:bobrek_dostu/core/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sürüm karşılaştırması yanlışsa ya güncelleme hiç gelmez ya da
/// kullanıcıya sürekli "yeni sürüm var" denir. İkisi de kötü.
void main() {
  group('Sürüm karşılaştırma', () {
    test('yama sürümü artışı yakalanır', () {
      expect(compareAppVersions('1.0.1', '1.0.0'), greaterThan(0));
    });

    test('ara sürüm yamadan önceliklidir', () {
      expect(compareAppVersions('1.1.0', '1.0.9'), greaterThan(0));
    });

    test('ana sürüm her şeyden önceliklidir', () {
      expect(compareAppVersions('2.0.0', '1.9.9'), greaterThan(0));
    });

    test('aynı sürüm eşittir', () {
      expect(compareAppVersions('1.2.3', '1.2.3'), 0);
    });

    test('derleme numarası sürümü etkilemez', () {
      expect(compareAppVersions('1.2.3+99', '1.2.3+1'), 0);
    });

    test('sayısal karşılaştırma yapılır, metinsel değil', () {
      // Metin karşılaştırmasında "1.10.0" < "1.9.0" çıkardı.
      expect(compareAppVersions('1.10.0', '1.9.0'), greaterThan(0));
    });

    test('yama parçası eksikse sıfır sayılır', () {
      expect(compareAppVersions('1.2', '1.2.0'), 0);
      expect(compareAppVersions('1.3', '1.2.9'), greaterThan(0));
    });

    test('eski sürüm negatif döner', () {
      expect(compareAppVersions('1.0.0', '1.0.1'), lessThan(0));
    });

    test('bozuk sürüm metni çökertmez', () {
      expect(compareAppVersions('bozuk', '1.0.0'), 0);
      expect(compareAppVersions('1.0.0', ''), 0);
    });
  });
}
