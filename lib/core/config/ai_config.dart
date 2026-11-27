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

  /// Yanıt uzunluğu üst sınırı.
  ///
  /// DİKKAT — BURASI BİR HATA KAYNAĞIYDI. Claude 5.x modellerinde
  /// "düşünme" (thinking) KAPATILAMAZ ve düşünme jetonları da
  /// `max_tokens` bütçesinden harcanır. Sınır 4096'dayken model
  /// bütçeyi düşünürken bitiriyor, yanıt metni hiç üretilemiyordu:
  /// sunucu 200 dönüyor ama içerikte metin bloğu olmuyordu ve
  /// uygulama "Model boş bir yanıt döndürdü" diyordu. Üç modelde de
  /// aynı olmasının sebebi buydu. Akışsız istekte zaman aşımına
  /// girmeyecek kadar yüksek bir tavan veriyoruz.
  static const int maxTokensChat = 16000;
  static const int maxTokensVision = 12000;

  /// Anthropic "effort" ayarı: düşünmenin derinliğini belirler.
  ///
  /// Sohbet telefonda hızlı olmalı — 'low'. Tahlil kağıdı ve yemek
  /// fotoğrafı okumak gerçek bir çıkarım işi, orada 'medium'.
  static const String chatEffort = 'low';
  static const String visionEffort = 'medium';

  /// Bağlantı testinde kullanılan istek: GET /v1/models.
  /// Token harcamaz, bu yüzden "Bağlantıyı test et" ücretsizdir.
  ///
  /// Düşünme açıkken yanıt birkaç on saniye sürebilir; 60 saniye
  /// kısaydı.
  static const Duration timeout = Duration(seconds: 150);
  static const Duration testTimeout = Duration(seconds: 20);

  /// Anahtarın nasıl alınacağını anlatan resmî adres.
  static const String consoleUrl = 'https://platform.claude.com/';
  static const String apiKeysUrl = 'https://platform.claude.com/settings/keys';
}
