import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart' hide Text;
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/responsive.dart';
import '../../core/i18n/i18n.dart';
import '../../core/i18n/text.dart';

/// Canlı barkod tarayıcı.
///
/// Eskiden barkod, çekilmiş tek bir fotoğraf üzerinde aranıyordu: kullanıcı
/// barkodu net çekebilirse okunuyordu, çoğu denemede okunmuyordu. Artık
/// kamera akışı sürekli taranır; kullanıcı barkodu çerçeveye tutar, cihaz
/// okur okumaz titreşimle haber verir.
///
/// Okunan kodu geri döndürür (`Navigator.pop` ile) ya da kullanıcı elle
/// yazarsa onu döndürür.
class BarcodeScannerView extends StatefulWidget {
  const BarcodeScannerView({super.key});

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  late final MobileScannerController _controller = MobileScannerController(
    // Gıda ambalajlarında kullanılan biçimler; dar liste okumayı hızlandırır.
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
    ],
    detectionSpeed: DetectionSpeed.normal,
    autoZoom: true,
  );

  bool _handled = false;
  bool _torch = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .firstOrNull;
    if (code == null) return;

    _handled = true;
    HapticFeedback.mediumImpact();
    unawaited(_controller.stop());
    if (mounted) Navigator.of(context).pop(code);
  }

  String _errorMessage(MobileScannerException e) => switch (e.errorCode) {
        MobileScannerErrorCode.permissionDenied =>
          'Kamera izni verilmedi. Barkod okumak için kameraya erişmem '
              'gerekiyor; izni ayarlardan açabilirsin.',
        MobileScannerErrorCode.unsupported =>
          'Bu cihazda barkod taraması desteklenmiyor. Kodu elle yazabilirsin.',
        _ => 'Kamera açılamadı. Kodu elle yazabilirsin.',
      };

  Future<void> _enterManually() async {
    final code = await showDialog<String>(
      context: context,
      builder: (context) => const _ManualCodeDialog(),
    );
    if (code != null && mounted) Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            tapToFocus: true,
            fit: BoxFit.cover,
            errorBuilder: (context, error) {
              final message = _errorMessage(error);
              return _ScannerFallback(
                messageTr: message,
                onManual: _enterManually,
              );
            },
            placeholderBuilder: (context) => ColoredBox(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(color: p.primary),
              ),
            ),
          ),

          // Hedef çerçevesi — nereye tutacağını gösterir.
          const _Reticle(),

          // Üst şerit: kapat + fener.
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(r.gapSm),
              child: Row(
                children: [
                  _CircleAction(
                    icon: Icons.close_rounded,
                    tooltip: 'Kapat',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  _CircleAction(
                    icon: _torch
                        ? Icons.flashlight_on_rounded
                        : Icons.flashlight_off_rounded,
                    tooltip: _torch ? 'Feneri kapat' : 'Feneri aç',
                    active: _torch,
                    onTap: () async {
                      await _controller.toggleTorch();
                      if (mounted) setState(() => _torch = !_torch);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Alt şerit: ne yapması gerektiği + elle giriş.
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(r.pagePadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Barkodu çerçeveye tut',
                      textAlign: TextAlign.center,
                      style: text.titleMedium?.copyWith(color: Colors.white),
                    ),
                    SizedBox(height: r.gapXs),
                    Text(
                      'Okunduğunda telefon kısa bir titreşimle haber verir. '
                      'Görüntü telefondan çıkmaz.',
                      textAlign: TextAlign.center,
                      style: text.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    SizedBox(height: r.gapMd),
                    NeuButton(
                      label: 'Kodu elle yaz',
                      icon: Icons.keyboard_rounded,
                      filled: false,
                      tone: NeuTone.neutral,
                      expanded: true,
                      onPressed: _enterManually,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Karartılmış zemin üstünde şeffaf bir pencere ve köşe işaretleri.
class _Reticle extends StatelessWidget {
  const _Reticle();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        // Barkodlar geniş ve alçaktır; pencere de öyle olmalı.
        final windowW = (w * 0.82).clamp(180.0, 420.0);
        final windowH = (windowW * 0.52).clamp(110.0, 240.0);
        final rect = Rect.fromCenter(
          center: Offset(w / 2, h * 0.42),
          width: windowW,
          height: windowH,
        );
        return IgnorePointer(
          child: CustomPaint(
            painter: _ReticlePainter(rect: rect, accent: p.primary),
            size: Size(w, h),
          ),
        );
      },
    );
  }
}

class _ReticlePainter extends CustomPainter {
  const _ReticlePainter({required this.rect, required this.accent});

  final Rect rect;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(18));

    // Pencere dışını karart.
    final scrim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(rrect),
    );
    canvas.drawPath(scrim, Paint()..color = const Color(0x99000000));

    // Köşe işaretleri.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = accent;
    const arm = 26.0;
    void corner(Offset c, double dx, double dy) {
      canvas.drawLine(c, c.translate(arm * dx, 0), paint);
      canvas.drawLine(c, c.translate(0, arm * dy), paint);
    }

    corner(rect.topLeft.translate(2, 2), 1, 1);
    corner(rect.topRight.translate(-2, 2), -1, 1);
    corner(rect.bottomLeft.translate(2, -2), 1, -1);
    corner(rect.bottomRight.translate(-2, -2), -1, -1);
  }

  @override
  bool shouldRepaint(_ReticlePainter old) =>
      old.rect != rect || old.accent != accent;
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      // Tooltip ve Semantics metni String alır; Flutter kendi çizer,
      // çeviren Text'imize uğramaz.
      message: t(tooltip),
      child: Semantics(
        button: true,
        label: t(tooltip),
        child: Pressable(
          onTap: onTap,
          radius: 24,
          // 48dp en küçük dokunma alanı.
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? p.primary : const Color(0x73000000),
              border: Border.all(color: const Color(0x4DFFFFFF)),
            ),
            child: Icon(
              icon,
              color: active ? p.onPrimary : Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScannerFallback extends StatelessWidget {
  const _ScannerFallback({required this.messageTr, required this.onManual});

  final String messageTr;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final text = Theme.of(context).textTheme;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(r.pagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined,
                  color: Colors.white, size: 40),
              SizedBox(height: r.gapSm),
              Text(
                messageTr,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: Colors.white),
              ),
              SizedBox(height: r.gapMd),
              NeuButton(
                label: 'Kodu elle yaz',
                icon: Icons.keyboard_rounded,
                onPressed: onManual,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barkod okunamadığında kodu elle girme.
class _ManualCodeDialog extends StatefulWidget {
  const _ManualCodeDialog();

  @override
  State<_ManualCodeDialog> createState() => _ManualCodeDialogState();
}

class _ManualCodeDialogState extends State<_ManualCodeDialog> {
  final TextEditingController _c = TextEditingController();
  String? _errorTr;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _c.text.trim();
    if (code.length < 6 || !RegExp(r'^\d+$').hasMatch(code)) {
      setState(() => _errorTr = 'Barkod yalnız rakamlardan oluşur, en az 6 hane.');
      return;
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Barkodu elle yaz'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ambalajın üstündeki rakamları olduğu gibi yaz. '
            'Genelde 8 ya da 13 hanelidir.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _c,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Barkod',
              errorText: _errorTr,
              counterText: '',
            ),
            maxLength: 14,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Ara')),
      ],
    );
  }
}
