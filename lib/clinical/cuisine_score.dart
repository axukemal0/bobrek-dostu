/// Mutfak türüne göre böbrek diyetine UYGUNLUK PUANI.
///
/// !!! ÖNEMLİ SINIR !!!
/// Bu puan menüye DEĞİL, yalnızca OSM'deki `cuisine` etiketine dayanır.
/// Hiçbir restoranın gerçek menüsü, porsiyonu veya tuz kullanımı
/// bilinmemektedir. Puan "genel öneri"dir; arayüzde her zaman
/// "menü doğrulanmadı" etiketiyle gösterilir.
///
/// Puan mantığı: tipik olarak yüksek sodyum (salamura, turşu, soslu),
/// yüksek fosfor (işlenmiş et, eritme peynir, kola) ve yüksek potasyum
/// (domates salçası, patates, kuru baklagil) içeren mutfaklar düşük
/// puan alır. Taze ızgara/fırın ağırlıklı mutfaklar yüksek puan alır.
library;

import '../core/i18n/i18n.dart';

enum CuisineSuitability { good, moderate, caution, unknown }

extension CuisineSuitabilityTr on CuisineSuitability {
  String get labelTr => switch (this) {
        CuisineSuitability.good => 'Genelde uygun',
        CuisineSuitability.moderate => 'Seçerek uygun',
        CuisineSuitability.caution => 'Dikkatli ol',
        CuisineSuitability.unknown => 'Bilinmiyor',
      };

  /// 0-100 arası gösterim puanı (arayüzdeki çubuk için).
  int get score => switch (this) {
        CuisineSuitability.good => 75,
        CuisineSuitability.moderate => 50,
        CuisineSuitability.caution => 25,
        CuisineSuitability.unknown => 0,
      };
}

class CuisineAdvice {
  const CuisineAdvice({
    required this.suitability,
    required this.reasonTr,
    required this.tipsTr,
  });

  final CuisineSuitability suitability;
  final String reasonTr;

  /// Sipariş verirken işe yarayacak somut öneriler.
  final List<String> tipsTr;
}

/// OSM `cuisine` etiketi -> öneri.
///
/// Etiketler ';' ile çoklu olabilir (örn. "kebab;turkish").
/// En DÜŞÜK puanlı eşleşme kullanılır (güvenli taraf).
CuisineAdvice adviseCuisine(String? rawCuisine, {String? amenity}) {
  if (rawCuisine == null || rawCuisine.trim().isEmpty) {
    return CuisineAdvice(
      suitability: CuisineSuitability.unknown,
      reasonTr: amenity == 'cafe'
          ? 'Mutfak türü etiketlenmemiş. Kafelerde genellikle '
              'tatlı, tost ve paketli ürün ağırlıklıdır.'
          : 'Bu mekanın mutfak türü OpenStreetMap\'te '
              'etiketlenmemiş. Menü hakkında bir şey bilemiyoruz.',
      tipsTr: const [
        'Menüyü fotoğraflayıp yapay zekaya analiz ettirebilirsin.',
        'Garsona "tuzsuz pişirilebilir mi?" diye sormak çoğu yerde işe yarar.',
      ],
    );
  }

  final tags = rawCuisine
      .toLowerCase()
      .split(RegExp(r'[;,]'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty);

  CuisineAdvice? worst;
  for (final tag in tags) {
    final advice = _adviceFor(tag);
    if (advice == null) continue;
    if (worst == null ||
        advice.suitability.score < worst.suitability.score) {
      worst = advice;
    }
  }

  return worst ??
      CuisineAdvice(
        suitability: CuisineSuitability.unknown,
        reasonTr: tf(
                    'Mutfak türü ("{0}") listemizde yok. Genel öneri '
                    'veremiyoruz.',
                    [rawCuisine],
                  ),
        tipsTr: const [
          'Menüyü fotoğraflayıp yapay zekaya analiz ettirebilirsin.',
        ],
      );
}

CuisineAdvice? _adviceFor(String tag) {
  // --- Genelde uygun: taze, ızgara/fırın ağırlıklı ---
  const good = {
    'grill', 'barbecue', 'steak_house', 'fish', 'seafood', 'chicken',
    'salad', 'vegetarian', 'vegan', 'breakfast', 'soup',
  };
  if (good.contains(tag)) {
    return const CuisineAdvice(
      suitability: CuisineSuitability.good,
      reasonTr: 'Izgara/fırın ve taze malzeme ağırlıklı mutfaklarda '
          'tuzu ve sosu kontrol etmek kolaydır.',
      tipsTr: [
        'Izgara balık veya tavuk iste, sos ve marinat olmadan.',
        'Garnitür olarak pilav/patates yerine haşlanmış sebze iste.',
        'Masadaki tuzluğa dokunma; limon ve baharat tercih et.',
      ],
    );
  }

  // --- Seçerek uygun ---
  const moderate = {
    'turkish', 'anatolian', 'ottoman', 'mediterranean', 'italian',
    'french', 'international', 'regional', 'asian', 'japanese',
    'sushi', 'indian', 'home_made', 'lokanta', 'coffee_shop', 'cafe',
    'bakery', 'dessert', 'ice_cream',
  };
  if (moderate.contains(tag)) {
    return const CuisineAdvice(
      suitability: CuisineSuitability.moderate,
      reasonTr: 'Bu mutfakta böbrek diyetine uygun seçenek vardır ama '
          'tuz, salça ve peynir kullanımı yüksek olabilir.',
      tipsTr: [
        'Çorbayı atla ya da "tuzsuz" iste: hazır çorba bazları çok tuzludur.',
        'Salçalı/soslu yemek yerine ızgara veya fırın seç.',
        'Turşu, zeytin, salamura peynir ve meze tabağını sınırla.',
        'Pilav/makarna porsiyonunu küçült, protein hedefini unutma.',
      ],
    );
  }

  // --- Dikkatli ol: tipik olarak yüksek sodyum/fosfor ---
  const caution = {
    'kebab', 'pizza', 'burger', 'fast_food', 'fried_chicken',
    'sandwich', 'chinese', 'thai', 'korean', 'vietnamese',
    'mexican', 'tex-mex', 'american', 'pita', 'doner', 'lahmacun',
    'pide', 'noodle', 'ramen', 'sausage', 'hot_dog', 'tapas',
    'deli', 'buffet',
  };
  if (caution.contains(tag)) {
    return const CuisineAdvice(
      suitability: CuisineSuitability.caution,
      reasonTr: 'Bu tür mutfaklarda tipik olarak sodyum çok yüksektir; '
          'işlenmiş et ve eritme peynir fosfor katkı maddesi içerir. '
          'Soya sosu ve hazır soslar sodyumu hızla yükseltir.',
      tipsTr: [
        'Soya sosu, balık sosu ve hazır sosları istemeden sipariş et.',
        'İşlenmiş et (sucuk, salam, sosis, pastırma) ve eritme peyniri atla.',
        'Porsiyonun yarısını paket yaptırmak hem sodyumu hem fosforu yarıya indirir.',
        'Kola ve koyu renkli gazlı içecekler fosforik asit içerir — ayran da tuzlu. Su iyi seçim.',
      ],
    );
  }

  return null;
}

/// Bir mutfak türü için "menü doğrulanmadı" etiketinin metni.
const String kMenuNotVerifiedTr =
    'Menü doğrulanmadı — bu öneri yalnızca mutfak türüne dayanır, '
    'bu restoranın gerçek menüsüne değil.';
