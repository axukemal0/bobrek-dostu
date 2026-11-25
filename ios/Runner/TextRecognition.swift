import Flutter
import UIKit
import Vision

/// Cihaz üstü metin okuma (OCR) — Apple Vision.
///
/// Neden Google ML Kit değil: GoogleMLKit iOS simülatörü için arm64 dilimi
/// yayınlamıyor. Apple Silicon üzerinde iOS 26+ simülatörleri arm64 zorunlu
/// kıldığı için ML Kit bağımlılığı uygulamayı x86_64'e düşürüyor ve
/// simülatörde hiç çalıştırılamıyordu. Apple Vision hem yerel (arm64), hem
/// cihaz üstü, hem de uygulamaya hiçbir boyut eklemiyor — çerçeve zaten
/// işletim sisteminde.
///
/// Görsel cihazdan ÇIKMAZ.
enum TextRecognition {
    static let channelName = "com.bobrekdostu.app/ocr"

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "recognize":
                guard
                    let args = call.arguments as? [String: Any],
                    let path = args["path"] as? String
                else {
                    result(FlutterError(
                        code: "BAD_ARGS",
                        message: "Dosya yolu verilmedi.",
                        details: nil
                    ))
                    return
                }
                recognize(path: path, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private static func recognize(path: String, result: @escaping FlutterResult) {
        guard
            let image = UIImage(contentsOfFile: path),
            let cgImage = image.cgImage
        else {
            result(FlutterError(
                code: "BAD_IMAGE",
                message: "Görsel okunamadı.",
                details: path
            ))
            return
        }

        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                result(FlutterError(
                    code: "RECOGNITION_FAILED",
                    message: error.localizedDescription,
                    details: nil
                ))
                return
            }
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            // Satırları yukarıdan aşağı sırala: etiket tablosunun satır
            // düzeni korunsun (çözümleyici sütunları satırdan çıkarıyor).
            let sorted = observations.sorted { a, b in
                a.boundingBox.origin.y > b.boundingBox.origin.y
            }
            let lines = sorted.compactMap { $0.topCandidates(1).first?.string }
            result([
                "text": lines.joined(separator: "\n"),
                "lines": lines,
            ])
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        // Türkçe destekleniyorsa iste; yoksa Vision varsayılanına bırak.
        // (Vision'da Türkçe iOS 16 ile geldi. Desteklenmediğinde etiketin
        // sayıları yine doğru okunur; çözümleyici zaten sayı odaklı.)
        let wanted = ["tr-TR", "en-US"]
        if let supported = try? VNRecognizeTextRequest
            .supportedRecognitionLanguages(
                for: .accurate,
                revision: VNRecognizeTextRequest.currentRevision
            ) {
            let available = wanted.filter { supported.contains($0) }
            if !available.isEmpty {
                request.recognitionLanguages = available
            }
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "RECOGNITION_FAILED",
                        message: error.localizedDescription,
                        details: nil
                    ))
                }
            }
        }
    }
}
