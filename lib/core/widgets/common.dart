import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../clinical/definitions.dart';
import '../../clinical/evaluator.dart';
import '../../clinical/sources.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../theme/neumorphic.dart';
import 'responsive.dart';

/// Bölüm başlığı (serif) + isteğe bağlı eylem.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    return Padding(
      padding: EdgeInsets.only(bottom: r.gapSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: p.accent, size: r.s(20)),
            SizedBox(width: r.gapSm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                if (subtitle != null) ...[
                  SizedBox(height: r.s(3)),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[SizedBox(width: r.gapSm), trailing!],
        ],
      ),
    );
  }
}

/// Her yerde görünen tıbbi uyarı şeridi.
class MedicalDisclaimerBanner extends StatelessWidget {
  const MedicalDisclaimerBanner({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    return Semantics(
      label: 'Tıbbi uyarı: $kMedicalDisclaimerTr',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: r.gapMd,
          vertical: compact ? r.gapXs : r.gapSm,
        ),
        decoration: BoxDecoration(
          color: p.accentSoft.withValues(alpha: p.isDark ? 0.6 : 0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: r.s(16), color: p.accent),
            SizedBox(width: r.gapSm),
            Expanded(
              child: Text(
                kMedicalDisclaimerTr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: p.textSecondary,
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Doğrulanmadı" / "Kaynaktan doğrulandı" etiketi.
class VerificationChip extends StatelessWidget {
  const VerificationChip({required this.verification, this.dense = false, super.key});

  final Verification verification;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color bg, Color fg, IconData ic) = switch (verification) {
      Verification.verified => (
          p.primarySoft,
          p.success,
          Icons.verified_outlined,
        ),
      Verification.unverified => (
          p.danger.withValues(alpha: 0.12),
          p.danger,
          Icons.help_outline_rounded,
        ),
      Verification.startingPoint => (
          p.accentSoft,
          p.warning,
          Icons.flag_outlined,
        ),
      Verification.individualized => (
          p.info.withValues(alpha: 0.12),
          p.info,
          Icons.person_outline_rounded,
        ),
    };

    return Tooltip(
      message: verification.explanationTr,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 7 : 9,
          vertical: dense ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fg.withValues(alpha: 0.3)),
        ),
        // Dar ekranda ve büyük yazı ölçeğinde daralabilsin:
        // etiket Flexible + ellipsis, böylece çağıran taraf sınırlı
        // genişlik verdiğinde taşma olmaz.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ic, size: dense ? 11 : 13, color: fg),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                verification.labelTr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uyarı kartı (alarm sonuçları için).
class AlertCard extends StatelessWidget {
  const AlertCard({required this.alert, this.onSourceTap, super.key});

  final Alert alert;
  final VoidCallback? onSourceTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    if (alert.level == AlertLevel.none && alert.messageTr.isEmpty) {
      return const SizedBox.shrink();
    }

    final (Color accent, IconData icon) = switch (alert.level) {
      AlertLevel.urgent => (p.danger, Icons.emergency_outlined),
      AlertLevel.warning => (p.warning, Icons.warning_amber_rounded),
      AlertLevel.info => (p.info, Icons.info_outline_rounded),
      AlertLevel.none => (p.success, Icons.check_circle_outline_rounded),
    };

    return NeuCard(
      color: accent.withValues(alpha: p.isDark ? 0.14 : 0.08),
      padding: EdgeInsets.all(r.gapMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: r.s(22)),
              SizedBox(width: r.gapSm),
              Expanded(
                child: Text(
                  alert.titleTr,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: accent),
                ),
              ),
              if (alert.verification != null)
                Flexible(
                  child: VerificationChip(
                    verification: alert.verification!,
                    dense: true,
                  ),
                ),
            ],
          ),
          if (alert.messageTr.isNotEmpty) ...[
            SizedBox(height: r.gapSm),
            Text(alert.messageTr,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (alert.sourceIds.isNotEmpty) ...[
            SizedBox(height: r.gapSm),
            SourceFootnote(sourceIds: alert.sourceIds, onTap: onSourceTap),
          ],
        ],
      ),
    );
  }
}

/// Kaynak dipnotu: "Kaynak: KDIGO 2024 ..." + dokununca Kaynaklar ekranı.
class SourceFootnote extends StatelessWidget {
  const SourceFootnote({required this.sourceIds, this.onTap, super.key});

  final List<String> sourceIds;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final sources = sourcesByIds(sourceIds);
    if (sources.isEmpty) return const SizedBox.shrink();
    final text = 'Kaynak: ${sources.map((s) => s.citation).join(" · ")}';
    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.menu_book_outlined, size: 13, color: p.textMuted),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: p.textMuted,
                  decoration: onTap != null ? TextDecoration.underline : null,
                  decorationColor: p.textMuted,
                ),
          ),
        ),
      ],
    );
    return onTap == null
        ? body
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(padding: const EdgeInsets.all(2), child: body),
          );
  }
}

/// Boş durum kartı.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    return NeuCard(
      padding: EdgeInsets.symmetric(horizontal: r.gapMd, vertical: r.gapLg),
      child: Column(
        children: [
          Icon(icon, size: r.s(40), color: p.textMuted),
          SizedBox(height: r.gapSm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: r.gapXs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (action != null) ...[SizedBox(height: r.gapMd), action!],
        ],
      ),
    );
  }
}

/// Yaklaşık/tahmini değer etiketi (besin değerleri, AI tahminleri).
class ApproximateBadge extends StatelessWidget {
  const ApproximateBadge({
    this.labelTr = 'yaklaşık',
    this.tooltipTr,
    super.key,
  });

  final String labelTr;
  final String? tooltipTr;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: p.backgroundDeep.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: p.divider),
      ),
      child: Text(
        '≈ $labelTr',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: p.textMuted,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
    if (tooltipTr == null) return chip;
    return Tooltip(
      message: tooltipTr!,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 6),
      child: chip,
    );
  }
}

/// Dokunma alanı en az 48dp olan ikon butonu.
class TapIcon extends StatelessWidget {
  const TapIcon({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.color,
    this.size = 22,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onPressed == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onPressed!();
              },
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Icon(
              icon,
              size: size,
              color: color ?? context.palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Sayfa gövdesi: kaydırılabilir, taşmaz, ortalanmış.
class PageBody extends StatelessWidget {
  const PageBody({
    required this.children,
    this.showDisclaimer = true,
    this.padBottom = true,
    this.controller,
    super.key,
  });

  final List<Widget> children;
  final bool showDisclaimer;
  final bool padBottom;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    return LayoutBuilder(
      builder: (context, _) => SingleChildScrollView(
        controller: controller,
        padding: EdgeInsets.only(
          left: r.pagePadding,
          right: r.pagePadding,
          top: r.gapSm,
          bottom: padBottom ? r.gapXl * 2 : r.gapMd,
        ),
        child: ContentColumn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: r.gapMd),
                StaggeredEntrance(index: i, child: children[i]),
              ],
              if (showDisclaimer) ...[
                SizedBox(height: r.gapLg),
                const MedicalDisclaimerBanner(compact: true),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
