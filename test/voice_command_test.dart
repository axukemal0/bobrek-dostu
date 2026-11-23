import 'package:bobrek_dostu/core/services/speech_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sesli komut — sıvı', () {
    test('mililitre ile açık miktar', () {
      final c = parseVoiceCommand('250 mililitre çay içtim');
      expect(c.kind, VoiceCommandKind.fluid);
      expect(c.fluidMl, 250);
      expect(c.label, 'Çay');
    });

    test('kısaltma ml de anlaşılır', () {
      final c = parseVoiceCommand('500 ml su içtim');
      expect(c.fluidMl, 500);
      expect(c.label, 'Su');
    });

    test('yazıyla sayı + birim', () {
      final c = parseVoiceCommand('iki bardak su içtim');
      expect(c.kind, VoiceCommandKind.fluid);
      expect(c.fluidMl, 400); // bardak = 200 mL
    });

    test('çay bardağı daha küçük sayılır', () {
      final c = parseVoiceCommand('bir çay bardağı çay içtim');
      expect(c.fluidMl, 100);
    });

    test('yarım birim', () {
      final c = parseVoiceCommand('yarım bardak ayran içtim');
      expect(c.fluidMl, 100);
      expect(c.label, 'Ayran');
    });

    test('çorba sıvı olarak sayılır', () {
      final c = parseVoiceCommand('bir kase çorba içtim');
      expect(c.kind, VoiceCommandKind.fluid);
      expect(c.label, 'Çorba');
    });

    test('anlaşılmayan metin unknown döner', () {
      expect(
        parseVoiceCommand('bugün hava çok güzel').kind,
        VoiceCommandKind.unknown,
      );
      expect(parseVoiceCommand('').kind, VoiceCommandKind.unknown);
    });
  });

  group('Sesli komut — tansiyon', () {
    test('iki sayı sistolik/diyastolik olarak alınır', () {
      final c = parseVoiceCommand('tansiyon 140 90');
      expect(c.kind, VoiceCommandKind.bloodPressure);
      expect(c.systolic, 140);
      expect(c.diastolic, 90);
    });

    test('araya kelime girse de çalışır', () {
      final c = parseVoiceCommand('tansiyonum 155 e 95 ölçtüm');
      expect(c.systolic, 155);
      expect(c.diastolic, 95);
    });

    test('tek sayı varsa tansiyon olarak alınmaz', () {
      expect(
        parseVoiceCommand('tansiyon 140').kind,
        isNot(VoiceCommandKind.bloodPressure),
      );
    });
  });

  group('Sesli komut — kilo', () {
    test('ondalık virgülle', () {
      final c = parseVoiceCommand('kilo 78,5');
      expect(c.kind, VoiceCommandKind.weight);
      expect(c.weightKg, closeTo(78.5, 1e-9));
    });

    test('ondalık noktayla', () {
      expect(parseVoiceCommand('kilom 72.3').weightKg, closeTo(72.3, 1e-9));
    });

    test('buçuk kelimesi yarım kilo ekler', () {
      expect(parseVoiceCommand('kilo 78 buçuk').weightKg, closeTo(78.5, 1e-9));
    });

    test('tartı kelimesi de tanınır', () {
      expect(parseVoiceCommand('tartı 69').weightKg, closeTo(69, 1e-9));
    });
  });

  test('bilinen hacim birimleri tanımlı', () {
    expect(kVolumeUnitsMl['bardak'], 200);
    expect(kVolumeUnitsMl['çay bardağı'], 100);
    expect(kVolumeUnitsMl['litre'], 1000);
  });
}
