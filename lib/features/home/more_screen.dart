import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/config/app_config.dart';
import '../../core/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/ai_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/responsive.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final conn = ref.watch(aiConnectionProvider).value;

    final groups = <({String title, IconData icon, List<_Item> items})>[
      (
        title: 'Takip',
        icon: Icons.insights_outlined,
        items: [
          _Item(
            icon: Icons.science_outlined,
            label: 'Laboratuvar takibi',
            subtitle: 'Manuel giriş, tahlil fotoğrafı, grafik ve trend',
            route: Routes.labs,
          ),
          _Item(
            icon: Icons.monitor_weight_outlined,
            label: 'Kilo, ödem ve tansiyon',
            subtitle: 'Günlük kayıt, grafikler, diyaliz arası kilo artışı',
            route: Routes.weight,
          ),
          _Item(
            icon: Icons.calendar_month_outlined,
            label: 'Diyaliz ve randevu takvimi',
            subtitle: 'Seans günleri, kontrol ve tahlil tarihleri',
            route: Routes.calendar,
          ),
          _Item(
            icon: Icons.watch_outlined,
            label: 'Akıllı saat verisi',
            subtitle: Platform.isIOS
                ? 'Apple Watch: nabız, EKG, uyku, SpO₂'
                : 'Health Connect: nabız, tansiyon, uyku, SpO₂',
            route: Routes.health,
          ),
          _Item(
            icon: Icons.restaurant_menu_outlined,
            label: 'Diyet planı ve uyum',
            subtitle: 'Planını gir, günlük uyumu işaretle',
            route: Routes.dietPlan,
          ),
        ],
      ),
      (
        title: 'Yardımcılar',
        icon: Icons.auto_awesome_outlined,
        items: [
          _Item(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Yapay zeka sohbeti',
            subtitle: conn == AiConnectionState.ok
                ? 'Hastalıkla ilgili sorularını sor'
                : 'Önce bağlantıyı kurman gerekiyor',
            route: Routes.ai,
            dimmed: conn != AiConnectionState.ok,
          ),
          _Item(
            icon: Icons.place_outlined,
            label: 'Yakındaki restoranlar',
            subtitle: 'Mesafe, süre ve mutfağa göre uygunluk',
            route: Routes.places,
          ),
          _Item(
            icon: Icons.luggage_outlined,
            label: 'Seyahat planlayıcı',
            subtitle: 'Yolda ne yenir, sıvı ve ilaç saatleri',
            route: Routes.travel,
          ),
          _Item(
            icon: Icons.menu_book_outlined,
            label: 'Okuma',
            subtitle: 'Güvenilir kaynaklardan içerik, çevrimdışı okunur',
            route: Routes.reading,
          ),
        ],
      ),
      (
        title: 'Paylaşım',
        icon: Icons.ios_share_outlined,
        items: [
          _Item(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Doktor raporu (PDF)',
            subtitle: 'Son 1 veya 3 ayın özeti, grafiklerle',
            route: Routes.report,
          ),
          _Item(
            icon: Icons.family_restroom_outlined,
            label: 'Yakın modu',
            subtitle: 'Günlük/haftalık özeti tek dokunuşla paylaş',
            route: Routes.caregiver,
          ),
          _Item(
            icon: Icons.emergency_outlined,
            label: 'Acil durum',
            subtitle: '112 kısayolu, konum ve kritik bilgi gönderimi',
            route: Routes.emergency,
            danger: true,
          ),
        ],
      ),
      (
        title: 'Ayarlar',
        icon: Icons.settings_outlined,
        items: [
          _Item(
            icon: Icons.tune_rounded,
            label: 'Klinik Ayarlar',
            subtitle: 'Tüm eşikler ve hedefler — serbestçe düzenlenebilir',
            route: Routes.clinicalSettings,
          ),
          _Item(
            icon: Icons.key_outlined,
            label: 'Yapay Zeka Bağlantısı',
            subtitle: conn == AiConnectionState.ok
                ? 'Bağlı — model ve veri paylaşımını yönet'
                : 'Anahtarını ekle',
            route: Routes.aiConnection,
          ),
          _Item(
            icon: Icons.menu_book_outlined,
            label: 'Kaynaklar',
            subtitle: 'Her klinik değerin kaynağı, yılı ve bağlantısı',
            route: Routes.sources,
          ),
          _Item(
            icon: Icons.shield_outlined,
            label: 'İzinler',
            subtitle: 'Hangi izin ne için — tek tek yönet',
            route: Routes.permissions,
          ),
          _Item(
            icon: Icons.settings_outlined,
            label: 'Tüm ayarlar',
            subtitle: 'Erişilebilirlik, bildirim, yedekleme',
            route: Routes.settings,
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: PageBody(
          children: [
            Padding(
              padding: EdgeInsets.only(top: r.gapSm),
              child: Text(
                'Tüm özellikler',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            for (final g in groups) ...[
              SectionHeader(title: g.title, icon: g.icon),
              for (final item in g.items)
                Padding(
                  padding: EdgeInsets.only(bottom: r.gapSm),
                  child: _MoreTile(item: item),
                ),
            ],
            NeuCard(
              color: p.backgroundDeep.withValues(alpha: 0.4),
              child: Column(
                children: [
                  Text(
                    '${AppConfig.appName} ${AppConfig.appVersion}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: r.gapXs),
                  Text(
                    'Tek profil · Giriş yok · Sunucu yok · '
                    'Veriler telefonda şifreli',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item {
  const _Item({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.route,
    this.dimmed = false,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final String route;
  final bool dimmed;
  final bool danger;
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.item});

  final _Item item;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final tone = item.danger ? p.danger : p.primary;

    return NeuCard(
      onTap: () => context.push(item.route),
      semanticLabel: '${item.label}. ${item.subtitle}',
      padding: EdgeInsets.all(r.gapMd),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(r.gapSm),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(item.icon, color: tone, size: r.s(21)),
          ),
          SizedBox(width: r.gapMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: item.dimmed ? p.textMuted : null,
                      ),
                ),
                SizedBox(height: r.s(2)),
                Text(
                  item.subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.textMuted),
        ],
      ),
    );
  }
}
