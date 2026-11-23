import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../config/app_config.dart';
import 'api_client.dart';

/// Yerel besin kaydı (assets/data/turkish_foods.json).
class LocalFood {
  const LocalFood({
    required this.name,
    required this.category,
    required this.kcal,
    required this.proteinG,
    required this.sodiumMg,
    required this.potassiumMg,
    required this.phosphorusMg,
    required this.fluidMl,
    this.portionG,
    this.portionLabel,
  });

  final String name;
  final String category;

  /// 100 g başına.
  final double kcal;
  final double proteinG;
  final double sodiumMg;
  final double potassiumMg;
  final double phosphorusMg;

  /// Su içeriği (mL/100 g) — sıvı bütçesine katkı.
  final double fluidMl;

  final double? portionG;
  final String? portionLabel;

  static LocalFood fromJson(Map<String, dynamic> j) => LocalFood(
        name: j['n'] as String,
        category: j['c'] as String,
        kcal: (j['kcal'] as num).toDouble(),
        proteinG: (j['p'] as num).toDouble(),
        sodiumMg: (j['na'] as num).toDouble(),
        potassiumMg: (j['k'] as num).toDouble(),
        phosphorusMg: (j['ph'] as num).toDouble(),
        fluidMl: (j['fl'] as num).toDouble(),
        portionG: (j['pg'] as num?)?.toDouble(),
        portionLabel: j['pl'] as String?,
      );
}

/// Barkodla bulunan paketli ürün.
///
/// Eksik besin öğeleri null kalır — SIFIR SAYILMAZ.
class BarcodeProduct {
  const BarcodeProduct({
    required this.barcode,
    required this.name,
    this.brand,
    this.kcal,
    this.proteinG,
    this.sodiumMg,
    this.potassiumMg,
    this.phosphorusMg,
    this.servingG,
    this.missingFieldsTr = const [],
  });

  final String barcode;
  final String name;
  final String? brand;
  final double? kcal;
  final double? proteinG;
  final double? sodiumMg;
  final double? potassiumMg;
  final double? phosphorusMg;
  final double? servingG;

  /// Open Food Facts'te bulunmayan alanların Türkçe adları.
  final List<String> missingFieldsTr;

  String get displayName =>
      brand == null || brand!.isEmpty ? name : '$brand — $name';
}

class FoodService {
  FoodService(this._api);

  final ApiClient _api;

  List<LocalFood>? _cache;
  String? _disclaimer;

  /// Yerel besin tablosunu yükler (bir kez).
  Future<List<LocalFood>> loadLocalFoods() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/turkish_foods.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _disclaimer = json['disclaimerTr'] as String?;
    _cache = (json['foods'] as List)
        .map((f) => LocalFood.fromJson(Map<String, dynamic>.from(f as Map)))
        .toList(growable: false);
    return _cache!;
  }

  Future<String> localDisclaimer() async {
    await loadLocalFoods();
    return _disclaimer ?? 'Değerler yaklaşıktır.';
  }

  /// Türkçe'ye duyarlı besin arama.
  Future<List<LocalFood>> search(String query, {int limit = 30}) async {
    final foods = await loadLocalFoods();
    final q = normalizeTr(query);
    if (q.isEmpty) return foods.take(limit).toList();

    final starts = <LocalFood>[];
    final contains = <LocalFood>[];
    for (final f in foods) {
      final n = normalizeTr(f.name);
      if (n.startsWith(q)) {
        starts.add(f);
      } else if (n.contains(q) || normalizeTr(f.category).contains(q)) {
        contains.add(f);
      }
    }
    return [...starts, ...contains].take(limit).toList();
  }

  Future<List<String>> categories() async {
    final foods = await loadLocalFoods();
    return foods.map((f) => f.category).toSet().toList()..sort();
  }

  /// Barkoddan ürün bilgisi (Open Food Facts).
  Future<BarcodeProduct?> lookupBarcode(String barcode) async {
    final clean = barcode.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length < 8) return null;

    final uri = Uri.parse('${Endpoints.openFoodFacts}/$clean.json').replace(
      queryParameters: {
        'fields': 'product_name,product_name_tr,brands,nutriments,'
            'serving_quantity,quantity',
      },
    );

    final raw = await _api.cachedGet(uri, maxAge: const Duration(days: 30));
    final body = jsonDecode(raw);
    if (body is! Map) return null;
    if (body['status'] == 0 || body['product'] == null) return null;

    final product = Map<String, dynamic>.from(body['product'] as Map);
    final nutriments = product['nutriments'] is Map
        ? Map<String, dynamic>.from(product['nutriments'] as Map)
        : <String, dynamic>{};

    double? num100g(String key) {
      final v = nutriments['${key}_100g'] ?? nutriments[key];
      return v is num ? v.toDouble() : null;
    }

    final name = ((product['product_name_tr'] as String?)?.trim().isNotEmpty ==
                true
            ? product['product_name_tr'] as String
            : product['product_name'] as String?) ??
        'Adsız ürün';

    // Sodyum: OFF 'sodium' gramla, 'salt' tuzla verir.
    double? sodiumMg = num100g('sodium');
    if (sodiumMg != null) {
      sodiumMg *= 1000; // g -> mg
    } else {
      final salt = num100g('salt');
      // Tuz (g) -> sodyum (mg): tuz x 1000 / 2.5
      if (salt != null) sodiumMg = salt * 1000 / 2.5;
    }

    double? potassium = num100g('potassium');
    if (potassium != null && potassium < 10) {
      potassium *= 1000; // g olarak gelmişse mg'a çevir
    }
    double? phosphorus = num100g('phosphorus');
    if (phosphorus != null && phosphorus < 5) {
      phosphorus *= 1000;
    }

    final missing = <String>[
      if (num100g('energy-kcal') == null) 'kalori',
      if (num100g('proteins') == null) 'protein',
      if (sodiumMg == null) 'sodyum',
      if (potassium == null) 'potasyum',
      if (phosphorus == null) 'fosfor',
    ];

    return BarcodeProduct(
      barcode: clean,
      name: name,
      brand: (product['brands'] as String?)?.split(',').first.trim(),
      kcal: num100g('energy-kcal'),
      proteinG: num100g('proteins'),
      sodiumMg: sodiumMg,
      potassiumMg: potassium,
      phosphorusMg: phosphorus,
      servingG: (product['serving_quantity'] as num?)?.toDouble(),
      missingFieldsTr: missing,
    );
  }

  static const String kBarcodeDisclaimerTr =
      'Barkod verisi Open Food Facts\'ten gelir: topluluk katkılı bir '
      'veri tabanıdır. Etiket değerleri eksik veya hatalı olabilir. '
      'Böbrek hastaları için en önemli iki değer olan POTASYUM ve '
      'FOSFOR, çoğu üründe etiketlenmediği için genellikle BOŞ gelir. '
      'Boş gelen değerler sıfır sayılmaz, "bilinmiyor" olarak '
      'gösterilir.';
}

/// Türkçe karakterleri sadeleştirerek arama için normalleştirir.
///
/// Dart'ın toLowerCase()'i Türkçe'de "I" -> "i" yapar ("ı" değil),
/// bu yüzden elle eşleme gerekir.
String normalizeTr(String input) {
  const map = {
    'ı': 'i', 'İ': 'i', 'I': 'i',
    'ş': 's', 'Ş': 's',
    'ğ': 'g', 'Ğ': 'g',
    'ü': 'u', 'Ü': 'u',
    'ö': 'o', 'Ö': 'o',
    'ç': 'c', 'Ç': 'c',
    'â': 'a', 'î': 'i', 'û': 'u',
  };
  final sb = StringBuffer();
  for (final ch in input.split('')) {
    sb.write(map[ch] ?? ch.toLowerCase());
  }
  return sb.toString().trim();
}
