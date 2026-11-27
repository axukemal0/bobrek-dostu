import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as d;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';
import '../db/database.dart';
import '../i18n/i18n.dart';

/// JSON yedek alma / geri yükleme.
///
/// GÜVENLİK NOTU: Dışa aktarılan JSON ŞİFRESİZDİR. Bu yüzden
/// kullanıcıya her seferinde açıkça söylenir ve dosyanın güvenli
/// bir yere konması önerilir. API ANAHTARI ve PIN yedeğe DAHİL
/// EDİLMEZ (bunlar yalnızca cihazın güvenli deposunda kalır).
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  static const int formatVersion = 1;

  static const String warningTr =
      'Yedek dosyası ŞİFRELENMEZ: içinde sağlık bilgilerin düz metin '
      'olarak bulunur. Dosyayı güvenli bir yere kaydet ve paylaşırken '
      'dikkatli ol. Yapay zeka anahtarın ve PIN\'in yedeğe DAHİL '
      'EDİLMEZ.';

  /// Tüm veriyi JSON'a çevirir.
  Future<Map<String, dynamic>> exportToJson() async {
    Future<List<Map<String, dynamic>>> dump(
      d.TableInfo<d.Table, dynamic> table,
    ) async {
      final rows = await _db.select(table).get();
      return rows
          .map((r) => (r as d.DataClass).toJson())
          .cast<Map<String, dynamic>>()
          .toList();
    }

    return {
      'format': 'bobrek_dostu_backup',
      'formatVersion': formatVersion,
      'appVersion': AppConfig.appVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'warning': warningTr,
      'tables': {
        'appSettings': await dump(_db.appSettingsRows),
        'clinicalChanges': await dump(_db.clinicalChangeRows),
        'profile': await dump(_db.profileRows),
        'emergencyContacts': await dump(_db.emergencyContactRows),
        'foodItems': await dump(_db.foodItemRows),
        'foodLogs': await dump(_db.foodLogRows),
        'fluidLogs': await dump(_db.fluidLogRows),
        'labResults': await dump(_db.labResultRows),
        'appointments': await dump(_db.appointmentRows),
        'medications': await dump(_db.medicationRows),
        'medicationDoses': await dump(_db.medicationDoseRows),
        'vitals': await dump(_db.vitalRows),
        'dietPlans': await dump(_db.dietPlanRows),
        'dietAdherence': await dump(_db.dietAdherenceRows),
        'chatMessages': await dump(_db.chatMessageRows),
        'travelPlans': await dump(_db.travelPlanRows),
        'articles': await dump(_db.articleRows),
      },
    };
  }

  /// Yedeği dosyaya yazar ve paylaşım penceresini açar.
  Future<File> exportAndShare() async {
    final json = await exportToJson();
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File('${dir.path}/bobrek-dostu-yedek-$stamp.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(json),
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        title: 'Böbrek Dostu yedeği',
        text: warningTr,
      ),
    );
    return file;
  }

  /// Kullanıcıdan dosya seçmesini ister ve içe aktarır.
  ///
  /// [replaceExisting] true ise mevcut veri SİLİNİR.
  Future<ImportReport> importFromPicker({
    required bool replaceExisting,
  }) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: false,
    );
    final path = picked?.files.singleOrNull?.path;
    if (path == null) {
      return const ImportReport(
        ok: false,
        messageTr: 'Dosya seçilmedi.',
      );
    }
    return importFromFile(File(path), replaceExisting: replaceExisting);
  }

  Future<ImportReport> importFromFile(
    File file, {
    required bool replaceExisting,
  }) async {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } on Object {
      return const ImportReport(
        ok: false,
        messageTr: 'Dosya okunamadı. Bu bir Böbrek Dostu yedeği '
            '(JSON) olmalı.',
      );
    }

    if (json['format'] != 'bobrek_dostu_backup') {
      return const ImportReport(
        ok: false,
        messageTr: 'Bu dosya bir Böbrek Dostu yedeği değil.',
      );
    }

    final version = json['formatVersion'];
    if (version is! int || version > formatVersion) {
      return ImportReport(
        ok: false,
        messageTr: tf(
                     'Yedek biçimi bu sürümden yeni ({0}). Uygulamayı '
                     'güncellemen gerekiyor.',
                     [version],
                   ),
      );
    }

    final tables = json['tables'];
    if (tables is! Map) {
      return const ImportReport(
        ok: false,
        messageTr: 'Yedek içeriği eksik veya bozuk.',
      );
    }

    final counts = <String, int>{};
    final skipped = <String>[];

    Future<void> restore(
      String key,
      d.TableInfo<d.Table, dynamic> table,
    ) async {
      final list = tables[key];
      if (list is! List) return;
      var n = 0;
      for (final item in list) {
        if (item is! Map) continue;
        try {
          await _db
              .into(table)
              .insertOnConflictUpdate(
                d.RawValuesInsertable(
                  _toSqlValues(Map<String, dynamic>.from(item)),
                ),
              );
          n++;
        } on Object {
          // Tek bir bozuk satır tüm geri yüklemeyi durdurmasın.
          skipped.add(key);
        }
      }
      counts[key] = n;
    }

    try {
      if (replaceExisting) await _db.wipeAll();

      await restore('appSettings', _db.appSettingsRows);
      await restore('profile', _db.profileRows);
      await restore('emergencyContacts', _db.emergencyContactRows);
      await restore('foodItems', _db.foodItemRows);
      await restore('foodLogs', _db.foodLogRows);
      await restore('fluidLogs', _db.fluidLogRows);
      await restore('labResults', _db.labResultRows);
      await restore('appointments', _db.appointmentRows);
      await restore('medications', _db.medicationRows);
      await restore('medicationDoses', _db.medicationDoseRows);
      await restore('vitals', _db.vitalRows);
      await restore('dietPlans', _db.dietPlanRows);
      await restore('dietAdherence', _db.dietAdherenceRows);
      await restore('chatMessages', _db.chatMessageRows);
      await restore('travelPlans', _db.travelPlanRows);
      await restore('articles', _db.articleRows);
      await restore('clinicalChanges', _db.clinicalChangeRows);
    } on Object catch (e) {
      return ImportReport(
        ok: false,
        messageTr: tf('Geri yükleme yarıda kaldı: {0}', [e]),
        restoredCounts: counts,
      );
    }

    final total = counts.values.fold<int>(0, (a, b) => a + b);
    return ImportReport(
      ok: true,
      messageTr: tf(
                   '{0} kayıt geri yüklendi.{1}',
                   [
                     total,
                     skipped.isEmpty ? '' : ' ${skipped.length} satır '
              'okunamadı ve atlandı.',
                   ],
                 ),
      restoredCounts: counts,
    );
  }

  /// JSON değerlerini drift'in beklediği türlere çevirir.
  static Map<String, d.Expression<Object>> _toSqlValues(
    Map<String, dynamic> row,
  ) {
    final out = <String, d.Expression<Object>>{};
    for (final e in row.entries) {
      final v = e.value;
      if (v == null) continue;
      out[e.key] = switch (v) {
        int() => d.Variable<int>(v),
        double() => d.Variable<double>(v),
        bool() => d.Variable<bool>(v),
        String() => d.Variable<String>(v),
        _ => d.Variable<String>(v.toString()),
      };
    }
    return out;
  }
}

class ImportReport {
  const ImportReport({
    required this.ok,
    required this.messageTr,
    this.restoredCounts = const {},
  });

  final bool ok;
  final String messageTr;
  final Map<String, int> restoredCounts;
}
