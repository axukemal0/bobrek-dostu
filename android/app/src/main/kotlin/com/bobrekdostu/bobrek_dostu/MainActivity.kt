package com.bobrekdostu.bobrek_dostu

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.telephony.SmsManager
import androidx.core.content.ContextCompat
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Böbrek Dostu ana aktivitesi.
 *
 * İki platform kanalı: doğrudan SMS gönderimi ve cihaz üstü metin okuma.
 * Acil durumda ve ölçüm alarm eşiği aşıldığında (kullanıcı bu ayarı
 * AÇIKÇA açtıysa) acil kişilere mesaj gönderilmesi için kullanılır.
 *
 * İzin yoksa PERMISSION_DENIED döner; Dart tarafı bu durumda mesajı
 * hazırlayıp SMS uygulamasını açar (gönder tuşuna kullanıcı basar).
 */
class MainActivity : FlutterActivity() {

    private val smsChannel = "com.bobrekdostu.app/sms"
    private val ocrChannel = "com.bobrekdostu.app/ocr"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            smsChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendSms" -> handleSendSms(call.argument("numbers"), call.argument("message"), result)
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ocrChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "recognize" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrBlank()) {
                        result.error("BAD_ARGS", "Dosya yolu verilmedi.", null)
                    } else {
                        recognizeText(path, result)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun handleSendSms(
        numbers: List<String>?,
        message: String?,
        result: MethodChannel.Result,
    ) {
        if (numbers.isNullOrEmpty() || message.isNullOrBlank()) {
            result.error("BAD_ARGS", "Numara listesi veya mesaj boş.", null)
            return
        }

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            result.error("PERMISSION_DENIED", "SEND_SMS izni verilmemiş.", null)
            return
        }

        val smsManager = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                getSystemService(SmsManager::class.java)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }
        } catch (e: Exception) {
            null
        }

        if (smsManager == null) {
            result.error("NO_SMS_MANAGER", "Bu cihazda SMS gönderilemiyor.", null)
            return
        }

        var sent = 0
        val failures = mutableListOf<String>()

        for (raw in numbers) {
            val number = raw.filter { it.isDigit() || it == '+' }
            if (number.length < 7) {
                failures.add(raw)
                continue
            }
            try {
                // 160 karakterden uzun mesajlar parçalanarak gönderilir.
                val parts = smsManager.divideMessage(message)
                if (parts.size > 1) {
                    smsManager.sendMultipartTextMessage(number, null, parts, null, null)
                } else {
                    smsManager.sendTextMessage(number, null, message, null, null)
                }
                sent++
            } catch (e: Exception) {
                failures.add("$raw (${e.message})")
            }
        }

        if (sent == 0) {
            result.error(
                "SEND_FAILED",
                "Hiçbir numaraya gönderilemedi: ${failures.joinToString()}",
                null,
            )
        } else {
            result.success(sent)
        }
    }

    /**
     * Cihaz üstü metin okuma.
     *
     * AYRIK ML Kit kullanılır: model APK'ya gömülmez, Google Play
     * hizmetleri sağlar. Görsel cihazdan ÇIKMAZ.
     */
    private fun recognizeText(path: String, result: MethodChannel.Result) {
        val file = File(path)
        if (!file.exists()) {
            result.error("BAD_IMAGE", "Fotoğraf bulunamadı.", path)
            return
        }

        val image = try {
            InputImage.fromFilePath(this, Uri.fromFile(file))
        } catch (e: Exception) {
            result.error("BAD_IMAGE", e.message, null)
            return
        }

        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        recognizer.process(image)
            .addOnSuccessListener { visionText ->
                // Satırları yukarıdan aşağı sırala: etiket tablosunun satır
                // düzeni korunsun (Dart tarafındaki çözümleyici sütunları
                // satırdan çıkarıyor).
                val lines = visionText.textBlocks
                    .flatMap { it.lines }
                    .sortedBy { it.boundingBox?.top ?: 0 }
                    .map { it.text }
                result.success(
                    mapOf(
                        "text" to lines.joinToString("\n"),
                        "lines" to lines,
                    ),
                )
                recognizer.close()
            }
            .addOnFailureListener { e ->
                // Play hizmetleri eski/eksikse modül indirilemez.
                result.error("UNAVAILABLE", e.message, null)
                recognizer.close()
            }
    }
}
