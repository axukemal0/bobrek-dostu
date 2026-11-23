package com.bobrekdostu.bobrek_dostu

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Böbrek Dostu ana aktivitesi.
 *
 * Tek platform kanalı: doğrudan SMS gönderimi.
 * Acil durumda ve ölçüm alarm eşiği aşıldığında (kullanıcı bu ayarı
 * AÇIKÇA açtıysa) acil kişilere mesaj gönderilmesi için kullanılır.
 *
 * İzin yoksa PERMISSION_DENIED döner; Dart tarafı bu durumda mesajı
 * hazırlayıp SMS uygulamasını açar (gönder tuşuna kullanıcı basar).
 */
class MainActivity : FlutterActivity() {

    private val smsChannel = "com.bobrekdostu.app/sms"

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
}
