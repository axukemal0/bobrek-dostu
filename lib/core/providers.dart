import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../clinical/definitions.dart';
import '../clinical/settings.dart';
import 'db/database.dart';
import 'services/ai_prompts.dart';
import 'services/ai_service.dart';
import 'services/api_client.dart';
import 'services/backup_service.dart';
import 'services/caregiver_service.dart';
import 'services/food_service.dart';
import 'services/document_intake.dart';
import 'services/health_service.dart';
import 'services/notification_service.dart';
import 'services/permission_service.dart';
import 'services/places_service.dart';
import 'services/reading_service.dart';
import 'services/report_service.dart';
import 'services/scanner_service.dart';
import 'services/secure_store.dart';
import 'services/smart_notifications.dart';
import 'services/sms_service.dart';
import 'services/speech_service.dart';
import 'services/update_service.dart';
import 'services/sync_repository.dart';
import 'services/weather_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';

/// Veritabanı — main() içinde overrideWith ile sağlanır.
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'databaseProvider main() içinde overrideWith ile sağlanmalı.',
  );
});

final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(db: ref.watch(databaseProvider));
  ref.onDispose(client.dispose);
  return client;
});

final aiServiceProvider = Provider<AiService>((ref) {
  final service = AiService(secureStore: ref.watch(secureStoreProvider));
  ref.onDispose(service.dispose);
  return service;
});

final aiPromptBuilderProvider =
    Provider<AiPromptBuilder>((ref) => const AiPromptBuilder());

final weatherServiceProvider =
    Provider<WeatherService>((ref) => WeatherService(ref.watch(apiClientProvider)));

final placesServiceProvider =
    Provider<PlacesService>((ref) => PlacesService(ref.watch(apiClientProvider)));

final foodServiceProvider =
    Provider<FoodService>((ref) => FoodService(ref.watch(apiClientProvider)));

final scannerServiceProvider = Provider<ScannerService>((ref) {
  final s = ScannerService();
  ref.onDispose(() => unawaited(s.dispose()));
  return s;
});

/// Kamera / galeri / PDF — üçü de tek kapıdan geçer.
final documentIntakeProvider = Provider<DocumentIntakeService>(
  (ref) => DocumentIntakeService(ref.watch(scannerServiceProvider)),
);

final healthServiceProvider = Provider<HealthService>((ref) => HealthService());

/// Yeni sürüm denetimi (GitHub Releases).
final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

/// Açılışta bir kez denetlenir; hata yutulur (güncelleme denetimi
/// uygulamanın çalışmasını engellememeli).
final availableUpdateProvider = FutureProvider<AvailableUpdate?>((ref) async {
  try {
    return await ref.read(updateServiceProvider).check();
  } on Object {
    return null;
  }
});

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(ref.watch(databaseProvider)),
);

final smartNotificationsProvider = Provider<SmartNotifications>(
  (ref) => SmartNotifications(
    db: ref.watch(databaseProvider),
    notifications: ref.watch(notificationServiceProvider),
    weather: ref.watch(weatherServiceProvider),
  ),
);

final permissionServiceProvider =
    Provider<PermissionService>((ref) => const PermissionService());

final smsServiceProvider = Provider<SmsService>((ref) => const SmsService());

final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());
final sttServiceProvider = Provider<SttService>((ref) => SttService());

final reportServiceProvider =
    Provider<ReportService>((ref) => ReportService(ref.watch(databaseProvider)));

final backupServiceProvider =
    Provider<BackupService>((ref) => BackupService(ref.watch(databaseProvider)));

final caregiverServiceProvider = Provider<CaregiverService>(
  (ref) => CaregiverService(ref.watch(databaseProvider)),
);

final readingServiceProvider = Provider<ReadingService>(
  (ref) => ReadingService(
    api: ref.watch(apiClientProvider),
    db: ref.watch(databaseProvider),
  ),
);

/// v1'de senkronizasyon yoktur; arayüz ileride değiştirilebilir.
final syncRepositoryProvider =
    Provider<SyncRepository>((ref) => const NoOpSyncRepository());

// ---------------------------------------------------------------------------
// UYGULAMA AYARLARI
// ---------------------------------------------------------------------------
class AppPreferences {
  const AppPreferences({
    this.loaded = false,
    this.textScaleStep = TextScaleStep.normal,
    this.highContrast = false,
    this.reduceMotion = false,
    this.darkMode = false,
    this.followSystemDark = true,
    this.lockEnabled = false,
    this.useBiometrics = true,
    this.onboardingCompleted = false,
    this.aiShareLabs = true,
    this.aiShareMedications = true,
    this.aiShareClinicalSettings = true,
    this.autoSmsOnAlarm = false,
    this.waterReminders = false,
    this.smartNotifications = true,
    this.dailySummary = true,
    this.lowStepsNotification = false,
    this.aiModel,
  });

  /// Ayarlar diskten OKUNDU mu?
  ///
  /// Önemli: uygulama kilidi bu bayrak true olmadan karar vermez.
  /// Aksi hâlde soğuk açılışta varsayılan (kilit kapalı) değerle
  /// bir an uygulama içeriği görünürdü.
  final bool loaded;

  final TextScaleStep textScaleStep;
  final bool highContrast;
  final bool reduceMotion;
  final bool darkMode;
  final bool followSystemDark;
  final bool lockEnabled;
  final bool useBiometrics;
  final bool onboardingCompleted;

  /// Yapay zekaya hangi verilerin gönderileceği.
  final bool aiShareLabs;
  final bool aiShareMedications;
  final bool aiShareClinicalSettings;

  /// Alarm eşiği aşımında acil kişilere OTOMATİK SMS.
  /// VARSAYILAN: KAPALI.
  final bool autoSmsOnAlarm;

  /// "Su iç" hatırlatmaları. VARSAYILAN: KAPALI (gereklilik).
  final bool waterReminders;

  final bool smartNotifications;
  final bool dailySummary;
  final bool lowStepsNotification;

  final String? aiModel;

  AppPreferences copyWith({
    bool? loaded,
    TextScaleStep? textScaleStep,
    bool? highContrast,
    bool? reduceMotion,
    bool? darkMode,
    bool? followSystemDark,
    bool? lockEnabled,
    bool? useBiometrics,
    bool? onboardingCompleted,
    bool? aiShareLabs,
    bool? aiShareMedications,
    bool? aiShareClinicalSettings,
    bool? autoSmsOnAlarm,
    bool? waterReminders,
    bool? smartNotifications,
    bool? dailySummary,
    bool? lowStepsNotification,
    String? aiModel,
  }) =>
      AppPreferences(
        loaded: loaded ?? this.loaded,
        textScaleStep: textScaleStep ?? this.textScaleStep,
        highContrast: highContrast ?? this.highContrast,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        darkMode: darkMode ?? this.darkMode,
        followSystemDark: followSystemDark ?? this.followSystemDark,
        lockEnabled: lockEnabled ?? this.lockEnabled,
        useBiometrics: useBiometrics ?? this.useBiometrics,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
        aiShareLabs: aiShareLabs ?? this.aiShareLabs,
        aiShareMedications: aiShareMedications ?? this.aiShareMedications,
        aiShareClinicalSettings:
            aiShareClinicalSettings ?? this.aiShareClinicalSettings,
        autoSmsOnAlarm: autoSmsOnAlarm ?? this.autoSmsOnAlarm,
        waterReminders: waterReminders ?? this.waterReminders,
        smartNotifications: smartNotifications ?? this.smartNotifications,
        dailySummary: dailySummary ?? this.dailySummary,
        lowStepsNotification:
            lowStepsNotification ?? this.lowStepsNotification,
        aiModel: aiModel ?? this.aiModel,
      );

  Map<String, dynamic> toJson() => {
        'textScaleStep': textScaleStep.name,
        'highContrast': highContrast,
        'reduceMotion': reduceMotion,
        'darkMode': darkMode,
        'followSystemDark': followSystemDark,
        'lockEnabled': lockEnabled,
        'useBiometrics': useBiometrics,
        'onboardingCompleted': onboardingCompleted,
        'aiShareLabs': aiShareLabs,
        'aiShareMedications': aiShareMedications,
        'aiShareClinicalSettings': aiShareClinicalSettings,
        'autoSmsOnAlarm': autoSmsOnAlarm,
        'waterReminders': waterReminders,
        'smartNotifications': smartNotifications,
        'dailySummary': dailySummary,
        'lowStepsNotification': lowStepsNotification,
        'aiModel': aiModel,
      };

  static AppPreferences fromJson(Map<String, dynamic>? j) {
    if (j == null) return const AppPreferences(loaded: true);
    return AppPreferences(
      loaded: true,
      textScaleStep: TextScaleStep.values.firstWhere(
        (s) => s.name == j['textScaleStep'],
        orElse: () => TextScaleStep.normal,
      ),
      highContrast: j['highContrast'] as bool? ?? false,
      reduceMotion: j['reduceMotion'] as bool? ?? false,
      darkMode: j['darkMode'] as bool? ?? false,
      followSystemDark: j['followSystemDark'] as bool? ?? true,
      lockEnabled: j['lockEnabled'] as bool? ?? false,
      useBiometrics: j['useBiometrics'] as bool? ?? true,
      onboardingCompleted: j['onboardingCompleted'] as bool? ?? false,
      aiShareLabs: j['aiShareLabs'] as bool? ?? true,
      aiShareMedications: j['aiShareMedications'] as bool? ?? true,
      aiShareClinicalSettings:
          j['aiShareClinicalSettings'] as bool? ?? true,
      autoSmsOnAlarm: j['autoSmsOnAlarm'] as bool? ?? false,
      waterReminders: j['waterReminders'] as bool? ?? false,
      smartNotifications: j['smartNotifications'] as bool? ?? true,
      dailySummary: j['dailySummary'] as bool? ?? true,
      lowStepsNotification: j['lowStepsNotification'] as bool? ?? false,
      aiModel: j['aiModel'] as String?,
    );
  }
}

const String kPreferencesKey = 'app_preferences';

class PreferencesNotifier extends Notifier<AppPreferences> {
  @override
  AppPreferences build() {
    final db = ref.watch(databaseProvider);
    // İlk değer eşzamanlı okunamaz; yüklenince state güncellenir.
    unawaited(_load(db));
    return const AppPreferences();
  }

  Future<void> _load(AppDatabase db) async {
    final json = await db.readJsonSetting(kPreferencesKey);
    // json null olsa bile "okundu" işaretlenir: kilit kararı
    // bekletilmesin, ama okuma öncesi de verilmesin.
    state = AppPreferences.fromJson(json);
  }

  Future<void> update(
    AppPreferences Function(AppPreferences) transform,
  ) async {
    final next = transform(state);
    state = next;
    await ref
        .read(databaseProvider)
        .writeJsonSetting(kPreferencesKey, next.toJson());
  }
}

final preferencesProvider =
    NotifierProvider<PreferencesNotifier, AppPreferences>(
  PreferencesNotifier.new,
);

/// Sistemin açık/koyu teması — DİNLENİR, tek seferlik okunmaz.
///
/// Önceki sürümde palet `PlatformDispatcher.instance.platformBrightness`
/// değerini doğrudan okuyordu. Bu bir `Provider` gövdesinde sabit bir
/// okumadır: Riverpod'un o değeri yeniden hesaplaması için bir sebebi
/// yoktur, dolayısıyla telefon karanlıktan aydınlığa geçtiğinde uygulama
/// kapatılıp açılana kadar eski paleti kullanıyordu. (Kök widget'taki
/// `didChangePlatformBrightness` yeniden çizim tetikliyordu ama provider
/// önbellekten aynı paleti döndürdüğü için bir şey değişmiyordu.)
///
/// Burada değişim `WidgetsBindingObserver` ile dinlenir ve duruma yazılır;
/// palet de bunu izlediği için tema anında döner.
class SystemBrightnessNotifier extends Notifier<Brightness>
    with WidgetsBindingObserver {
  @override
  Brightness build() {
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);
    ref.onDispose(() => binding.removeObserver(this));
    return binding.platformDispatcher.platformBrightness;
  }

  @override
  void didChangePlatformBrightness() {
    state = WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }
}

final systemBrightnessProvider =
    NotifierProvider<SystemBrightnessNotifier, Brightness>(
  SystemBrightnessNotifier.new,
);

/// Renk paleti — ayarlara ve sistem temasına göre.
final paletteProvider = Provider<AppPalette>((ref) {
  final prefs = ref.watch(preferencesProvider);
  final systemDark = ref.watch(systemBrightnessProvider) == Brightness.dark;
  final dark = prefs.followSystemDark ? systemDark : prefs.darkMode;
  return AppPalette.resolve(dark: dark, highContrast: prefs.highContrast);
});

// ---------------------------------------------------------------------------
// KLİNİK AYARLAR
// ---------------------------------------------------------------------------
const String kClinicalSettingsKey = 'clinical_settings';

class ClinicalSettingsNotifier extends Notifier<ClinicalSettings> {
  @override
  ClinicalSettings build() {
    final db = ref.watch(databaseProvider);
    unawaited(_load(db));
    return const ClinicalSettings();
  }

  Future<void> _load(AppDatabase db) async {
    final json = await db.readJsonSetting(kClinicalSettingsKey);
    if (json != null) state = ClinicalSettings.fromJson(json);
  }

  Future<void> _persist(ClinicalSettings next) async {
    state = next;
    await ref
        .read(databaseProvider)
        .writeJsonSetting(kClinicalSettingsKey, next.toJson());
  }

  /// Bir değeri günceller ve değişikliği geçmişe yazar.
  Future<void> setOverride(
    String key,
    ClinicalOverride override, {
    String? noteTr,
  }) async {
    final def = definitionByKey(key);
    if (def == null) return;

    final before = state.resolve(key).formatted();

    final next = state.copyWith(
      overrides: {
        ...state.overrides,
        key: ClinicalOverride(
          value: override.value,
          min: override.min,
          max: override.max,
          isCleared: override.isCleared,
          noteTr: noteTr ?? override.noteTr,
          updatedAt: DateTime.now(),
        ),
      },
    );
    await _persist(next);

    final after = next.resolve(key).formatted();
    if (before != after) {
      await ref.read(databaseProvider).into(
            ref.read(databaseProvider).clinicalChangeRows,
          ).insert(
            ClinicalChangeRowsCompanion.insert(
              valueKey: key,
              oldText: Value(before),
              newText: Value(after),
              note: Value(noteTr),
            ),
          );
    }
  }

  /// Varsayılana döner (geçmişe kaydedilir).
  Future<void> resetToDefault(String key) async {
    final before = state.resolve(key).formatted();
    final overrides = {...state.overrides}..remove(key);
    final next = state.copyWith(overrides: overrides);
    await _persist(next);
    final after = next.resolve(key).formatted();

    final db = ref.read(databaseProvider);
    await db.into(db.clinicalChangeRows).insert(
          ClinicalChangeRowsCompanion.insert(
            valueKey: key,
            oldText: Value(before),
            newText: Value(after),
            note: const Value('Varsayılana döndürüldü'),
          ),
        );
  }

  Future<void> setBodyWeight(double? kg) =>
      _persist(ClinicalSettings(
        overrides: state.overrides,
        bodyWeightKg: kg,
        dryWeightKg: state.dryWeightKg,
        hasResidualUrine: state.hasResidualUrine,
        treatmentMode: state.treatmentMode,
      ));

  Future<void> setDryWeight(double? kg) => _persist(ClinicalSettings(
        overrides: state.overrides,
        bodyWeightKg: state.bodyWeightKg,
        dryWeightKg: kg,
        hasResidualUrine: state.hasResidualUrine,
        treatmentMode: state.treatmentMode,
      ));

  Future<void> setTreatmentMode(TreatmentMode mode) =>
      _persist(state.copyWith(treatmentMode: mode));

  Future<void> setResidualUrine(bool has) =>
      _persist(state.copyWith(hasResidualUrine: has));
}

final clinicalSettingsProvider =
    NotifierProvider<ClinicalSettingsNotifier, ClinicalSettings>(
  ClinicalSettingsNotifier.new,
);

/// Bir klinik değerin değişiklik geçmişi.
final clinicalHistoryProvider =
    FutureProvider.family<List<ClinicalChangeRow>, String>(
  (ref, key) => ref.watch(databaseProvider).changesFor(key),
);

// ---------------------------------------------------------------------------
// VERİ AKIŞLARI
// ---------------------------------------------------------------------------
final profileProvider = StreamProvider<ProfileRow?>(
  (ref) => ref.watch(databaseProvider).watchProfile(),
);

final emergencyContactsProvider = StreamProvider<List<EmergencyContactRow>>(
  (ref) => ref.watch(databaseProvider).watchEmergencyContacts(),
);

/// Seçili gün (ana sayfa ve kayıt ekranları bunu kullanır).
class SelectedDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void set(DateTime day) => state = DateTime(day.year, day.month, day.day);
  void today() => set(DateTime.now());
  void shift(int days) => state = state.add(Duration(days: days));
}

final selectedDayProvider =
    NotifierProvider<SelectedDayNotifier, DateTime>(SelectedDayNotifier.new);

final foodLogsForDayProvider = StreamProvider<List<FoodLogRow>>((ref) {
  final day = ref.watch(selectedDayProvider);
  return ref.watch(databaseProvider).watchFoodLogsForDay(day);
});

final fluidLogsForDayProvider = StreamProvider<List<FluidLogRow>>((ref) {
  final day = ref.watch(selectedDayProvider);
  return ref.watch(databaseProvider).watchFluidLogsForDay(day);
});

final dosesForDayProvider = StreamProvider<List<MedicationDoseRow>>((ref) {
  final day = ref.watch(selectedDayProvider);
  return ref.watch(databaseProvider).watchDosesForDay(day);
});

final medicationsProvider = StreamProvider<List<MedicationRow>>(
  (ref) => ref.watch(databaseProvider).watchActiveMedications(),
);

final appointmentsProvider = StreamProvider<List<AppointmentRow>>(
  (ref) => ref.watch(databaseProvider).watchUpcomingAppointments(),
);

final vitalsProvider = StreamProvider<List<VitalRow>>(
  (ref) => ref.watch(databaseProvider).watchRecentVitals(),
);

final labResultsProvider = StreamProvider<List<LabResultRow>>(
  (ref) => ref.watch(databaseProvider).watchLabResults(),
);

final chatMessagesProvider = StreamProvider<List<ChatMessageRow>>(
  (ref) => ref.watch(databaseProvider).watchChat(),
);

final articlesProvider = StreamProvider<List<ArticleRow>>(
  (ref) => ref.watch(databaseProvider).watchArticles(),
);

final dietPlansProvider = StreamProvider<List<DietPlanRow>>(
  (ref) => ref.watch(databaseProvider).watchDietPlans(),
);

final travelPlansProvider = StreamProvider<List<TravelPlanRow>>(
  (ref) => ref.watch(databaseProvider).watchTravelPlans(),
);

// ---------------------------------------------------------------------------
// YAPAY ZEKA BAĞLANTI DURUMU
// ---------------------------------------------------------------------------
class AiConnectionNotifier extends AsyncNotifier<AiConnectionState> {
  @override
  Future<AiConnectionState> build() async {
    final has = await ref.watch(secureStoreProvider).hasApiKey();
    if (!has) return AiConnectionState.noKey;
    final verified = await ref
        .watch(databaseProvider)
        .readSetting('ai_connection_verified');
    return verified == 'true'
        ? AiConnectionState.ok
        : AiConnectionState.untested;
  }

  /// Anahtarı kaydeder ve bağlantıyı test eder.
  Future<AiTestResult> saveAndTest(String key, {String? model}) async {
    final store = ref.read(secureStoreProvider);
    final ai = ref.read(aiServiceProvider);
    final db = ref.read(databaseProvider);

    final result = await ai.testConnection(
      overrideKey: key,
      modelToCheck: model,
    );
    if (result.ok) {
      await store.writeApiKey(key);
      await db.writeSetting('ai_connection_verified', 'true');
      state = const AsyncValue.data(AiConnectionState.ok);
    } else {
      state = const AsyncValue.data(AiConnectionState.failed);
    }
    return result;
  }

  /// Kayıtlı anahtarla yeniden test.
  Future<AiTestResult> retest({String? model}) async {
    final result = await ref
        .read(aiServiceProvider)
        .testConnection(modelToCheck: model);
    await ref
        .read(databaseProvider)
        .writeSetting('ai_connection_verified', result.ok ? 'true' : 'false');
    state = AsyncValue.data(
      result.ok ? AiConnectionState.ok : AiConnectionState.failed,
    );
    return result;
  }

  /// Anahtar geçerli ama MESAJ gönderilemiyor (kredi yok, kota dolu,
  /// model hakkı yok). Anahtarı silmeden durumu "başarısız"a çeker;
  /// böylece ekranlar yapay zeka düğmelerini "çalışıyor" gibi
  /// göstermez.
  Future<void> markFailed() async {
    await ref
        .read(databaseProvider)
        .writeSetting('ai_connection_verified', 'false');
    state = const AsyncValue.data(AiConnectionState.failed);
  }

  Future<void> deleteKey() async {
    await ref.read(secureStoreProvider).deleteApiKey();
    await ref.read(databaseProvider).writeSetting(
          'ai_connection_verified',
          'false',
        );
    state = const AsyncValue.data(AiConnectionState.noKey);
  }
}

final aiConnectionProvider =
    AsyncNotifierProvider<AiConnectionNotifier, AiConnectionState>(
  AiConnectionNotifier.new,
);

/// Yapay zekaya gönderilecek bağlam özeti.
final aiContextProvider = FutureProvider<AiContextSummary>((ref) async {
  final db = ref.watch(databaseProvider);
  final prefs = ref.watch(preferencesProvider);
  final settings = ref.watch(clinicalSettingsProvider);
  final profile = await db.getProfile();

  final labs = prefs.aiShareLabs
      ? await (db.select(db.labResultRows)
            ..orderBy([(t) => OrderingTerm.desc(t.takenAt)])
            ..limit(20))
          .get()
      : <LabResultRow>[];

  final meds = prefs.aiShareMedications
      ? await db.getActiveMedications()
      : <MedicationRow>[];

  return ref.watch(aiPromptBuilderProvider).buildChatContext(
        profile: profile,
        settings: settings,
        recentLabs: labs,
        medications: meds,
        includeLabs: prefs.aiShareLabs,
        includeMedications: prefs.aiShareMedications,
        includeClinicalSettings: prefs.aiShareClinicalSettings,
      );
});

// ---------------------------------------------------------------------------
// HAVA DURUMU & KONUM
// ---------------------------------------------------------------------------
class LastLocation {
  const LastLocation({
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.at,
  });

  final double latitude;
  final double longitude;
  final String? placeName;
  final DateTime? at;

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lon': longitude,
        'place': placeName,
        'at': at?.toIso8601String(),
      };

  static LastLocation? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    final lat = (j['lat'] as num?)?.toDouble();
    final lon = (j['lon'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;
    return LastLocation(
      latitude: lat,
      longitude: lon,
      placeName: j['place'] as String?,
      at: j['at'] == null ? null : DateTime.tryParse(j['at'] as String),
    );
  }
}

const String kLastLocationKey = 'last_location';

class LocationNotifier extends Notifier<LastLocation?> {
  @override
  LastLocation? build() {
    unawaited(_load());
    return null;
  }

  Future<void> _load() async {
    final json =
        await ref.read(databaseProvider).readJsonSetting(kLastLocationKey);
    final loc = LastLocation.fromJson(json);
    if (loc != null) state = loc;
  }

  Future<void> save(LastLocation loc) async {
    state = loc;
    await ref
        .read(databaseProvider)
        .writeJsonSetting(kLastLocationKey, loc.toJson());
  }
}

final locationProvider =
    NotifierProvider<LocationNotifier, LastLocation?>(LocationNotifier.new);

final weatherProvider = FutureProvider.autoDispose((ref) async {
  final loc = ref.watch(locationProvider);
  if (loc == null) return null;
  return ref.watch(weatherServiceProvider).fetch(
        latitude: loc.latitude,
        longitude: loc.longitude,
      );
});

/// Bugünün adım sayısı. İzin yoksa veya Health Connect yoksa null.
///
/// Ana sayfada gösterilir; hata fırlatmaz, sessizce null döner.
final todayStepsProvider = FutureProvider.autoDispose<int?>((ref) async {
  final service = ref.watch(healthServiceProvider);
  try {
    if (!await service.hasPermissions()) return null;
    final now = DateTime.now();
    final snap = await service.fetch(
      from: DateTime(now.year, now.month, now.day),
      to: now,
    );
    return snap.steps;
  } on Object {
    return null;
  }
});

final quietHoursProvider = FutureProvider<QuietHours>(
  (ref) => ref.watch(notificationServiceProvider).readQuietHours(),
);

/// JSON kodlayıcı — paylaşım metinlerinde kullanılır.
const jsonPretty = JsonEncoder.withIndent('  ');
