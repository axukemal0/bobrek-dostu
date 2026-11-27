import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/providers.dart';
import '../../core/services/health_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/responsive.dart';
import '../home/home_screen.dart' show showPermissionDialog;

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() =>
      _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  Map<AppPermission, AppPermissionStatus> _statuses = {};
  bool _healthGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final service = ref.read(permissionServiceProvider);
    final map = <AppPermission, AppPermissionStatus>{};
    for (final p in AppPermission.values) {
      map[p] = await service.status(p);
    }
    final health = await ref.read(healthServiceProvider).hasPermissions();
    if (!mounted) return;
    setState(() {
      _statuses = map;
      _healthGranted = health;
    });
  }

  Future<void> _request(AppPermission permission) async {
    if (permission == AppPermission.healthConnect) {
      final ok = await showPermissionDialog(
        context,
        permissionInfo(permission),
      );
      if (!ok) return;
      await ref.read(healthServiceProvider).requestPermissions();
      await _refresh();
      return;
    }

    final info = permissionInfo(permission);
    final ok = await showPermissionDialog(context, info);
    if (!ok) return;
    final result =
        await ref.read(permissionServiceProvider).request(permission);
    if (result == AppPermissionStatus.permanentlyDenied && mounted) {
      final open = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('İzin kalıcı olarak reddedilmiş'),
          content: Text(
            '${Platform.isIOS ? "iOS" : "Android"} bu izni bir daha '
            'sormuyor. Telefon ayarlarından elle vermen gerekiyor.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ayarları aç'),
            ),
          ],
        ),
      );
      if (open == true) {
        await ref.read(permissionServiceProvider).openSettings();
      }
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: const Text('İzinler'),
        actions: [
          TapIcon(
            icon: Icons.refresh_rounded,
            semanticLabel: 'Durumları yenile',
            onPressed: _refresh,
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
                    'Hiçbir izin zorunlu değil',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: r.gapXs),
                  Text(
                    'Her izin yalnızca bir özellik için kullanılır ve '
                    'o özelliğe ilk girdiğinde, gerekçesi söylenerek '
                    'TEK TEK istenir. Vermediğin izin yalnızca ilgili '
                    'özelliği kapatır; uygulamanın geri kalanı '
                    'çalışmaya devam eder.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            for (final info in kPermissionInfos)
              Padding(
                padding: EdgeInsets.only(bottom: r.gapSm),
                child: _PermissionCard(
                  info: info,
                  status: info.permission == AppPermission.healthConnect
                      ? (_healthGranted
                          ? AppPermissionStatus.granted
                          : AppPermissionStatus.denied)
                      : (_statuses[info.permission] ??
                          AppPermissionStatus.denied),
                  onRequest: () => _request(info.permission),
                ),
              ),

            NeuCard(
              color: p.backgroundDeep.withValues(alpha: 0.45),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hangi veri nereye gider?',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: r.gapSm),
                  for (final line in [
                    'Barkod ve metin okuma: TELEFONUN İÇİNDE '
                        '(google_mlkit, cihaz üstü). İnternete gitmez.',
                    'Konum: yalnızca Open-Meteo/Overpass/OSRM '
                        'sorgularında koordinat olarak, ve acil durum '
                        'mesajındaki harita bağlantısında kullanılır. '
                        'Kimliğinle birlikte hiçbir yere gönderilmez.',
                    Platform.isIOS
                        ? 'Ses tanıma: iPhone\'un kendi servisiyle yapılır.'
                        : 'Ses tanıma: Android\'in kendi servisiyle yapılır.',
                    '${HealthService.providerNameTr}: yalnızca OKUNUR, hiçbir şey '
                        'yazılmaz.',
                    'Yapay zeka: yalnızca sen bir AI özelliğini '
                        'kullandığında, o an onayladığın metin/görsel '
                        'Claude API\'ye gider.',
                  ])
                    Padding(
                      padding: EdgeInsets.only(bottom: r.gapXs),
                      child: Text(
                        '• $line',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),

            NeuButton(
              label: 'Telefon ayarlarını aç',
              icon: Icons.settings_applications_outlined,
              filled: false,
              expanded: true,
              onPressed: () =>
                  ref.read(permissionServiceProvider).openSettings(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.info,
    required this.status,
    required this.onRequest,
  });

  final PermissionInfo info;
  final AppPermissionStatus status;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final granted = status == AppPermissionStatus.granted;

    return NeuCard(
      padding: EdgeInsets.all(r.gapMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                granted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: granted ? p.success : p.textMuted,
                size: r.s(22),
              ),
              SizedBox(width: r.gapSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.titleTr,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      info.featureTr,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: granted
                      ? p.primarySoft
                      : p.backgroundDeep.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  switch (status) {
                    AppPermissionStatus.granted => 'verildi',
                    AppPermissionStatus.denied => 'verilmedi',
                    AppPermissionStatus.permanentlyDenied => 'reddedildi',
                    AppPermissionStatus.unavailable => 'yok',
                  },
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          SizedBox(height: r.gapSm),
          Text(
            info.whyTr,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (!granted &&
              status != AppPermissionStatus.unavailable) ...[
            SizedBox(height: r.gapMd),
            NeuButton(
              label: status == AppPermissionStatus.permanentlyDenied
                  ? 'Ayarlardan ver'
                  : 'İzin ver',
              compact: true,
              filled: false,
              expanded: true,
              onPressed: onRequest,
            ),
          ],
        ],
      ),
    );
  }
}
