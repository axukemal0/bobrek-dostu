import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/config/ai_config.dart';
import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/api_client.dart';
import '../../core/services/food_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/scanner_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/responsive.dart';
import '../home/home_screen.dart' show showPermissionDialog;
import 'barcode_scanner_view.dart';
import 'meal_vision_parser.dart';
import 'nutrition_label_parser.dart';

Future<void> showAddFoodSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Kök gezginde açılır: alt gezinme çubuğunun ÜSTÜNÜ kaplar.
    // Aksi hâlde sayfa içeriği çubuğun altında kesiliyordu ve odaklanılmış
    // bir iş için yarım bir pencere gibi duruyordu.
    useRootNavigator: true,
    builder: (context) => const _AddFoodSheet(),
  );
}

class _AddFoodSheet extends ConsumerStatefulWidget {
  const _AddFoodSheet();

  @override
  ConsumerState<_AddFoodSheet> createState() => _AddFoodSheetState();
}

enum _Mode { search, barcode, label, photo, manual }

class _AddFoodSheetState extends ConsumerState<_AddFoodSheet> {
  _Mode _mode = _Mode.search;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final p = context.palette;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              r.pagePadding,
              r.gapMd,
              r.pagePadding,
              r.gapSm,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Yemek ekle',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    TapIcon(
                      icon: Icons.close_rounded,
                      semanticLabel: 'Kapat',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: r.gapSm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final m in _Mode.values)
                        Padding(
                          padding: EdgeInsets.only(right: r.gapXs),
                          child: ChoiceChip(
                            avatar: Icon(_iconOf(m), size: 17),
                            label: Text(_labelOf(m)),
                            selected: _mode == m,
                            onSelected: (_) => setState(() => _mode = m),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: p.divider),
          Expanded(
            child: switch (_mode) {
              _Mode.search => _SearchTab(scrollController: scrollController),
              _Mode.barcode => const _BarcodeTab(),
              _Mode.label => const _LabelOcrTab(),
              _Mode.photo => const _PhotoTab(),
              _Mode.manual => const _ManualTab(),
            },
          ),
        ],
      ),
    );
  }

  static IconData _iconOf(_Mode m) => switch (m) {
        _Mode.search => Icons.search_rounded,
        _Mode.barcode => Icons.qr_code_scanner_rounded,
        _Mode.label => Icons.text_snippet_outlined,
        _Mode.photo => Icons.photo_camera_outlined,
        _Mode.manual => Icons.edit_outlined,
      };

  static String _labelOf(_Mode m) => switch (m) {
        _Mode.search => 'Ara',
        _Mode.barcode => 'Barkod',
        _Mode.label => 'Etiket',
        _Mode.photo => 'Fotoğraf',
        _Mode.manual => 'Elle',
      };
}

// ===========================================================================
// ARAMA
// ===========================================================================
class _SearchTab extends ConsumerStatefulWidget {
  const _SearchTab({required this.scrollController});

  final ScrollController scrollController;

  @override
  ConsumerState<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<_SearchTab> {
  final _query = TextEditingController();
  List<LocalFood> _results = const [];
  String? _disclaimer;

  @override
  void initState() {
    super.initState();
    _search('');
    ref
        .read(foodServiceProvider)
        .localDisclaimer()
        .then((d) => mounted ? setState(() => _disclaimer = d) : null);
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    final res = await ref.read(foodServiceProvider).search(q);
    if (mounted) setState(() => _results = res);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(r.pagePadding),
          child: TextField(
            controller: _query,
            autofocus: false,
            onChanged: _search,
            decoration: const InputDecoration(
              hintText: 'Örn. mercimek çorbası, beyaz peynir…',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            controller: widget.scrollController,
            padding: EdgeInsets.fromLTRB(
              r.pagePadding,
              0,
              r.pagePadding,
              r.gapXl,
            ),
            itemCount: _results.length + 1,
            separatorBuilder: (_, _) => SizedBox(height: r.gapSm),
            itemBuilder: (context, i) {
              if (i == _results.length) {
                return Padding(
                  padding: EdgeInsets.only(top: r.gapMd),
                  child: Text(
                    _disclaimer ?? '',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              }
              final f = _results[i];
              return NeuCard(
                padding: EdgeInsets.all(r.gapMd),
                onTap: () => _openPortion(context, f),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.name,
                            style:
                                Theme.of(context).textTheme.titleSmall,
                          ),
                          SizedBox(height: r.s(2)),
                          Text(
                            '${f.category} · 100 g: '
                            '${f.kcal.round()} kcal, '
                            'Na ${f.sodiumMg.round()}, '
                            'K ${f.potassiumMg.round()}, '
                            'P ${f.phosphorusMg.round()} mg',
                            style:
                                Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    const ApproximateBadge(),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openPortion(BuildContext context, LocalFood food) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _PortionSheet(food: food),
    );
  }
}

/// Porsiyon seçme + kaydetme.
class _PortionSheet extends ConsumerStatefulWidget {
  const _PortionSheet({required this.food});

  final LocalFood food;

  @override
  ConsumerState<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends ConsumerState<_PortionSheet> {
  late final TextEditingController _grams = TextEditingController(
    text: (widget.food.portionG ?? 100).toStringAsFixed(0),
  );
  String? _mealType;

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final grams = parseLocaleNumber(_grams.text) ?? 100;
    final f = widget.food;
    final factor = grams / 100.0;
    final db = ref.read(databaseProvider);
    final day = ref.read(selectedDayProvider);
    final now = DateTime.now();

    await db.into(db.foodLogRows).insert(
          FoodLogRowsCompanion.insert(
            label: f.name,
            grams: grams,
            kcal: Value(f.kcal * factor),
            proteinG: Value(f.proteinG * factor),
            sodiumMg: Value(f.sodiumMg * factor),
            potassiumMg: Value(f.potassiumMg * factor),
            phosphorusMg: Value(f.phosphorusMg * factor),
            fluidMl: Value(f.fluidMl * factor),
            mealType: Value(_mealType),
            origin: const Value('local'),
            consumedAt: DateTime(
              day.year,
              day.month,
              day.day,
              now.hour,
              now.minute,
            ),
          ),
        );
    if (mounted) {
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final f = widget.food;
    final grams = parseLocaleNumber(_grams.text) ?? 100;
    final factor = grams / 100.0;

    return Padding(
      padding: EdgeInsets.only(
        left: r.pagePadding,
        right: r.pagePadding,
        top: r.gapLg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + r.gapLg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(f.name, style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: r.gapMd),
            LabeledField(
              label: 'Miktar',
              hint: f.portionLabel == null
                  ? null
                  : 'Tipik porsiyon: ${f.portionLabel}',
              child: NumberField(
                controller: _grams,
                suffix: 'g',
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(height: r.gapMd),
            LabeledField(
              label: 'Öğün',
              child: ChipSelector<String>(
                options: const [
                  'Kahvaltı',
                  'Öğle',
                  'Akşam',
                  'Ara öğün',
                ],
                selected: _mealType,
                labelOf: (s) => s,
                onSelected: (s) => setState(() => _mealType = s),
              ),
            ),
            SizedBox(height: r.gapLg),
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Bu porsiyonda',
                          style:
                              Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const ApproximateBadge(),
                    ],
                  ),
                  SizedBox(height: r.gapSm),
                  for (final line in [
                    'Enerji: ${(f.kcal * factor).round()} kcal',
                    'Protein: ${(f.proteinG * factor).toStringAsFixed(1)} g',
                    'Sodyum: ${(f.sodiumMg * factor).round()} mg',
                    'Potasyum: ${(f.potassiumMg * factor).round()} mg',
                    'Fosfor: ${(f.phosphorusMg * factor).round()} mg',
                    'Sıvı katkısı: ${(f.fluidMl * factor).round()} mL',
                  ])
                    Text(
                      line,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
            SizedBox(height: r.gapLg),
            NeuButton(
              label: 'Kaydet',
              icon: Icons.check_rounded,
              expanded: true,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// BARKOD
// ===========================================================================
class _BarcodeTab extends ConsumerStatefulWidget {
  const _BarcodeTab();

  @override
  ConsumerState<_BarcodeTab> createState() => _BarcodeTabState();
}

class _BarcodeTabState extends ConsumerState<_BarcodeTab> {
  bool _busy = false;
  String? _statusTr;
  BarcodeProduct? _product;
  final _manualBarcode = TextEditingController();
  final _grams = TextEditingController(text: '100');

  @override
  void dispose() {
    _manualBarcode.dispose();
    _grams.dispose();
    super.dispose();
  }

  /// Canlı tarayıcıyı açar.
  ///
  /// Önceden burada fotoğraf çekilip o tek kare taranıyordu; barkod net
  /// çıkmazsa okunmuyordu. Artık kamera akışı sürekli taranıyor.
  Future<void> _scan() async {
    final granted = await _ensureCamera();
    if (!granted || !mounted) return;

    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const BarcodeScannerView(),
        fullscreenDialog: true,
      ),
    );
    if (code == null || !mounted) return;
    await _lookup(code);
  }

  /// Galeriden seçilen fotoğrafta barkod arar (ambalajın fotoğrafı
  /// önceden çekilmişse).
  Future<void> _scanFromGallery() async {
    setState(() {
      _busy = true;
      _statusTr = 'Fotoğraftaki barkod aranıyor (telefonun içinde)…';
      _product = null;
    });
    try {
      final scanner = ref.read(scannerServiceProvider);
      final file = await scanner.pickFromGallery();
      if (file == null) {
        if (mounted) {
          setState(() {
            _busy = false;
            _statusTr = null;
          });
        }
        return;
      }
      final codes = await scanner.scanBarcodes(file);
      if (!mounted) return;
      if (codes.isEmpty) {
        setState(() {
          _busy = false;
          _statusTr = 'Bu fotoğrafta barkod bulunamadı. Canlı taramayı dene '
              'ya da numarayı elle yaz.';
        });
        return;
      }
      await _lookup(codes.first);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _statusTr = 'Okuma başarısız: $e';
        });
      }
    }
  }

  Future<bool> _ensureCamera() async {
    final service = ref.read(permissionServiceProvider);
    if (await service.status(AppPermission.camera) ==
        AppPermissionStatus.granted) {
      return true;
    }
    if (!mounted) return false;
    final ok = await showPermissionDialog(
      context,
      permissionInfo(AppPermission.camera),
    );
    if (!ok) return false;
    return await service.request(AppPermission.camera) ==
        AppPermissionStatus.granted;
  }

  Future<void> _lookup(String code) async {
    setState(() {
      _busy = true;
      _statusTr = 'Ürün aranıyor (Open Food Facts)…';
    });
    try {
      final product =
          await ref.read(foodServiceProvider).lookupBarcode(code);
      if (!mounted) return;
      if (product == null) {
        setState(() {
          _busy = false;
          _statusTr = 'Bu barkod ($code) Open Food Facts\'te bulunamadı. '
              '"Elle gir" sekmesinden etiket değerlerini yazabilirsin.';
        });
        return;
      }
      setState(() {
        _busy = false;
        _statusTr = null;
        _product = product;
        _grams.text = (product.servingG ?? 100).toStringAsFixed(0);
      });
    } on ServiceFailure catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _statusTr = e.messageTr;
        });
      }
    }
  }

  Future<void> _save() async {
    final product = _product;
    if (product == null) return;
    final grams = parseLocaleNumber(_grams.text) ?? 100;
    final factor = grams / 100.0;
    final db = ref.read(databaseProvider);
    final day = ref.read(selectedDayProvider);
    final now = DateTime.now();

    double? scale(double? v) => v == null ? null : v * factor;

    await db.into(db.foodLogRows).insert(
          FoodLogRowsCompanion.insert(
            label: product.displayName,
            grams: grams,
            kcal: Value(scale(product.kcal)),
            proteinG: Value(scale(product.proteinG)),
            sodiumMg: Value(scale(product.sodiumMg)),
            potassiumMg: Value(scale(product.potassiumMg)),
            phosphorusMg: Value(scale(product.phosphorusMg)),
            origin: const Value('off'),
            note: Value(
              product.missingFieldsTr.isEmpty
                  ? 'Barkod: ${product.barcode}'
                  : 'Barkod: ${product.barcode} · Etiketten okunamayan: '
                      '${product.missingFieldsTr.join(", ")}',
            ),
            consumedAt: DateTime(
              day.year,
              day.month,
              day.day,
              now.hour,
              now.minute,
            ),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final p = context.palette;

    return SingleChildScrollView(
      padding: EdgeInsets.all(r.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NeuButton(
            label: 'Barkodu tara',
            icon: Icons.qr_code_scanner_rounded,
            expanded: true,
            loading: _busy,
            onPressed: _busy ? null : _scan,
          ),
          SizedBox(height: r.gapSm),
          NeuButton(
            label: 'Galerideki fotoğraftan oku',
            icon: Icons.photo_library_outlined,
            filled: false,
            tone: NeuTone.neutral,
            expanded: true,
            onPressed: _busy ? null : _scanFromGallery,
          ),
          SizedBox(height: r.gapMd),
          LabeledField(
            label: 'Barkod numarasını elle yaz',
            child: Row(
              children: [
                Expanded(
                  child: NumberField(
                    controller: _manualBarcode,
                    allowDecimal: false,
                    hintText: '8690…',
                  ),
                ),
                SizedBox(width: r.gapSm),
                NeuButton(
                  label: 'Ara',
                  compact: true,
                  onPressed: _busy
                      ? null
                      : () => _lookup(_manualBarcode.text.trim()),
                ),
              ],
            ),
          ),
          if (_statusTr != null) ...[
            SizedBox(height: r.gapMd),
            NeuCard(
              color: p.accentSoft.withValues(alpha: 0.5),
              child: Text(
                _statusTr!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          SizedBox(height: r.gapMd),
          Text(
            FoodService.kBarcodeDisclaimerTr,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          if (_product != null) ...[
            SizedBox(height: r.gapLg),
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _product!.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: r.gapSm),
                  LabeledField(
                    label: 'Miktar',
                    child: NumberField(
                      controller: _grams,
                      suffix: 'g',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  SizedBox(height: r.gapMd),
                  for (final e in <({String label, double? v, String u})>[
                    (label: 'Enerji', v: _product!.kcal, u: 'kcal'),
                    (label: 'Protein', v: _product!.proteinG, u: 'g'),
                    (label: 'Sodyum', v: _product!.sodiumMg, u: 'mg'),
                    (label: 'Potasyum', v: _product!.potassiumMg, u: 'mg'),
                    (label: 'Fosfor', v: _product!.phosphorusMg, u: 'mg'),
                  ])
                    Padding(
                      padding: EdgeInsets.only(bottom: r.gapXs),
                      child: Row(
                        children: [
                          Expanded(child: Text('${e.label} (100 g)')),
                          Text(
                            e.v == null
                                ? 'bilinmiyor'
                                : '${e.v!.round()} ${e.u}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color:
                                      e.v == null ? p.danger : p.textPrimary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  if (_product!.missingFieldsTr.isNotEmpty) ...[
                    SizedBox(height: r.gapSm),
                    Text(
                      'Etikette olmayan değerler "bilinmiyor" olarak '
                      'kaydedilir, sıfır sayılmaz: '
                      '${_product!.missingFieldsTr.join(", ")}.',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: p.danger),
                    ),
                  ],
                  SizedBox(height: r.gapMd),
                  NeuButton(
                    label: 'Kaydet',
                    icon: Icons.check_rounded,
                    expanded: true,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
// ETİKET OCR
// ===========================================================================
class _LabelOcrTab extends ConsumerStatefulWidget {
  const _LabelOcrTab();

  @override
  ConsumerState<_LabelOcrTab> createState() => _LabelOcrTabState();
}

class _LabelOcrTabState extends ConsumerState<_LabelOcrTab> {
  bool _busy = false;
  String? _text;
  String? _statusTr;

  /// Çözümlenmiş etiket — hangi değer hangi sütundan, hangi birimden geldi.
  ParsedNutritionLabel? _parsed;

  final _label = TextEditingController();
  final _grams = TextEditingController(text: '100');
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _sodium = TextEditingController();
  final _potassium = TextEditingController();
  final _phosphorus = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _label, _grams, _kcal, _protein, _sodium, _potassium, _phosphorus,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<bool> _ensureCamera() async {
    final service = ref.read(permissionServiceProvider);
    if (await service.status(AppPermission.camera) ==
        AppPermissionStatus.granted) {
      return true;
    }
    if (!mounted) return false;
    final ok = await showPermissionDialog(
      context,
      permissionInfo(AppPermission.camera),
    );
    if (!ok) return false;
    return await service.request(AppPermission.camera) ==
        AppPermissionStatus.granted;
  }

  Future<void> _capture() async {
    if (!await _ensureCamera()) return;
    await _read(fromCamera: true);
  }

  Future<void> _pickFromGallery() => _read(fromCamera: false);

  Future<void> _read({required bool fromCamera}) async {
    setState(() {
      _busy = true;
      _statusTr = 'Etiket okunuyor (telefonun içinde)…';
    });
    try {
      final scanner = ref.read(scannerServiceProvider);
      // Etiket yazısı küçük: daha yüksek çözünürlük OCR'ı belirgin
      // biçimde iyileştiriyor.
      final file = fromCamera
          ? await scanner.captureFromCamera(maxWidth: 2400)
          : await scanner.pickFromGallery(maxWidth: 2400);
      if (file == null) {
        if (mounted) {
          setState(() {
            _busy = false;
            _statusTr = null;
          });
        }
        return;
      }
      final result = await scanner.recognizeText(file);
      if (!mounted) return;
      final parsed = parseNutritionLabel(result.fullText);
      setState(() {
        _busy = false;
        _text = result.fullText;
        _parsed = parsed;
        _statusTr = result.isEmpty
            ? 'Metin bulunamadı. Etiketi daha yakın, düz ve iyi ışıkta '
                'çekmeyi dene.'
            : parsed.isEmpty
                ? 'Metin okundu ama besin değerleri tablosu bulunamadı. '
                    'Tablonun tamamı kadrajda mı?'
                : null;
      });
      _applyParsed(parsed);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _statusTr = 'Okuma başarısız: $e';
        });
      }
    }
  }

  /// Çözümlenen değerleri alanlara yazar.
  ///
  /// Değerler 100 g sütunundan gelmediyse ve etikette porsiyon ağırlığı
  /// varsa 100 g'a çevrilir — alanlar "100 g için" diye etiketli olduğu
  /// için aksi hâlde kayıt sessizce yanlış ölçeklenirdi.
  void _applyParsed(ParsedNutritionLabel parsed) {
    final factor = _normalizationFactor(parsed);

    void fill(TextEditingController c, String key, int decimals) {
      final f = parsed[key];
      if (f == null) {
        c.text = '';
        return;
      }
      final v = f.value * factor;
      c.text = v.toStringAsFixed(decimals).replaceAll('.', ',');
    }

    fill(_kcal, 'kcal', 0);
    fill(_protein, 'protein', 1);
    fill(_sodium, 'sodium', 0);
    fill(_potassium, 'potassium', 0);
    fill(_phosphorus, 'phosphorus', 0);
    setState(() {});
  }

  /// Okunan sütunu 100 g'a çeviren çarpan (çevrilemiyorsa 1).
  double _normalizationFactor(ParsedNutritionLabel parsed) {
    if (parsed.basis != NutrientBasis.perPortion) return 1;
    final portion = parsed.portionG;
    if (portion == null || portion <= 0) return 1;
    return 100 / portion;
  }

  Future<void> _save() async {
    final grams = parseLocaleNumber(_grams.text) ?? 100;
    final factor = grams / 100.0;
    final db = ref.read(databaseProvider);
    final day = ref.read(selectedDayProvider);
    final now = DateTime.now();

    double? v(TextEditingController c) {
      final n = parseLocaleNumber(c.text);
      return n == null ? null : n * factor;
    }

    await db.into(db.foodLogRows).insert(
          FoodLogRowsCompanion.insert(
            label: _label.text.trim().isEmpty
                ? 'Etiketten okunan ürün'
                : _label.text.trim(),
            grams: grams,
            kcal: Value(v(_kcal)),
            proteinG: Value(v(_protein)),
            sodiumMg: Value(v(_sodium)),
            potassiumMg: Value(v(_potassium)),
            phosphorusMg: Value(v(_phosphorus)),
            origin: const Value('ocr'),
            note: const Value('Etiket fotoğrafından okundu, '
                'kullanıcı onayladı'),
            consumedAt: DateTime(
              day.year,
              day.month,
              day.day,
              now.hour,
              now.minute,
            ),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final p = context.palette;

    return SingleChildScrollView(
      padding: EdgeInsets.all(r.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NeuButton(
            label: 'Etiketi çek',
            icon: Icons.text_snippet_outlined,
            expanded: true,
            loading: _busy,
            onPressed: _busy ? null : _capture,
          ),
          SizedBox(height: r.gapSm),
          NeuButton(
            label: 'Galerideki fotoğraftan oku',
            icon: Icons.photo_library_outlined,
            filled: false,
            tone: NeuTone.neutral,
            expanded: true,
            onPressed: _busy ? null : _pickFromGallery,
          ),
          SizedBox(height: r.gapSm),
          Text(
            'Metin okuma TELEFONUN İÇİNDE yapılır, internete gitmez.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          if (_parsed != null && !_parsed!.isEmpty) ...[
            SizedBox(height: r.gapMd),
            _LabelReadout(
              parsed: _parsed!,
              normalizationFactor: _normalizationFactor(_parsed!),
            ),
          ],
          if (_statusTr != null) ...[
            SizedBox(height: r.gapMd),
            NeuCard(
              color: p.accentSoft.withValues(alpha: 0.5),
              child: Text(
                _statusTr!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          SizedBox(height: r.gapLg),
          NeuCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Değerleri onayla',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: r.gapXs),
                Text(
                  'Okunan değerler önceden dolduruldu. '
                  'Yanlış olanı düzelt, olmayanı boş bırak — '
                  'boş bırakılan değer sıfır sayılmaz.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(height: r.gapMd),
                TextField(
                  controller: _label,
                  decoration: const InputDecoration(labelText: 'Ürün adı'),
                ),
                SizedBox(height: r.gapSm),
                NumberField(
                  controller: _grams,
                  suffix: 'g yedim',
                  hintText: '100',
                ),
                SizedBox(height: r.gapMd),
                for (final f in <({TextEditingController c, String label})>[
                  (c: _kcal, label: 'Enerji (kcal/100 g)'),
                  (c: _protein, label: 'Protein (g/100 g)'),
                  (c: _sodium, label: 'Sodyum (mg/100 g)'),
                  (c: _potassium, label: 'Potasyum (mg/100 g)'),
                  (c: _phosphorus, label: 'Fosfor (mg/100 g)'),
                ])
                  Padding(
                    padding: EdgeInsets.only(bottom: r.gapSm),
                    child: NumberField(
                      controller: f.c,
                      hintText: f.label,
                    ),
                  ),
                SizedBox(height: r.gapSm),
                NeuButton(
                  label: 'Kaydet',
                  icon: Icons.check_rounded,
                  expanded: true,
                  onPressed: _save,
                ),
              ],
            ),
          ),
          if (_text?.isNotEmpty == true) ...[
            SizedBox(height: r.gapMd),
            ExpansionTile(
              title: Text(
                'Okunan ham metin',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(r.gapSm),
                  child: Text(
                    _text!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: r.gapMd),
          Text(
            kOcrDisclaimerTr,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// FOTOĞRAF ANALİZİ (Claude vision)
// ===========================================================================
class _PhotoTab extends ConsumerStatefulWidget {
  const _PhotoTab();

  @override
  ConsumerState<_PhotoTab> createState() => _PhotoTabState();
}

/// Bir kalemin düzenlenebilir hâli.
class _EditableItem {
  _EditableItem(this.item) : include = true {
    portion = TextEditingController(
      text: (item.portionG ?? 0) > 0
          ? item.portionG!.toStringAsFixed(0)
          : '',
    );
  }

  MealItem item;
  bool include;
  late final TextEditingController portion;

  void dispose() => portion.dispose();
}

class _PhotoTabState extends ConsumerState<_PhotoTab> {
  File? _image;
  bool _busy = false;
  String? _errorTr;
  MealAnalysis? _analysis;
  List<_EditableItem> _items = [];

  final _label = TextEditingController();

  @override
  void dispose() {
    _label.dispose();
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  Future<void> _pick({required bool camera}) async {
    if (camera) {
      final service = ref.read(permissionServiceProvider);
      if (await service.status(AppPermission.camera) !=
          AppPermissionStatus.granted) {
        if (!mounted) return;
        final ok = await showPermissionDialog(
          context,
          permissionInfo(AppPermission.camera),
        );
        if (!ok) return;
        if (await service.request(AppPermission.camera) !=
            AppPermissionStatus.granted) {
          return;
        }
      }
    }
    final scanner = ref.read(scannerServiceProvider);
    final file = camera
        ? await scanner.captureFromCamera()
        : await scanner.pickFromGallery();
    if (file == null || !mounted) return;
    setState(() {
      _image = file;
      _analysis = null;
      _errorTr = null;
      for (final i in _items) {
        i.dispose();
      }
      _items = [];
    });
  }

  Future<void> _analyze() async {
    final image = _image;
    if (image == null) return;

    // GİZLİLİK: Gönderim öncesi açık onay.
    final consent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fotoğraf yapay zekaya gönderilecek'),
        content: const Text(
          'Bu fotoğraf Anthropic Claude API sunucusuna gönderilecek ve '
          'orada analiz edilecek. Fotoğrafın dışında hiçbir kişisel '
          'bilgin (adın, tahlillerin, ilaçların) bu istekle '
          'gönderilmez — yalnızca günlük hedeflerin gönderilir.\n\n'
          'Sonuç TAHMİNDİR: porsiyon ve özellikle tuz miktarı '
          'fotoğraftan kesin bilinemez. Her kalemi kaydetmeden önce '
          'düzeltebilir ya da listeden çıkarabilirsin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
    if (consent != true) return;

    setState(() {
      _busy = true;
      _errorTr = null;
    });

    try {
      final settings = ref.read(clinicalSettingsProvider);
      final prompt = ref
          .read(aiPromptBuilderProvider)
          .buildMealVisionPrompt(settings: settings);
      final model =
          ref.read(preferencesProvider).aiModel ?? AiConfig.defaultModel;

      final reply = await ref.read(aiServiceProvider).sendVision(
            systemPrompt: prompt,
            userText: 'Bu fotoğraftaki yemeği analiz et.',
            image: image,
            model: model,
          );

      final analysis = parseMealAnalysis(reply.text);
      if (!mounted) return;
      for (final i in _items) {
        i.dispose();
      }
      setState(() {
        _busy = false;
        _analysis = analysis;
        _items = [for (final it in analysis.items) _EditableItem(it)];
        _label.text = analysis.dishNameTr ?? 'Fotoğraftan analiz';
        if (analysis.isEmpty) {
          _errorTr = analysis.noteTr ??
              'Fotoğrafta tanıyabildiğim bir yemek yok. Başka bir açıdan '
                  'çekmeyi ya da elle girmeyi dene.';
        }
      });
    } on AiFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorTr = e.messageTr;
      });
    }
  }

  /// Kullanıcının düzenlediği hâliyle seçili kalemler.
  List<MealItem> get _selected {
    final out = <MealItem>[];
    for (final e in _items) {
      if (!e.include) continue;
      final grams = parseLocaleNumber(e.portion.text);
      out.add(grams != null && grams > 0 ? e.item.withPortion(grams) : e.item);
    }
    return out;
  }

  Future<void> _save() async {
    final analysis = _analysis;
    final items = _selected;
    if (analysis == null || items.isEmpty) return;

    final db = ref.read(databaseProvider);
    final day = ref.read(selectedDayProvider);
    final now = DateTime.now();
    final consumedAt =
        DateTime(day.year, day.month, day.day, now.hour, now.minute);

    // Her kalem AYRI kaydedilir: kullanıcı sonradan tek bir kalemi
    // silebilsin ya da düzeltebilsin.
    for (final item in items) {
      await db.into(db.foodLogRows).insert(
            FoodLogRowsCompanion.insert(
              label: item.name,
              grams: item.portionG ?? 0,
              // AI çıktısı PORSİYON TOPLAMI olarak verilir, 100 g değil.
              kcal: Value(item.kcal?.value),
              proteinG: Value(item.protein?.value),
              sodiumMg: Value(item.sodium?.value),
              potassiumMg: Value(item.potassium?.value),
              phosphorusMg: Value(item.phosphorus?.value),
              origin: const Value('ai'),
              confidence: Value(item.confidence.dbValue),
              note: Value(
                [
                  'Yapay zeka tahmini (${item.confidence.labelTr})',
                  if (analysis.noteTr != null) analysis.noteTr!,
                ].join(' · '),
              ),
              consumedAt: consumedAt,
            ),
          );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final connected =
        ref.watch(aiConnectionProvider).value == AiConnectionState.ok;

    if (!connected) {
      return Padding(
        padding: EdgeInsets.all(r.pagePadding),
        child: EmptyState(
          icon: Icons.link_off_rounded,
          title: 'Önce yapay zeka bağlantısını kur',
          message: 'Fotoğraftan yemek analizi Claude API ile çalışır. '
              'Ayarlar → Yapay Zeka Bağlantısı bölümünden anahtarını '
              'girdikten sonra burası açılır. Diğer sekmeler anahtarsız '
              'da çalışır.',
          action: NeuButton(
            label: 'Bağlantıyı kur',
            icon: Icons.key_rounded,
            onPressed: () => context.push(Routes.aiConnection),
          ),
        ),
      );
    }

    final selected = _selected;
    final totals = _analysis?.withItems(selected);

    return SingleChildScrollView(
      padding: EdgeInsets.all(r.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                _image!,
                height: r.s(170),
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: r.gapSm),
          ],
          Row(
            children: [
              Expanded(
                child: NeuButton(
                  label: 'Fotoğraf çek',
                  icon: Icons.photo_camera_outlined,
                  compact: true,
                  onPressed: _busy ? null : () => _pick(camera: true),
                ),
              ),
              SizedBox(width: r.gapSm),
              Expanded(
                child: NeuButton(
                  label: 'Galeriden',
                  icon: Icons.photo_library_outlined,
                  filled: false,
                  tone: NeuTone.neutral,
                  compact: true,
                  onPressed: _busy ? null : () => _pick(camera: false),
                ),
              ),
            ],
          ),
          if (_image != null) ...[
            SizedBox(height: r.gapSm),
            NeuButton(
              label: 'Analiz et',
              icon: Icons.auto_awesome_rounded,
              expanded: true,
              loading: _busy,
              onPressed: _busy ? null : _analyze,
            ),
          ],
          if (_errorTr != null) ...[
            SizedBox(height: r.gapMd),
            NeuCard(
              color: p.danger.withValues(alpha: 0.10),
              child: Text(_errorTr!, style: text.bodyMedium),
            ),
          ],
          if (_items.isNotEmpty) ...[
            SizedBox(height: r.gapLg),
            Row(
              children: [
                Expanded(
                  child: Text('Tabaktaki kalemler', style: text.titleMedium),
                ),
                Text(
                  '${selected.length}/${_items.length} seçili',
                  style: text.labelSmall,
                ),
              ],
            ),
            SizedBox(height: r.gapXs),
            Text(
              'Her kalemi ayrı ayrı düzelt. Porsiyonu değiştirince o '
              'kalemin tüm değerleri orantılı güncellenir. Yemediğin '
              'kalemi listeden çıkar.',
              style: text.bodySmall,
            ),
            SizedBox(height: r.gapSm),
            for (final e in _items) ...[
              _MealItemCard(
                editable: e,
                onChanged: () => setState(() {}),
              ),
              SizedBox(height: r.gapSm),
            ],
            if (totals != null && selected.isNotEmpty) ...[
              SizedBox(height: r.gapSm),
              NeuCard(
                surface: Surface.raised,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Toplam', style: text.titleMedium),
                    SizedBox(height: r.gapSm),
                    for (final row in <({String l, EstimatedValue? v, String u})>[
                      (l: 'Enerji', v: totals.kcal, u: 'kcal'),
                      (l: 'Protein', v: totals.protein, u: 'g'),
                      (l: 'Sodyum', v: totals.sodium, u: 'mg'),
                      (l: 'Potasyum', v: totals.potassium, u: 'mg'),
                      (l: 'Fosfor', v: totals.phosphorus, u: 'mg'),
                    ])
                      Padding(
                        padding: EdgeInsets.only(bottom: r.gapXs),
                        child: Row(
                          children: [
                            Expanded(child: Text(row.l, style: text.bodyMedium)),
                            Text(
                              row.v == null
                                  ? 'bilinmiyor'
                                  : row.v!.formatted(row.u),
                              style: AppTypography.numericSmall(
                                p,
                                color: row.v == null ? p.danger : p.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (_analysis?.noteTr != null) ...[
              SizedBox(height: r.gapSm),
              NeuCard(
                color: p.accentSoft.withValues(alpha: 0.5),
                child: Text(_analysis!.noteTr!, style: text.bodySmall),
              ),
            ],
            SizedBox(height: r.gapMd),
            NeuButton(
              label: selected.length == 1
                  ? 'Kalemi kaydet'
                  : '${selected.length} kalemi kaydet',
              icon: Icons.check_rounded,
              expanded: true,
              onPressed: selected.isEmpty ? null : _save,
            ),
          ],
          SizedBox(height: r.gapMd),
          Text(
            'Değerler TAHMİNDİR. Fotoğraftan porsiyon ve özellikle tuz '
            'kesin bilinemez; kaydedilen kalemler "yapay zeka tahmini" '
            'olarak işaretlenir.',
            style: text.labelSmall,
          ),
        ],
      ),
    );
  }
}

/// Tabaktaki tek bir kalem: seç/çıkar, porsiyonu düzelt, değerleri gör.
class _MealItemCard extends StatelessWidget {
  const _MealItemCard({required this.editable, required this.onChanged});

  final _EditableItem editable;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final text = Theme.of(context).textTheme;

    final grams = parseLocaleNumber(editable.portion.text);
    final shown = grams != null && grams > 0
        ? editable.item.withPortion(grams)
        : editable.item;

    return NeuCard(
      selected: editable.include,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Semantics(
                label: '${editable.item.name} kalemini dahil et',
                child: Checkbox(
                  value: editable.include,
                  onChanged: (v) {
                    editable.include = v ?? false;
                    onChanged();
                  },
                ),
              ),
              Expanded(
                child: Text(
                  editable.item.name,
                  style: text.titleSmall?.copyWith(color: p.textPrimary),
                ),
              ),
            ],
          ),
          if (editable.item.portionNoteTr?.isNotEmpty == true)
            Padding(
              padding: EdgeInsets.only(left: r.gapLg, bottom: r.gapXs),
              child: Text(
                editable.item.portionNoteTr!,
                style: text.labelSmall,
              ),
            ),
          if (editable.include) ...[
            SizedBox(height: r.gapXs),
            Row(
              children: [
                SizedBox(
                  width: r.s(120),
                  child: NumberField(
                    controller: editable.portion,
                    suffix: 'g',
                    hintText: 'porsiyon',
                    onChanged: (_) => onChanged(),
                  ),
                ),
                SizedBox(width: r.gapSm),
                Flexible(
                  child: ApproximateBadge(
                    labelTr: editable.item.confidence.labelTr,
                  ),
                ),
              ],
            ),
            SizedBox(height: r.gapSm),
            Wrap(
              spacing: r.gapSm,
              runSpacing: r.gapXs,
              children: [
                for (final e in <({String l, EstimatedValue? v, String u})>[
                  (l: 'kcal', v: shown.kcal, u: 'kcal'),
                  (l: 'protein', v: shown.protein, u: 'g'),
                  (l: 'Na', v: shown.sodium, u: 'mg'),
                  (l: 'K', v: shown.potassium, u: 'mg'),
                  (l: 'P', v: shown.phosphorus, u: 'mg'),
                ])
                  if (e.v != null)
                    Text(
                      '${e.l} ${e.v!.formatted(e.u)}',
                      style: AppTypography.numericSmall(p, size: 13),
                    ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Etiketten okunan değerlerin kaynağını gösterir: hangi sütun, hangi
/// birim, türetildi mi. Kullanıcı etiketle karşılaştırabilsin diye.
class _LabelReadout extends StatelessWidget {
  const _LabelReadout({
    required this.parsed,
    required this.normalizationFactor,
  });

  final ParsedNutritionLabel parsed;
  final double normalizationFactor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final text = Theme.of(context).textTheme;

    Color colorFor(LabelConfidence c) => switch (c) {
          LabelConfidence.high => p.success,
          LabelConfidence.medium => p.warning,
          LabelConfidence.low => p.danger,
        };

    const rows = <({String key, String label, String unit})>[
      (key: 'kcal', label: 'Enerji', unit: 'kcal'),
      (key: 'protein', label: 'Protein', unit: 'g'),
      (key: 'sodium', label: 'Sodyum', unit: 'mg'),
      (key: 'potassium', label: 'Potasyum', unit: 'mg'),
      (key: 'phosphorus', label: 'Fosfor', unit: 'mg'),
    ];

    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Etiketten okunanlar', style: text.titleMedium),
          SizedBox(height: r.gapXs),
          Text(
            parsed.basis == NutrientBasis.perPortion && normalizationFactor != 1
                ? 'Etiket porsiyon sütununu veriyor '
                    '(${parsed.portionG?.toStringAsFixed(0)} g). Değerler '
                    '100 g\'a çevrildi.'
                : 'Sütun: ${parsed.basis.labelTr}.',
            style: text.bodySmall,
          ),
          SizedBox(height: r.gapSm),
          for (final row in rows)
            Padding(
              padding: EdgeInsets.only(bottom: r.gapXs),
              child: Builder(
                builder: (context) {
                  final f = parsed[row.key];
                  if (f == null) {
                    return Row(
                      children: [
                        Expanded(
                          child: Text(row.label, style: text.bodyMedium),
                        ),
                        Text(
                          'okunamadı',
                          style: text.labelMedium?.copyWith(color: p.danger),
                        ),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(row.label, style: text.bodyMedium),
                          ),
                          Text(
                            '${(f.value * normalizationFactor).toStringAsFixed(f.unit == 'g' ? 1 : 0)} ${row.unit}',
                            style: AppTypography.numericSmall(p),
                          ),
                          SizedBox(width: r.gapXs),
                          Icon(Icons.circle,
                              size: 8, color: colorFor(f.confidence)),
                        ],
                      ),
                      if (f.derivationTr != null)
                        Text(f.derivationTr!, style: text.labelSmall),
                    ],
                  );
                },
              ),
            ),
          if (parsed.missingCriticalTr.isNotEmpty) ...[
            SizedBox(height: r.gapSm),
            Text(
              'Etikette yazmayanlar: ${parsed.missingCriticalTr.join(", ")}. '
              'Potasyum ve fosfor Türkiye\'de genelde etikete yazılmaz; '
              'boş bırakılırsa sıfır değil "bilinmiyor" olarak kaydedilir.',
              style: text.labelSmall?.copyWith(color: p.warning),
            ),
          ],
        ],
      ),
    );
  }
}

class _ManualTab extends ConsumerStatefulWidget {
  const _ManualTab();

  @override
  ConsumerState<_ManualTab> createState() => _ManualTabState();
}

class _ManualTabState extends ConsumerState<_ManualTab> {
  final _label = TextEditingController();
  final _grams = TextEditingController(text: '100');
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _sodium = TextEditingController();
  final _potassium = TextEditingController();
  final _phosphorus = TextEditingController();
  final _fluid = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _label, _grams, _kcal, _protein, _sodium,
      _potassium, _phosphorus, _fluid,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_label.text.trim().isEmpty) return;
    final db = ref.read(databaseProvider);
    final day = ref.read(selectedDayProvider);
    final now = DateTime.now();

    await db.into(db.foodLogRows).insert(
          FoodLogRowsCompanion.insert(
            label: _label.text.trim(),
            grams: parseLocaleNumber(_grams.text) ?? 100,
            kcal: Value(parseLocaleNumber(_kcal.text)),
            proteinG: Value(parseLocaleNumber(_protein.text)),
            sodiumMg: Value(parseLocaleNumber(_sodium.text)),
            potassiumMg: Value(parseLocaleNumber(_potassium.text)),
            phosphorusMg: Value(parseLocaleNumber(_phosphorus.text)),
            fluidMl: Value(parseLocaleNumber(_fluid.text)),
            origin: const Value('manual'),
            consumedAt: DateTime(
              day.year,
              day.month,
              day.day,
              now.hour,
              now.minute,
            ),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(r.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bilmediğin değerleri BOŞ bırak. Boş bırakılan değer '
            'sıfır sayılmaz, "bilinmiyor" olarak gösterilir.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: r.gapMd),
          TextField(
            controller: _label,
            decoration: const InputDecoration(
              labelText: 'Ne yedin?',
              hintText: 'Örn. annemin yaptığı karnıyarık',
            ),
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: r.gapSm),
          NumberField(controller: _grams, suffix: 'g', hintText: 'Miktar'),
          SizedBox(height: r.gapMd),
          for (final f in <({TextEditingController c, String l})>[
            (c: _kcal, l: 'Enerji (kcal, toplam)'),
            (c: _protein, l: 'Protein (g)'),
            (c: _sodium, l: 'Sodyum (mg)'),
            (c: _potassium, l: 'Potasyum (mg)'),
            (c: _phosphorus, l: 'Fosfor (mg)'),
            (c: _fluid, l: 'Sıvı katkısı (mL)'),
          ])
            Padding(
              padding: EdgeInsets.only(bottom: r.gapSm),
              child: NumberField(controller: f.c, hintText: f.l),
            ),
          SizedBox(height: r.gapSm),
          NeuButton(
            label: 'Kaydet',
            icon: Icons.check_rounded,
            expanded: true,
            onPressed: _label.text.trim().isEmpty ? null : _save,
          ),
        ],
      ),
    );
  }
}
