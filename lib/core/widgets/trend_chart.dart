import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import 'responsive.dart';

/// Zaman serisi grafiği (tahlil, kilo, tansiyon).
///
/// [refMin]/[refMax] verilirse referans aralığı gölgelenir.
class TrendChart extends StatelessWidget {
  const TrendChart({
    required this.points,
    required this.unit,
    this.secondarySeries,
    this.refMin,
    this.refMax,
    this.targetLine,
    this.targetLabelTr,
    this.height = 220,
    this.decimals = 1,
    super.key,
  });

  /// (zaman, değer) noktaları — sıralı olmak zorunda değil.
  final List<({DateTime at, double value})> points;

  /// İkinci seri (örn. diyastolik tansiyon).
  final List<({DateTime at, double value})>? secondarySeries;

  final String unit;
  final double? refMin;
  final double? refMax;
  final double? targetLine;
  final String? targetLabelTr;
  final double height;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);

    if (points.length < 2) {
      return SizedBox(
        height: height * 0.5,
        child: Center(
          child: Text(
            points.isEmpty
                ? 'Grafik için kayıt yok.'
                : 'Grafik için en az 2 kayıt gerekiyor.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final sorted = [...points]..sort((a, b) => a.at.compareTo(b.at));
    final secondary = secondarySeries == null
        ? null
        : ([...secondarySeries!]..sort((a, b) => a.at.compareTo(b.at)));

    final allValues = [
      ...sorted.map((e) => e.value),
      ...?secondary?.map((e) => e.value),
      ?refMin,
      ?refMax,
      ?targetLine,
    ];
    var minY = allValues.reduce((a, b) => a < b ? a : b);
    var maxY = allValues.reduce((a, b) => a > b ? a : b);
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }
    final pad = (maxY - minY) * 0.12;
    minY -= pad;
    maxY += pad;

    final firstMs = sorted.first.at.millisecondsSinceEpoch.toDouble();
    final lastMs = sorted.last.at.millisecondsSinceEpoch.toDouble();
    final span = (lastMs - firstMs) == 0 ? 1.0 : lastMs - firstMs;

    double x(DateTime d) =>
        (d.millisecondsSinceEpoch - firstMs) / span;

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.only(right: r.gapSm, top: r.gapSm),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 1,
            minY: minY,
            maxY: maxY,
            clipData: const FlClipData.all(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxY - minY) / 4,
              getDrawingHorizontalLine: (_) => FlLine(
                color: p.divider.withValues(alpha: 0.5),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            // Referans aralığı gölgesi.
            rangeAnnotations: RangeAnnotations(
              horizontalRangeAnnotations: [
                if (refMin != null || refMax != null)
                  HorizontalRangeAnnotation(
                    y1: refMin ?? minY,
                    y2: refMax ?? maxY,
                    color: p.primary.withValues(alpha: 0.10),
                  ),
              ],
            ),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                if (targetLine != null)
                  HorizontalLine(
                    y: targetLine!,
                    color: p.accent.withValues(alpha: 0.8),
                    strokeWidth: 1.6,
                    dashArray: [6, 4],
                    label: HorizontalLineLabel(
                      show: targetLabelTr != null,
                      labelResolver: (_) => targetLabelTr ?? '',
                      alignment: Alignment.topRight,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: r.s(42),
                  interval: (maxY - minY) / 4,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      value.toStringAsFixed(
                        (maxY - minY) > 20 ? 0 : decimals,
                      ),
                      style: Theme.of(context).textTheme.labelSmall,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: r.s(28),
                  interval: 0.5,
                  getTitlesWidget: (value, meta) {
                    final ms = firstMs + value * span;
                    final d = DateTime.fromMillisecondsSinceEpoch(ms.round());
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${d.day}.${d.month}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => p.isDark ? p.surface : p.textPrimary,
                getTooltipItems: (spots) => spots.map((s) {
                  final ms = firstMs + s.x * span;
                  final d =
                      DateTime.fromMillisecondsSinceEpoch(ms.round());
                  return LineTooltipItem(
                    '${s.y.toStringAsFixed(decimals)} $unit\n'
                    '${d.day}.${d.month}.${d.year}',
                    TextStyle(
                      color: p.isDark ? p.textPrimary : p.surface,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (final pt in sorted) FlSpot(x(pt.at), pt.value),
                ],
                isCurved: true,
                curveSmoothness: 0.22,
                preventCurveOverShooting: true,
                color: p.primary,
                barWidth: 2.6,
                dotData: FlDotData(
                  show: sorted.length <= 30,
                  getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                    radius: 3,
                    color: p.primary,
                    strokeColor: p.surface,
                    strokeWidth: 1.5,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      p.primary.withValues(alpha: 0.22),
                      p.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              if (secondary != null)
                LineChartBarData(
                  spots: [
                    for (final pt in secondary) FlSpot(x(pt.at), pt.value),
                  ],
                  isCurved: true,
                  curveSmoothness: 0.22,
                  preventCurveOverShooting: true,
                  color: p.accent,
                  barWidth: 2.2,
                  dotData: FlDotData(
                    show: secondary.length <= 30,
                    getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                      radius: 2.6,
                      color: p.accent,
                      strokeColor: p.surface,
                      strokeWidth: 1.4,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trend yönü özeti.
class TrendSummary extends StatelessWidget {
  const TrendSummary({
    required this.points,
    required this.unit,
    this.decimals = 1,
    this.higherIsWorse,
    super.key,
  });

  final List<({DateTime at, double value})> points;
  final String unit;
  final int decimals;

  /// null ise yön nötr gösterilir.
  final bool? higherIsWorse;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (points.length < 2) return const SizedBox.shrink();

    final sorted = [...points]..sort((a, b) => a.at.compareTo(b.at));
    final delta = sorted.last.value - sorted.first.value;
    final rising = delta > 0;

    final Color tone;
    if (higherIsWorse == null || delta.abs() < 0.0001) {
      tone = p.textMuted;
    } else {
      tone = (rising == higherIsWorse!) ? p.warning : p.success;
    }

    return Row(
      children: [
        Icon(
          delta.abs() < 0.0001
              ? Icons.trending_flat_rounded
              : (rising
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded),
          color: tone,
          size: 18,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${sorted.first.value.toStringAsFixed(decimals)} → '
            '${sorted.last.value.toStringAsFixed(decimals)} $unit '
            '(${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(decimals)})',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: tone),
          ),
        ),
      ],
    );
  }
}
