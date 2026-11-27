import 'package:material_ui/material_ui.dart' hide Text;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/services.dart';

import '../../clinical/definitions.dart';
import '../../clinical/evaluator.dart';
import '../../clinical/sources.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../theme/neumorphic.dart';
import '../i18n/i18n.dart';
import '../i18n/languages.dart';
import '../i18n/text.dart';
import 'app_shell.dart';
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kMedicalDisclaimerTr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: p.textSecondary,
                          height: 1.35,
                        ),
                  ),

                  // Türkçe dışındaki her dilde makine çevirisi uyarısı.
                  // Klinik metinleri (ilaç uyarıları, tahlil yorumları,
                  // diyet kuralları) hiçbir uzman gözden geçirmedi;
                  // kullanıcının bunu bilmeye hakkı var. Uyarı şeridi
                  // her sayfanın altında olduğu için tek yerden gelir.
                  if (I18n.active != AppLanguage.tr) ...[
                    SizedBox(height: r.gapXs),
                    Text(
                      kMachineTranslationNoticeTr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: p.textMuted,
                            height: 1.3,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ],
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
    this.hasFab = false,
    this.controller,
    super.key,
  });

  final List<Widget> children;
  final bool showDisclaimer;
  final bool padBottom;

  /// Sayfada kayan eylem butonu varsa son kartın altına onun kadar yer
  /// bırakılır. Eskiden bu boşluk HER sayfaya veriliyordu; butonu olmayan
  /// ekranlarda uyarı şeridinin altında kocaman bir boşluk kalıyordu.
  final bool hasFab;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = EdgeInsets.only(
          left: r.pagePadding,
          right: r.pagePadding,
          top: r.gapSm,
          // Alt gezinme çubuğu gövdenin üstünde durduğu için onun yüksekliği
          // kadar fazladan boşluk bırakılır (kabuk dışındaki sayfalarda 0).
          bottom: (padBottom ? r.gapSm : 0) +
              (hasFab ? r.s(72) : 0) +
              BottomBarInset.of(context),
        );

        // Sayfanın gövdesine kalan yükseklik. Kısa sayfalarda uyarı
        // şeridi bu yüksekliğin ALTINA itilir.
        final available = constraints.maxHeight.isFinite
            ? (constraints.maxHeight - padding.vertical).clamp(0.0, 20000.0)
            : 0.0;

        final cards = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kartlar kısa bir gecikmeyle içeri süzülür. Gecikme en çok
            // altı kart sürer ([AppMotion.stagger]) ve her kart kendi
            // katmanında çizilir; böylece sayfanın açılışı canlı durur
            // ama kullanıcı yüklenmeyi İZLEMEK zorunda kalmaz.
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(height: r.gapMd),
              FadeSlideIn(
                delay: context.motion.stagger(i),
                child: children[i],
              ),
            ],
          ],
        );

        return SingleChildScrollView(
          controller: controller,
          // Parmakla kaydırınca klavye kapansın: sayısal klavyede kapatma
          // tuşu olmadığı için kullanıcı başka türlü sıkışabiliyor.
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: padding,
          child: ContentColumn(
            // DİKKAT — sayfanın altındaki BOŞLUK SORUNU buradan çözülür.
            //
            // Uyarı şeridi son kartın hemen altına konuyordu; kısa bir
            // sayfada (örn. "Henüz tahlil yok") şerit ekranın ortasında
            // asılı kalıyor ve altında kocaman bir boşluk oluyordu.
            // Artık gövdeye en az "ekran kadar" yükseklik veriliyor ve
            // iki parça arasındaki artık boşluk şeridi ALTA itiyor
            // (`spaceBetween`). Uzun sayfalarda artık boşluk sıfırdır,
            // yani davranış değişmez. Burada esnek (Expanded/Spacer)
            // çocuk YOK: o yüzden pahalı bir intrinsic ölçüm gerekmez.
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: available),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  cards,
                  if (showDisclaimer)
                    Padding(
                      padding: EdgeInsets.only(top: r.gapMd),
                      child: const MedicalDisclaimerBanner(compact: true),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Renkli ikon karosu — bir kartın hangi alana ait olduğunu söyler.
///
/// Uygulamanın her takip alanının (besin, sıvı, ilaç, tahlil, kilo…) kendi
/// rengi var; bu karo o rengi kartın başına koyar. Amaç süs değil yön
/// bulma: ekranı tarayan biri kartın ne hakkında olduğunu okumadan anlar.
/// Renk tek başına bilgi taşımaz — başlık zaten yanında yazar.
class AccentTile extends StatelessWidget {
  const AccentTile({
    required this.icon,
    required this.color,
    this.size,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final dimension = size ?? r.s(24);
    return Container(
      padding: EdgeInsets.all(r.gapSm),
      decoration: BoxDecoration(
        // Zemine karışmayan, rengin kendi tonundan yumuşak bir dolgu.
        color: color.withValues(alpha: p.isDark ? 0.20 : 0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: color, size: dimension),
    );
  }
}

/// Bölüm rengiyle boyanmış kayan eylem butonu.
///
/// Her ekranın birincil eylemi o bölümün rengini taşır (bkz. [AppAccents]).
/// Önceden hepsi aynı yeşildi: ekranlar birbirinden ayırt edilemiyordu ve
/// renk hiçbir iş yapmıyordu. Buton ayrıca gezinme çubuğunun üstüne
/// kaldırılır — [ShellFabLocation] bunu [BottomBarInset] ile yapar.
class SectionFab extends StatelessWidget {
  const SectionFab({
    required this.label,
    required this.onPressed,
    required this.tone,
    this.icon = Icons.add_rounded,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final Color tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final motion = context.motion;
    final fg = p.onAccent(tone);
    // Buton sayfa açılırken yerine oturur: hafif bir yaylanma
    // ("settle") yalnız burada kullanılıyor, gezinmede değil.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: motion.reduceMotion ? 1 : 0.6, end: 1),
      duration: motion.slow,
      curve: motion.settle,
      builder: (context, t, child) => Transform.scale(
        scale: t,
        child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        icon: Icon(icon, color: fg),
        label: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
        ),
        backgroundColor: tone,
        foregroundColor: fg,
        elevation: 3,
        highlightElevation: 6,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    );
  }
}

/// Sayısal klavyeyi kapatmak için klavyenin üstünde beliren çubuk.
///
/// iOS'un sayı tuş takımında "Bitti" / "Return" tuşu YOKTUR; alan tam
/// ekranı kaplayan bir alt sayfadaysa kullanıcı klavyeyi kapatamıyordu
/// (kilo ve tahlil girişlerinde yaşanan sorun buydu). Bu çubuk odak
/// varken görünür ve odağı bırakır. Android'de sistemin kendi geri tuşu
/// işi gördüğü için gösterilmez.
class KeyboardDismissBar extends StatelessWidget {
  const KeyboardDismissBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) return child;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final p = context.palette;

    return Stack(
      children: [
        child,
        if (keyboard > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: keyboard,
            child: Material(
              color: Colors.transparent,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: p.surface,
                  border: Border(
                    top: BorderSide(color: p.divider),
                    bottom: BorderSide(color: p.divider),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: p.shadowDark,
                      offset: const Offset(0, -2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  icon: Icon(
                    Icons.keyboard_hide_rounded,
                    size: 20,
                    color: p.primary,
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(88, 42),
                    foregroundColor: p.primary,
                  ),
                  label: Text(
                    'Bitti',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: p.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// İçeri süzülerek giren sarmalayıcı.
///
/// Tek bir denetleyici kullanır ve kendi katmanında kalır
/// ([RepaintBoundary]); listede onlarca öğe olduğunda bile sayfanın
/// geri kalanını yeniden çizdirmez. "Hareketi azalt" açıkken hiçbir
/// denetleyici kurulmaz — animasyon sıfır maliyetle kaybolur.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    required this.child,
    this.delay = Duration.zero,
    this.offset = 14,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    if (context.motion.reduceMotion) return;
    final c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _c = c;
    if (widget.delay == Duration.zero) {
      c.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) return widget.child;
    final curved = CurvedAnimation(parent: c, curve: Curves.easeOutCubic);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, child) => Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - curved.value)),
            child: child,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Değiştiğinde sayıyı sayarak gösteren metin.
///
/// Rakamlar tablo genişliğinde çizilir ([AppTypography.numeric]), bu
/// yüzden sayarken satır oynamaz.
class CountUpText extends StatelessWidget {
  const CountUpText({
    required this.value,
    this.decimals = 0,
    this.style,
    this.suffix,
    super.key,
  });

  final double value;
  final int decimals;
  final TextStyle? style;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: value, end: value),
      duration: motion.slow,
      curve: motion.emphasized,
      builder: (context, v, _) => Text(
        '${v.toStringAsFixed(decimals)}${suffix ?? ''}',
        style: style,
      ),
    );
  }
}
