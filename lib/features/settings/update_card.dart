import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' hide Text;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../core/services/update_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/responsive.dart';
import '../../core/i18n/text.dart';
import '../../core/i18n/i18n.dart';

/// Sürüm ve güncelleme kartı.
///
/// Uygulama mağazada olmadığı için güncellemeyi kendi haber verir.
/// Android'de APK doğrudan indirilip kurulabilir; iPhone'da Apple buna
/// izin vermediği için TestFlight açılır (orada "Automatic Updates"
/// açıksa güncelleme kendiliğinden iner).
class UpdateCard extends ConsumerStatefulWidget {
  const UpdateCard({super.key});

  @override
  ConsumerState<UpdateCard> createState() => _UpdateCardState();
}

class _UpdateCardState extends ConsumerState<UpdateCard> {
  String? _statusTr;
  bool _busy = false;
  double? _progress;
  String _current = '…';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((i) {
      if (mounted) setState(() => _current = '${i.version} (${i.buildNumber})');
    });
  }

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _statusTr = 'Denetleniyor…';
    });
    try {
      final update = await ref.read(updateServiceProvider).check();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _statusTr = update == null
            ? 'En güncel sürümü kullanıyorsun.'
            : null;
      });
      ref.invalidate(availableUpdateProvider);
    } on UpdateFailure catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _statusTr = e.messageTr;
        });
      }
    }
  }

  Future<void> _install(AvailableUpdate update) async {
    if (!update.canInstallDirectly) {
      await launchUrl(
        Uri.parse(update.releaseUrl),
        mode: LaunchMode.externalApplication,
      );
      return;
    }
    setState(() {
      _busy = true;
      _progress = 0;
      _statusTr = 'İndiriliyor…';
    });
    try {
      await ref.read(updateServiceProvider).downloadAndInstall(
            update,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
          _statusTr = 'Kurulum ekranı açıldı.';
        });
      }
    } on UpdateFailure catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
          _statusTr = e.messageTr;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final text = Theme.of(context).textTheme;
    final update = ref.watch(availableUpdateProvider).value;

    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AccentTile(
                icon: update == null
                    ? Icons.verified_outlined
                    : Icons.system_update_alt_rounded,
                color: update == null ? p.accents.medication : p.accent,
                size: r.s(20),
              ),
              SizedBox(width: r.gapMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      update == null ? 'Sürüm' : 'Yeni sürüm var',
                      style: text.titleMedium,
                    ),
                    Text(
                      update == null
                          ? tf('Yüklü: {0}', [_current])
                          : tf('Yüklü {0} → {1}', [_current, update.version]),
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (update?.notesTr?.isNotEmpty == true) ...[
            SizedBox(height: r.gapMd),
            Container(
              padding: EdgeInsets.all(r.gapSm),
              decoration: BoxDecoration(
                color: p.accentSoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                update!.notesTr!,
                style: text.bodySmall,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (_progress != null) ...[
            SizedBox(height: r.gapMd),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 7,
                backgroundColor: p.backgroundDeep,
                color: p.accent,
              ),
            ),
            SizedBox(height: r.gapXs),
            Text('%${((_progress ?? 0) * 100).round()}', style: text.labelSmall),
          ],
          if (_statusTr != null) ...[
            SizedBox(height: r.gapSm),
            Text(_statusTr!, style: text.bodySmall),
          ],
          SizedBox(height: r.gapMd),
          if (update != null)
            NeuButton(
              label: update.canInstallDirectly
                  ? 'İndir ve kur'
                  : 'TestFlight\'ta aç',
              icon: update.canInstallDirectly
                  ? Icons.download_rounded
                  : Icons.open_in_new_rounded,
              tone: NeuTone.accent,
              expanded: true,
              loading: _busy,
              onPressed: _busy ? null : () => _install(update),
            )
          else
            NeuButton(
              label: 'Güncellemeleri denetle',
              icon: Icons.refresh_rounded,
              filled: false,
              tone: NeuTone.neutral,
              expanded: true,
              loading: _busy,
              onPressed: _busy ? null : _check,
            ),
          SizedBox(height: r.gapSm),
          Text(
            Platform.isIOS
                ? 'iPhone\'da güncellemeler TestFlight üzerinden gelir. '
                    'TestFlight > Böbrek Dostu > "Automatic Updates" açıksa '
                    'yeni sürüm kendiliğinden kurulur.'
                : 'Güncellemeler doğrudan projenin GitHub sürüm sayfasından '
                    'iner. Kurulumu sistem yapar, onayı sen verirsin.',
            style: text.labelSmall,
          ),
        ],
      ),
    );
  }
}
