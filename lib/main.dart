import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/db/database.dart';
import 'core/providers.dart';
import 'core/services/secure_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tek elle kullanım: dikey yönlendirme (tablette yatay da serbest).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  Object? startupError;
  AppDatabase? db;

  try {
    final store = SecureStore();
    db = await openEncryptedDatabase(
      keyStore: DatabaseKeyStore(store.raw),
    );
  } on Object catch (e) {
    // Şifreli veritabanı açılamazsa ŞİFRESİZ veriye DÜŞMEYİZ.
    startupError = e;
  }

  if (db == null) {
    runApp(StartupErrorApp(error: startupError));
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
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({required this.error, super.key});

  final Object? error;

  @override
  Widget build(BuildContext context) {
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
        body: SafeArea(
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
                  const Text(
                    'Şifreli veritabanı açılamadı',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A2621),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Uygulama verilerini yalnızca şifreli olarak saklar. '
                    'Şifreleme kurulamadığı için veri yazmayı durdurdum — '
                    'sağlık bilgilerin korumasız kaydedilmeyecek.\n\n'
                    'Yapabileceklerin:\n'
                    '• Uygulamayı kapatıp tekrar aç.\n'
                    '• Telefonu yeniden başlat.\n'
                    '• Sorun sürerse uygulamayı kaldırıp yeniden kur '
                    '(bu durumda cihazdaki veriler silinir).',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Color(0xFF574F44),
                    ),
                  ),
                  const SizedBox(height: 20),
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
    );
  }
}
