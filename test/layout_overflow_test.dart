import 'package:bobrek_dostu/clinical/definitions.dart';
import 'package:bobrek_dostu/core/theme/app_colors.dart';
import 'package:bobrek_dostu/core/theme/app_theme.dart';
import 'package:bobrek_dostu/core/theme/app_typography.dart';
import 'package:bobrek_dostu/core/theme/motion.dart';
import 'package:bobrek_dostu/core/theme/neumorphic.dart';
import 'package:bobrek_dostu/core/widgets/common.dart';
import 'package:bobrek_dostu/core/widgets/drop_leaf_logo.dart';
import 'package:bobrek_dostu/core/widgets/form_fields.dart';
import 'package:bobrek_dostu/core/widgets/progress_ring.dart';
import 'package:bobrek_dostu/core/widgets/responsive.dart';
import 'package:bobrek_dostu/core/widgets/trend_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Taşma (overflow) testleri.
///
/// 360x640 (küçük telefon), 390x844 (orta) ve 800x1280 (tablet)
/// boyutlarında; ayrıca en büyük yazı ölçeğiyle çalıştırılır.
/// Flutter taşmayı bir hata olarak bildirir, bu yüzden
/// `tester.takeException()` boş kalmalıdır.

const List<({double w, double h, String label})> viewports = [
  (w: 360, h: 640, label: '360x640 küçük telefon'),
  (w: 390, h: 844, label: '390x844 orta telefon'),
  (w: 800, h: 1280, label: '800x1280 tablet'),
];

Widget harness(
  Widget child, {
  double textScale = 1.0,
  bool highContrast = false,
  bool reduceMotion = false,
}) {
  final palette = AppPalette.resolve(dark: false, highContrast: highContrast);
  return MaterialApp(
    theme: AppTheme.build(palette),
    home: AppPaletteScope(
      palette: palette,
      child: AppMotionScope(
        motion: AppMotion(reduceMotion: reduceMotion),
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: Scaffold(
              backgroundColor: palette.background,
              body: child,
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> pumpAt(
  WidgetTester tester,
  Widget child, {
  required double w,
  required double h,
  double textScale = 1.0,
  bool highContrast = false,
}) async {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    harness(child, textScale: textScale, highContrast: highContrast),
  );
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

void main() {
  for (final v in viewports) {
    group(v.label, () {
      testWidgets('besin halkaları taşmaz', (tester) async {
        await pumpAt(
          tester,
          PageBody(
            children: [
              NeuCard(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final item in [
                      ('Enerji', 0.82, '1850', 'kcal'),
                      ('Protein', 1.14, '64.0', 'g'),
                      ('Sodyum', 0.95, '1900', 'mg'),
                      ('Potasyum', null, '2450', 'mg'),
                      ('Fosfor', 0.4, '640', 'mg'),
                    ])
                      ProgressRing(
                        ratio: item.$2,
                        label: item.$1,
                        valueText: item.$3,
                        unitText: item.$4,
                        size: 88,
                      ),
                  ],
                ),
              ),
            ],
          ),
          w: v.w,
          h: v.h,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('uzun Türkçe metinli kartlar taşmaz', (tester) async {
        await pumpAt(
          tester,
          PageBody(
            children: [
              const MedicalDisclaimerBanner(),
              const SectionHeader(
                title: 'Diyaliz arası kilo artışı',
                subtitle: 'Kuru ağırlığın yüzdesi olarak hesaplanır',
                icon: Icons.monitor_weight_outlined,
              ),
              NeuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      definitionByKey('potassium_mild')!.referenceTextTr,
                    ),
                    const SizedBox(height: 10),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        VerificationChip(
                          verification: Verification.unverified,
                        ),
                        ApproximateBadge(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const SourceFootnote(
                      sourceIds: [
                        'kdigo_potassium_2020',
                        'mayo_hyperkalemia_2021',
                      ],
                    ),
                  ],
                ),
              ),
              const EmptyState(
                title: 'Henüz kayıt yok',
                message: 'Sağ alttaki düğmeyle arama yapabilir, barkod '
                    'okutabilir, etiket veya yemek fotoğrafı çekebilirsin.',
              ),
            ],
          ),
          w: v.w,
          h: v.h,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('butonlar ve form alanları taşmaz', (tester) async {
        final c1 = TextEditingController(text: '72,5');
        addTearDown(c1.dispose);
        await pumpAt(
          tester,
          PageBody(
            children: [
              NeuCard(
                child: Column(
                  children: [
                    LabeledField(
                      label: 'Diyaliz arası kilo artışı eşiği',
                      hint: 'Kuru ağırlığın yüzdesi olarak girilir; '
                          'varsayılan %4,0.',
                      child: NumberField(controller: c1, suffix: 'kg'),
                    ),
                    const SizedBox(height: 14),
                    WeekdayPicker(selected: const {1, 3, 5}, onToggle: (_) {}),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: NeuButton(
                            label: 'Varsayılana dön',
                            icon: Icons.restart_alt_rounded,
                            compact: true,
                            expanded: true,
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: NeuButton(
                            label: 'Kaydet',
                            icon: Icons.check_rounded,
                            compact: true,
                            expanded: true,
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          w: v.w,
          h: v.h,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('grafik taşmaz', (tester) async {
        final base = DateTime(2026, 11, 1);
        await pumpAt(
          tester,
          PageBody(
            children: [
              NeuCard(
                child: TrendChart(
                  points: [
                    for (var i = 0; i < 12; i++)
                      (
                        at: base.add(Duration(days: i * 2)),
                        value: 70 + (i % 5) * 0.7,
                      ),
                  ],
                  unit: 'kg',
                  targetLine: 70,
                  targetLabelTr: 'kuru ağırlık',
                  height: 200,
                ),
              ),
            ],
          ),
          w: v.w,
          h: v.h,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('en büyük yazı ölçeğinde taşmaz', (tester) async {
        await pumpAt(
          tester,
          PageBody(
            children: [
              const MedicalDisclaimerBanner(),
              NeuCard(
                child: Row(
                  children: [
                    const ProgressRing(
                      ratio: 1.3,
                      label: 'Sıvı',
                      valueText: '1300',
                      unitText: 'mL',
                      size: 100,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sıvı bütçesi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'Günlük limitini 300 mL aştın. Ağız kuruluğu '
                            'için buz parçası emmeyi dene.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          w: v.w,
          h: v.h,
          // AppTypography.clampedScale üst sınırı 2.0
          textScale: 2.0,
        );
        expect(tester.takeException(), isNull);
      });
    });
  }

  group('Açılış işareti', () {
    testWidgets('animasyonsuz çizilir ve geri çağırır', (tester) async {
      var completed = false;
      await pumpAt(
        tester,
        Center(
          child: DropLeafMark(
            size: 120,
            animate: false,
            onCompleted: () => completed = true,
          ),
        ),
        w: 360,
        h: 640,
      );
      expect(tester.takeException(), isNull);
      expect(completed, isTrue);
    });

    testWidgets('animasyonlu çizim tamamlanır', (tester) async {
      var completed = false;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        harness(
          Center(
            child: DropLeafMark(
              size: 120,
              duration: const Duration(milliseconds: 600),
              onCompleted: () => completed = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 400));
      expect(completed, isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('Yüksek kontrast', () {
    testWidgets('yüksek kontrast paletiyle de taşma yok', (tester) async {
      await pumpAt(
        tester,
        PageBody(
          children: [
            const MedicalDisclaimerBanner(),
            NeuCard(
              child: Text(definitionByKey('lab_pth')!.referenceTextTr),
            ),
          ],
        ),
        w: 360,
        h: 640,
        highContrast: true,
        textScale: 1.4,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Responsive ölçek', () {
    test('ölçek sınırları içinde kalır', () {
      final small = Responsive.of(
        const BoxConstraints(maxWidth: 240, maxHeight: 400),
      );
      expect(small.scale, greaterThanOrEqualTo(0.88));
      expect(small.isCompact, isTrue);
      expect(small.columns, 1);

      final tablet = Responsive.of(
        const BoxConstraints(maxWidth: 1400, maxHeight: 900),
      );
      expect(tablet.scale, lessThanOrEqualTo(1.22));
      expect(tablet.isTablet, isTrue);
      expect(tablet.columns, 3);

      final phone = Responsive.of(
        const BoxConstraints(maxWidth: 390, maxHeight: 844),
      );
      expect(phone.scale, closeTo(1.0, 1e-9));
      expect(phone.columns, 1);
    });

    test('metin ölçeği 2.0 ile sınırlanır', () {
      expect(
        AppTypography.clampedScale(2.0, TextScaleStep.extraLarge),
        2.0,
      );
      expect(
        AppTypography.clampedScale(1.0, TextScaleStep.normal),
        1.0,
      );
      expect(
        AppTypography.clampedScale(0.5, TextScaleStep.normal),
        0.85,
      );
    });
  });
}
