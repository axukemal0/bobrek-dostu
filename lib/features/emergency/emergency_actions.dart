import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' hide Text;

import '../../core/config/app_config.dart';
import '../../core/providers.dart';
import '../../core/i18n/text.dart';

/// 112'yi arar. Onay istemez — acil durumda gecikme olmaması için.
///
/// Telefon uygulamasını açar; aramayı kullanıcı başlatır.
Future<void> call112(BuildContext context, WidgetRef ref) async {
  final ok = await ref
      .read(smsServiceProvider)
      .callEmergency(AppConfig.emergencyNumber);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Telefon uygulaması açılamadı. Numarayı elle çevir: 112',
        ),
      ),
    );
  }
}
