import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:material_ui/material_ui.dart' hide Text;

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/brand/brand_mark.dart';
import '../../core/widgets/responsive.dart';
import '../../core/i18n/text.dart';
import '../../core/i18n/i18n.dart';

/// PIN hash'i (SHA-256 + sabit tuz yerine kullanıcıya özgü tuz).
///
/// Bu bir parola deposu değil, yalnızca yerel bir kilit.
/// Gerçek koruma veritabanı şifrelemesinden gelir.
String hashPin(String pin, String salt) =>
    sha256.convert(utf8.encode('$salt::$pin')).toString();

const String kPinSalt = 'bobrek-dostu-local-lock-v1';

/// Biyometrik/PIN kilidi. Kapalıysa hiçbir şey yapmaz.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate>
    with WidgetsBindingObserver {
  bool _unlocked = false;
  bool _attempting = false;
  String _pinInput = '';
  String? _errorTr;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama arka plana alınınca yeniden kilitlenir.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (mounted && _unlocked) setState(() => _unlocked = false);
    }
  }

  Future<void> _tryBiometrics() async {
    if (_attempting) return;
    setState(() {
      _attempting = true;
      _errorTr = null;
    });
    try {
      final auth = LocalAuthentication();
      final can = await auth.canCheckBiometrics ||
          await auth.isDeviceSupported();
      if (!can) {
        setState(() {
          _errorTr = 'Bu cihazda biyometrik doğrulama kullanılamıyor. '
              'PIN ile gir.';
          _attempting = false;
        });
        return;
      }
      final ok = await auth.authenticate(
        localizedReason: 'Böbrek Dostu\'nu açmak için kimliğini doğrula',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (!mounted) return;
      setState(() {
        _unlocked = ok;
        _attempting = false;
        if (!ok) _errorTr = 'Doğrulama tamamlanmadı.';
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _attempting = false;
        _errorTr = tf('Biyometrik doğrulama başarısız: {0}', [e]);
      });
    }
  }

  Future<void> _submitPin() async {
    final stored = await ref.read(secureStoreProvider).readPinHash();
    if (!mounted) return;
    if (stored == null) {
      setState(() => _unlocked = true);
      return;
    }
    if (hashPin(_pinInput, kPinSalt) == stored) {
      setState(() {
        _unlocked = true;
        _pinInput = '';
        _errorTr = null;
      });
    } else {
      setState(() {
        _errorTr = 'PIN yanlış. Tekrar dene.';
        _pinInput = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    final p = context.palette;
    final r = Responsive.fromContext(context);

    // Ayarlar diskten okunmadan kilit kararı verilmez; aksi hâlde
    // soğuk açılışta bir kare boyunca uygulama içeriği görünürdü.
    if (!prefs.loaded) {
      return Material(
        color: p.background,
        child: Center(child: BrandMark(size: r.s(92))),
      );
    }

    if (!prefs.lockEnabled || _unlocked) return widget.child;

    return Material(
      color: p.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(r.gapLg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BrandMark(size: r.s(92)),
                  SizedBox(height: r.gapLg),
                  Text(
                    'Uygulama kilitli',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: r.gapXs),
                  Text(
                    'Sağlık verilerin korunuyor.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: r.gapLg),
                  if (prefs.useBiometrics)
                    NeuButton(
                      label: _attempting
                          ? 'Doğrulanıyor…'
                          : 'Parmak izi / yüz ile aç',
                      icon: Icons.fingerprint_rounded,
                      expanded: true,
                      onPressed: _attempting ? null : _tryBiometrics,
                    ),
                  SizedBox(height: r.gapMd),
                  NeuCard(
                    child: Column(
                      children: [
                        Text(
                          'PIN ile gir',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        SizedBox(height: r.gapSm),
                        TextField(
                          autofocus: !prefs.useBiometrics,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 8,
                          decoration: const InputDecoration(
                            hintText: '••••',
                            counterText: '',
                          ),
                          onChanged: (v) => _pinInput = v,
                          onSubmitted: (_) => _submitPin(),
                        ),
                        SizedBox(height: r.gapSm),
                        NeuButton(
                          label: 'Aç',
                          expanded: true,
                          onPressed: _submitPin,
                        ),
                      ],
                    ),
                  ),
                  if (_errorTr != null) ...[
                    SizedBox(height: r.gapMd),
                    Text(
                      _errorTr!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: p.danger),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
