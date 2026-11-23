import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/ai_config.dart';
import 'secure_store.dart';

/// Yapay zeka bağlantı durumu.
enum AiConnectionState { noKey, untested, ok, failed }

/// Bağlantı testi sonucu.
class AiTestResult {
  const AiTestResult({
    required this.ok,
    required this.messageTr,
    this.availableModels = const [],
    this.configuredModelAvailable,
  });

  final bool ok;
  final String messageTr;
  final List<String> availableModels;

  /// Ayarlarda seçili model, anahtarın erişebildiği modeller
  /// arasında mı? null = belirlenemedi.
  final bool? configuredModelAvailable;
}

/// AI yanıtı.
class AiReply {
  const AiReply({
    required this.text,
    this.inputTokens,
    this.outputTokens,
    this.stopReason,
    this.refused = false,
  });

  final String text;
  final int? inputTokens;
  final int? outputTokens;
  final String? stopReason;

  /// Model güvenlik gerekçesiyle yanıt vermeyi reddetti.
  final bool refused;
}

/// AI hataları — mesajlar sade Türkçedir, kullanıcıya doğrudan gösterilir.
class AiFailure implements Exception {
  const AiFailure(this.messageTr, {this.needsKey = false, this.statusCode});

  final String messageTr;
  final bool needsKey;
  final int? statusCode;

  @override
  String toString() => 'AiFailure($messageTr)';
}

/// Anthropic Claude API istemcisi.
///
/// GİZLİLİK: Bu sınıf yalnızca kullanıcının açık eylemiyle çağrılır.
/// Gönderilen içerik çağıran ekranda kullanıcıya önceden gösterilir.
/// API anahtarı yalnızca [SecureStore]'dan okunur; kodda gömülü
/// anahtar YOKTUR.
class AiService {
  AiService({required this.secureStore, http.Client? client})
      : _client = client ?? http.Client();

  final SecureStore secureStore;
  final http.Client _client;

  Future<Map<String, String>> _headers(String apiKey) async => {
        'x-api-key': apiKey,
        'anthropic-version': AiConfig.apiVersion,
        'content-type': 'application/json',
      };

  Future<String> _requireKey() async {
    final key = await secureStore.readApiKey();
    if (key == null || key.trim().isEmpty) {
      throw const AiFailure(
        'Önce yapay zeka bağlantısını kurman gerekiyor. '
        'Ayarlar > Yapay Zeka Bağlantısı bölümünden anahtarını '
        'ekleyebilirsin.',
        needsKey: true,
      );
    }
    return key.trim();
  }

  /// Bağlantı testi: GET /v1/models.
  ///
  /// Bu istek TOKEN HARCAMAZ, yani testi istediğin kadar çalıştırabilirsin.
  /// Anahtarın geçerliliğini ve hangi modellere erişebildiğini doğrular.
  Future<AiTestResult> testConnection({
    String? overrideKey,
    String? modelToCheck,
  }) async {
    final key = (overrideKey ?? await secureStore.readApiKey())?.trim();
    if (key == null || key.isEmpty) {
      return const AiTestResult(
        ok: false,
        messageTr: 'Anahtar girilmemiş. Yukarıdaki alana anahtarını '
            'yapıştır, sonra tekrar dene.',
      );
    }

    if (!looksLikeAnthropicKey(key)) {
      return const AiTestResult(
        ok: false,
        messageTr: 'Bu bir Anthropic anahtarına benzemiyor. '
            'Anahtar "sk-ant-" ile başlar ve uzun bir metindir. '
            'Kopyalarken başına/sonuna boşluk veya satır sonu '
            'karışmış olabilir.',
      );
    }

    try {
      final res = await _client
          .get(
            Uri.parse('${AiConfig.apiBase}${AiConfig.modelsPath}?limit=60'),
            headers: await _headers(key),
          )
          .timeout(AiConfig.testTimeout);

      if (res.statusCode == 200) {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        final data = (body is Map && body['data'] is List)
            ? (body['data'] as List)
            : const [];
        final ids = data
            .map((m) => (m is Map ? m['id'] : null))
            .whereType<String>()
            .toList(growable: false);

        final target = modelToCheck ?? AiConfig.defaultModel;
        final hasTarget = ids.isEmpty ? null : ids.contains(target);

        final msg = StringBuffer('Bağlantı başarılı. Anahtar geçerli.');
        if (ids.isNotEmpty) {
          msg.write(' Erişebildiğin model sayısı: ${ids.length}.');
        }
        if (hasTarget == false) {
          msg.write(
            ' DİKKAT: Seçili model ($target) bu anahtarla '
            'erişilebilir modeller arasında görünmüyor. '
            'Ayarlardan başka bir model seç.',
          );
        }
        return AiTestResult(
          ok: hasTarget != false,
          messageTr: msg.toString(),
          availableModels: ids,
          configuredModelAvailable: hasTarget,
        );
      }

      return AiTestResult(ok: false, messageTr: _statusMessageTr(res));
    } on TimeoutException {
      return const AiTestResult(
        ok: false,
        messageTr: 'Sunucu zamanında yanıt vermedi. İnternet bağlantını '
            'kontrol et ve tekrar dene.',
      );
    } on SocketException {
      return const AiTestResult(
        ok: false,
        messageTr: 'İnternete ulaşılamadı. Wi-Fi veya mobil veriyi '
            'kontrol et.',
      );
    } on http.ClientException catch (e) {
      return AiTestResult(
        ok: false,
        messageTr: 'Bağlantı kurulamadı: ${e.message}',
      );
    }
  }

  /// Anahtar biçimi ön kontrolü (ağ isteği yapmadan).
  static bool looksLikeAnthropicKey(String key) {
    final k = key.trim();
    return k.startsWith('sk-ant-') && k.length >= 40 && !k.contains(' ');
  }

  /// Metin sohbeti.
  Future<AiReply> sendChat({
    required String systemPrompt,
    required List<({String role, String text})> messages,
    String? model,
    int maxTokens = AiConfig.maxTokensChat,
  }) async {
    final payload = <String, dynamic>{
      'model': model ?? AiConfig.defaultModel,
      'max_tokens': maxTokens,
      'system': systemPrompt,
      'output_config': {'effort': AiConfig.effort},
      'messages': [
        for (final m in messages)
          {
            'role': m.role,
            'content': [
              {'type': 'text', 'text': m.text},
            ],
          },
      ],
    };
    return _postMessages(payload);
  }

  /// Görsel + metin (yemek fotoğrafı, tahlil kağıdı, menü fotoğrafı).
  Future<AiReply> sendVision({
    required String systemPrompt,
    required String userText,
    required File image,
    String? model,
    int maxTokens = AiConfig.maxTokensVision,
  }) async {
    final bytes = await image.readAsBytes();
    final mediaType = _mediaTypeFor(image.path);
    if (mediaType == null) {
      throw const AiFailure(
        'Bu görsel biçimi desteklenmiyor. JPEG, PNG, GIF veya WebP '
        'kullan.',
      );
    }
    // 5 MB üstü görseller API tarafında reddedilebilir.
    if (bytes.length > 5 * 1024 * 1024) {
      throw const AiFailure(
        'Görsel çok büyük (5 MB üstü). Daha küçük bir fotoğraf çek '
        'veya telefon ayarlarından fotoğraf çözünürlüğünü düşür.',
      );
    }

    final payload = <String, dynamic>{
      'model': model ?? AiConfig.defaultModel,
      'max_tokens': maxTokens,
      'system': systemPrompt,
      'output_config': {'effort': AiConfig.effort},
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': mediaType,
                'data': base64Encode(bytes),
              },
            },
            {'type': 'text', 'text': userText},
          ],
        },
      ],
    };
    return _postMessages(payload);
  }

  static String? _mediaTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return null;
  }

  Future<AiReply> _postMessages(Map<String, dynamic> payload) async {
    final key = await _requireKey();
    try {
      final res = await _client
          .post(
            Uri.parse('${AiConfig.apiBase}${AiConfig.messagesPath}'),
            headers: await _headers(key),
            body: jsonEncode(payload),
          )
          .timeout(AiConfig.timeout);

      if (res.statusCode != 200) {
        throw AiFailure(_statusMessageTr(res), statusCode: res.statusCode);
      }

      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final stopReason = body['stop_reason'] as String?;

      // Güvenlik sınıflandırıcısı isteği reddettiyse HTTP 200 döner.
      if (stopReason == 'refusal') {
        final details = body['stop_details'];
        final explanation =
            (details is Map ? details['explanation'] : null) as String?;
        return AiReply(
          text: 'Model bu isteği yanıtlamadı'
              '${explanation == null ? "" : " ($explanation)"}. '
              'Soruyu farklı biçimde sormayı dene. '
              'Acil bir durumsa beklemeden 112\'yi ara.',
          stopReason: stopReason,
          refused: true,
        );
      }

      final content = body['content'];
      final sb = StringBuffer();
      if (content is List) {
        for (final block in content) {
          if (block is Map && block['type'] == 'text') {
            sb.write(block['text'] ?? '');
          }
        }
      }

      final usage = body['usage'];
      final text = sb.toString().trim();

      if (text.isEmpty) {
        throw const AiFailure(
          'Model boş bir yanıt döndürdü. Tekrar dene; sürerse '
          'Ayarlar\'dan başka bir model seçmeyi dene.',
        );
      }

      var out = text;
      if (stopReason == 'max_tokens') {
        out = '$text\n\n[Yanıt uzunluk sınırına takıldı ve kesildi. '
            'Daha kısa bir soru sorarsan tam cevap alırsın.]';
      }

      return AiReply(
        text: out,
        inputTokens: (usage is Map ? usage['input_tokens'] : null) as int?,
        outputTokens: (usage is Map ? usage['output_tokens'] : null) as int?,
        stopReason: stopReason,
      );
    } on TimeoutException {
      throw const AiFailure(
        'Yapay zeka zamanında yanıt vermedi. İnternetin yavaş olabilir '
        'ya da model yoğun. Biraz sonra tekrar dene.',
      );
    } on SocketException {
      throw const AiFailure(
        'İnternete ulaşılamadı. Yapay zeka özellikleri internet '
        'gerektirir; uygulamanın geri kalanı çevrimdışı çalışır.',
      );
    } on http.ClientException catch (e) {
      throw AiFailure('Bağlantı kesildi: ${e.message}');
    } on FormatException {
      throw const AiFailure(
        'Sunucudan okunamayan bir yanıt geldi. Tekrar dene.',
      );
    }
  }

  /// HTTP durum kodlarını sade Türkçeye çevirir.
  static String _statusMessageTr(http.Response res) {
    String? apiMessage;
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      final err = (body is Map ? body['error'] : null);
      apiMessage = (err is Map ? err['message'] : null) as String?;
    } on Object {
      apiMessage = null;
    }

    final detail = apiMessage == null ? '' : '\n\nSunucu notu: $apiMessage';

    return switch (res.statusCode) {
      400 => 'İstek geçersiz (400). Seçili model adı yanlış olabilir — '
          'Ayarlar\'dan başka bir model dene.$detail',
      401 => 'Anahtar geçersiz (401). Anahtarı yanlış kopyalamış '
          'olabilirsin ya da anahtar silinmiş/iptal edilmiş olabilir. '
          'platform.claude.com adresinden yeni bir anahtar oluşturup '
          'tekrar yapıştır.$detail',
      403 => 'Bu anahtarın yetkisi yok (403). Anahtarın bağlı olduğu '
          'çalışma alanının izinlerini kontrol et.$detail',
      404 => 'İstenen model bulunamadı (404). Ayarlar\'dan geçerli bir '
          'model seç.$detail',
      413 => 'Gönderilen içerik çok büyük (413). Daha küçük bir '
          'fotoğraf veya daha kısa bir metin dene.',
      429 => 'İstek sınırına takıldın (429). Anthropic hesabında '
          'dakikalık/aylık sınır dolmuş olabilir. Birkaç dakika bekle '
          've tekrar dene.$detail',
      402 => 'İstek işlenemedi (402). Hesabında kredi kalmamış '
          'olabilir; platform.claude.com > Billing bölümünü kontrol '
          'et.$detail',
      500 => 'Anthropic sunucusunda hata (500). Senin tarafında bir '
          'sorun yok; biraz sonra tekrar dene.',
      529 => 'Sunucu aşırı yoğun (529). Birkaç dakika sonra tekrar '
          'dene.',
      _ when res.statusCode >= 500 =>
        'Sunucu şu an hizmet veremiyor (${res.statusCode}). '
            'Biraz sonra tekrar dene.',
      _ => 'Beklenmedik bir yanıt geldi (${res.statusCode}).$detail',
    };
  }

  void dispose() => _client.close();
}
