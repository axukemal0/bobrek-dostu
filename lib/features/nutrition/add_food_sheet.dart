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
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/responsive.dart';
import '../home/home_screen.dart' show showPermissionDialog;
import 'meal_vision_parser.dart';

Future<void> showAddFoodSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
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
        _Mode.label => 'Etiket oku',
        _Mode.photo => 'Fotoğraf analizi',
        _Mode.manual => 'Elle gir',
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

  Future<void> _scan() async {
    final granted = await _ensureCamera();
    if (!granted) return;

    setState(() {
      _busy = true;
      _statusTr = 'Fotoğraf çekiliyor…';
      _product = null;
    });
    try {
      final scanner = ref.read(scannerServiceProvider);
      final file = await scanner.captureFromCamera();
      if (file == null) {
        setState(() {
          _busy = false;
          _statusTr = null;
        });
        return;
      }
      setState(() => _statusTr = 'Barkod okunuyor (telefonun içinde)…');
      final codes = await scanner.scanBarcodes(file);
      if (codes.isEmpty) {
        setState(() {
          _busy = false;
          _statusTr = 'Barkod bulunamadı. Barkodu çerçeveye yakın ve '
              'net çekmeyi dene, ya da numarayı elle yaz.';
        });
        return;
      }
      await _lookup(codes.first);
    } on Object catch (e) {
      setState(() {
        _busy = false;
        _statusTr = 'Okuma başarısız: $e';
      });
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
            label: _busy ? 'İşleniyor…' : 'Barkodu çek',
            icon: Icons.qr_code_scanner_rounded,
            expanded: true,
            onPressed: _busy ? null : _scan,
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

  Future<void> _capture() async {
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

    setState(() {
      _busy = true;
      _statusTr = 'Metin okunuyor (telefonun içinde)…';
    });
    try {
      final scanner = ref.read(scannerServiceProvider);
      final file = await scanner.captureFromCamera();
      if (file == null) {
        setState(() {
          _busy = false;
          _statusTr = null;
        });
        return;
      }
      final result = await scanner.recognizeText(file);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _text = result.fullText;
        _statusTr = result.isEmpty
            ? 'Metin bulunamadı. Etiketi daha yakın ve net çekmeyi dene.'
            : null;
      });
      _prefillFromText(result.fullText);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _statusTr = 'Okuma başarısız: $e';
        });
      }
    }
  }

  /// Etiket metninden sayıları tahmin eder — kullanıcı onaylar.
  void _prefillFromText(String text) {
    final t = text.toLowerCase().replaceAll(',', '.');
    void fill(TextEditingController c, List<String> keys) {
      for (final k in keys) {
        final m = RegExp('$k[^0-9]{0,20}(\\d+\\.?\\d*)').firstMatch(t);
        if (m != null) {
          c.text = m.group(1)!;
          return;
        }
      }
    }

    fill(_kcal, ['enerji', 'kalori', 'kcal', 'energy']);
    fill(_protein, ['protein']);
    fill(_sodium, ['sodyum', 'sodium']);
    fill(_potassium, ['potasyum', 'potassium']);
    fill(_phosphorus, ['fosfor', 'phosphorus']);
    setState(() {});
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
            label: _busy ? 'Okunuyor…' : 'Etiketi çek',
            icon: Icons.text_snippet_outlined,
            expanded: true,
            onPressed: _busy ? null : _capture,
          ),
          SizedBox(height: r.gapSm),
          Text(
            'Metin okuma TELEFONUN İÇİNDE yapılır, internete gitmez.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
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

class _PhotoTabState extends ConsumerState<_PhotoTab> {
  File? _image;
  bool _busy = false;
  String? _errorTr;
  MealEstimate? _estimate;

  final _label = TextEditingController();
  final _grams = TextEditingController(text: '200');
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
        ? await scanner.captureFromCamera(maxWidth: 1280)
        : await scanner.pickFromGallery(maxWidth: 1280);
    if (file != null && mounted) {
      setState(() {
        _image = file;
        _estimate = null;
        _errorTr = null;
      });
    }
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
          'fotoğraftan kesin bilinemez. Değerleri kaydetmeden önce '
          'düzeltebilirsin.',
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

      final est = parseMealEstimate(reply.text);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _estimate = est;
        _label.text = est.name ?? 'Fotoğraftan analiz';
        if (est.portionG != null) {
          _grams.text = est.portionG!.toStringAsFixed(0);
        }
        _kcal.text = est.kcal?.value.toStringAsFixed(0) ?? '';
        _protein.text = est.protein?.value.toStringAsFixed(1) ?? '';
        _sodium.text = est.sodium?.value.toStringAsFixed(0) ?? '';
        _potassium.text = est.potassium?.value.toStringAsFixed(0) ?? '';
        _phosphorus.text = est.phosphorus?.value.toStringAsFixed(0) ?? '';
      });
    } on AiFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errorTr = e.messageTr;
      });
    }
  }

  Future<void> _save() async {
    final db = ref.read(databaseProvider);
    final day = ref.read(selectedDayProvider);
    final now = DateTime.now();
    final grams = parseLocaleNumber(_grams.text) ?? 200;

    await db.into(db.foodLogRows).insert(
          FoodLogRowsCompanion.insert(
            label: _label.text.trim().isEmpty
                ? 'Fotoğraftan analiz'
                : _label.text.trim(),
            grams: grams,
            // AI çıktısı PORSİYON TOPLAMI olarak verilir, 100 g değil.
            kcal: Value(parseLocaleNumber(_kcal.text)),
            proteinG: Value(parseLocaleNumber(_protein.text)),
            sodiumMg: Value(parseLocaleNumber(_sodium.text)),
            potassiumMg: Value(parseLocaleNumber(_potassium.text)),
            phosphorusMg: Value(parseLocaleNumber(_phosphorus.text)),
            origin: const Value('ai'),
            confidence: Value(_estimate?.confidence.dbValue),
            note: Value(
              [
                'Yapay zeka tahmini (${_estimate?.confidence.labelTr})',
                if (_estimate?.noteTr != null) _estimate!.noteTr!,
              ].join(' · '),
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
    final conn = ref.watch(aiConnectionProvider).value;

    if (conn != AiConnectionState.ok) {
      return Padding(
        padding: EdgeInsets.all(r.pagePadding),
        child: EmptyState(
          title: 'Önce bağlantıyı kur',
          message: 'Fotoğraftan yemek analizi, kendi Anthropic '
              'anahtarınla çalışır. Ayarlar > Yapay Zeka Bağlantısı '
              'bölümünden anahtarını ekleyebilirsin. '
              'Diğer ekleme yolları (ara, barkod, etiket, elle) '
              'anahtarsız çalışır.',
          icon: Icons.key_off_outlined,
          action: NeuButton(
            label: 'Bağlantıyı kur',
            icon: Icons.key_outlined,
            onPressed: () {
              Navigator.pop(context);
              context.push(Routes.aiConnection);
            },
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(r.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _image!,
                height: r.s(180),
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          if (_image != null) SizedBox(height: r.gapMd),
          Row(
            children: [
              Expanded(
                child: NeuButton(
                  label: 'Fotoğraf çek',
                  icon: Icons.photo_camera_outlined,
                  compact: true,
                  expanded: true,
                  onPressed: _busy ? null : () => _pick(camera: true),
                ),
              ),
              SizedBox(width: r.gapSm),
              Expanded(
                child: NeuButton(
                  label: 'Galeriden',
                  icon: Icons.photo_library_outlined,
                  filled: false,
                  compact: true,
                  expanded: true,
                  onPressed: _busy ? null : () => _pick(camera: false),
                ),
              ),
            ],
          ),
          if (_image != null) ...[
            SizedBox(height: r.gapMd),
            NeuButton(
              label: _busy ? 'Analiz ediliyor…' : 'Yapay zekaya analiz ettir',
              icon: Icons.auto_awesome_rounded,
              expanded: true,
              tone: NeuTone.accent,
              onPressed: _busy ? null : _analyze,
            ),
          ],
          if (_errorTr != null) ...[
            SizedBox(height: r.gapMd),
            NeuCard(
              color: p.danger.withValues(alpha: 0.09),
              child: Text(
                _errorTr!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          if (_estimate != null) ...[
            SizedBox(height: r.gapLg),
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tahmin',
                          style:
                              Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: switch (_estimate!.confidence) {
                            AiConfidence.high => p.primarySoft,
                            AiConfidence.medium => p.accentSoft,
                            _ => p.danger.withValues(alpha: 0.12),
                          },
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          _estimate!.confidence.labelTr,
                          style:
                              Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.gapSm),
                  for (final e
                      in <({String label, EstimatedValue? v, String u})>[
                    (label: 'Enerji', v: _estimate!.kcal, u: 'kcal'),
                    (label: 'Protein', v: _estimate!.protein, u: 'g'),
                    (label: 'Sodyum', v: _estimate!.sodium, u: 'mg'),
                    (label: 'Potasyum', v: _estimate!.potassium, u: 'mg'),
                    (label: 'Fosfor', v: _estimate!.phosphorus, u: 'mg'),
                  ])
                    Padding(
                      padding: EdgeInsets.only(bottom: r.gapXs),
                      child: Row(
                        children: [
                          Expanded(child: Text(e.label)),
                          Text(
                            e.v?.formatted(e.u) ?? 'bilinmiyor',
                            style:
                                Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                  if (_estimate!.noteTr != null) ...[
                    SizedBox(height: r.gapSm),
                    Container(
                      padding: EdgeInsets.all(r.gapSm),
                      decoration: BoxDecoration(
                        color: p.accentSoft.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _estimate!.noteTr!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                  SizedBox(height: r.gapMd),
                  Text(
                    'Düzelt ve kaydet',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: r.gapSm),
                  TextField(
                    controller: _label,
                    decoration:
                        const InputDecoration(labelText: 'Yemek adı'),
                  ),
                  SizedBox(height: r.gapSm),
                  NumberField(
                    controller: _grams,
                    suffix: 'g',
                    hintText: 'Porsiyon',
                  ),
                  SizedBox(height: r.gapSm),
                  for (final f in <({TextEditingController c, String l})>[
                    (c: _kcal, l: 'Enerji (kcal, porsiyon toplamı)'),
                    (c: _protein, l: 'Protein (g)'),
                    (c: _sodium, l: 'Sodyum (mg)'),
                    (c: _potassium, l: 'Potasyum (mg)'),
                    (c: _phosphorus, l: 'Fosfor (mg)'),
                  ])
                    Padding(
                      padding: EdgeInsets.only(bottom: r.gapSm),
                      child: NumberField(controller: f.c, hintText: f.l),
                    ),
                  NeuButton(
                    label: 'Kaydet',
                    icon: Icons.check_rounded,
                    expanded: true,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
            SizedBox(height: r.gapMd),
            ExpansionTile(
              title: Text(
                'Yapay zekanın ham yanıtı',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              children: [
                Padding(
                  padding: EdgeInsets.all(r.gapSm),
                  child: Text(
                    _estimate!.rawText,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
// ELLE GİRİŞ
// ===========================================================================
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
