import 'dart:io';

import 'package:flutter/services.dart';

/// Cihaz üstü metin okuma (OCR).
///
/// İki platformda da YEREL çerçeve kullanılır, Dart eklentisi değil:
///  * iOS   → Apple Vision (`ios/Runner/TextRecognition.swift`)
///  * Android → ML Kit metin tanıma, Play Services üzerinden AYRIK
///    (`play-services-mlkit-text-recognition`)
///
/// Neden böyle: `google_mlkit_text_recognition` paketi iOS'ta GoogleMLKit
/// pod'unu getiriyor ve GoogleMLKit simülatör için arm64 dilimi
/// YAYINLAMIYOR. Apple Silicon'da iOS 26+ simülatörleri arm64 zorunlu
/// kıldığından uygulama x86_64'e düşüyor ve simülatörde hiç
/// çalıştırılamıyordu. Ayrıca modelin APK'ya gömülmesi uygulamayı
/// büyütüyordu; ayrık sürümde model Play Services'te durur.
///
/// Görseller HİÇBİR KOŞULDA cihazdan çıkmaz.
class TextRecognitionService {
  const TextRecognitionService();

  static const MethodChannel _channel =
      MethodChannel('com.bobrekdostu.app/ocr');

  /// Dosyadaki metni okur.
  Future<RecognizedTextResult> recognize(File image) async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'recognize',
        {'path': image.path},
      );
      if (raw == null) return const RecognizedTextResult(fullText: '', lines: []);
      final lines = (raw['lines'] as List?)?.cast<String>() ?? const <String>[];
      return RecognizedTextResult(
        fullText: (raw['text'] as String?) ?? lines.join('\n'),
        lines: lines,
      );
    } on PlatformException catch (e) {
      throw OcrFailure(
        switch (e.code) {
          'BAD_IMAGE' =>
            'Fotoğraf okunamadı. Başka bir fotoğrafla dener misin?',
          'UNAVAILABLE' =>
            'Metin okuma bu cihazda kullanılamıyor. Google Play '
                'hizmetleri güncel değilse güncellemeyi dene; değerleri '
                'elle de girebilirsin.',
          _ => 'Metin okunamadı: ${e.message ?? e.code}',
        },
      );
    } on MissingPluginException {
      throw const OcrFailure(
        'Metin okuma bu derlemede kullanılamıyor. Değerleri elle '
        'girebilirsin.',
      );
    }
  }
}

class RecognizedTextResult {
  const RecognizedTextResult({required this.fullText, required this.lines});

  final String fullText;
  final List<String> lines;

  bool get isEmpty => fullText.trim().isEmpty;
}

class OcrFailure implements Exception {
  const OcrFailure(this.messageTr);
  final String messageTr;
  @override
  String toString() => 'OcrFailure($messageTr)';
}
