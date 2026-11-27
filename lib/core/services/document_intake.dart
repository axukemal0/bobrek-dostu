import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'scanner_service.dart';

/// Kullanıcının getirdiği belgenin türü.
///
/// Fark işlevseldir: GÖRSEL cihaz üstü OCR'den geçebilir (hiçbir şey
/// internete çıkmaz), PDF geçemez — telefonda PDF metin katmanını
/// çözecek bir çözümleyici yok. Bu yüzden PDF yalnız yapay zekaya
/// gönderilerek okunabilir ve kullanıcıya bu açıkça söylenir.
enum IntakeKind {
  /// Kamerayla yeni çekilmiş fotoğraf.
  photo,

  /// Galeriden / Dosyalar'dan seçilmiş görsel.
  image,

  /// PDF belgesi.
  pdf,
}

extension IntakeKindTr on IntakeKind {
  String get labelTr => switch (this) {
        IntakeKind.photo => 'Fotoğraf',
        IntakeKind.image => 'Görsel dosya',
        IntakeKind.pdf => 'PDF belgesi',
      };

  /// Cihaz üstü OCR bu türde çalışır mı?
  bool get supportsOnDeviceOcr => this != IntakeKind.pdf;
}

/// Kullanıcının getirdiği tek bir belge.
class IntakeDocument {
  const IntakeDocument({
    required this.file,
    required this.kind,
    this.displayName,
  });

  final File file;
  final IntakeKind kind;

  /// Dosyadan seçildiyse kullanıcının gördüğü ad.
  final String? displayName;

  bool get isPdf => kind == IntakeKind.pdf;

  String get nameTr =>
      displayName ?? file.uri.pathSegments.lastOrNull ?? kind.labelTr;

  /// Anthropic'e gönderilirken kullanılacak MIME türü.
  /// Tanınmayan bir uzantı için null döner.
  String? get mediaType {
    final lower = file.path.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return null;
  }

  Future<int> sizeBytes() => file.length();
}

/// Belge alma hatası — mesaj doğrudan kullanıcıya gösterilir.
class IntakeFailure implements Exception {
  const IntakeFailure(this.messageTr);

  final String messageTr;

  @override
  String toString() => 'IntakeFailure($messageTr)';
}

/// Kamera · galeri · dosya — üç yol da tek kapıdan geçer.
///
/// Tahlil kağıdı, diyet listesi ve besin etiketi ekranlarının hepsi aynı
/// üç seçeneği sunuyor. Seçim mantığı (hangi uzantılar kabul edilir,
/// dosya ne kadar büyük olabilir, PDF neden farklıdır) tek yerde durur;
/// yoksa her ekran kendi kurallarını uydurur ve biri eksik kalır.
class DocumentIntakeService {
  const DocumentIntakeService(this._scanner);

  final ScannerService _scanner;

  /// Yapay zekaya gönderilebilecek en büyük dosya.
  ///
  /// Anthropic görselleri ~5 MB, belgeleri ~32 MB'a kadar kabul eder.
  /// Fotoğraflar zaten küçültülerek çekilir; sınır dosyadan seçilenler
  /// için vardır.
  static const int maxImageBytes = 5 * 1024 * 1024;
  static const int maxPdfBytes = 20 * 1024 * 1024;

  static const List<String> imageExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  /// Kamerayla belge çeker.
  Future<IntakeDocument?> fromCamera({int maxWidth = 2000}) async {
    final file = await _scanner.captureFromCamera(maxWidth: maxWidth);
    if (file == null) return null;
    return IntakeDocument(file: file, kind: IntakeKind.photo);
  }

  /// Fotoğraf galerisinden görsel seçer.
  Future<IntakeDocument?> fromGallery({int maxWidth = 2000}) async {
    final file = await _scanner.pickFromGallery(maxWidth: maxWidth);
    if (file == null) return null;
    final doc = IntakeDocument(file: file, kind: IntakeKind.image);
    await _checkSize(doc);
    return doc;
  }

  /// Dosyalar uygulamasından PDF ya da görsel seçer.
  ///
  /// iPhone'da bu kapı iCloud Drive'ı, "Dosyalarım"ı ve e-postadan
  /// kaydedilmiş ekleri de kapsar — hastaneden gelen tahlil PDF'i
  /// çoğunlukla oradadır.
  Future<IntakeDocument?> fromFiles({bool allowPdf = true}) async {
    final FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          ...imageExtensions,
          if (allowPdf) 'pdf',
        ],
        withData: false,
      );
    } on Object catch (e) {
      throw IntakeFailure('Dosya seçici açılamadı: $e');
    }

    final path = picked?.files.singleOrNull?.path;
    if (path == null) return null;

    final lower = path.toLowerCase();
    final kind = lower.endsWith('.pdf') ? IntakeKind.pdf : IntakeKind.image;
    if (kind == IntakeKind.pdf && !allowPdf) {
      throw const IntakeFailure(
        'Bu bölümde PDF okunamıyor. Belgenin ekran görüntüsünü alıp '
        'görsel olarak ekleyebilirsin.',
      );
    }

    final doc = IntakeDocument(
      file: File(path),
      kind: kind,
      displayName: picked?.files.singleOrNull?.name,
    );
    if (doc.mediaType == null) {
      throw const IntakeFailure(
        'Bu dosya biçimini okuyamıyorum. JPEG, PNG, WebP ya da PDF dene.',
      );
    }
    await _checkSize(doc);
    return doc;
  }

  Future<void> _checkSize(IntakeDocument doc) async {
    final bytes = await doc.sizeBytes();
    final limit = doc.isPdf ? maxPdfBytes : maxImageBytes;
    if (bytes <= limit) return;
    final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
    throw IntakeFailure(
      doc.isPdf
          ? 'PDF çok büyük ($mb MB). Yalnız tahlil sayfalarını içeren '
              'daha küçük bir PDF ya da sayfaların fotoğrafını dene.'
          : 'Görsel çok büyük ($mb MB). Fotoğrafı yeniden çekersen '
              'uygulama otomatik küçültür.',
    );
  }
}
