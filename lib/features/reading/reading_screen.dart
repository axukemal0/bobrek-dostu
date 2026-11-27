import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' hide Text;
import 'package:url_launcher/url_launcher.dart';

import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/services/reading_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/responsive.dart';
import '../../core/i18n/text.dart';
import '../../core/i18n/i18n.dart';

class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({super.key});

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  bool _refreshing = false;
  String? _statusTr;

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
      _statusTr = null;
    });
    final profile = ref.read(profileProvider).value;
    final result = await ref.read(readingServiceProvider).refreshFeeds(
          includeTechnical: profile?.expertMode ?? false,
        );
    if (!mounted) return;
    setState(() {
      _refreshing = false;
      _statusTr = [
        if (result.added > 0)
          tf('{0} yeni içerik eklendi.', [result.added])
        else
          'Yeni içerik yok.',
        if (result.failedTr.isNotEmpty)
          tf('Erişilemeyen kaynaklar: {0}', [result.failedTr.join('; ')]),
      ].join(' ');
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final articles = ref.watch(articlesProvider).value ?? const [];
    final profile = ref.watch(profileProvider).value;

    final builtin = articles.where((a) => a.origin == 'builtin').toList();
    final feed = articles.where((a) => a.origin == 'rss').toList();

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: const Text('Okuma'),
        actions: [
          TapIcon(
            icon: Icons.refresh_rounded,
            semanticLabel: 'İçerikleri yenile',
            onPressed: _refreshing ? null : _refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: PageBody(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kaynaklı, çevrimdışı okunabilir',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: r.gapXs),
                  Text(
                    'Buradaki içerikler telefona indirilir ve '
                    'internet olmadan da okunabilir. Her maddenin '
                    'kaynağı belirtilir.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            if (_statusTr != null)
              NeuCard(
                color: p.accentSoft.withValues(alpha: 0.5),
                child: Text(
                  _statusTr!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

            if (_refreshing)
              const NeuCard(
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 14),
                    Expanded(child: Text('Kaynaklar taranıyor…')),
                  ],
                ),
              ),

            // --- yerleşik içerikler ---
            const SectionHeader(
              title: 'Temel bilgiler',
              subtitle: 'Kılavuz kaynaklı, elle yazılmış içerikler',
              icon: Icons.local_library_outlined,
            ),
            for (final a in builtin)
              Padding(
                padding: EdgeInsets.only(bottom: r.gapSm),
                child: _ArticleCard(article: a, expandable: true),
              ),

            // --- akış ---
            SectionHeader(
              title: 'Kaynaklardan',
              subtitle: feed.isEmpty
                  ? 'Henüz içerik indirilmedi — yenile düğmesine bas'
                  : tf('{0} içerik', [feed.length]),
              icon: Icons.rss_feed_rounded,
            ),
            if (feed.isEmpty)
              NeuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Doğrulanmış kaynaklar',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SizedBox(height: r.gapSm),
                    for (final f in kVerifiedFeeds)
                      Padding(
                        padding: EdgeInsets.only(bottom: r.gapSm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              f.technical
                                  ? Icons.science_outlined
                                  : Icons.article_outlined,
                              size: r.s(16),
                              color: p.accent,
                            ),
                            SizedBox(width: r.gapSm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.nameTr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                  Text(
                                    f.descriptionTr,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: r.gapSm),
                    NeuButton(
                      label: 'İçerikleri indir',
                      icon: Icons.download_outlined,
                      compact: true,
                      expanded: true,
                      onPressed: _refreshing ? null : _refresh,
                    ),
                  ],
                ),
              )
            else
              for (final a in feed)
                Padding(
                  padding: EdgeInsets.only(bottom: r.gapSm),
                  child: _ArticleCard(article: a, expandable: false),
                ),

            // --- dürüstlük notu ---
            NeuCard(
              color: p.backgroundDeep.withValues(alpha: 0.45),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hangi kaynaklara erişilemedi?',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: r.gapSm),
                  Text(
                    'kidney.org (National Kidney Foundation), '
                    'kidneyfund.org, NIDDK, Mayo Clinic ve Türk '
                    'Nefroloji Derneği için makine ile okunabilir '
                    '(RSS) bir içerik akışı BULUNAMADI — bu siteler '
                    'RSS yayınlamıyor ya da otomatik erişimi '
                    'engelliyor. Bu kurumların bilgileri yerine '
                    '"Temel bilgiler" bölümünde elle yazılmış, '
                    'kaynak gösteren içerikler kullanıldı.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (profile?.expertMode != true) ...[
                    SizedBox(height: r.gapSm),
                    Text(
                      'Not: Uzman modu kapalı olduğu için teknik '
                      'dergi akışları (Kidney International, NephJC) '
                      'indirilmiyor. Uzman modunu ilk kurulumda veya '
                      'Ayarlar\'dan açabilirsin.',
                      style: Theme.of(context).textTheme.labelSmall,
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

class _ArticleCard extends ConsumerStatefulWidget {
  const _ArticleCard({required this.article, required this.expandable});

  final ArticleRow article;
  final bool expandable;

  @override
  ConsumerState<_ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends ConsumerState<_ArticleCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final a = widget.article;

    return NeuCard(
      padding: EdgeInsets.all(r.gapMd),
      onTap: widget.expandable ? () => setState(() => _open = !_open) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.title, style: Theme.of(context).textTheme.titleMedium),
          if (a.summary != null) ...[
            SizedBox(height: r.gapXs),
            Text(
              a.summary!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: _open ? null : 3,
              overflow: _open ? null : TextOverflow.ellipsis,
            ),
          ],
          if (_open && a.body != null && a.body != a.summary) ...[
            SizedBox(height: r.gapSm),
            SelectableText(
              a.body!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
          SizedBox(height: r.gapSm),
          Row(
            children: [
              Icon(
                Icons.verified_outlined,
                size: r.s(14),
                color: p.textMuted,
              ),
              SizedBox(width: r.gapXs),
              Expanded(
                child: Text(
                  'Kaynak: ${a.sourceName}'
                  '${a.publishedAt == null ? "" : " · ${_fmt(a.publishedAt!)}"}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              if (_open && a.body != null)
                TapIcon(
                  icon: Icons.volume_up_outlined,
                  semanticLabel: 'Sesli oku',
                  size: 17,
                  onPressed: () => ref
                      .read(ttsServiceProvider)
                      .speak('${a.title}. ${a.body ?? a.summary ?? ""}'),
                ),
              if (a.link != null)
                TapIcon(
                  icon: Icons.open_in_new_rounded,
                  semanticLabel: 'Kaynağı tarayıcıda aç',
                  size: 17,
                  onPressed: () async {
                    final uri = Uri.tryParse(a.link!);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
            ],
          ),
          if (widget.expandable && !_open)
            Padding(
              padding: EdgeInsets.only(top: r.gapXs),
              child: Text(
                'Devamını okumak için dokun',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: p.primary),
              ),
            ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';
}
