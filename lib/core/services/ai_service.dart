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

  /// GERÇEK bir mesaj gönderen tanılama testi.
  ///
  /// `GET /v1/models` yalnız anahtarın geçerli olduğunu söyler; mesaj
  /// gönderimi başka sebeplerle (jeton bütçesi, model hakkı, kota)
  /// başarısız olabilir ve kullanıcı o zaman "anahtarı girdim ama
  /// çalışmıyor" durumunda kalır. Bu test birkaç kuruşluk gerçek bir
  /// istek atar ve HATANIN HAM METNİNİ geri verir.
  Future<AiTestResult> probeMessage({String? model}) async {
    final target = model ?? AiConfig.defaultModel;
    try {
      final reply = await sendChat(
        systemPrompt: 'Türkçe yanıt ver. Yalnızca "hazır" yaz.',
        messages: const [(role: 'user', text: 'Bağlantı testi.')],
        model: target,
        maxTokens: 2048,
      );
      final used = (reply.inputTokens ?? 0) + (reply.outputTokens ?? 0);
      return AiTestResult(
        ok: true,
        messageTr: 'Mesaj gönderildi ve yanıt alındı. '
            'Model: $target. Harcanan jeton: $used.\n\n'
            'Modelin yanıtı: "${reply.text.trim()}"',
      );
    } on AiFailure catch (e) {
      return AiTestResult(
        ok: false,
        messageTr: '${e.messageTr}'
            '${lastErrorDetail == null ? "" : "\n\n--- ham yanıt ---\n$lastErrorDetail"}',
      );
    } on Object catch (e) {
      return AiTestResult(
        ok: false,
        messageTr: 'Beklenmedik hata: $e',
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
      'output_config': {'effort': AiConfig.chatEffort},
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
      'output_config': {'effort': AiConfig.visionEffort},
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

  /// PDF belgesi + metin (tahlil raporu, diyetisyen listesi).
  ///
  /// Telefonda PDF'in metin katmanını çözen bir çözümleyici yok; bu
  /// yüzden PDF yalnız bu yolla okunabilir ve çağıran ekran kullanıcıdan
  /// AÇIK onay alır.
  Future<AiReply> sendDocument({
    required String systemPrompt,
    required String userText,
    required File document,
    String? model,
    int maxTokens = AiConfig.maxTokensVision,
  }) async {
    final bytes = await document.readAsBytes();
    if (bytes.length > 20 * 1024 * 1024) {
      throw const AiFailure(
        'Belge çok büyük (20 MB üstü). Yalnız gerekli sayfaları içeren '
        'daha küçük bir PDF dene.',
      );
    }

    final payload = <String, dynamic>{
      'model': model ?? AiConfig.defaultModel,
      'max_tokens': maxTokens,
      'system': systemPrompt,
      'output_config': {'effort': AiConfig.visionEffort},
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'document',
              'source': {
                'type': 'base64',
                'media_type': 'application/pdf',
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

  /// Son başarısız isteğin ham sunucu yanıtı — Yapay Zeka Bağlantısı
  /// ekranındaki tanılama kutusunda gösterilir. Kullanıcı "çalışmıyor"
  /// dediğinde elimizde yalnız Türkçe bir cümle kalmasın diye tutulur.
  String? lastErrorDetail;

  Future<AiReply> _postMessages(Map<String, dynamic> payload) async {
    final key = await _requireKey();
    try {
      var res = await _client
          .post(
            Uri.parse('${AiConfig.apiBase}${AiConfig.messagesPath}'),
            headers: await _headers(key),
            body: jsonEncode(payload),
          )
          .timeout(AiConfig.timeout);

      // Sunucu `output_config` alanını tanımazsa (eski API sürümü, farklı
      // bir uç nokta) istek 400 ile döner. Bu alan bir iyileştirmedir,
      // zorunlu değil: bir kez de onsuz denenir. Böylece tek bir isteğe
      // bağlı parametre yüzünden yapay zeka tamamen çalışmaz hâle gelmez.
      if (res.statusCode == 400 && payload.containsKey('output_config')) {
        final body = utf8.decode(res.bodyBytes).toLowerCase();
        if (body.contains('output_config') ||
            body.contains('extra inputs') ||
            body.contains('unexpected')) {
          final retry = Map<String, dynamic>.from(payload)
            ..remove('output_config');
          res = await _client
              .post(
                Uri.parse('${AiConfig.apiBase}${AiConfig.messagesPath}'),
                headers: await _headers(key),
                body: jsonEncode(retry),
              )
              .timeout(AiConfig.timeout);
        }
      }

      if (res.statusCode != 200) {
        lastErrorDetail =
            'HTTP ${res.statusCode}\n${utf8.decode(res.bodyBytes)}';
        throw AiFailure(_statusMessageTr(res), statusCode: res.statusCode);
      }
      lastErrorDetail = null;

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
        // Jeton bütçesi düşünme aşamasında bittiyse içerik yalnız
        // `thinking` bloklarından oluşur ve metin boş gelir. Bunu
        // "boş yanıt" diye geçmek kullanıcıyı yanlış yere bakmaya
        // yönlendiriyordu.
        if (stopReason == 'max_tokens') {
          throw const AiFailure(
            'Model yanıtı tamamlayamadan uzunluk sınırına takıldı. '
            'Daha kısa bir soru sor ya da Ayarlar > Yapay Zeka '
            'Bağlantısı\'ndan daha hızlı bir model (Haiku) seç.',
          );
        }
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
    final lower = (apiMessage ?? '').toLowerCase();

    // BAKİYE / FATURALANDIRMA — en sık karşılaşılan ve en yanıltıcı hata.
    //
    // Anthropic, kredisi bitmiş bir hesapta `GET /v1/models` isteğini
    // SORUNSUZ yanıtlar ama `POST /v1/messages` isteğine 400 döner.
    // Yani "Bağlantıyı test et" yeşil yanar, sonra hiçbir yapay zeka
    // özelliği çalışmaz. Önceki metin bu durumda "model adı yanlış
    // olabilir, başka model dene" diyordu; kullanıcı da üç modeli
    // sırayla deneyip hepsinde aynı duvara çarpıyordu. Hata artık adıyla
    // söyleniyor.
    if (lower.contains('credit balance') ||
        lower.contains('billing') ||
        lower.contains('insufficient') ||
        lower.contains('purchase credits')) {
      return 'Anthropic hesabında KULLANILABİLİR KREDİ YOK. Anahtarın '
          'geçerli (bu yüzden bağlantı testi başarılı oluyor) ama mesaj '
          'göndermek ücretli: platform.claude.com adresinde '
          '"Plans & Billing" bölümünden kredi yüklemen gerekiyor. '
          'Kredi yükleyene kadar uygulamanın yapay zeka dışındaki tüm '
          'bölümleri normal çalışır.$detail';
    }

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
