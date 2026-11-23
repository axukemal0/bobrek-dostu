import 'package:bobrek_dostu/clinical/drug_safety.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Türkçe ad normalleştirme', () {
    test('Türkçe büyük I ve ı doğru çevrilir', () {
      // Dart'ın toLowerCase()'i "I" -> "i" yapar; "İbuprofen" -> "ibuprofen"
      expect(normalizeDrugName('İbuprofen'), 'ibuprofen');
      expect(normalizeDrugName('IBUPROFEN'), 'ibuprofen');
      expect(normalizeDrugName('Isırgan'), 'isirgan');
      expect(normalizeDrugName('ISIRGAN OTU'), 'isirgan otu');
    });

    test('diğer Türkçe karakterler sadeleşir', () {
      expect(normalizeDrugName('Deksketoprofen'), 'deksketoprofen');
      expect(normalizeDrugName('Şeker'), 'seker');
      expect(normalizeDrugName('Ğ Ü Ö Ç'), 'g u o c');
    });

    test('noktalama ve fazla boşluk temizlenir', () {
      expect(normalizeDrugName('  Brufen-400,  mg '), 'brufen 400 mg');
      expect(normalizeDrugName('Voltaren® jel'), 'voltaren jel');
    });
  });

  group('NSAİİ eşleştirme', () {
    test('etken madde adıyla tam eşleşir', () {
      final m = matchDrugRisks('İbuprofen');
      expect(m, isNotEmpty);
      expect(m.first.risk.id, 'ibuprofen');
      expect(m.first.isExact, isTrue);
      expect(m.first.risk.severity, RiskSeverity.avoid);
    });

    test('Türkiye ticari adıyla eşleşir', () {
      for (final entry in {
        'Brufen': 'ibuprofen',
        'Voltaren': 'diklofenak',
        'Apranax': 'naproksen',
        'Arveles': 'deksketoprofen',
        'Etol': 'etodolak',
        'Majezik': null, // listede yok — kapsamlı olmadığını gösterir
      }.entries) {
        final m = matchDrugRisks(entry.key);
        if (entry.value == null) {
          expect(
            m.where((x) => x.isExact),
            isEmpty,
            reason: '${entry.key} listede yok, tam eşleşme olmamalı',
          );
        } else {
          expect(
            m.first.risk.id,
            entry.value,
            reason: '${entry.key} -> ${entry.value}',
          );
        }
      }
    });

    test('doz bilgisi ekli yazımda da yakalanır', () {
      final m = matchDrugRisks('brufen 400 mg film tablet');
      expect(m, isNotEmpty);
      expect(m.first.risk.id, 'ibuprofen');
    });

    test('her NSAİİ uyarısı NKF kaynağını gösterir', () {
      for (final risk in kNsaidRisks) {
        expect(risk.sourceIds, contains('nkf_pain_meds'));
        expect(risk.riskClass, RiskClass.nsaid);
      }
    });

    test('aspirin için düşük doz ayrımı belirtilir', () {
      final m = matchDrugRisks('Coraspin');
      expect(m, isNotEmpty);
      expect(m.first.risk.reasonTr, contains('DÜŞÜK DOZ'));
      expect(m.first.risk.severity, RiskSeverity.caution);
    });
  });

  group('Bitkisel ürün eşleştirme', () {
    test('ısırgan otu yakalanır', () {
      final m = matchDrugRisks('ısırgan otu çayı');
      expect(m, isNotEmpty);
      expect(m.first.risk.id, 'isirgan');
      expect(m.first.risk.riskClass, RiskClass.herbal);
    });

    test('meyan kökü yakalanır', () {
      expect(matchDrugRisks('meyan kökü').first.risk.id, 'meyan_koku');
    });

    test('İngilizce adla da eşleşir', () {
      expect(matchDrugRisks('horsetail').first.risk.id, 'atkuyrugu');
      expect(matchDrugRisks('licorice').first.risk.id, 'meyan_koku');
    });

    test('potasyumlu diyet tuzu yakalanır ve kritik uyarı verir', () {
      final m = matchDrugRisks('light tuz');
      expect(m, isNotEmpty);
      expect(m.first.risk.id, 'potasyumlu_tuz');
      expect(m.first.risk.reasonTr, contains('hiperkalemi'));
    });
  });

  group('Yanlış pozitif kontrolü', () {
    test('alakasız ilaç adı eşleşmez', () {
      expect(matchDrugRisks('Renagel'), isEmpty);
      expect(matchDrugRisks('Kalsiyum karbonat'), isEmpty);
      expect(matchDrugRisks('Eritropoetin'), isEmpty);
    });

    test('boş ve çok kısa girdi güvenli', () {
      expect(matchDrugRisks(''), isEmpty);
      expect(matchDrugRisks('  '), isEmpty);
      expect(matchDrugRisks('ab'), isEmpty);
    });

    test('kısmi harf dizisi tek kelime olarak eşleşmez', () {
      // "bal" içinde "ba" geçse de eşleşme olmamalı.
      expect(matchDrugRisks('bal'), isEmpty);
    });

    test('aynı ilaç iki kez listelenmez', () {
      final m = matchDrugRisks('ibuprofen brufen nurofen');
      final ids = m.map((x) => x.risk.id).toList();
      expect(ids.length, ids.toSet().length);
    });
  });

  test('veri seti kapsamlı olmadığını belirtir', () {
    expect(kDrugDatasetDisclaimerTr, contains('KAPSAMLI DEĞİLDİR'));
    expect(kDrugDatasetDisclaimerTr, contains('güvenli olduğu anlamına gelmez'));
  });
}
