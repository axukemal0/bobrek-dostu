import 'package:bobrek_dostu/clinical/definitions.dart' show Verification;
import 'package:bobrek_dostu/clinical/sources.dart';
import 'package:bobrek_dostu/features/nutrition/diet_plan_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Öğün başlığı tanıma', () {
    test('iki nokta ile yazılmış başlıklar', () {
      final m = matchMealHeading('Kahvaltı: 1 dilim ekmek, beyaz peynir');
      expect(m, isNotNull);
      expect(m!.name, 'Kahvaltı');
      expect(m.rest, '1 dilim ekmek, beyaz peynir');
    });

    test('madde işaretli ve saatli başlık', () {
      final m = matchMealHeading('- Öğle (13:00) - mercimek çorbası');
      expect(m, isNotNull);
      expect(m!.name, 'Öğle');
      expect(m.time, '13:00');
    });

    test('numaralı öğün başlığı', () {
      final m = matchMealHeading('3. Öğün:');
      expect(m, isNotNull);
      expect(m!.name, '3. öğün');
    });

    test('"ara" tek başına ara öğün sayılır', () {
      expect(matchMealHeading('Ara öğün: 1 elma')?.name, 'Ara öğün');
      expect(matchMealHeading('İkindi: ceviz')?.name, 'İkindi (ara öğün)');
    });

    test('cümle başlık sayılmaz', () {
      expect(
        matchMealHeading('Akşam yemeğinden sonra yürüyüş yapmanı öneririm'),
        isNull,
      );
      expect(matchMealHeading('Bol su içmeyi unutma'), isNull);
    });

    test('geçersiz saat yok sayılır', () {
      expect(matchMealHeading('Kahvaltı (99:99): ekmek')?.time, isNull);
    });
  });

  group('Plan çözümleme', () {
    const plan = '''
Kahvaltı (08:00):
- 1 dilim ekmek
- beyaz peynir (tuzsuz)

Ara öğün: 1 elma

Öğle:
mercimek çorbası
ızgara tavuk

Akşam (19:30): zeytinyağlı sebze

Kaçınılacaklar: turşu, salamura
- hazır çorba
- kola
''';

    test('öğünler sırayla çıkar', () {
      final parsed = parseDietPlan(plan);
      expect(
        parsed.meals.map((m) => m.name).toList(),
        ['Kahvaltı', 'Ara öğün', 'Öğle', 'Akşam'],
      );
    });

    test('öğün içeriği ve saati korunur', () {
      final parsed = parseDietPlan(plan);
      expect(parsed.meals.first.timeHint, '08:00');
      expect(parsed.meals.first.detail, contains('1 dilim ekmek'));
      expect(parsed.meals.first.detail, contains('beyaz peynir'));
      expect(parsed.meals[1].detail, '1 elma');
      expect(parsed.meals[3].timeHint, '19:30');
    });

    test('kaçınılacaklar hem aynı satırdan hem alttan toplanır', () {
      final parsed = parseDietPlan(plan);
      expect(
        parsed.avoid,
        containsAll(['turşu', 'salamura', 'hazır çorba', 'kola']),
      );
    });

    test('kaçınma bölümünden sonra gelen satırlar öğüne karışmaz', () {
      final parsed = parseDietPlan(plan);
      expect(parsed.meals.last.detail, 'zeytinyağlı sebze');
    });

    test('başlıksız metin boş öğün listesi döndürür', () {
      final parsed = parseDietPlan(
        'Günde 2 litre sıvı al, tuzu azalt, hareket et.',
      );
      expect(parsed.meals, isEmpty);
    });

    test('tekrarlayan boş başlıklar teke iner', () {
      final parsed = parseDietPlan('Ara öğün:\nAra öğün:\nÖğle: pilav');
      expect(parsed.meals.map((m) => m.name).toList(), ['Ara öğün', 'Öğle']);
    });
  });

  group('Türkçe işaretleri olmayan metin', () {
    // Fotoğraftan okuma Türkçe işaretleri sık düşürür; başlıklar yine
    // tanınmalı, yoksa "Kaçınılacaklar" satırı bile öğün içeriği
    // sanılıyor.
    const plain = '''
Kahvalti (08:00): 1 dilim ekmek
Ara ogun: 1 elma
Ogle (13:00): mercimek corbasi
Aksam (19:30): zeytinyagli sebze
Kacinilacaklar: tursu, kola
''';

    test('işaretsiz başlıklar da tanınır', () {
      final parsed = parseDietPlan(plain);
      expect(
        parsed.meals.map((m) => m.name).toList(),
        ['Kahvaltı', 'Ara öğün', 'Öğle', 'Akşam'],
      );
    });

    test('işaretsiz kaçınma başlığı da tanınır', () {
      final parsed = parseDietPlan(plain);
      expect(parsed.avoid, ['tursu', 'kola']);
      expect(parsed.meals.last.detail, 'zeytinyagli sebze');
    });

    test('işaretsiz numaralı öğün', () {
      expect(matchMealHeading('2. Ogun: corba')?.name, '2. öğün');
    });

    test('foldTr Türkçe harfleri sadeleştirir', () {
      expect(foldTr('Kahvaltı'), 'kahvalti');
      expect(foldTr('ÖĞLE'), 'ogle');
      expect(foldTr('Akşam'), 'aksam');
      expect(foldTr('Çiğ'), 'cig');
      expect(foldTr('İncir'), 'incir');
    });

    test('işaretli ve işaretsiz yazım aynı madde sayılır', () {
      expect(dedupeAvoid(['kayısı', 'kayisi']), ['kayısı']);
    });
  });

  group('Kaçınma satırı ayırma', () {
    test('virgül, noktalı virgül ve "ve" ayırır', () {
      expect(
        splitAvoidItems('tuz, turşu; salamura ve kola'),
        ['tuz', 'turşu', 'salamura', 'kola'],
      );
    });

    test('madde işareti ve sondaki nokta temizlenir', () {
      expect(splitAvoidItems('• hazır çorba.'), ['hazır çorba']);
    });

    test('tek harflik parçalar atılır', () {
      expect(splitAvoidItems('a, tuz'), ['tuz']);
    });

    test('büyük/küçük harf farkı tekrar saymaz', () {
      expect(dedupeAvoid(['Tuz', 'tuz', 'TUZ']), ['Tuz']);
      // Türkçe I/İ: "İncir" ile "incir" aynı maddedir.
      expect(dedupeAvoid(['İncir', 'incir']), ['İncir']);
    });
  });

  group('Hazır kaçınma listesi', () {
    test('her maddenin kaynağı gerçekten tanımlı', () {
      for (final item in kAvoidLibrary) {
        expect(
          sourceById(item.sourceId),
          isNotNull,
          reason: '${item.label} için kaynak bulunamadı: ${item.sourceId}',
        );
      }
    });

    test('potasyum maddeleri "bireyselleştirilir" etiketli', () {
      // Kılavuz potasyum için SAYI VERMEZ; herkese kısıtlama önermek
      // yanlış olurdu. Tek istisna potasyumlu tuz ikamesi.
      final potassium =
          kAvoidLibrary.where((i) => i.group == 'potasyum').toList();
      expect(potassium, isNotEmpty);
      final food = potassium.where((i) => !i.label.contains('Tuz yerine'));
      for (final item in food) {
        expect(
          item.verification,
          Verification.individualized,
          reason: item.label,
        );
      }
    });

    test('her grubun görünen adı var', () {
      for (final item in kAvoidLibrary) {
        expect(kAvoidGroupLabels.containsKey(item.group), isTrue,
            reason: item.group);
      }
    });

    test('etiketler benzersiz', () {
      final labels = kAvoidLibrary.map((i) => trLower(i.label)).toList();
      expect(labels.toSet().length, labels.length);
    });
  });

  group('Uyum yüzdesi', () {
    test('işaretlenmemiş gün null döner', () {
      expect(adherencePercent(const []), isNull);
    });

    test('hepsi uyulduysa 100', () {
      expect(
        adherencePercent([MealMark.full, MealMark.full]),
        100,
      );
    });

    test('kısmen yarım sayılır', () {
      expect(
        adherencePercent([MealMark.full, MealMark.partial]),
        75,
      );
    });

    test('uyulmayan sıfır sayılır ve yuvarlanır', () {
      expect(
        adherencePercent([MealMark.full, MealMark.missed, MealMark.missed]),
        33,
      );
    });

    test('kod dönüşümü iki yönlü çalışır', () {
      for (final m in MealMark.values) {
        expect(MealMark.fromCode(m.code), m);
      }
      expect(MealMark.fromCode('bilinmeyen'), isNull);
      expect(MealMark.fromCode(null), isNull);
    });
  });
}
