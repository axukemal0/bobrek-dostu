import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../clinical/definitions.dart';
import '../../clinical/evaluator.dart';
import '../../clinical/settings.dart';
import '../../clinical/sources.dart';
import '../config/app_config.dart';
import '../db/database.dart';

/// Doktor raporu: son 1 veya 3 aylık veriyi PDF olarak dışa aktarır.
class ReportService {
  ReportService(this._db);

  final AppDatabase _db;

  pw.Font? _body;
  pw.Font? _bodyBold;
  pw.Font? _title;

  Future<void> _loadFonts() async {
    if (_body != null) return;
    _body = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Nunito-Regular.ttf'),
    );
    _bodyBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Nunito-Bold.ttf'),
    );
    _title = pw.Font.ttf(
      await rootBundle.load('assets/fonts/PlayfairDisplay-SemiBold.ttf'),
    );
  }

  /// Raporu üretir.
  Future<Uint8List> build({required Duration window}) async {
    await _loadFonts();

    final now = DateTime.now();
    final from = now.subtract(window);

    final profile = await _db.getProfile();
    final settings = await _readSettings();

    final labs = await _db.labResultsBetween(from, now);
    final vitals = await _db.vitalsBetween(from, now);
    final foods = await _db.foodLogsBetween(from, now);
    final fluids = await _db.fluidLogsBetween(from, now);
    final doses = await _db.dosesBetween(from, now);
    final meds = await _db.getActiveMedications();

    final theme = pw.ThemeData.withFont(
      base: _body!,
      bold: _bodyBold!,
    ).copyWith(
      defaultTextStyle: pw.TextStyle(font: _body, fontSize: 9.5, lineSpacing: 1.6),
    );

    final doc = pw.Document(
      title: 'Böbrek Dostu — Doktor Raporu',
      author: AppConfig.appName,
      theme: theme,
    );

    const green = PdfColor.fromInt(0xFF3C6B54);
    const gold = PdfColor.fromInt(0xFF8A6A20);
    const ink = PdfColor.fromInt(0xFF2A2621);
    const muted = PdfColor.fromInt(0xFF6B6459);
    const bg = PdfColor.fromInt(0xFFF8F4EC);

    pw.Widget h1(String t) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text(
            t,
            style: pw.TextStyle(font: _title, fontSize: 15, color: green),
          ),
        );

    pw.Widget note(String t) => pw.Text(
          t,
          style: pw.TextStyle(fontSize: 8, color: muted, font: _body),
        );

    pw.Widget section(String title, pw.Widget child, {String? footnote}) =>
        pw.Container(
          width: double.infinity,
          margin: const pw.EdgeInsets.only(bottom: 14),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: bg,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColor.fromInt(0xFFDCD2BE)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              h1(title),
              child,
              if (footnote != null) ...[
                pw.SizedBox(height: 5),
                note(footnote),
              ],
            ],
          ),
        );

    // ---------------- Hesaplamalar ----------------
    final adherence = computeAdherence(doses);
    final bpStats = computeBpStats(vitals);
    final weightSeries = vitals
        .where((v) => v.weightKg != null)
        .map((v) => (at: v.measuredAt, kg: v.weightKg!))
        .toList();
    final nutritionAvg = computeNutritionAverages(foods, from, now);
    final fluidAvg = computeFluidAverage(fluids, from, now);

    final labsByAnalyte = <String, List<LabResultRow>>{};
    for (final l in labs) {
      labsByAnalyte.putIfAbsent(l.analyteLabel, () => []).add(l);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 30, 32, 36),
        header: (ctx) => ctx.pageNumber == 1
            ? pw.SizedBox.shrink()
            : pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Text(
                  '${AppConfig.appName} — Doktor Raporu',
                  style: pw.TextStyle(fontSize: 8, color: muted),
                ),
              ),
        footer: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                kMedicalDisclaimerTr,
                style: pw.TextStyle(fontSize: 7.5, color: muted),
              ),
              pw.Text(
                'Sayfa ${ctx.pageNumber} / ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 7.5, color: muted),
              ),
            ],
          ),
        ),
        build: (ctx) => [
          // ---------------- Başlık ----------------
          pw.Header(
            level: 0,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: gold, width: 1.5),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Doktor Raporu',
                  style: pw.TextStyle(font: _title, fontSize: 24, color: ink),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  '${_fmtDate(from)} – ${_fmtDate(now)} '
                  '(${window.inDays} gün) · '
                  'Oluşturma: ${_fmtDateTime(now)}',
                  style: pw.TextStyle(fontSize: 9, color: muted),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // ---------------- Hasta ----------------
          section(
            'Hasta',
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(2),
              },
              children: [
                _kv('Ad', profile?.name ?? '—'),
                _kv(
                  'Yaş',
                  profile?.birthYear == null
                      ? '—'
                      : '${now.year - profile!.birthYear!}',
                ),
                _kv(
                  'Boy / Kilo',
                  '${profile?.heightCm?.toStringAsFixed(0) ?? "—"} cm / '
                      '${profile?.weightKg?.toStringAsFixed(1) ?? "—"} kg',
                ),
                _kv('Durum', settings.treatmentMode.labelTr),
                if (settings.treatmentMode.isDialysis)
                  _kv(
                    'Kuru ağırlık',
                    settings.dryWeightKg == null
                        ? '—'
                        : '${settings.dryWeightKg!.toStringAsFixed(1)} kg',
                  ),
                if (settings.treatmentMode.isDialysis)
                  _kv(
                    'Rezidüel idrar',
                    settings.hasResidualUrine ? 'Var' : 'Yok',
                  ),
                _kv('Diğer hastalıklar', profile?.comorbidities ?? '—'),
                _kv('Alerjiler', profile?.allergies ?? '—'),
                _kv('Hekim', profile?.doctorName ?? '—'),
              ],
            ),
          ),

          // ---------------- Klinik ayarlar ----------------
          section(
            'Hastanın kendi klinik ayarları',
            pw.TableHelper.fromTextArray(
              headers: const ['Değer', 'Ayar', 'Kaynak / durum'],
              headerStyle: pw.TextStyle(font: _bodyBold, fontSize: 8.5),
              cellStyle: pw.TextStyle(fontSize: 8.5),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE4EDE7),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: const {
                0: pw.FlexColumnWidth(2.2),
                1: pw.FlexColumnWidth(1.4),
                2: pw.FlexColumnWidth(2.4),
              },
              data: [
                for (final def in [...kDietTargets, ...kAlarmThresholds])
                  () {
                    final r = settings.resolveDefinition(def);
                    return [
                      '${def.labelTr} (${def.kind.shortTr})',
                      '${r.formatted()} ${def.unit}',
                      r.isCustom
                          ? 'Hekim ayarı'
                          : def.verification.labelTr,
                    ];
                  }(),
              ],
            ),
            footnote: 'Bu değerler hastanın (hekimin) kendisi tarafından '
                'girilmiştir. "Hekim ayarı" yazmayan satırlar uygulama '
                'varsayılanıdır ve yanındaki etiket doğrulama durumunu '
                'gösterir.',
          ),

          // ---------------- Laboratuvar ----------------
          if (labsByAnalyte.isEmpty)
            section(
              'Laboratuvar',
              pw.Text('Bu dönemde kayıtlı tahlil yok.'),
            )
          else
            section(
              'Laboratuvar (${labs.length} kayıt)',
              pw.TableHelper.fromTextArray(
                headers: const [
                  'Analit',
                  'İlk',
                  'Son',
                  'Değişim',
                  'Lab aralığı',
                  'n',
                ],
                headerStyle: pw.TextStyle(font: _bodyBold, fontSize: 8.5),
                cellStyle: pw.TextStyle(fontSize: 8.5),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE4EDE7),
                ),
                data: [
                  for (final e in labsByAnalyte.entries)
                    () {
                      final list = e.value
                        ..sort((a, b) => a.takenAt.compareTo(b.takenAt));
                      final first = list.first;
                      final last = list.last;
                      final delta = last.value - first.value;
                      final range =
                          (last.refMin != null && last.refMax != null)
                              ? '${last.refMin}–${last.refMax}'
                              : '—';
                      return [
                        e.key,
                        '${_n(first.value)} (${_fmtDate(first.takenAt)})',
                        '${_n(last.value)} ${last.unit}',
                        list.length < 2
                            ? '—'
                            : '${delta >= 0 ? "+" : ""}${_n(delta)}',
                        range,
                        '${list.length}',
                      ];
                    }(),
                ],
              ),
              footnote: 'Hedef aralıklar hastanın laboratuvarının referans '
                  'aralığına göre değerlendirilmelidir.',
            ),

          // ---------------- Tansiyon ----------------
          section(
            'Kan basıncı',
            bpStats == null
                ? pw.Text('Bu dönemde kayıtlı tansiyon ölçümü yok.')
                : pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Table(
                        columnWidths: const {
                          0: pw.FlexColumnWidth(1),
                          1: pw.FlexColumnWidth(2),
                        },
                        children: [
                          _kv('Ölçüm sayısı', '${bpStats.count}'),
                          _kv(
                            'Ortalama',
                            '${bpStats.meanSystolic.round()}/'
                                '${bpStats.meanDiastolic.round()} mmHg',
                          ),
                          _kv(
                            'En yüksek',
                            '${bpStats.maxSystolic}/'
                                '${bpStats.maxDiastolic} mmHg',
                          ),
                          _kv(
                            'En düşük sistolik',
                            '${bpStats.minSystolic} mmHg',
                          ),
                          _kv(
                            'Alarm eşiği aşan ölçüm',
                            '${bpStats.aboveAlarm} '
                                '(${_pct(bpStats.aboveAlarm, bpStats.count)})',
                          ),
                          _kv(
                            'Hedefin (<${settings.resolve("bp_systolic_target").value?.round() ?? "—"}) '
                                'altındaki ölçüm',
                            '${bpStats.belowTarget} '
                                '(${_pct(bpStats.belowTarget, bpStats.count)})',
                          ),
                        ],
                      ),
                      if (bpStats.series.length > 1) ...[
                        pw.SizedBox(height: 8),
                        _lineChart(
                          bpStats.series
                              .map((p) => (x: p.at, y: p.systolic.toDouble()))
                              .toList(),
                          'Sistolik (mmHg)',
                          green,
                        ),
                      ],
                    ],
                  ),
            footnote: 'ACC/AHA 2017 sınıflaması ≥2 ayrı ölçümün '
                'ortalamasına dayanır; buradaki ortalama evde yapılan '
                'tüm ölçümlerin ortalamasıdır.',
          ),

          // ---------------- Kilo ----------------
          section(
            'Kilo ve sıvı yükü',
            weightSeries.isEmpty
                ? pw.Text('Bu dönemde kayıtlı kilo ölçümü yok.')
                : pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Table(
                        columnWidths: const {
                          0: pw.FlexColumnWidth(1),
                          1: pw.FlexColumnWidth(2),
                        },
                        children: [
                          _kv('Ölçüm sayısı', '${weightSeries.length}'),
                          _kv(
                            'İlk / son',
                            '${weightSeries.first.kg.toStringAsFixed(1)} kg / '
                                '${weightSeries.last.kg.toStringAsFixed(1)} kg',
                          ),
                          _kv(
                            'En yüksek / en düşük',
                            '${weightSeries.map((w) => w.kg).reduce((a, b) => a > b ? a : b).toStringAsFixed(1)} kg / '
                                '${weightSeries.map((w) => w.kg).reduce((a, b) => a < b ? a : b).toStringAsFixed(1)} kg',
                          ),
                          if (settings.dryWeightKg != null)
                            _kv(
                              'Kuru ağırlık üstü azami artış',
                              () {
                                final maxKg = weightSeries
                                    .map((w) => w.kg)
                                    .reduce((a, b) => a > b ? a : b);
                                final idwg = computeIdwg(
                                  currentKg: maxKg,
                                  dryWeightKg: settings.dryWeightKg!,
                                  thresholdPercent: settings
                                          .resolve('idwg_percent')
                                          .value ??
                                      4.0,
                                );
                                return idwg == null
                                    ? '—'
                                    : '${idwg.gainKg.toStringAsFixed(1)} kg '
                                        '(%${idwg.percent.toStringAsFixed(1)})';
                              }(),
                            ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      if (weightSeries.length > 1)
                        _lineChart(
                          weightSeries
                              .map((w) => (x: w.at, y: w.kg))
                              .toList(),
                          'Kilo (kg)',
                          gold,
                        ),
                    ],
                  ),
            footnote: settings.dryWeightKg == null
                ? 'Kuru ağırlık girilmediği için diyaliz arası kilo '
                    'artışı yüzdesi hesaplanamadı.'
                : 'Diyaliz arası kilo artışı hedefi, hastanın ayarına '
                    'göre kuru ağırlığın '
                    '%${(settings.resolve("idwg_percent").value ?? 4).toStringAsFixed(1)}'
                    '\'inden az.',
          ),

          // ---------------- İlaç uyumu ----------------
          section(
            'İlaç uyumu',
            adherence.totalDoses == 0
                ? pw.Text(
                    'Bu dönemde planlanmış ilaç dozu kaydı yok.',
                  )
                : pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Table(
                        columnWidths: const {
                          0: pw.FlexColumnWidth(1),
                          1: pw.FlexColumnWidth(2),
                        },
                        children: [
                          _kv('Planlanan doz', '${adherence.totalDoses}'),
                          _kv(
                            'Alındı',
                            '${adherence.taken} '
                                '(${_pct(adherence.taken, adherence.totalDoses)})',
                          ),
                          _kv(
                            'Atlandı',
                            '${adherence.skipped} '
                                '(${_pct(adherence.skipped, adherence.totalDoses)})',
                          ),
                          _kv(
                            'İşaretlenmedi',
                            '${adherence.pending} '
                                '(${_pct(adherence.pending, adherence.totalDoses)})',
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Kullandığı ilaçlar',
                        style: pw.TextStyle(font: _bodyBold, fontSize: 9.5),
                      ),
                      pw.SizedBox(height: 3),
                      for (final m in meds)
                        pw.Bullet(
                          text: '${m.name}'
                              '${m.dose == null ? "" : " — ${m.dose}"}'
                              ' — ${m.times}',
                          style: pw.TextStyle(fontSize: 8.5),
                        ),
                    ],
                  ),
            footnote: 'Uyum oranı hastanın uygulamada işaretlemesine '
                'dayanır; işaretlenmemiş dozlar alınmamış sayılmaz.',
          ),

          // ---------------- Besin ve sıvı ----------------
          section(
            'Besin ve sıvı (günlük ortalama)',
            pw.TableHelper.fromTextArray(
              headers: const ['Öğe', 'Günlük ortalama', 'Hedef', 'Durum'],
              headerStyle: pw.TextStyle(font: _bodyBold, fontSize: 8.5),
              cellStyle: pw.TextStyle(fontSize: 8.5),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE4EDE7),
              ),
              data: [
                [
                  'Enerji',
                  '${nutritionAvg.kcal.round()} kcal',
                  settings.dailyAbsoluteRange('energy_kcal_per_kg') == null
                      ? '—'
                      : '${settings.dailyAbsoluteRange("energy_kcal_per_kg")!.min.round()}'
                          '–${settings.dailyAbsoluteRange("energy_kcal_per_kg")!.max.round()}',
                  '',
                ],
                [
                  'Protein',
                  '${nutritionAvg.proteinG.toStringAsFixed(1)} g',
                  settings.dailyAbsolute('protein_g_per_kg') == null
                      ? '—'
                      : '${settings.dailyAbsolute("protein_g_per_kg")!.toStringAsFixed(0)} g',
                  _overUnder(
                    nutritionAvg.proteinG,
                    settings.dailyAbsolute('protein_g_per_kg'),
                  ),
                ],
                [
                  'Sodyum',
                  '${nutritionAvg.sodiumMg.round()} mg',
                  '${settings.resolve("sodium_mg").value?.round() ?? "—"} mg',
                  _overUnder(
                    nutritionAvg.sodiumMg,
                    settings.resolve('sodium_mg').value,
                  ),
                ],
                [
                  'Potasyum',
                  '${nutritionAvg.potassiumMg.round()} mg',
                  settings.resolve('potassium_mg').value == null
                      ? 'belirlenmedi'
                      : '${settings.resolve("potassium_mg").value!.round()} mg',
                  _overUnder(
                    nutritionAvg.potassiumMg,
                    settings.resolve('potassium_mg').value,
                  ),
                ],
                [
                  'Fosfor',
                  '${nutritionAvg.phosphorusMg.round()} mg',
                  settings.resolve('phosphorus_mg').value == null
                      ? 'belirlenmedi'
                      : '${settings.resolve("phosphorus_mg").value!.round()} mg',
                  _overUnder(
                    nutritionAvg.phosphorusMg,
                    settings.resolve('phosphorus_mg').value,
                  ),
                ],
                [
                  'Sıvı (kayıtlı)',
                  '${fluidAvg.round()} mL',
                  settings.resolve('fluid_ml').isCleared ||
                          settings.resolve('fluid_ml').value == null
                      ? 'limit yok'
                      : '${settings.resolve("fluid_ml").value!.round()} mL',
                  _overUnder(
                    fluidAvg,
                    settings.resolve('fluid_ml').value,
                  ),
                ],
              ],
            ),
            footnote: 'Besin değerleri YAKLAŞIKTIR ve hastanın girdiği '
                'kayıtlara dayanır (kaydedilmeyen öğünler ortalamayı '
                'düşürür). Kaynak: TürKomp ve USDA FoodData Central '
                'temelinde derlenmiş yerel tablo; barkodlu ürünlerde '
                'Open Food Facts. Potasyum ve fosfor çoğu paketli '
                'üründe etiketlenmediği için eksik olabilir.',
          ),

          // ---------------- Kaynaklar ----------------
          section(
            'Uygulamanın kullandığı klinik kaynaklar',
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final s in kClinicalSources)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '${s.name} (${s.year})',
                          style: pw.TextStyle(font: _bodyBold, fontSize: 8.5),
                        ),
                        pw.Text(
                          s.url,
                          style: const pw.TextStyle(
                            fontSize: 7.5,
                            color: PdfColor.fromInt(0xFF2F5668),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            footnote: 'Bağlantılar $kSourcesLastCheckedTr tarihinde '
                'erişilebilirdi.',
          ),

          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF5E8C8),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Text(
              '$kMedicalDisclaimerTr\n$kPrivacyNoteTr',
              style: pw.TextStyle(fontSize: 8, color: ink),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// Basit çizgi grafiği.
  pw.Widget _lineChart(
    List<({DateTime x, double y})> series,
    String label,
    PdfColor color,
  ) {
    if (series.length < 2) return pw.SizedBox.shrink();
    final sorted = [...series]..sort((a, b) => a.x.compareTo(b.x));
    final first = sorted.first.x.millisecondsSinceEpoch.toDouble();
    final last = sorted.last.x.millisecondsSinceEpoch.toDouble();
    final span = (last - first) == 0 ? 1.0 : (last - first);

    return pw.SizedBox(
      height: 110,
      child: pw.Chart(
        grid: pw.CartesianGrid(
          xAxis: pw.FixedAxis<double>(
            [0, 0.25, 0.5, 0.75, 1],
            format: (v) {
              final ms = first + (v as double) * span;
              return _fmtDate(
                DateTime.fromMillisecondsSinceEpoch(ms.round()),
              );
            },
            textStyle: const pw.TextStyle(fontSize: 6.5),
          ),
          yAxis: pw.FixedAxis<double>(
            _niceTicks(sorted.map((e) => e.y)),
            format: (v) => _n(v as double),
            textStyle: const pw.TextStyle(fontSize: 6.5),
            divisions: true,
          ),
        ),
        datasets: [
          pw.LineDataSet(
            legend: label,
            drawSurface: false,
            drawPoints: true,
            pointSize: 1.6,
            lineWidth: 1.2,
            color: color,
            data: [
              for (final p in sorted)
                pw.PointChartValue(
                  (p.x.millisecondsSinceEpoch - first) / span,
                  p.y,
                ),
            ],
          ),
        ],
      ),
    );
  }

  static List<double> _niceTicks(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return [0, 1];
    var min = list.reduce((a, b) => a < b ? a : b);
    var max = list.reduce((a, b) => a > b ? a : b);
    if (min == max) {
      min -= 1;
      max += 1;
    }
    final pad = (max - min) * 0.1;
    min -= pad;
    max += pad;
    final step = (max - min) / 4;
    return [for (var i = 0; i <= 4; i++) min + step * i];
  }

  Future<ClinicalSettings> _readSettings() async {
    final json = await _db.readJsonSetting('clinical_settings');
    return json == null
        ? const ClinicalSettings()
        : ClinicalSettings.fromJson(json);
  }

  /// PDF'i paylaşım penceresiyle paylaşır.
  Future<void> shareReport({required Duration window}) async {
    final bytes = await build(window: window);
    final stamp = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'bobrek-dostu-doktor-raporu-$stamp.pdf',
    );
  }

  /// Yazdırma / PDF önizleme.
  Future<void> printReport({required Duration window}) async {
    final bytes = await build(window: window);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  pw.TableRow _kv(String k, String v) => pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Text(
              k,
              style: const pw.TextStyle(
                fontSize: 8.5,
                color: PdfColor.fromInt(0xFF6B6459),
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Text(v, style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// SAF HESAPLAMALAR (test edilebilir)
// ---------------------------------------------------------------------------

class AdherenceStats {
  const AdherenceStats({
    required this.totalDoses,
    required this.taken,
    required this.skipped,
    required this.pending,
  });

  final int totalDoses;
  final int taken;
  final int skipped;
  final int pending;

  double get takenRatio => totalDoses == 0 ? 0 : taken / totalDoses;
}

AdherenceStats computeAdherence(List<MedicationDoseRow> doses) {
  var taken = 0;
  var skipped = 0;
  var pending = 0;
  for (final d in doses) {
    switch (d.status) {
      case 'taken':
        taken++;
      case 'skipped':
        skipped++;
      default:
        pending++;
    }
  }
  return AdherenceStats(
    totalDoses: doses.length,
    taken: taken,
    skipped: skipped,
    pending: pending,
  );
}

class BpStats {
  const BpStats({
    required this.count,
    required this.meanSystolic,
    required this.meanDiastolic,
    required this.maxSystolic,
    required this.maxDiastolic,
    required this.minSystolic,
    required this.aboveAlarm,
    required this.belowTarget,
    required this.series,
  });

  final int count;
  final double meanSystolic;
  final double meanDiastolic;
  final int maxSystolic;
  final int maxDiastolic;
  final int minSystolic;
  final int aboveAlarm;
  final int belowTarget;
  final List<({DateTime at, int systolic, int diastolic})> series;
}

BpStats? computeBpStats(
  List<VitalRow> vitals, {
  double alarmSystolic = 180,
  double targetSystolic = 120,
}) {
  final rows = vitals
      .where((v) => v.systolic != null && v.diastolic != null)
      .map((v) => (at: v.measuredAt, systolic: v.systolic!, diastolic: v.diastolic!))
      .toList()
    ..sort((a, b) => a.at.compareTo(b.at));
  if (rows.isEmpty) return null;

  final sys = rows.map((r) => r.systolic).toList();
  final dia = rows.map((r) => r.diastolic).toList();

  return BpStats(
    count: rows.length,
    meanSystolic: sys.reduce((a, b) => a + b) / sys.length,
    meanDiastolic: dia.reduce((a, b) => a + b) / dia.length,
    maxSystolic: sys.reduce((a, b) => a > b ? a : b),
    maxDiastolic: dia.reduce((a, b) => a > b ? a : b),
    minSystolic: sys.reduce((a, b) => a < b ? a : b),
    aboveAlarm: sys.where((s) => s >= alarmSystolic).length,
    belowTarget: sys.where((s) => s < targetSystolic).length,
    series: rows,
  );
}

class NutritionAverages {
  const NutritionAverages({
    required this.kcal,
    required this.proteinG,
    required this.sodiumMg,
    required this.potassiumMg,
    required this.phosphorusMg,
    required this.daysWithData,
  });

  final double kcal;
  final double proteinG;
  final double sodiumMg;
  final double potassiumMg;
  final double phosphorusMg;
  final int daysWithData;
}

/// Günlük ortalama besin alımı.
///
/// Bölen, VERİ GİRİLEN GÜN sayısıdır (dönemdeki tüm günler değil);
/// böylece boş günler ortalamayı yapay olarak düşürmez.
NutritionAverages computeNutritionAverages(
  List<FoodLogRow> logs,
  DateTime from,
  DateTime to,
) {
  if (logs.isEmpty) {
    return const NutritionAverages(
      kcal: 0,
      proteinG: 0,
      sodiumMg: 0,
      potassiumMg: 0,
      phosphorusMg: 0,
      daysWithData: 0,
    );
  }
  final days = logs
      .map((l) => DateTime(
            l.consumedAt.year,
            l.consumedAt.month,
            l.consumedAt.day,
          ))
      .toSet()
      .length;
  final divisor = days == 0 ? 1 : days;

  double sum(double? Function(FoodLogRow) f) =>
      logs.map(f).whereType<double>().fold(0.0, (a, b) => a + b);

  return NutritionAverages(
    kcal: sum((l) => l.kcal) / divisor,
    proteinG: sum((l) => l.proteinG) / divisor,
    sodiumMg: sum((l) => l.sodiumMg) / divisor,
    potassiumMg: sum((l) => l.potassiumMg) / divisor,
    phosphorusMg: sum((l) => l.phosphorusMg) / divisor,
    daysWithData: days,
  );
}

/// Günlük ortalama sıvı (kayıt girilen günlere bölünür).
double computeFluidAverage(
  List<FluidLogRow> logs,
  DateTime from,
  DateTime to,
) {
  if (logs.isEmpty) return 0;
  final days = logs
      .map((l) => DateTime(
            l.consumedAt.year,
            l.consumedAt.month,
            l.consumedAt.day,
          ))
      .toSet()
      .length;
  final total = logs.fold<int>(0, (a, b) => a + b.ml);
  return total / (days == 0 ? 1 : days);
}

String _overUnder(double actual, double? target) {
  if (target == null || target <= 0) return '';
  final pct = actual / target * 100;
  if (pct > 110) return 'Hedef üstü (%${pct.round()})';
  if (pct < 70) return 'Hedef altı (%${pct.round()})';
  return 'Hedefte (%${pct.round()})';
}

String _pct(int part, int total) =>
    total == 0 ? '—' : '%${(part / total * 100).round()}';

String _n(double v) => v.abs() >= 100
    ? v.toStringAsFixed(0)
    : (v.abs() >= 10 ? v.toStringAsFixed(1) : v.toStringAsFixed(2));

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.'
    '${d.month.toString().padLeft(2, '0')}.${d.year}';

String _fmtDateTime(DateTime d) =>
    '${_fmtDate(d)} ${d.hour.toString().padLeft(2, '0')}:'
    '${d.minute.toString().padLeft(2, '0')}';
