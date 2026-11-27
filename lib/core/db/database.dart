import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';

import 'tables.dart';

part 'database.g.dart';

/// Böbrek Dostu veritabanı.
///
/// ŞİFRELEME: Dosya SQLCipher ile şifrelenir. Anahtar cihazda
/// flutter_secure_storage içinde (Android Keystore destekli) tutulur.
/// Anahtar ilk açılışta rastgele üretilir; uygulama dışına çıkmaz.
@DriftDatabase(
  tables: [
    AppSettingsRows,
    ClinicalChangeRows,
    ProfileRows,
    EmergencyContactRows,
    FoodItemRows,
    FoodLogRows,
    FluidLogRows,
    LabResultRows,
    AppointmentRows,
    MedicationRows,
    MedicationDoseRows,
    VitalRows,
    DietPlanRows,
    DietMealRows,
    DietMealMarkRows,
    DietAvoidItemRows,
    DietSlipRows,
    DietAdherenceRows,
    ChatMessageRows,
    TravelPlanRows,
    ArticleRows,
    HttpCacheRows,
    NotificationLogRows,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        // Telefondaki veriler korunur: her sürüm yalnız EKLER.
        //  v2 — diyet planına kağıdın kendisi (fotoğraf/PDF) eklendi.
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(dietPlanRows, dietPlanRows.attachmentPath);
            await m.addColumn(dietPlanRows, dietPlanRows.attachmentKind);
          }
          //  v3 — öğün öğün uyum işaretlemesi ve kaçınma sayacı.
          if (from < 3) {
            await m.createTable(dietMealRows);
            await m.createTable(dietMealMarkRows);
            await m.createTable(dietAvoidItemRows);
            await m.createTable(dietSlipRows);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ---------------------------------------------------------------------
  // AYARLAR (anahtar-değer)
  // ---------------------------------------------------------------------
  Future<String?> readSetting(String key) async {
    final row = await (select(appSettingsRows)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<Map<String, dynamic>?> readJsonSetting(String key) async {
    final raw = await readSetting(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> writeSetting(String key, String value) =>
      into(appSettingsRows).insertOnConflictUpdate(
        AppSettingsRow(key: key, value: value, updatedAt: DateTime.now()),
      );

  Future<void> writeJsonSetting(String key, Map<String, dynamic> value) =>
      writeSetting(key, jsonEncode(value));

  Stream<String?> watchSetting(String key) =>
      (select(appSettingsRows)..where((t) => t.key.equals(key)))
          .watchSingleOrNull()
          .map((r) => r?.value);

  // ---------------------------------------------------------------------
  // GÜNLÜK SORGULAR
  // ---------------------------------------------------------------------
  /// Verilen günün (yerel saat) başı ve sonu.
  static (DateTime start, DateTime end) dayBounds(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    return (start, start.add(const Duration(days: 1)));
  }

  Stream<List<FoodLogRow>> watchFoodLogsForDay(DateTime day) {
    final (start, end) = dayBounds(day);
    return (select(foodLogRows)
          ..where((t) => t.consumedAt.isBiggerOrEqualValue(start))
          ..where((t) => t.consumedAt.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.consumedAt)]))
        .watch();
  }

  Stream<List<FluidLogRow>> watchFluidLogsForDay(DateTime day) {
    final (start, end) = dayBounds(day);
    return (select(fluidLogRows)
          ..where((t) => t.consumedAt.isBiggerOrEqualValue(start))
          ..where((t) => t.consumedAt.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.consumedAt)]))
        .watch();
  }

  Future<List<FoodLogRow>> foodLogsBetween(DateTime from, DateTime to) =>
      (select(foodLogRows)
            ..where((t) => t.consumedAt.isBetweenValues(from, to))
            ..orderBy([(t) => OrderingTerm.asc(t.consumedAt)]))
          .get();

  Future<List<FluidLogRow>> fluidLogsBetween(DateTime from, DateTime to) =>
      (select(fluidLogRows)
            ..where((t) => t.consumedAt.isBetweenValues(from, to))
            ..orderBy([(t) => OrderingTerm.asc(t.consumedAt)]))
          .get();

  Stream<ProfileRow?> watchProfile() =>
      (select(profileRows)..where((t) => t.id.equals(1)))
          .watchSingleOrNull();

  Future<ProfileRow?> getProfile() =>
      (select(profileRows)..where((t) => t.id.equals(1))).getSingleOrNull();

  Stream<List<EmergencyContactRow>> watchEmergencyContacts() =>
      (select(emergencyContactRows)
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<List<EmergencyContactRow>> getEmergencyContacts() =>
      (select(emergencyContactRows)
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  Stream<List<MedicationRow>> watchActiveMedications() =>
      (select(medicationRows)..where((t) => t.active.equals(true))).watch();

  Future<List<MedicationRow>> getActiveMedications() =>
      (select(medicationRows)..where((t) => t.active.equals(true))).get();

  Stream<List<AppointmentRow>> watchUpcomingAppointments({
    int limit = 20,
  }) =>
      (select(appointmentRows)
            ..where((t) => t.startsAt
                .isBiggerThanValue(DateTime.now().subtract(const Duration(hours: 6))))
            ..orderBy([(t) => OrderingTerm.asc(t.startsAt)])
            ..limit(limit))
          .watch();

  Stream<List<VitalRow>> watchRecentVitals({int limit = 60}) =>
      (select(vitalRows)
            ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)])
            ..limit(limit))
          .watch();

  Future<List<VitalRow>> vitalsBetween(DateTime from, DateTime to) =>
      (select(vitalRows)
            ..where((t) => t.measuredAt.isBetweenValues(from, to))
            ..orderBy([(t) => OrderingTerm.asc(t.measuredAt)]))
          .get();

  Stream<List<LabResultRow>> watchLabResults({String? analyte}) {
    final q = select(labResultRows)
      ..orderBy([(t) => OrderingTerm.desc(t.takenAt)]);
    if (analyte != null) q.where((t) => t.analyte.equals(analyte));
    return q.watch();
  }

  Future<List<LabResultRow>> labResultsBetween(
    DateTime from,
    DateTime to,
  ) =>
      (select(labResultRows)
            ..where((t) => t.takenAt.isBetweenValues(from, to))
            ..orderBy([(t) => OrderingTerm.asc(t.takenAt)]))
          .get();

  Future<List<MedicationDoseRow>> dosesBetween(
    DateTime from,
    DateTime to,
  ) =>
      (select(medicationDoseRows)
            ..where((t) => t.scheduledAt.isBetweenValues(from, to))
            ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
          .get();

  Stream<List<MedicationDoseRow>> watchDosesForDay(DateTime day) {
    final (start, end) = dayBounds(day);
    return (select(medicationDoseRows)
          ..where((t) => t.scheduledAt.isBiggerOrEqualValue(start))
          ..where((t) => t.scheduledAt.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
        .watch();
  }

  Stream<List<ChatMessageRow>> watchChat({int limit = 200}) =>
      (select(chatMessageRows)
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
            ..limit(limit))
          .watch();

  Stream<List<ArticleRow>> watchArticles() => (select(articleRows)
        ..orderBy([
          (t) => OrderingTerm.desc(t.publishedAt),
          (t) => OrderingTerm.desc(t.fetchedAt),
        ]))
      .watch();

  Stream<List<DietPlanRow>> watchDietPlans() =>
      (select(dietPlanRows)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  // -------------------------------------------------------------------
  // DİYET UYUMU — öğün öğün işaretleme ve kaçınma sayacı
  // -------------------------------------------------------------------

  /// Günün başlangıcı (saat bilgisi kayıtta gürültü yapmasın).
  static DateTime dayOf(DateTime at) => DateTime(at.year, at.month, at.day);

  Future<List<DietMealRow>> mealsOfPlan(int planId) =>
      (select(dietMealRows)
            ..where((t) => t.planId.equals(planId))
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();

  Future<List<DietMealMarkRow>> mealMarksForDay(
    List<int> mealIds,
    DateTime day,
  ) async {
    if (mealIds.isEmpty) return const [];
    return (select(dietMealMarkRows)
          ..where((t) => t.mealId.isIn(mealIds) & t.day.equals(dayOf(day))))
        .get();
  }

  /// Bir öğünün o günkü işaretini yazar; [status] null ise işareti kaldırır.
  Future<void> setMealMark({
    required int mealId,
    required DateTime day,
    required String? status,
  }) async {
    final d = dayOf(day);
    final existing = await (select(dietMealMarkRows)
          ..where((t) => t.mealId.equals(mealId) & t.day.equals(d)))
        .getSingleOrNull();

    if (status == null) {
      if (existing != null) {
        await (delete(dietMealMarkRows)
              ..where((t) => t.id.equals(existing.id)))
            .go();
      }
      return;
    }
    if (existing == null) {
      await into(dietMealMarkRows).insert(
        DietMealMarkRowsCompanion.insert(
          mealId: mealId,
          day: d,
          status: status,
        ),
      );
    } else {
      await (update(dietMealMarkRows)..where((t) => t.id.equals(existing.id)))
          .write(DietMealMarkRowsCompanion(status: Value(status)));
    }
  }

  /// Günün uyum yüzdesini [DietAdherenceRows] içine yazar.
  ///
  /// Yüzde artık kullanıcının tahmini değil, işaretlenen öğünlerden
  /// HESAPLANAN değerdir. Hiç işaret yoksa o günün satırı silinir —
  /// "işaretlemedim" ile "%0 uydum" aynı şey değildir.
  Future<void> writeAdherence({
    required int planId,
    required DateTime day,
    required int? percent,
  }) async {
    final d = dayOf(day);
    final existing = await (select(dietAdherenceRows)
          ..where((t) => t.planId.equals(planId) & t.day.equals(d)))
        .getSingleOrNull();

    if (percent == null) {
      if (existing != null) {
        await (delete(dietAdherenceRows)
              ..where((t) => t.id.equals(existing.id)))
            .go();
      }
      return;
    }
    if (existing == null) {
      await into(dietAdherenceRows).insert(
        DietAdherenceRowsCompanion.insert(
          planId: planId,
          day: d,
          percent: percent,
        ),
      );
    } else {
      await (update(dietAdherenceRows)..where((t) => t.id.equals(existing.id)))
          .write(DietAdherenceRowsCompanion(percent: Value(percent)));
    }
  }

  Future<List<DietAdherenceRow>> adherenceBetween(
    List<int> planIds,
    DateTime from,
    DateTime to,
  ) async {
    if (planIds.isEmpty) return const [];
    return (select(dietAdherenceRows)
          ..where(
            (t) =>
                t.planId.isIn(planIds) &
                t.day.isBiggerOrEqualValue(dayOf(from)) &
                t.day.isSmallerOrEqualValue(dayOf(to)),
          ))
        .get();
  }

  Future<List<DietMealMarkRow>> mealMarksBetween(
    int mealId,
    DateTime from,
    DateTime to,
  ) =>
      (select(dietMealMarkRows)
            ..where(
              (t) =>
                  t.mealId.equals(mealId) &
                  t.day.isBiggerOrEqualValue(dayOf(from)) &
                  t.day.isSmallerOrEqualValue(dayOf(to)),
            ))
          .get();

  Future<List<DietPlanRow>> activeDietPlans() =>
      (select(dietPlanRows)..where((t) => t.active.equals(true))).get();

  Future<List<DietAvoidItemRow>> activeAvoidItems() =>
      (select(dietAvoidItemRows)
            ..where((t) => t.active.equals(true))
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();

  Future<List<DietSlipRow>> slipsForDay(DateTime day) =>
      (select(dietSlipRows)..where((t) => t.day.equals(dayOf(day)))).get();

  /// "Bugün bunu yedim" işaretini açar/kapatır.
  Future<void> toggleSlip({required int itemId, required DateTime day}) async {
    final d = dayOf(day);
    final existing = await (select(dietSlipRows)
          ..where((t) => t.itemId.equals(itemId) & t.day.equals(d)))
        .getSingleOrNull();
    if (existing == null) {
      await into(dietSlipRows)
          .insert(DietSlipRowsCompanion.insert(itemId: itemId, day: d));
    } else {
      await (delete(dietSlipRows)..where((t) => t.id.equals(existing.id)))
          .go();
    }
  }

  /// Son [days] gündeki kaçınma işaretlerini madde adıyla döner.
  Future<List<({String label, DateTime day})>> recentSlips({
    int days = 30,
  }) async {
    final from = dayOf(DateTime.now()).subtract(Duration(days: days));
    final query = select(dietSlipRows).join([
      innerJoin(
        dietAvoidItemRows,
        dietAvoidItemRows.id.equalsExp(dietSlipRows.itemId),
      ),
    ])..where(dietSlipRows.day.isBiggerOrEqualValue(from));
    final rows = await query.get();
    return rows
        .map(
          (r) => (
            label: r.readTable(dietAvoidItemRows).label,
            day: r.readTable(dietSlipRows).day,
          ),
        )
        .toList(growable: false);
  }

  Stream<List<TravelPlanRow>> watchTravelPlans() =>
      (select(travelPlanRows)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Bugün gönderilen bildirim sayısı (kategori bazlı).
  Future<int> notificationCountToday(List<String> categories) async {
    final (start, end) = dayBounds(DateTime.now());
    final rows = await (select(notificationLogRows)
          ..where((t) => t.sentAt.isBiggerOrEqualValue(start))
          ..where((t) => t.sentAt.isSmallerThanValue(end))
          ..where((t) => t.category.isIn(categories)))
        .get();
    return rows.length;
  }

  Future<List<ClinicalChangeRow>> changesFor(String valueKey) =>
      (select(clinicalChangeRows)
            ..where((t) => t.valueKey.equals(valueKey))
            ..orderBy([(t) => OrderingTerm.desc(t.changedAt)]))
          .get();

  // ---------------------------------------------------------------------
  // HTTP ÖNBELLEĞİ
  // ---------------------------------------------------------------------
  Future<String?> cacheGet(String key, Duration maxAge) async {
    final row = await (select(httpCacheRows)
          ..where((t) => t.cacheKey.equals(key)))
        .getSingleOrNull();
    if (row == null) return null;
    if (DateTime.now().difference(row.fetchedAt) > maxAge) return null;
    return row.body;
  }

  /// Süresi geçmiş olsa da en son gövdeyi döner (çevrimdışı yedek).
  Future<String?> cacheGetStale(String key) async {
    final row = await (select(httpCacheRows)
          ..where((t) => t.cacheKey.equals(key)))
        .getSingleOrNull();
    return row?.body;
  }

  Future<void> cachePut(String key, String body) =>
      into(httpCacheRows).insertOnConflictUpdate(
        HttpCacheRow(
          cacheKey: key,
          body: body,
          fetchedAt: DateTime.now(),
        ),
      );

  Future<void> cacheClear() => delete(httpCacheRows).go();

  /// Tüm kişisel verileri siler (ayarlar ve klinik ayarlar dahil).
  Future<void> wipeAll() async {
    await transaction(() async {
      for (final t in allTables) {
        await delete(t).go();
      }
    });
  }
}

/// Veritabanı anahtarını üreten / okuyan yardımcı.
class DatabaseKeyStore {
  DatabaseKeyStore(this._storage);

  final FlutterSecureStorage _storage;
  static const String _keyName = 'db_encryption_key_v1';

  /// 32 baytlık rastgele anahtar (base64). Yoksa üretir.
  Future<String> getOrCreate() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null && existing.isNotEmpty) return existing;

    final rnd = Random.secure();
    final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    final key = base64UrlEncode(bytes);
    await _storage.write(key: _keyName, value: key);
    return key;
  }

  Future<void> deleteKey() => _storage.delete(key: _keyName);
}

/// Şifreli veritabanı açılamadı.
///
/// [unreadable] true ise dosya var ama ELDEKİ ANAHTARLA ÇÖZÜLEMİYOR
/// (SQLCipher böyle bir dosyayı "file is not a database" diye bildirir).
/// Bu, anahtar zincirindeki anahtarın kaybolduğu anlamına gelir —
/// yedekten geri yükleme, anahtar zincirinin sıfırlanması ya da farklı
/// bir imzayla yeniden kurulum sonrası olabilir. O veriye bir daha
/// ulaşılamaz; tek çıkış dosyayı kenara koyup sıfırdan başlamaktır.
class DatabaseOpenFailure implements Exception {
  const DatabaseOpenFailure(this.cause, {required this.unreadable});

  final Object cause;
  final bool unreadable;

  @override
  String toString() => 'DatabaseOpenFailure($cause)';
}

/// Şifreli veritabanının dosya yolu.
Future<File> databaseFile({String fileName = 'bobrek_dostu.sqlite'}) async {
  final dir = await getApplicationDocumentsDirectory();
  return File(p.join(dir.path, fileName));
}

/// Çözülemeyen veritabanını KENARA KOYAR (silmez) ve yolunu döner.
///
/// Silmiyoruz: dosya bugün okunamıyor ama bir gün anahtar bulunursa
/// (başka bir yedekten) işe yarayabilir. Kullanıcıya da "sildim"
/// demektense "kenara aldım" demek dürüst olanı.
Future<String> setAsideUnreadableDatabase({
  String fileName = 'bobrek_dostu.sqlite',
}) async {
  final file = await databaseFile(fileName: fileName);
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final target = '${file.path}.okunamayan-$stamp';
  if (file.existsSync()) await file.rename(target);
  // SQLite yan dosyaları da taşınmalı; kalırlarsa yeni veritabanı
  // onların üstüne denk gelip aynı hatayı tekrar üretebilir.
  for (final suffix in ['-wal', '-shm', '-journal']) {
    final side = File('${file.path}$suffix');
    if (side.existsSync()) await side.rename('$target$suffix');
  }
  return target;
}

/// Şifreli veritabanını açar.
///
/// SQLCipher kullanılamazsa (örn. kütüphane yüklenemedi) uygulama
/// SESSİZCE şifresiz veritabanına DÜŞMEZ; hata fırlatır ve çağıran
/// taraf kullanıcıya durumu açıkça söyler.
///
/// DİKKAT — BU FONKSİYON BAĞLANTIYI GERÇEKTEN AÇAR. Drift'in
/// çalıştırıcısı tembeldir: nesneyi kurmak dosyaya dokunmaz, ilk
/// sorguya kadar bekler. Eskiden burada yalnız nesne kuruluyordu, bu
/// yüzden "dosya çözülemiyor" hatası main()'in try bloğunun DIŞINDA,
/// ilk sorguda patlıyordu: yakalayan kimse olmadığı için uygulama
/// açılış ekranında sonsuza kadar asılı kalıyordu — ne hata, ne
/// çıkış. Artık küçük bir sorgu çalıştırılıp sonuç burada denetleniyor.
Future<AppDatabase> openEncryptedDatabase({
  required DatabaseKeyStore keyStore,
  String fileName = 'bobrek_dostu.sqlite',
}) async {
  // SQLCipher kütüphanesini sqlite3 paketinin varsayılanı yap.
  await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
  open.overrideFor(OperatingSystem.android, openCipherOnAndroid);

  final file = await databaseFile(fileName: fileName);
  final key = await keyStore.getOrCreate();

  final executor = NativeDatabase.createInBackground(
    file,
    isolateSetup: () async {
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
    },
    setup: (rawDb) {
      // Anahtarı tek tırnak kaçışıyla güvenli biçimde uygula.
      final escaped = key.replaceAll("'", "''");
      rawDb.execute("PRAGMA key = '$escaped'");

      // Şifrelemenin gerçekten etkin olduğunu doğrula:
      // yanlış/eksik anahtarla bu sorgu hata verir.
      final result = rawDb.select('PRAGMA cipher_version');
      if (result.isEmpty) {
        throw StateError(
          'SQLCipher etkin değil: veritabanı şifrelenemiyor. '
          'Uygulama şifresiz veri yazmayacak.',
        );
      }
      rawDb.execute('PRAGMA foreign_keys = ON');
    },
  );

  final db = AppDatabase(executor);
  try {
    // Göçleri de tetikleyen en küçük gerçek iş.
    await db.customSelect('SELECT 1').get();
    return db;
  } on Object catch (e) {
    await db.close().catchError((_) {});
    final text = e.toString().toLowerCase();
    throw DatabaseOpenFailure(
      e,
      unreadable: text.contains('file is not a database') ||
          text.contains('(code 26)'),
    );
  }
}
