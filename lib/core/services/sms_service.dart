import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// SMS gönderimi.
///
/// İKİ YOL vardır ve ikisi de desteklenir:
///  1. [sendDirect] — SEND_SMS izni ile, kullanıcı müdahalesi olmadan.
///     Yalnızca kullanıcı bunu ayarlardan AÇIKÇA açtıysa kullanılır.
///     Varsayılan KAPALIDIR.
///  2. [openComposer] — mesajı hazırlar, SMS uygulamasını açar;
///     gönder tuşuna kullanıcı basar. İzin GEREKTİRMEZ.
class SmsService {
  const SmsService();

  static const MethodChannel _channel =
      MethodChannel('com.bobrekdostu.app/sms');

  /// Doğrudan SMS gönderir (SEND_SMS izni gerekir).
  ///
  /// Dönen değer: başarıyla gönderime verilen numara sayısı.
  /// Hata durumunda [SmsFailure] fırlatır.
  Future<int> sendDirect({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    if (phoneNumbers.isEmpty) return 0;
    try {
      final sent = await _channel.invokeMethod<int>('sendSms', {
        'numbers': phoneNumbers,
        'message': message,
      });
      return sent ?? 0;
    } on PlatformException catch (e) {
      throw SmsFailure(
        switch (e.code) {
          'PERMISSION_DENIED' =>
            'SMS gönderme izni yok. Ayarlar > İzinler bölümünden '
                'izni verebilir ya da mesajı elle göndermeyi '
                'seçebilirsin.',
          'NO_SMS_MANAGER' =>
            'Bu cihazda SMS gönderilemiyor (SIM kart yok veya '
                'telefon özelliği kapalı).',
          _ => 'SMS gönderilemedi: ${e.message ?? e.code}',
        },
      );
    } on MissingPluginException {
      throw const SmsFailure(
        'SMS gönderimi bu derlemede kullanılamıyor.',
      );
    }
  }

  /// SMS uygulamasını hazır mesajla açar (izin gerekmez).
  Future<bool> openComposer({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    final recipients = phoneNumbers.join(',');
    final uri = Uri(
      scheme: 'sms',
      path: recipients,
      queryParameters: {'body': message},
    );
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// WhatsApp ile paylaşım (tek numara).
  ///
  /// Numara uluslararası biçimde olmalıdır (örn. 905321234567).
  Future<bool> openWhatsApp({
    required String phoneNumber,
    required String message,
  }) async {
    final normalized = normalizePhoneForWhatsApp(phoneNumber);
    final uri = Uri.parse(
      'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}',
    );
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// 112'yi arar (telefon uygulamasını açar).
  Future<bool> callEmergency([String number = '112']) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> call(String number) => callEmergency(number);
}

class SmsFailure implements Exception {
  const SmsFailure(this.messageTr);
  final String messageTr;
  @override
  String toString() => 'SmsFailure($messageTr)';
}

/// Türkiye numaralarını WhatsApp için uluslararası biçime çevirir.
///
/// "0532 123 45 67" -> "905321234567"
/// "+90 532 123 45 67" -> "905321234567"
String normalizePhoneForWhatsApp(String input) {
  var digits = input.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.startsWith('+')) digits = digits.substring(1);
  if (digits.startsWith('00')) digits = digits.substring(2);
  // Başındaki 0'ı at ve Türkiye kodunu ekle.
  if (digits.startsWith('0')) {
    digits = '90${digits.substring(1)}';
  } else if (digits.length == 10 && digits.startsWith('5')) {
    digits = '90$digits';
  }
  return digits;
}
