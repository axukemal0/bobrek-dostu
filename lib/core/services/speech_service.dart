import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Sesli okuma (TTS) — Türkçe.
class TtsService {
  TtsService() : _tts = FlutterTts();

  final FlutterTts _tts;
  bool _ready = false;
  bool _speaking = false;

  bool get isSpeaking => _speaking;

  Future<void> _prepare() async {
    if (_ready) return;
    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(0.46);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
    _tts.setCompletionHandler(() => _speaking = false);
    _tts.setCancelHandler(() => _speaking = false);
    _ready = true;
  }

  /// Türkçe sesin cihazda yüklü olup olmadığını söyler.
  Future<bool> isTurkishAvailable() async {
    await _prepare();
    try {
      final available = await _tts.isLanguageAvailable('tr-TR');
      return available == true || available == 1;
    } on Object {
      return false;
    }
  }

  Future<void> speak(String text) async {
    await _prepare();
    if (text.trim().isEmpty) return;
    _speaking = true;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    _speaking = false;
    await _tts.stop();
  }
}

/// Sesli komut (STT) — Türkçe.
class SttService {
  SttService() : _stt = SpeechToText();

  final SpeechToText _stt;
  bool _available = false;

  bool get isListening => _stt.isListening;

  Future<bool> init() async {
    if (_available) return true;
    _available = await _stt.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    return _available;
  }

  /// Türkçe dinlemeyi başlatır. Tanınan metni [onResult] ile verir.
  Future<bool> listen({
    required void Function(String text, bool isFinal) onResult,
    Duration listenFor = const Duration(seconds: 20),
  }) async {
    if (!await init()) return false;
    await _stt.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(
        localeId: 'tr_TR',
        partialResults: true,
        cancelOnError: true,
        listenFor: listenFor,
        pauseFor: const Duration(seconds: 4),
      ),
    );
    return true;
  }

  Future<void> stop() => _stt.stop();
  Future<void> cancel() => _stt.cancel();
}

/// Sesli komut yorumlayıcı — SAF fonksiyon, test edilebilir.
///
/// Örnekler:
///   "250 mililitre çay içtim"      -> sıvı 250 mL
///   "iki bardak su"                -> sıvı 400 mL (bardak = 200 mL)
///   "tansiyon 140 90"              -> tansiyon 140/90
///   "kilo 78 buçuk"                -> kilo 78.5
class VoiceCommand {
  const VoiceCommand({
    required this.kind,
    this.fluidMl,
    this.label,
    this.systolic,
    this.diastolic,
    this.weightKg,
  });

  final VoiceCommandKind kind;
  final int? fluidMl;
  final String? label;
  final int? systolic;
  final int? diastolic;
  final double? weightKg;
}

enum VoiceCommandKind { fluid, bloodPressure, weight, unknown }

/// Yaygın Türkçe ölçü birimleri (mL).
const Map<String, int> kVolumeUnitsMl = {
  'bardak': 200,
  'su bardağı': 200,
  'çay bardağı': 100,
  'fincan': 80,
  'kupa': 250,
  'kase': 200,
  'kâse': 200,
  'şişe': 500,
  'litre': 1000,
  'kaşık': 15,
  'yemek kaşığı': 15,
  'tatlı kaşığı': 7,
  'çay kaşığı': 5,
};

VoiceCommand parseVoiceCommand(String raw) {
  final t = raw.toLowerCase().trim();
  if (t.isEmpty) return const VoiceCommand(kind: VoiceCommandKind.unknown);

  // --- tansiyon ---
  if (t.contains('tansiyon') || t.contains('basınç')) {
    final nums = RegExp(r'\d{2,3}')
        .allMatches(t)
        .map((m) => int.parse(m.group(0)!))
        .toList();
    if (nums.length >= 2) {
      return VoiceCommand(
        kind: VoiceCommandKind.bloodPressure,
        systolic: nums[0],
        diastolic: nums[1],
      );
    }
  }

  // --- kilo ---
  if (t.contains('kilo') || t.contains('ağırlık') || t.contains('tartı')) {
    final m = RegExp(r'(\d{2,3})([.,](\d{1,2}))?').firstMatch(t);
    if (m != null) {
      var value = double.parse(m.group(1)!);
      final frac = m.group(3);
      if (frac != null) {
        value += double.parse(frac) / (frac.length == 1 ? 10 : 100);
      } else if (t.contains('buçuk')) {
        value += 0.5;
      }
      return VoiceCommand(kind: VoiceCommandKind.weight, weightKg: value);
    }
  }

  // --- sıvı ---
  final isFluid = t.contains('içtim') ||
      t.contains('mililitre') ||
      t.contains('ml') ||
      kVolumeUnitsMl.keys.any(t.contains);

  if (isFluid) {
    int? ml;

    final mlMatch = RegExp(r'(\d{2,4})\s*(ml|mililitre|mili litre)').firstMatch(t);
    if (mlMatch != null) {
      ml = int.parse(mlMatch.group(1)!);
    } else {
      // Birim + sayı (sayı yazıyla da olabilir).
      for (final entry in kVolumeUnitsMl.entries) {
        if (!t.contains(entry.key)) continue;
        final count = _parseTurkishCount(t) ?? 1;
        ml = (entry.value * count).round();
        break;
      }
      // "500 su içtim" gibi birimsiz sayı.
      ml ??= () {
        final n = RegExp(r'(\d{2,4})').firstMatch(t);
        return n == null ? null : int.parse(n.group(1)!);
      }();
    }

    if (ml != null && ml > 0) {
      return VoiceCommand(
        kind: VoiceCommandKind.fluid,
        fluidMl: ml,
        label: _guessFluidLabel(t),
      );
    }
  }

  return const VoiceCommand(kind: VoiceCommandKind.unknown);
}

/// "iki", "üç buçuk", "yarım" gibi yazıyla sayıları çözer.
double? _parseTurkishCount(String t) {
  const words = {
    'yarım': 0.5,
    'bir': 1.0,
    'iki': 2.0,
    'üç': 3.0,
    'dört': 4.0,
    'beş': 5.0,
    'altı': 6.0,
    'yedi': 7.0,
    'sekiz': 8.0,
    'dokuz': 9.0,
    'on': 10.0,
  };
  final digit = RegExp(r'^(\d+)').firstMatch(t.trim());
  if (digit != null) {
    final base = double.parse(digit.group(1)!);
    return t.contains('buçuk') ? base + 0.5 : base;
  }
  for (final e in words.entries) {
    if (t.contains(e.key)) {
      return t.contains('buçuk') && e.key != 'yarım' ? e.value + 0.5 : e.value;
    }
  }
  return null;
}

String _guessFluidLabel(String t) {
  const labels = {
    'çay': 'Çay',
    'kahve': 'Kahve',
    'su': 'Su',
    'ayran': 'Ayran',
    'çorba': 'Çorba',
    'meyve suyu': 'Meyve suyu',
    'maden suyu': 'Maden suyu',
    'soda': 'Soda',
    'süt': 'Süt',
    'limonata': 'Limonata',
  };
  for (final e in labels.entries) {
    if (t.contains(e.key)) return e.value;
  }
  return 'Sıvı';
}
