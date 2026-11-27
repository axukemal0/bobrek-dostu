import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Uygulama ÖN PLANDAYKEN de bildirim görünsün.
    // flutter_local_notifications bunun için merkezin delegesinin
    // atanmasını ister; atanmazsa uygulama açıkken ilaç hatırlatması
    // sessizce yutulur.
    UNUserNotificationCenter.current().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Cihaz üstü OCR: Apple Vision (bkz. TextRecognition.swift).
    TextRecognition.register(
      with: engineBridge.pluginRegistry.registrar(forPlugin: "TextRecognition")!
    )

    // Sağlık (HealthKit) hakkının bu derlemede olup olmadığını söyler;
    // ücretsiz imzalı derlemede Apple Watch verisi okunamaz ve bunu
    // kullanıcıya "izin vermedin" demeden açıklayabilmek gerekiyor.
    HealthKitSupport.register(
      with: engineBridge.pluginRegistry.registrar(forPlugin: "HealthKitSupport")!
    )
  }
}
