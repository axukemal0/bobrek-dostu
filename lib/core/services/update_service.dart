import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';
import '../i18n/i18n.dart';

/// Yeni sürüm denetimi.
///
/// Uygulama mağazada olmadığı için güncellemeyi kendisi haber verir.
/// Kaynak: projenin GitHub "Releases" sayfası (herkese açık, anahtar
/// gerekmez). Sürüm etiketi `v1.0.1` biçimindedir.
///
/// PLATFORM FARKI:
///  * Android — APK doğrudan indirilip kurulabilir (kullanıcı sistem
///    kurulum ekranını yine onaylar).
///  * iOS — Apple, uygulamaların kendi kendini güncellemesine izin
///    vermez. iPhone'da güncelleme TestFlight üzerinden gelir ve
///    TestFlight'ta "Automatic Updates" açıksa kendiliğinden kurulur.
///    Burada yalnızca "yeni sürüm var" denir ve TestFlight açılır.
class UpdateService {
  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const MethodChannel _channel =
      MethodChannel('com.bobrekdostu.app/install');

  /// Yeni sürüm var mı? Yoksa null.
  Future<AvailableUpdate?> check() async {
    final info = await PackageInfo.fromPlatform();
    final current = _Version.parse(info.version);
    if (current == null) return null;

    final uri = Uri.parse(
      'https://api.github.com/repos/${AppConfig.githubRepo}/releases/latest',
    );

    final res = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/vnd.github+json',
        // GitHub anonim isteklerde bir istemci adı bekler.
        'User-Agent': 'bobrek-dostu-app',
      },
    ).timeout(const Duration(seconds: 12));

    if (res.statusCode == 404) return null; // henüz hiç sürüm yayınlanmamış
    if (res.statusCode != 200) {
      throw UpdateFailure(
        tf(
          'Sürüm bilgisi alınamadı (HTTP {0}). İnternet '
          'bağlantını kontrol edip tekrar dene.',
          [res.statusCode],
        ),
      );
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['draft'] == true || body['prerelease'] == true) return null;

    final tag = (body['tag_name'] as String?)?.trim() ?? '';
    final latest = _Version.parse(tag.startsWith('v') ? tag.substring(1) : tag);
    if (latest == null || !latest.isNewerThan(current)) return null;

    String? apkUrl;
    if (Platform.isAndroid) {
      final assets = (body['assets'] as List?) ?? const [];
      for (final a in assets) {
        if (a is! Map) continue;
        final name = (a['name'] as String?) ?? '';
        // Telefonların ezici çoğunluğu arm64.
        if (name.contains('arm64-v8a') && name.endsWith('.apk')) {
          apkUrl = a['browser_download_url'] as String?;
          break;
        }
      }
    }

    return AvailableUpdate(
      version: latest.toString(),
      currentVersion: current.toString(),
      notesTr: (body['body'] as String?)?.trim(),
      releaseUrl: (body['html_url'] as String?) ?? '',
      apkUrl: apkUrl,
    );
  }

  /// APK'yı indirir ve sistemin kurulum ekranını açar (yalnız Android).
  ///
  /// [onProgress] 0..1 arası ilerleme bildirir; toplam boyut
  /// bilinmiyorsa çağrılmaz.
  Future<void> downloadAndInstall(
    AvailableUpdate update, {
    void Function(double progress)? onProgress,
  }) async {
    final url = update.apkUrl;
    if (!Platform.isAndroid || url == null) {
      throw const UpdateFailure(
        'Bu platformda doğrudan kurulum yapılamıyor.',
      );
    }

    final request = http.Request('GET', Uri.parse(url))
      ..headers['User-Agent'] = 'bobrek-dostu-app';
    final response = await _client.send(request);
    if (response.statusCode != 200) {
      throw UpdateFailure(tf(
                            'İndirme başarısız (HTTP {0}).',
                            [response.statusCode],
                          ));
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/bobrek-dostu-${update.version}.apk');
    final sink = file.openWrite();
    final total = response.contentLength;
    var received = 0;

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total != null && total > 0) {
          onProgress?.call(received / total);
        }
      }
    } finally {
      await sink.close();
    }

    try {
      await _channel.invokeMethod<void>('installApk', {'path': file.path});
    } on PlatformException catch (e) {
      throw UpdateFailure(
        switch (e.code) {
          'PERMISSION_DENIED' =>
            'Kurulum için "bilinmeyen kaynaklardan uygulama yükleme" '
                'izni gerekiyor. Açılan ayar ekranından Böbrek Dostu\'na '
                'izin verip tekrar dene.',
          _ => tf('Kurulum başlatılamadı: {0}', [e.message ?? e.code]),
        },
      );
    }
  }
}

/// Yayınlanmış yeni sürüm.
class AvailableUpdate {
  const AvailableUpdate({
    required this.version,
    required this.currentVersion,
    required this.releaseUrl,
    this.notesTr,
    this.apkUrl,
  });

  final String version;
  final String currentVersion;
  final String releaseUrl;
  final String? notesTr;

  /// Android'de doğrudan kurulabilen APK (yoksa null).
  final String? apkUrl;

  bool get canInstallDirectly => apkUrl != null && Platform.isAndroid;
}

class UpdateFailure implements Exception {
  const UpdateFailure(this.messageTr);
  final String messageTr;
  @override
  String toString() => 'UpdateFailure($messageTr)';
}

/// Basit sürüm numarası (1.2.3) — SAF, test edilebilir.
class _Version implements Comparable<_Version> {
  const _Version(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  static _Version? parse(String raw) {
    // "1.2.3+45" -> derleme numarasını at
    final core = raw.split('+').first.trim();
    final m = RegExp(r'^(\d+)\.(\d+)(?:\.(\d+))?$').firstMatch(core);
    if (m == null) return null;
    return _Version(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3) ?? '0'),
    );
  }

  bool isNewerThan(_Version other) => compareTo(other) > 0;

  @override
  int compareTo(_Version o) {
    if (major != o.major) return major.compareTo(o.major);
    if (minor != o.minor) return minor.compareTo(o.minor);
    return patch.compareTo(o.patch);
  }

  @override
  String toString() => '$major.$minor.$patch';
}

/// Testler için açık sürüm karşılaştırması.
int compareAppVersions(String a, String b) {
  final va = _Version.parse(a);
  final vb = _Version.parse(b);
  if (va == null || vb == null) return 0;
  return va.compareTo(vb);
}
