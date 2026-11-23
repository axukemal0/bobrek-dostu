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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
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

/// Şifreli veritabanını açar.
///
/// SQLCipher kullanılamazsa (örn. kütüphane yüklenemedi) uygulama
/// SESSİZCE şifresiz veritabanına DÜŞMEZ; hata fırlatır ve çağıran
/// taraf kullanıcıya durumu açıkça söyler.
Future<AppDatabase> openEncryptedDatabase({
  required DatabaseKeyStore keyStore,
  String fileName = 'bobrek_dostu.sqlite',
}) async {
  // SQLCipher kütüphanesini sqlite3 paketinin varsayılanı yap.
  await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
  open.overrideFor(OperatingSystem.android, openCipherOnAndroid);

  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, fileName));

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

  return AppDatabase(executor);
}
