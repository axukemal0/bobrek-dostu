/// Yapay zeka (Anthropic Claude API) yapılandırması.
///
/// MODEL ADINI DEĞİŞTİRMEK İÇİN TEK YER BURASI.
/// Kodda ve depoda API ANAHTARI YOKTUR; anahtar yalnızca cihazda,
/// flutter_secure_storage içinde şifreli olarak tutulur.
library;

class AiConfig {
  const AiConfig._();

  static const String apiBase = 'https://api.anthropic.com';
  static const String messagesPath = '/v1/messages';
  static const String modelsPath = '/v1/models';

  /// Anthropic API sürümü (zorunlu başlık).
  static const String apiVersion = '2023-06-01';

  /// --- MODEL SEÇİMİ -------------------------------------------------
  /// Varsayılan model: metin + görsel (vision) destekler.
  static const String defaultModel = 'claude-opus-5-5';

  /// Ayarlar ekranında seçilebilen modeller.
  /// (Hepsi metin + görsel destekler.)
  static const List<({String id, String labelTr, String noteTr})> models = [
    (
      id: 'claude-opus-5-5',
      labelTr: 'Claude Opus 5.5',
      noteTr: 'En yetenekli. Tahlil fotoğrafı ve yemek analizinde '
          'en isabetli sonucu verir. Daha pahalı.',
    ),
    (
      id: 'claude-sonnet-5-5',
      labelTr: 'Claude Sonnet 5.5',
      noteTr: 'Hızlı ve belirgin ölçüde daha ucuz. Günlük sohbet ve '
          'basit görsel analiz için yeterli.',
    ),
    (
      id: 'claude-haiku-5-5',
      labelTr: 'Claude Haiku 5.5',
      noteTr: 'En ucuz ve en hızlı. Kısa sorular için iyi; '
          'karmaşık tahlil yorumunda zayıf kalabilir.',
    ),
  ];

  /// Yanıt uzunluğu üst sınırı (akışsız istekler için güvenli değer).
  static const int maxTokensChat = 4096;
  static const int maxTokensVision = 2048;

  /// Anthropic "effort" ayarı: düşük = daha az token, daha hızlı.
  /// Mobil kullanımda ve maliyet açısından 'medium' dengeli.
  static const String effort = 'medium';

  /// Bağlantı testinde kullanılan istek: GET /v1/models.
  /// Token harcamaz, bu yüzden "Bağlantıyı test et" ücretsizdir.
  static const Duration timeout = Duration(seconds: 60);
  static const Duration testTimeout = Duration(seconds: 20);

  /// Anahtarın nasıl alınacağını anlatan resmî adres.
  static const String consoleUrl = 'https://platform.claude.com/';
  static const String apiKeysUrl = 'https://platform.claude.com/settings/keys';
}
