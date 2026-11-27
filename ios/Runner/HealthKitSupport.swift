import Foundation
import Flutter
import HealthKit

/// iPhone Sağlık (HealthKit) DURUM SORGUSU.
///
/// Veri okuma işini `health` Flutter eklentisi yapıyor; burada yalnız
/// "bu derleme Sağlık verisine erişebilir mi" sorusu yanıtlanıyor.
///
/// NEDEN GEREKLİ: HealthKit, Apple'ın "hak" (entitlement) verdiği bir
/// yetenektir ve bu hak YALNIZ ÜCRETLİ geliştirici üyeliğiyle
/// oluşturulan provizyon profillerine konabilir. Ücretsiz Apple
/// kimliğiyle yan yüklenen bir derlemede `requestAuthorization`
/// çağrısı izin ekranını HİÇ AÇMADAN sessizce `false` döner.
/// Uygulama bunu "kullanıcı izin vermedi" diye yorumlarsa, kullanıcı
/// Ayarlar > Sağlık'ta izni açmaya çalışıp uygulamayı orada bile
/// bulamaz ve saatlerce kendi telefonunu suçlar. Bu yüzden durum
/// önceden ve dürüstçe ayırt ediliyor.
///
/// Hakkın olup olmadığı, uygulama paketindeki `embedded.mobileprovision`
/// dosyasından okunur:
///  * Dosya YOKSA derleme App Store / TestFlight'tan gelmiştir; o hat
///    `Runner-AppStore.entitlements` ile imzalandığı için hak vardır.
///  * Dosya VARSA (geliştirme / yan yükleme) içindeki `Entitlements`
///    sözlüğüne bakılır.
enum HealthKitSupport {
    static let channelName = "com.bobrekdostu.app/healthkit"

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "status":
                result([
                    "dataAvailable": HKHealthStore.isHealthDataAvailable(),
                    "entitled": hasHealthKitEntitlement(),
                    "signedForDevelopment": embeddedProfileEntitlements() != nil,
                ])
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    /// Bu derleme HealthKit hakkıyla mı imzalanmış?
    static func hasHealthKitEntitlement() -> Bool {
        guard let entitlements = embeddedProfileEntitlements() else {
            // Provizyon profili gömülü değil → mağaza derlemesi.
            return true
        }
        if let flag = entitlements["com.apple.developer.healthkit"] as? Bool {
            return flag
        }
        return entitlements["com.apple.developer.healthkit"] != nil
    }

    /// `embedded.mobileprovision` içindeki `Entitlements` sözlüğü.
    ///
    /// Dosya bir CMS (PKCS#7) imza kabıdır; içinde düz bir XML plist
    /// gömülüdür. Tam CMS çözümlemesi yerine plist bloğu metin olarak
    /// kesilip ayrıştırılıyor — Apple'ın araçları da bu biçimi üretir
    /// ve burada güvenlik kararı verilmiyor, yalnız arayüz metni
    /// seçiliyor.
    private static func embeddedProfileEntitlements() -> [String: Any]? {
        guard
            let url = Bundle.main.url(
                forResource: "embedded",
                withExtension: "mobileprovision"
            ),
            let data = try? Data(contentsOf: url),
            let raw = String(data: data, encoding: .isoLatin1)
        else {
            return nil
        }

        guard
            let start = raw.range(of: "<?xml"),
            let end = raw.range(of: "</plist>")
        else {
            return nil
        }

        let plistText = String(raw[start.lowerBound..<end.upperBound])
        guard let plistData = plistText.data(using: .isoLatin1) else {
            return nil
        }

        let parsed = try? PropertyListSerialization.propertyList(
            from: plistData,
            options: [],
            format: nil
        )
        guard let dict = parsed as? [String: Any] else { return nil }
        return dict["Entitlements"] as? [String: Any]
    }
}
