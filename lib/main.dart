import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' hide Text;

import 'app.dart';
import 'core/db/database.dart';
import 'core/providers.dart';
import 'core/services/secure_store.dart';
import 'core/i18n/text.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _start();
}

/// Veritabanını açar ve uygulamayı başlatır.
///
/// Ayrı bir fonksiyon: "veriyi sıfırla" düğmesi aynı yoldan yeniden
/// girebilsin diye.
Future<void> _start() async {

  // Tek elle kullanım: dikey yönlendirme (tablette yatay da serbest).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  Object? startupError;
  var unreadable = false;
  AppDatabase? db;

  try {
    final store = SecureStore();
    db = await openEncryptedDatabase(
      keyStore: DatabaseKeyStore(store.raw),
    );
  } on DatabaseOpenFailure catch (e) {
    // Şifreli veritabanı açılamazsa ŞİFRESİZ veriye DÜŞMEYİZ.
    startupError = e.cause;
    unreadable = e.unreadable;
  } on Object catch (e) {
    startupError = e;
  }

  if (db == null) {
    runApp(StartupErrorApp(error: startupError, unreadable: unreadable));
    return;
  }

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const BobrekDostuApp(),
    ),
  );
}

/// Veritabanı açılamadığında gösterilen ekran.
///
/// Sessizce şifresiz çalışmak yerine durumu açıkça söyler.
class StartupErrorApp extends StatefulWidget {
  const StartupErrorApp({
    required this.error,
    this.unreadable = false,
    super.key,
  });

  final Object? error;

  /// Dosya var ama eldeki anahtarla çözülemiyor.
  final bool unreadable;

  @override
  State<StartupErrorApp> createState() => _StartupErrorAppState();
}

class _StartupErrorAppState extends State<StartupErrorApp> {
  bool _resetting = false;

  /// [dialogContext] Navigator'ın ALTINDAN gelmeli.
  ///
  /// State'in kendi context'i MaterialApp'in ÜSTÜNDE kalıyor; oradan
  /// showDialog çağırmak sessizce başarısız oluyordu (düğmeye
  /// basıldığında hiçbir şey olmuyordu).
  Future<void> _resetData(BuildContext dialogContext) async {
    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: const Text('Sıfırdan başla'),
        content: const Text(
          'Okunamayan veritabanı dosyası kenara alınacak ve uygulama '
          'BOŞ bir veritabanıyla açılacak.\n\n'
          'Eski kayıtlarına (tahlil, ilaç, sıvı, kilo) bir daha '
          'ulaşamayacaksın — şifre anahtarı kaybolduğu için o dosya '
          'zaten çözülemiyor. Dosya silinmiyor, yalnız kenara '
          'alınıyor.\n\n'
          'Devam edeyim mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sıfırdan başla'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _resetting = true);
    try {
      await setAsideUnreadableDatabase();
      await _start();
    } on Object catch (e) {
      if (mounted) {
        setState(() => _resetting = false);
        if (dialogContext.mounted) {
          ScaffoldMessenger.maybeOf(dialogContext)?.showSnackBar(
            SnackBar(content: Text('Sıfırlanamadı: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.error;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F1E7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3C6B54),
        ),
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 48,
                    color: Color(0xFF9E3528),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.unreadable
                        ? 'Kayıtlı veri çözülemiyor'
                        : 'Şifreli veritabanı açılamadı',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A2621),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.unreadable
                        ? 'Veritabanı dosyası yerinde ama ŞİFRE ANAHTARI '
                            'eşleşmiyor; bu yüzden içeriği okunamıyor. '
                            'Anahtar telefonun güvenli deposunda tutulur '
                            've yedekten geri yükleme, anahtar deposunun '
                            'sıfırlanması ya da uygulamanın farklı bir '
                            'imzayla yeniden kurulması sonrası '
                            'kaybolabilir.\n\n'
                            'Bu dosya bir daha açılamaz. Aşağıdaki '
                            'düğmeyle onu kenara alıp boş bir '
                            'veritabanıyla devam edebilirsin.'
                        : 'Uygulama verilerini yalnızca şifreli olarak '
                            'saklar. Şifreleme kurulamadığı için veri '
                            'yazmayı durdurdum — sağlık bilgilerin '
                            'korumasız kaydedilmeyecek.\n\n'
                            'Yapabileceklerin:\n'
                            '• Uygulamayı kapatıp tekrar aç.\n'
                            '• Telefonu yeniden başlat.\n'
                            '• Sorun sürerse uygulamayı kaldırıp '
                            'yeniden kur (bu durumda cihazdaki veriler '
                            'silinir).',
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Color(0xFF574F44),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (widget.unreadable)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            _resetting ? null : () => _resetData(context),
                        icon: _resetting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.restart_alt_rounded),
                        label: Text(
                          _resetting
                              ? 'Sıfırlanıyor…'
                              : 'Kenara al ve sıfırdan başla',
                        ),
                      ),
                    ),
                  if (widget.unreadable) const SizedBox(height: 20),
                  if (error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBE2D1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Teknik ayrıntı:\n$error',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Color(0xFF574F44),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
