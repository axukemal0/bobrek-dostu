import 'package:drift/drift.dart';

/// Tek profil olduğu için hiçbir tabloda kullanıcı kimliği yoktur.
/// Veritabanı SQLCipher ile şifrelenir (bkz. database.dart).

/// Basit anahtar-değer ayar deposu (JSON gövdeli).
class AppSettingsRows extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

/// Klinik değer değişiklik geçmişi.
class ClinicalChangeRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get valueKey => text()();
  TextColumn get oldText => text().nullable()();
  TextColumn get newText => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get changedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Kullanıcı profili (tek satır, id = 1).
class ProfileRows extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get birthYear => integer().nullable()();
  RealColumn get heightCm => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  TextColumn get treatmentMode => text()();

  /// Hemodiyaliz günleri: "1,3,5" (1 = Pazartesi).
  TextColumn get dialysisDays => text().nullable()();
  TextColumn get comorbidities => text().nullable()();
  TextColumn get allergies => text().nullable()();
  TextColumn get dislikedFoods => text().nullable()();
  TextColumn get doctorName => text().nullable()();
  TextColumn get doctorPhone => text().nullable()();
  TextColumn get hospital => text().nullable()();
  BoolColumn get expertMode => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class EmergencyContactRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get relation => text().nullable()();
  BoolColumn get autoSmsEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// --- BESİN ---
class FoodItemRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get category => text().nullable()();

  /// 100 g başına değerler. null = bilinmiyor (sıfır DEĞİL).
  RealColumn get kcal => real().nullable()();
  RealColumn get proteinG => real().nullable()();
  RealColumn get sodiumMg => real().nullable()();
  RealColumn get potassiumMg => real().nullable()();
  RealColumn get phosphorusMg => real().nullable()();
  RealColumn get fluidMl => real().nullable()();

  /// Tipik porsiyon gramı (arayüzde öneri).
  RealColumn get portionG => real().nullable()();
  TextColumn get portionLabel => text().nullable()();

  /// 'local' (yerel JSON), 'off' (Open Food Facts), 'user', 'ai'
  TextColumn get source => text().withDefault(const Constant('user'))();
  TextColumn get sourceNote => text().nullable()();
  TextColumn get barcode => text().nullable()();
  BoolColumn get isApproximate =>
      boolean().withDefault(const Constant(true))();
}

class FoodLogRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get foodItemId =>
      integer().references(FoodItemRows, #id).nullable()();

  /// Serbest metin kaydı (AI analizi veya elle giriş).
  TextColumn get label => text()();
  RealColumn get grams => real()();

  /// Hesaplanmış değerler kaydedilir (besin tanımı sonradan değişebilir).
  RealColumn get kcal => real().nullable()();
  RealColumn get proteinG => real().nullable()();
  RealColumn get sodiumMg => real().nullable()();
  RealColumn get potassiumMg => real().nullable()();
  RealColumn get phosphorusMg => real().nullable()();
  RealColumn get fluidMl => real().nullable()();

  TextColumn get mealType => text().nullable()();
  TextColumn get origin => text().withDefault(const Constant('manual'))();

  /// AI tahmini ise güven düzeyi: 'low' | 'medium' | 'high'
  TextColumn get confidence => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get consumedAt => dateTime()();
}

/// --- SIVI ---
class FluidLogRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text()();
  IntColumn get ml => integer()();
  TextColumn get kind => text().withDefault(const Constant('drink'))();
  DateTimeColumn get consumedAt => dateTime()();
}

/// --- LABORATUVAR ---
class LabResultRows extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Klinik tanım anahtarı ('lab_hemoglobin' vb.) veya serbest ad.
  TextColumn get analyte => text()();
  TextColumn get analyteLabel => text()();
  RealColumn get value => real()();
  TextColumn get unit => text()();

  /// Kullanıcının laboratuvarının referans aralığı.
  RealColumn get refMin => real().nullable()();
  RealColumn get refMax => real().nullable()();
  TextColumn get labName => text().nullable()();

  /// 'manual' | 'ocr'
  TextColumn get origin => text().withDefault(const Constant('manual'))();
  BoolColumn get confirmedByUser =>
      boolean().withDefault(const Constant(true))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get takenAt => dateTime()();
}

/// --- TAKVİM / RANDEVU ---
class AppointmentRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();

  /// 'dialysis' | 'checkup' | 'lab' | 'other'
  TextColumn get kind => text()();
  TextColumn get location => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get startsAt => dateTime()();
  IntColumn get durationMinutes => integer().nullable()();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get reminderMinutesBefore =>
      integer().withDefault(const Constant(120))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
}

/// --- İLAÇ ---
class MedicationRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get dose => text().nullable()();
  TextColumn get form => text().nullable()();

  /// Günlük saatler: "08:00,20:00"
  TextColumn get times => text()();

  /// Haftanın günleri ("1,2,3,4,5,6,7") veya null = her gün.
  TextColumn get weekdays => text().nullable()();
  IntColumn get stockCount => integer().nullable()();
  IntColumn get stockWarnAt => integer().withDefault(const Constant(7))();
  TextColumn get note => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// Risk taramasında eşleşen uyarı (varsa) — kullanıcı onayladıysa saklanır.
  TextColumn get riskAcknowledged => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class MedicationDoseRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get medicationId => integer().references(MedicationRows, #id)();
  DateTimeColumn get scheduledAt => dateTime()();
  DateTimeColumn get takenAt => dateTime().nullable()();

  /// 'pending' | 'taken' | 'skipped' | 'snoozed'
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get snoozedUntil => dateTime().nullable()();
}

/// --- KİLO & ÖDEM ---
class VitalRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get weightKg => real().nullable()();

  /// 0 = yok, 1 = hafif, 2 = orta, 3 = belirgin
  IntColumn get edemaLevel => integer().nullable()();
  IntColumn get urineMl => integer().nullable()();
  IntColumn get systolic => integer().nullable()();
  IntColumn get diastolic => integer().nullable()();
  IntColumn get heartRate => integer().nullable()();
  RealColumn get temperatureC => real().nullable()();
  IntColumn get spo2 => integer().nullable()();
  RealColumn get glucoseMgDl => real().nullable()();
  TextColumn get note => text().nullable()();

  /// Diyaliz seansı öncesi/sonrası işareti: 'pre' | 'post' | null
  TextColumn get dialysisPhase => text().nullable()();
  DateTimeColumn get measuredAt => dateTime()();
}

/// --- DİYET PLANI ---
class DietPlanRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Diyetisyenin verdiği KAĞIDIN kendisi — fotoğrafı ya da PDF'i.
  ///
  /// Uygulamanın kendi klasörüne kopyalanır (galeri/Dosyalar'daki
  /// özgün dosya silinse bile plan sağlam kalsın diye). Yol cihaz
  /// dışına çıkmaz; yalnız kullanıcı "yapay zekaya okut" derse o tek
  /// dosya gönderilir.
  TextColumn get attachmentPath => text().nullable()();

  /// 'image' | 'pdf'
  TextColumn get attachmentKind => text().nullable()();
}

class DietAdherenceRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId => integer().references(DietPlanRows, #id)();
  DateTimeColumn get day => dateTime()();

  /// 0-100 arası kullanıcı değerlendirmesi.
  IntColumn get percent => integer()();
  TextColumn get note => text().nullable()();
}

/// --- YAPAY ZEKA SOHBETİ ---
class ChatMessageRows extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 'user' | 'assistant' | 'system_note'
  TextColumn get role => text()();
  TextColumn get content => text()();

  /// Gönderilen görselin yerel yolu (varsa).
  TextColumn get imagePath => text().nullable()();
  TextColumn get model => text().nullable()();
  IntColumn get inputTokens => integer().nullable()();
  IntColumn get outputTokens => integer().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// --- SEYAHAT ---
class TravelPlanRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get destination => text()();
  DateTimeColumn get startsAt => dateTime()();
  IntColumn get days => integer()();
  TextColumn get planMarkdown => text()();
  TextColumn get options => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// --- OKUMA (önbellekli içerik) ---
class ArticleRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get summary => text().nullable()();
  TextColumn get body => text().nullable()();
  TextColumn get link => text().nullable()();
  TextColumn get sourceName => text()();

  /// 'rss' | 'builtin'
  TextColumn get origin => text()();
  DateTimeColumn get publishedAt => dateTime().nullable()();
  DateTimeColumn get fetchedAt =>
      dateTime().withDefault(currentDateAndTime)();
  BoolColumn get savedOffline =>
      boolean().withDefault(const Constant(false))();
}

/// HTTP önbelleği (OSM/Overpass/Open-Meteo politika gereği).
class HttpCacheRows extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get body => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {cacheKey};
}

/// Gönderilen bildirimlerin kaydı (günlük limiti uygulamak için).
class NotificationLogRows extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 'medication' | 'appointment' | 'smart' | 'summary'
  TextColumn get category => text()();
  TextColumn get title => text()();
  TextColumn get body => text().nullable()();
  DateTimeColumn get sentAt =>
      dateTime().withDefault(currentDateAndTime)();
}
