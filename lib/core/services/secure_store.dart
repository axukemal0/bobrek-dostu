import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Şifreli anahtar deposu. API anahtarı ve PIN burada tutulur.
///
/// Android'de EncryptedSharedPreferences kullanılır (Keystore destekli).
class SecureStore {
  SecureStore([FlutterSecureStorage? storage])
      : _s = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _s;

  FlutterSecureStorage get raw => _s;

  static const String kAnthropicApiKey = 'anthropic_api_key';
  static const String kAppPin = 'app_pin_hash';

  Future<String?> readApiKey() => _s.read(key: kAnthropicApiKey);

  Future<void> writeApiKey(String key) =>
      _s.write(key: kAnthropicApiKey, value: key.trim());

  Future<void> deleteApiKey() => _s.delete(key: kAnthropicApiKey);

  Future<bool> hasApiKey() async {
    final k = await readApiKey();
    return k != null && k.trim().isNotEmpty;
  }

  Future<String?> readPinHash() => _s.read(key: kAppPin);
  Future<void> writePinHash(String hash) =>
      _s.write(key: kAppPin, value: hash);
  Future<void> deletePin() => _s.delete(key: kAppPin);
}
