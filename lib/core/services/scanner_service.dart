import 'dart:io';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Barkod ve metin okuma — TAMAMEN CİHAZ ÜSTÜNDE çalışır.
/// Hiçbir görsel internete gönderilmez.
class ScannerService {
  ScannerService();

  final ImagePicker _picker = ImagePicker();
  BarcodeScanner? _barcodeScanner;
  TextRecognizer? _textRecognizer;

  /// Kamera ile fotoğraf çeker.
  Future<File?> captureFromCamera({int maxWidth = 1600}) async {
    final shot = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth.toDouble(),
      imageQuality: 88,
    );
    return shot == null ? null : File(shot.path);
  }

  /// Galeriden fotoğraf seçer.
  Future<File?> pickFromGallery({int maxWidth = 1600}) async {
    final shot = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth.toDouble(),
      imageQuality: 88,
    );
    return shot == null ? null : File(shot.path);
  }

  /// Görseldeki barkodları okur (cihaz üstü).
  Future<List<String>> scanBarcodes(File image) async {
    _barcodeScanner ??= BarcodeScanner(
      formats: [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upca,
        BarcodeFormat.upce,
        BarcodeFormat.code128,
      ],
    );
    final input = InputImage.fromFile(image);
    final results = await _barcodeScanner!.processImage(input);
    return results
        .map((b) => b.rawValue)
        .whereType<String>()
        .where((v) => v.trim().isNotEmpty)
        .toList(growable: false);
  }

  /// Görseldeki metni okur (cihaz üstü OCR).
  ///
  /// Latin alfabesi tanıyıcısı kullanılır; Türkçe karakterlerde
  /// yanlış okuma olabilir, bu yüzden sonucu kullanıcı ONAYLAR.
  Future<RecognizedTextResult> recognizeText(File image) async {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    final input = InputImage.fromFile(image);
    final result = await _textRecognizer!.processImage(input);
    return RecognizedTextResult(
      fullText: result.text,
      lines: [
        for (final block in result.blocks)
          for (final line in block.lines) line.text,
      ],
    );
  }

  Future<void> dispose() async {
    await _barcodeScanner?.close();
    await _textRecognizer?.close();
    _barcodeScanner = null;
    _textRecognizer = null;
  }
}

class RecognizedTextResult {
  const RecognizedTextResult({required this.fullText, required this.lines});

  final String fullText;
  final List<String> lines;

  bool get isEmpty => fullText.trim().isEmpty;
}

/// OCR metninden tahlil değerleri çıkarır — SAF fonksiyon, test edilebilir.
///
/// Kullanıcı sonucu MUTLAKA onaylar; bu yüzden fonksiyon "yakalayabildiğini"
/// döner, kesinlik iddia etmez.
class ParsedLabValue {
  const ParsedLabValue({
    required this.rawLine,
    required this.analyteLabel,
    required this.value,
    required this.unit,
    this.refMin,
    this.refMax,
    this.analyteKey,
  });

  final String rawLine;
  final String analyteLabel;
  final double value;
  final String unit;
  final double? refMin;
  final double? refMax;

  /// Klinik tanım anahtarı ('lab_hemoglobin' vb.), tanınabildiyse.
  final String? analyteKey;
}

/// Türk laboratuvar raporlarında sık görülen analit adları.
const Map<String, ({String key, String label, String unit})> kLabAliases = {
  'hemoglobin': (key: 'lab_hemoglobin', label: 'Hemoglobin', unit: 'g/dL'),
  'hgb': (key: 'lab_hemoglobin', label: 'Hemoglobin', unit: 'g/dL'),
  'hb': (key: 'lab_hemoglobin', label: 'Hemoglobin', unit: 'g/dL'),
  'ferritin': (key: 'lab_ferritin', label: 'Ferritin', unit: 'ng/mL'),
  'transferrin saturasyonu':
      (key: 'lab_tsat', label: 'TSAT', unit: '%'),
  'tsat': (key: 'lab_tsat', label: 'TSAT', unit: '%'),
  'fosfor': (key: 'lab_phosphate', label: 'Serum fosfat', unit: 'mg/dL'),
  'fosfat': (key: 'lab_phosphate', label: 'Serum fosfat', unit: 'mg/dL'),
  'phosphorus': (key: 'lab_phosphate', label: 'Serum fosfat', unit: 'mg/dL'),
  'kalsiyum': (key: 'lab_calcium', label: 'Kalsiyum', unit: 'mg/dL'),
  'calcium': (key: 'lab_calcium', label: 'Kalsiyum', unit: 'mg/dL'),
  'parathormon': (key: 'lab_pth', label: 'PTH', unit: 'pg/mL'),
  'pth': (key: 'lab_pth', label: 'PTH', unit: 'pg/mL'),
  'potasyum': (key: 'lab_potassium', label: 'Potasyum', unit: 'mEq/L'),
  'potassium': (key: 'lab_potassium', label: 'Potasyum', unit: 'mEq/L'),
  'bikarbonat':
      (key: 'lab_bicarbonate', label: 'Bikarbonat', unit: 'mmol/L'),
  'albumin': (key: 'lab_albumin', label: 'Albümin', unit: 'g/dL'),
  'albümin': (key: 'lab_albumin', label: 'Albümin', unit: 'g/dL'),
  'kreatinin': (key: 'lab_creatinine', label: 'Kreatinin', unit: 'mg/dL'),
  'creatinine': (key: 'lab_creatinine', label: 'Kreatinin', unit: 'mg/dL'),
  'egfr': (key: 'lab_egfr', label: 'eGFR', unit: 'mL/dk/1,73m²'),
  'gfr': (key: 'lab_egfr', label: 'eGFR', unit: 'mL/dk/1,73m²'),
  'sodyum': (key: 'lab_potassium', label: 'Sodyum', unit: 'mEq/L'),
  'üre': (key: 'lab_creatinine', label: 'Üre', unit: 'mg/dL'),
};

/// OCR satırlarından tahlil değerleri çıkarır.
List<ParsedLabValue> parseLabLines(List<String> lines) {
  final out = <ParsedLabValue>[];

  for (final line in lines) {
    final normalized = line.toLowerCase().replaceAll(',', '.');

    // Analit adını bul.
    String? matchedAlias;
    for (final alias in kLabAliases.keys) {
      if (normalized.contains(alias)) {
        // En uzun eşleşmeyi tercih et ("hemoglobin" > "hb").
        if (matchedAlias == null || alias.length > matchedAlias.length) {
          matchedAlias = alias;
        }
      }
    }
    if (matchedAlias == null) continue;

    final meta = kLabAliases[matchedAlias]!;

    // Satırdaki sayıları topla.
    final numbers = RegExp(r'\d+\.?\d*')
        .allMatches(normalized)
        .map((m) => double.tryParse(m.group(0)!))
        .whereType<double>()
        .toList();
    if (numbers.isEmpty) continue;

    // İlk sayı sonuç; "4.5 - 6.0" biçiminde referans aralığı varsa yakala.
    final value = numbers.first;
    double? refMin;
    double? refMax;

    final rangeMatch =
        RegExp(r'(\d+\.?\d*)\s*[-–]\s*(\d+\.?\d*)').allMatches(normalized);
    for (final rm in rangeMatch) {
      final a = double.tryParse(rm.group(1)!);
      final b = double.tryParse(rm.group(2)!);
      if (a == null || b == null || a >= b) continue;
      // Aralık, sonucun kendisi olmasın.
      if (a == value && numbers.length < 3) continue;
      refMin = a;
      refMax = b;
      break;
    }

    out.add(
      ParsedLabValue(
        rawLine: line,
        analyteLabel: meta.label,
        analyteKey: meta.key,
        value: value,
        unit: meta.unit,
        refMin: refMin,
        refMax: refMax,
      ),
    );
  }

  // Aynı analit birden çok satırda yakalanırsa ilkini tut.
  final seen = <String>{};
  return out
      .where((v) => seen.add(v.analyteLabel))
      .toList(growable: false);
}

const String kOcrDisclaimerTr =
    'Fotoğraftan metin okuma telefonun içinde yapılır, internete '
    'gönderilmez. Ancak okuma HATA YAPABİLİR: virgül/nokta karışması, '
    'Türkçe karakterler ve bozuk baskı yanlış sonuç verebilir. '
    'Bu yüzden her değeri kaydetmeden önce SEN ONAYLARSIN.';
