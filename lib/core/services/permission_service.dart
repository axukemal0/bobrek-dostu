import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';

/// Uygulamanın istediği izinler ve her birinin SADE TÜRKÇE gerekçesi.
///
/// Kural: izinler topluca istenmez. Her izin, o özelliğe ilk
/// girildiğinde, ne için gerektiği söylenerek TEK TEK istenir.
enum AppPermission {
  notifications,
  exactAlarm,
  location,
  camera,
  microphone,
  sms,
  activityRecognition,
  healthConnect,
}

class PermissionInfo {
  const PermissionInfo({
    required this.permission,
    required this.titleTr,
    required this.whyTr,
    required this.featureTr,
    required this.optional,
  });

  final AppPermission permission;
  final String titleTr;

  /// Sade Türkçe gerekçe — izin ekranında birebir gösterilir.
  final String whyTr;

  /// Hangi özellik için.
  final String featureTr;

  /// İzin verilmezse uygulama çalışmaya devam eder mi?
  final bool optional;
}

const List<PermissionInfo> kPermissionInfos = [
  PermissionInfo(
    permission: AppPermission.notifications,
    titleTr: 'Bildirim izni',
    featureTr: 'İlaç ve randevu hatırlatmaları',
    whyTr: 'İlaç saatlerini ve diyaliz/kontrol randevularını zamanında '
        'hatırlatabilmek için bildirim göndermem gerekiyor. '
        'İzin vermezsen hatırlatma alamazsın; uygulamanın geri kalanı '
        'çalışmaya devam eder.',
    optional: true,
  ),
  PermissionInfo(
    permission: AppPermission.exactAlarm,
    titleTr: 'Tam zamanlı alarm izni',
    featureTr: 'İlaç saatinin kaçmaması',
    whyTr: 'Android pil tasarrufu, normal hatırlatmaları dakikalarca '
        'geciktirebilir. İlaç saatinin tam dakikasında uyarı '
        'verebilmem için bu izne ihtiyacım var. '
        'İzin vermezsen hatırlatmalar gelir ama gecikebilir.',
    optional: true,
  ),
  PermissionInfo(
    permission: AppPermission.location,
    titleTr: 'Konum izni',
    featureTr: 'Hava durumu, yakın restoranlar, acil durum butonu',
    whyTr: 'Üç şey için kullanıyorum: (1) bulunduğun yerin hava, UV ve '
        'hava kalitesi bilgisi, (2) yakındaki restoranları bulmak, '
        '(3) acil durum butonuna bastığında konumunu acil kişilerine '
        'gönderebilmek. Konumun telefonda kalır; hiçbir sunucuya '
        'kimliğinle birlikte gönderilmez.',
    optional: true,
  ),
  PermissionInfo(
    permission: AppPermission.camera,
    titleTr: 'Kamera izni',
    featureTr: 'Barkod okuma, etiket ve tahlil fotoğrafı, yemek analizi',
    whyTr: 'Ürün barkodunu okumak, besin etiketini ve tahlil kağıdını '
        'metne çevirmek, yemek fotoğrafını analiz etmek için kamera '
        'gerekiyor. Barkod ve metin okuma TELEFONUN İÇİNDE yapılır, '
        'internete gitmez. Yemek analizi ve tahlil fotoğrafı '
        'analizi için fotoğraf yapay zekaya gönderilir — bunu her '
        'seferinde ayrıca onaylarsın.',
    optional: true,
  ),
  PermissionInfo(
    permission: AppPermission.microphone,
    titleTr: 'Mikrofon izni',
    featureTr: 'Sesli komut ve sesle kayıt',
    whyTr: 'Yazmak yerine konuşarak kayıt yapabilmen için mikrofon '
        'gerekiyor (örn. "250 mililitre çay içtim"). Ses tanıma '
        'Android\'in kendi servisiyle yapılır.',
    optional: true,
  ),
  PermissionInfo(
    permission: AppPermission.sms,
    titleTr: 'SMS gönderme izni',
    featureTr: 'Acil durumda acil kişilere otomatik mesaj',
    whyTr: 'Acil durum butonuna bastığında ya da bir ölçüm alarm '
        'eşiğini aştığında acil kişilerine konum ve kritik bilgilerini '
        'SMS ile gönderebilmem için gerekiyor. '
        'İzin VERMEZSEN de çalışır: mesaj hazırlanır, gönder tuşuna '
        'sen basarsın. Otomatik gönderim ayrıca ayarlardan '
        'açılmalıdır — varsayılan olarak KAPALIDIR.',
    optional: true,
  ),
  PermissionInfo(
    permission: AppPermission.activityRecognition,
    titleTr: 'Hareket/adım izni',
    featureTr: 'Adım sayısı takibi',
    whyTr: 'Günlük adım sayını okuyabilmek için gerekiyor. '
        'Düzenli hafif hareket böbrek hastalığında genel sağlığa '
        'iyi gelir. İzin vermezsen adım kartı boş görünür.',
    optional: true,
  ),
  PermissionInfo(
    permission: AppPermission.healthConnect,
    titleTr: 'Health Connect izinleri',
    featureTr: 'Akıllı saat verisi (nabız, tansiyon, uyku, SpO₂)',
    whyTr: 'Akıllı saatinin ölçtüğü nabız, tansiyon, adım, uyku ve '
        'SpO₂ verilerini Health Connect üzerinden OKUMAK için '
        'gerekiyor. Uygulama Health Connect\'e hiçbir şey YAZMAZ. '
        'Verilerin telefonda kalır.',
    optional: true,
  ),
];

/// iOS'ta sağlık izni Health Connect'ten değil, iPhone'un Sağlık
/// uygulamasından gelir. Aynı metni iki platforma göstermek iPhone
/// kullanıcısını var olmayan bir Android servisini aramaya
/// gönderiyordu.
const PermissionInfo _healthInfoIos = PermissionInfo(
  permission: AppPermission.healthConnect,
  titleTr: 'Sağlık verisi izni',
  featureTr: 'Apple Watch verisi (nabız, EKG, uyku, SpO₂)',
  whyTr: 'Apple Watch\'unun ölçtüğü nabız, adım, uyku, SpO₂ ve EKG '
      'kayıtlarını iPhone\'un Sağlık uygulamasından OKUMAK için '
      'gerekiyor. Uygulama Sağlık\'a hiçbir şey YAZMAZ ve verilerin '
      'telefondan çıkmaz. İzin ekranında istediğin veri türlerini tek '
      'tek açabilirsin.',
  optional: true,
);

PermissionInfo permissionInfo(AppPermission p) {
  if (p == AppPermission.healthConnect && Platform.isIOS) {
    return _healthInfoIos;
  }
  return kPermissionInfos.firstWhere((i) => i.permission == p);
}

/// İzin durumu.
enum AppPermissionStatus { granted, denied, permanentlyDenied, unavailable }

class PermissionService {
  const PermissionService();

  Permission? _map(AppPermission p) => switch (p) {
        AppPermission.notifications => Permission.notification,
        AppPermission.exactAlarm => Permission.scheduleExactAlarm,
        AppPermission.location => Permission.locationWhenInUse,
        AppPermission.camera => Permission.camera,
        AppPermission.microphone => Permission.microphone,
        AppPermission.sms => Permission.sms,
        AppPermission.activityRecognition => Permission.activityRecognition,
        // Health Connect izinleri `health` paketiyle ayrı istenir.
        AppPermission.healthConnect => null,
      };

  Future<AppPermissionStatus> status(AppPermission p) async {
    final handle = _map(p);
    if (handle == null) return AppPermissionStatus.unavailable;
    final s = await handle.status;
    return _convert(s);
  }

  /// İzni ister. Çağıran taraf ÖNCE gerekçeyi göstermiş olmalıdır.
  Future<AppPermissionStatus> request(AppPermission p) async {
    final handle = _map(p);
    if (handle == null) return AppPermissionStatus.unavailable;
    final s = await handle.request();
    return _convert(s);
  }

  static AppPermissionStatus _convert(PermissionStatus s) {
    if (s.isGranted || s.isLimited || s.isProvisional) {
      return AppPermissionStatus.granted;
    }
    if (s.isPermanentlyDenied) return AppPermissionStatus.permanentlyDenied;
    if (s.isRestricted) return AppPermissionStatus.unavailable;
    return AppPermissionStatus.denied;
  }

  Future<bool> openSettings() => openAppSettings();
}
