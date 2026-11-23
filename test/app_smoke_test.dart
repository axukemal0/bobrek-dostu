import 'package:bobrek_dostu/clinical/settings.dart';
import 'package:bobrek_dostu/core/db/database.dart';
import 'package:bobrek_dostu/core/providers.dart';
import 'package:bobrek_dostu/core/router/app_router.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Uçtan uca duman testleri: GERÇEK (bellek içi) veritabanıyla
/// sağlayıcılar, servisler ve çıktılar.
///
/// Sınananlar: Riverpod sağlayıcı zinciri, drift sorguları ve
/// akışları, acil durum mesajı, yakın modu özeti, PDF üretimi,
/// yerel besin tablosu ve yapay zeka bağlamının kişisel kimlik
/// İÇERMEDİĞİ.
///
/// Not: `testWidgets` değil `test` kullanılır. `testWidgets` sahte
/// zaman (FakeAsync) içinde çalışır ve drift'in akış tabanlı
/// sağlayıcıları (StreamProvider) gerçek zamanlayıcı beklediği için
/// orada asla tamamlanmaz.

AppDatabase makeDb() => AppDatabase(NativeDatabase.memory());

Future<void> seed(AppDatabase db) async {
  await db.into(db.profileRows).insertOnConflictUpdate(
        ProfileRowsCompanion.insert(
          id: const Value(1),
          name: 'Test Hasta',
          birthYear: const Value(1958),
          heightCm: const Value(172),
          weightKg: const Value(74.5),
          treatmentMode: TreatmentMode.hemodialysis.name,
          dialysisDays: const Value('1,3,5'),
          comorbidities: const Value('Diyabet, Hipertansiyon'),
          allergies: const Value('Penisilin'),
          doctorName: const Value('Dr. Test'),
          doctorPhone: const Value('02120000000'),
        ),
      );

  await db.writeJsonSetting(
    kClinicalSettingsKey,
    const ClinicalSettings(
      bodyWeightKg: 74.5,
      dryWeightKg: 71,
      treatmentMode: TreatmentMode.hemodialysis,
      overrides: {'fluid_ml': ClinicalOverride(value: 1000)},
    ).toJson(),
  );

  await db.writeJsonSetting(
    kPreferencesKey,
    const AppPreferences(onboardingCompleted: true).toJson(),
  );

  final now = DateTime.now();

  await db.into(db.fluidLogRows).insert(
        FluidLogRowsCompanion.insert(
          label: 'Çay',
          ml: 300,
          consumedAt: now.subtract(const Duration(hours: 3)),
        ),
      );

  await db.into(db.foodLogRows).insert(
        FoodLogRowsCompanion.insert(
          label: 'Mercimek çorbası',
          grams: 250,
          kcal: const Value(188),
          proteinG: const Value(10),
          sodiumMg: const Value(1050),
          potassiumMg: const Value(450),
          phosphorusMg: const Value(175),
          fluidMl: const Value(212),
          origin: const Value('local'),
          consumedAt: now.subtract(const Duration(hours: 2)),
        ),
      );

  await db.into(db.medicationRows).insert(
        MedicationRowsCompanion.insert(
          name: 'Renagel',
          dose: const Value('800 mg'),
          times: '08:00,20:00',
          stockCount: const Value(5),
        ),
      );
  // Böbrek güvenliği taramasını tetikleyen bir ilaç
  await db.into(db.medicationRows).insert(
        MedicationRowsCompanion.insert(
          name: 'Brufen 400',
          times: '12:00',
        ),
      );

  await db.into(db.vitalRows).insert(
        VitalRowsCompanion.insert(
          weightKg: const Value(73.8),
          systolic: const Value(152),
          diastolic: const Value(88),
          heartRate: const Value(78),
          urineMl: const Value(350),
          edemaLevel: const Value(1),
          measuredAt: now.subtract(const Duration(days: 2)),
        ),
      );
  await db.into(db.vitalRows).insert(
        VitalRowsCompanion.insert(
          weightKg: const Value(74.9),
          systolic: const Value(186),
          diastolic: const Value(96),
          measuredAt: now.subtract(const Duration(hours: 5)),
        ),
      );

  for (final e in [
    ('lab_hemoglobin', 'Hemoglobin', 10.4, 'g/dL', 30),
    ('lab_hemoglobin', 'Hemoglobin', 11.1, 'g/dL', 2),
    ('lab_potassium', 'Potasyum', 5.6, 'mEq/L', 2),
    ('lab_phosphate', 'Serum fosfat', 5.9, 'mg/dL', 2),
  ]) {
    await db.into(db.labResultRows).insert(
          LabResultRowsCompanion.insert(
            analyte: e.$1,
            analyteLabel: e.$2,
            value: e.$3,
            unit: e.$4,
            refMin: const Value(3.5),
            refMax: const Value(5.1),
            takenAt: now.subtract(Duration(days: e.$5)),
          ),
        );
  }

  await db.into(db.appointmentRows).insert(
        AppointmentRowsCompanion.insert(
          title: 'Diyaliz seansı',
          kind: 'dialysis',
          startsAt: now.add(const Duration(hours: 20)),
        ),
      );

  await db.into(db.emergencyContactRows).insert(
        EmergencyContactRowsCompanion.insert(
          name: 'Mehmet',
          phone: '05320000000',
          relation: const Value('Oğlu'),
        ),
      );

  await db.into(db.dietPlanRows).insert(
        DietPlanRowsCompanion.insert(
          title: 'Diyetisyen planı',
          content: 'Kahvaltı: ...\nÖğle: ...\nAkşam: ...',
        ),
      );

  await db.into(db.articleRows).insert(
        ArticleRowsCompanion.insert(
          title: 'Potasyumu azaltmanın pratik yolları',
          summary: const Value('Haşlama suyunu dökmek işe yarar.'),
          body: const Value('Uzun gövde metni...'),
          sourceName: 'KDOQI 2020',
          origin: 'builtin',
        ),
      );
}

/// NOT: `container.read(provider.future)` bir DİNLEYİCİ olmadan asla
/// tamamlanmaz — sağlayıcı "yükleniyor" durumunda kalır ve container
/// kapanınca hata verir. Uygulamada bu sorun yoktur (widget'lar
/// `watch` ile dinler); testte `container.listen(...)` ile dinleyici
/// açmak gerekir. Abonelikler container kapanınca serbest kalır.

void main() {
  late AppDatabase db;

  setUp(() async {
    db = makeDb();
    await seed(db);
  });

  tearDown(() async => db.close());

  test('veritabanı tohumlandı ve sorgular çalışıyor', () async {
    expect((await db.getProfile())?.name, 'Test Hasta');
    expect((await db.getActiveMedications()).length, 2);
    expect((await db.getEmergencyContacts()).length, 1);

    final settings = ClinicalSettings.fromJson(
      (await db.readJsonSetting(kClinicalSettingsKey))!,
    );
    expect(settings.dryWeightKg, 71);
    expect(settings.resolve('fluid_ml').value, 1000);
    // Diyaliz hastasında protein varsayılanı 1,0 g/kg
    expect(settings.dailyAbsolute('protein_g_per_kg'), closeTo(74.5, 1e-9));
  });

  test('yönlendirici tüm rotaları kurabiliyor', () async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    expect(router, isA<GoRouter>());
    // Rota ağacı hatasız kurulmuş olmalı.
    expect(router.configuration.routes, isNotEmpty);
  });

  test('sağlayıcılar gerçek veriyle çözülüyor', () async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    container.listen(profileProvider, (_, _) {});
    final profile = await container.read(profileProvider.future);
    expect(profile?.name, 'Test Hasta');

    container.listen(medicationsProvider, (_, _) {});
    final meds = await container.read(medicationsProvider.future);
    expect(meds.length, 2);

    container.listen(labResultsProvider, (_, _) {});
    final labs = await container.read(labResultsProvider.future);
    expect(labs.length, 4);

    container.listen(emergencyContactsProvider, (_, _) {});
    final contacts = await container.read(emergencyContactsProvider.future);
    expect(contacts.single.name, 'Mehmet');

    container.listen(appointmentsProvider, (_, _) {});
    final appointments = await container.read(appointmentsProvider.future);
    expect(appointments, isNotEmpty);

    container.listen(articlesProvider, (_, _) {});
    final articles = await container.read(articlesProvider.future);
    expect(articles, isNotEmpty);
  });

  test('acil durum mesajı kişisel veriyle kurulur', () async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final msg = await container
        .read(caregiverServiceProvider)
        .buildEmergencyMessage(
          latitude: 39.9208,
          longitude: 32.8541,
          placeName: 'Ankara',
        );

    expect(msg, startsWith('ACİL — Test Hasta'));
    expect(msg, contains('Hemodiyaliz'));
    expect(msg, contains('ALERJİ: Penisilin'));
    expect(msg, contains('Renagel'));
    expect(msg, contains('Dr. Test'));
    expect(msg, contains('openstreetmap.org'));
    // Telefon numarası doktor için var; acil kişinin numarası
    // mesaja KONMAZ (mesaj ona gidiyor).
    expect(msg.contains('05320000000'), isFalse);
  });

  test('yakın modu özeti üretilir', () async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final summary = await container
        .read(caregiverServiceProvider)
        .buildShareSummary(window: const Duration(days: 7));

    expect(summary, contains('Test Hasta'));
    expect(summary, contains('TANSİYON'));
    expect(summary, contains('KİLO'));
    expect(summary, contains('TAHLİL'));
    // 186/96 alarm eşiğinin üstünde -> uyarı bölümü
    expect(summary, contains('UYARILAR'));
    expect(summary, contains('tıbbi rapor değildir'));
  });

  test('doktor raporu PDF üretilir ve boş değil', () async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final bytes = await container
        .read(reportServiceProvider)
        .build(window: const Duration(days: 90));

    expect(bytes.length, greaterThan(20000));
    // PDF imzası
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('yerel besin tablosu yüklenir ve Türkçe arama çalışır',
      () async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final service = container.read(foodServiceProvider);
    final all = await service.loadLocalFoods();
    expect(all.length, greaterThanOrEqualTo(100));

    // Türkçe büyük I duyarlılığı
    final ispanak = await service.search('ISPANAK');
    expect(ispanak.first.name, contains('Ispanak'));

    final corba = await service.search('çorba');
    expect(corba, isNotEmpty);

    final disclaimer = await service.localDisclaimer();
    expect(disclaimer, contains('YAKLAŞIKTIR'));
  });

  test('yapay zeka bağlam özeti kişisel kimlik İÇERMEZ',
      () async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    container.listen(aiContextProvider, (_, _) {});
    final summary = await container.read(aiContextProvider.future);

    // Klinik bağlam var
    expect(summary.systemPrompt, contains('Hemodiyaliz'));
    expect(summary.systemPrompt, contains('Penisilin'));
    expect(summary.systemPrompt, contains('Renagel'));
    expect(summary.systemPrompt, contains('112'));

    // Kimlik bilgileri YOK
    expect(summary.systemPrompt.contains('Test Hasta'), isFalse);
    expect(summary.systemPrompt.contains('Dr. Test'), isFalse);
    expect(summary.systemPrompt.contains('02120000000'), isFalse);
    expect(summary.systemPrompt.contains('Mehmet'), isFalse);
    expect(summary.systemPrompt.contains('05320000000'), isFalse);

    // Kullanıcıya gösterilen özet de bunu söyler
    expect(summary.humanReadableTr, contains('GÖNDERİLMEZ'));
  });
}
