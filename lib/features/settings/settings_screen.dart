import 'dart:io' show Platform;

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' hide Text;
import 'update_card.dart';
import '../../core/services/permission_service.dart';
import '../home/home_screen.dart' show showPermissionDialog;

import '../../clinical/definitions.dart';
import '../../core/config/app_config.dart';
import '../../core/db/database.dart';
import '../../core/i18n/languages.dart';
import '../../core/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/responsive.dart';
import 'lock_gate.dart';
import '../../core/i18n/text.dart';
import '../../core/i18n/i18n.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _statusTr;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final prefs = ref.watch(preferencesProvider);
    final profile = ref.watch(profileProvider).value;
    final conn = ref.watch(aiConnectionProvider).value;
    final quiet = ref.watch(quietHoursProvider).value ??
        const QuietHours();

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(title: const Text('Ayarlar')),
      body: SafeArea(
        child: PageBody(
          children: [
            // ============ DİL ============
            // En üstte duruyor: yanlış dile düşen biri aşağı inmek
            // zorunda kalmadan geri dönebilmeli. Dil adları kendi
            // dillerinde yazılı, o yüzden hangi dilde olursan ol okunur.
            const SectionHeader(
              title: 'Dil',
              icon: Icons.translate_rounded,
            ),
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Uygulamanın dili. Türkçe dışındaki diller makine '
                    'çevirisidir; klinik metinler bir uzman tarafından '
                    'gözden geçirilmedi.',
                  ),
                  SizedBox(height: r.gapMd),
                  Wrap(
                    spacing: r.gapSm,
                    runSpacing: r.gapSm,
                    children: [
                      for (final language in AppLanguage.values)
                        _LanguageChip(
                          language: language,
                          selected: language == prefs.language,
                          onTap: () => ref
                              .read(preferencesProvider.notifier)
                              .update((p) => p.copyWith(language: language)),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ============ KLİNİK ============
            const SectionHeader(
              title: 'Klinik',
              icon: Icons.medical_information_outlined,
            ),
            _NavTile(
              icon: Icons.tune_rounded,
              title: 'Klinik Ayarlar',
              subtitle: 'Tüm hedefler ve alarm eşikleri — '
                  'serbestçe düzenlenebilir',
              route: Routes.clinicalSettings,
              highlight: true,
            ),
            _NavTile(
              icon: Icons.menu_book_outlined,
              title: 'Kaynaklar',
              subtitle: 'Her değerin kaynağı, yılı ve bağlantısı',
              route: Routes.sources,
            ),

            // ============ YAPAY ZEKA ============
            const SectionHeader(
              title: 'Yapay zeka',
              icon: Icons.auto_awesome_outlined,
            ),
            _NavTile(
              icon: Icons.key_outlined,
              title: 'Yapay Zeka Bağlantısı',
              subtitle: switch (conn) {
                AiConnectionState.ok =>
                  tf('Bağlı · {0}', [prefs.aiModel ?? 'varsayılan model']),
                AiConnectionState.failed => 'Bağlantı başarısız',
                AiConnectionState.untested => 'Test edilmedi',
                _ => 'Anahtar yok — AI özellikleri kapalı',
              },
              route: Routes.aiConnection,
            ),

            // ============ ERİŞİLEBİLİRLİK ============
            const SectionHeader(
              title: 'Erişilebilirlik',
              icon: Icons.accessibility_new_rounded,
            ),
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LabeledField(
                    label: 'Yazı boyutu',
                    hint: 'Telefonun kendi yazı boyutu ayarının '
                        'üzerine biner. Taşmayı önlemek için toplam '
                        'ölçek sınırlanır.',
                    child: SegmentedButton<TextScaleStep>(
                      segments: [
                        for (final s in TextScaleStep.values)
                          ButtonSegment(
                            value: s,
                            label: Text(s.labelTr),
                          ),
                      ],
                      selected: {prefs.textScaleStep},
                      showSelectedIcon: false,
                      onSelectionChanged: (sel) => ref
                          .read(preferencesProvider.notifier)
                          .update(
                            (pr) =>
                                pr.copyWith(textScaleStep: sel.first),
                          ),
                    ),
                  ),
                  SizedBox(height: r.gapMd),
                  Container(
                    padding: EdgeInsets.all(r.gapSm),
                    decoration: BoxDecoration(
                      color: p.backgroundDeep.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Örnek metin: Günlük sodyum hedefin 2000 mg. '
                      'Bu boyutta rahat okuyabiliyor musun?',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  SwitchListTile.adaptive(
                    value: prefs.highContrast,
                    onChanged: (v) => ref
                        .read(preferencesProvider.notifier)
                        .update((pr) => pr.copyWith(highContrast: v)),
                    title: const Text('Yüksek kontrast'),
                    subtitle: const Text(
                      'Metin renklerini koyulaştırır, kenarları '
                      'belirginleştirir.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile.adaptive(
                    value: prefs.reduceMotion,
                    onChanged: (v) => ref
                        .read(preferencesProvider.notifier)
                        .update((pr) => pr.copyWith(reduceMotion: v)),
                    title: const Text('Hareketi azalt'),
                    subtitle: const Text(
                      'Tüm animasyonları kapatır. Telefonun kendi '
                      '"animasyonları kaldır" ayarına da uyulur.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile.adaptive(
                    value: prefs.followSystemDark,
                    onChanged: (v) => ref
                        .read(preferencesProvider.notifier)
                        .update((pr) => pr.copyWith(followSystemDark: v)),
                    title: const Text('Temayı telefondan al'),
                    subtitle: const Text(
                      'Kapatırsan gece modunu elle seçersin.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (!prefs.followSystemDark)
                    SwitchListTile.adaptive(
                      value: prefs.darkMode,
                      onChanged: (v) => ref
                          .read(preferencesProvider.notifier)
                          .update((pr) => pr.copyWith(darkMode: v)),
                      title: const Text('Gece modu'),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),

            // ============ SES ============
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sesli okuma (Türkçe)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: r.gapSm),
                  FutureBuilder<bool>(
                    future: ref
                        .read(ttsServiceProvider)
                        .isTurkishAvailable(),
                    builder: (context, snapshot) {
                      final available = snapshot.data;
                      return Text(
                        available == null
                            ? 'Kontrol ediliyor…'
                            : (available
                                ? 'Türkçe ses cihazda yüklü. '
                                    'Sohbet cevaplarını ve okuma '
                                    'içeriklerini sesli '
                                    'dinleyebilirsin.'
                                : 'Türkçe ses paketi cihazda '
                                    'bulunamadı. Android Ayarlar > '
                                    'Erişilebilirlik > Metin okuma '
                                    'bölümünden Türkçe sesi '
                                    'indirebilirsin.'),
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                  SizedBox(height: r.gapMd),
                  NeuButton(
                    label: 'Sesi dene',
                    icon: Icons.volume_up_outlined,
                    compact: true,
                    filled: false,
                    expanded: true,
                    onPressed: () => ref.read(ttsServiceProvider).speak(
                          'Merhaba. Bugün sıvı bütçenden '
                          'altı yüz mililitre kaldı.',
                        ),
                  ),
                ],
              ),
            ),

            // ============ BİLDİRİM ============
            const SectionHeader(
              title: 'Bildirimler',
              icon: Icons.notifications_outlined,
            ),
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tf(
                      'İlaç ve randevu bildirimleri her zaman gönderilir '
                      '(kritik). Diğerleri günde en fazla {0} tanedir ve '
                      'sessiz saatlerde gönderilmez.',
                      [NotificationService.maxDiscretionaryPerDay],
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: r.gapSm),
                  // Bildirimlerin gerçekten geldiğini kullanıcı kendi
                  // telefonunda görebilsin: izin, kanal ve ikon zinciri
                  // tek dokunuşla sınanır.
                  NeuButton(
                    label: 'Bildirimi dene',
                    icon: Icons.notifications_active_outlined,
                    filled: false,
                    tone: NeuTone.neutral,
                    expanded: true,
                    onPressed: () async {
                      final service = ref.read(permissionServiceProvider);
                      if (await service.status(AppPermission.notifications) !=
                          AppPermissionStatus.granted) {
                        if (!context.mounted) return;
                        final ok = await showPermissionDialog(
                          context,
                          permissionInfo(AppPermission.notifications),
                        );
                        if (!ok) return;
                        if (await service
                                .request(AppPermission.notifications) !=
                            AppPermissionStatus.granted) {
                          if (context.mounted) {
                            setState(() => _statusTr =
                                'Bildirim izni verilmedi.');
                          }
                          return;
                        }
                      }
                      final sent = await ref
                          .read(notificationServiceProvider)
                          .show(
                            category: NotifCategory.medication,
                            title: 'Böbrek Dostu',
                            body: 'Bildirimler çalışıyor. İlaç ve randevu '
                                'hatırlatmaların bu şekilde gelecek.',
                          );
                      if (context.mounted) {
                        setState(() => _statusTr = sent
                            ? 'Deneme bildirimi gönderildi.'
                            : 'Bildirim gönderilemedi.');
                      }
                    },
                  ),
                  SwitchListTile.adaptive(
                    value: prefs.smartNotifications,
                    onChanged: (v) => ref
                        .read(preferencesProvider.notifier)
                        .update((pr) => pr.copyWith(smartNotifications: v)),
                    title: const Text('Akıllı bildirimler'),
                    subtitle: const Text(
                      'Hava/UV/hava kalitesi uyarıları. Sıvı limitin '
                      'varsa metinler limitine saygı duyar.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile.adaptive(
                    value: prefs.dailySummary,
                    onChanged: (v) => ref
                        .read(preferencesProvider.notifier)
                        .update((pr) => pr.copyWith(dailySummary: v)),
                    title: const Text('Günlük bilgilendirici özet'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile.adaptive(
                    value: prefs.mealMarkReminder,
                    onChanged: (v) => ref
                        .read(preferencesProvider.notifier)
                        .update((pr) => pr.copyWith(mealMarkReminder: v)),
                    title: const Text('Diyet öğünü hatırlatması'),
                    subtitle: Text(
                      prefs.mealMarkReminder
                          ? tf(
                              'Akşam {0} saatinde, o gün işaretlenmemiş öğün '
                              'kaldıysa TEK bildirim. Hepsi işaretliyse bildirim '
                              'gelmez.',
                              [formatHour(prefs.mealMarkReminderHour)],
                            )
                          : 'Kapalı. Öğün işaretlemeyi kendin hatırlarsın.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (prefs.mealMarkReminder)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Hatırlatma saati'),
                      trailing: Text(
                        formatHour(prefs.mealMarkReminderHour),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: prefs.mealMarkReminderHour,
                            minute: 0,
                          ),
                          helpText: 'Hatırlatma saati',
                        );
                        if (picked != null) {
                          await ref.read(preferencesProvider.notifier).update(
                                (pr) => pr.copyWith(
                                  mealMarkReminderHour: picked.hour,
                                ),
                              );
                        }
                      },
                    ),
                  SwitchListTile.adaptive(
                    value: prefs.lowStepsNotification,
                    onChanged: (v) => ref
                        .read(preferencesProvider.notifier)
                        .update(
                          (pr) => pr.copyWith(lowStepsNotification: v),
                        ),
                    title: const Text('Düşük adım bildirimi'),
                    subtitle: Text(
                      Platform.isIOS
                          ? 'iPhone Sağlık izni gerekir.'
                          : 'Health Connect izni gerekir.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile.adaptive(
                    value: prefs.waterReminders,
                    onChanged: (v) => ref
                        .read(preferencesProvider.notifier)
                        .update((pr) => pr.copyWith(waterReminders: v)),
                    title: const Text('Sıvı hatırlatması'),
                    subtitle: const Text(
                      'VARSAYILAN KAPALI. Sıvı limiti olan hastada '
                      'açılması önerilmez.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SizedBox(height: r.gapSm),
                  Divider(color: p.divider),
                  SizedBox(height: r.gapSm),
                  Text(
                    tf('Sessiz saatler: {0}', [quiet.labelTr]),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: r.gapXs),
                  Text(
                    'Bu aralıkta yalnızca ilaç ve randevu '
                    'bildirimleri gelir.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: r.gapSm),
                  Row(
                    children: [
                      Expanded(
                        child: NeuButton(
                          label: 'Başlangıç',
                          icon: Icons.bedtime_outlined,
                          filled: false,
                          compact: true,
                          expanded: true,
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: quiet.startHour,
                                minute: quiet.startMinute,
                              ),
                            );
                            if (picked == null) return;
                            await ref
                                .read(notificationServiceProvider)
                                .writeQuietHours(
                                  QuietHours(
                                    enabled: quiet.enabled,
                                    startHour: picked.hour,
                                    startMinute: picked.minute,
                                    endHour: quiet.endHour,
                                    endMinute: quiet.endMinute,
                                  ),
                                );
                            ref.invalidate(quietHoursProvider);
                          },
                        ),
                      ),
                      SizedBox(width: r.gapSm),
                      Expanded(
                        child: NeuButton(
                          label: 'Bitiş',
                          icon: Icons.wb_twilight_rounded,
                          filled: false,
                          compact: true,
                          expanded: true,
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: quiet.endHour,
                                minute: quiet.endMinute,
                              ),
                            );
                            if (picked == null) return;
                            await ref
                                .read(notificationServiceProvider)
                                .writeQuietHours(
                                  QuietHours(
                                    enabled: quiet.enabled,
                                    startHour: quiet.startHour,
                                    startMinute: quiet.startMinute,
                                    endHour: picked.hour,
                                    endMinute: picked.minute,
                                  ),
                                );
                            ref.invalidate(quietHoursProvider);
                          },
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile.adaptive(
                    value: quiet.enabled,
                    onChanged: (v) async {
                      await ref
                          .read(notificationServiceProvider)
                          .writeQuietHours(
                            QuietHours(
                              enabled: v,
                              startHour: quiet.startHour,
                              startMinute: quiet.startMinute,
                              endHour: quiet.endHour,
                              endMinute: quiet.endMinute,
                            ),
                          );
                      ref.invalidate(quietHoursProvider);
                    },
                    title: const Text('Sessiz saatler açık'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            // ============ GÜVENLİK ============
            const SectionHeader(
              title: 'Güvenlik',
              icon: Icons.lock_outline_rounded,
            ),
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Veritabanı her zaman şifrelidir (SQLCipher). '
                    'Aşağıdaki kilit, telefonu başkası eline '
                    'aldığında uygulamanın açılmasını engeller.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SwitchListTile.adaptive(
                    value: prefs.lockEnabled,
                    onChanged: (v) async {
                      if (v) {
                        final pin = await _askPin(context);
                        if (pin == null) return;
                        await ref
                            .read(secureStoreProvider)
                            .writePinHash(hashPin(pin, kPinSalt));
                      } else {
                        await ref.read(secureStoreProvider).deletePin();
                      }
                      await ref
                          .read(preferencesProvider.notifier)
                          .update((pr) => pr.copyWith(lockEnabled: v));
                    },
                    title: const Text('Uygulama kilidi'),
                    subtitle: const Text(
                      'Açılışta ve uygulama arka plandan dönerken '
                      'doğrulama ister.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (prefs.lockEnabled)
                    SwitchListTile.adaptive(
                      value: prefs.useBiometrics,
                      onChanged: (v) => ref
                          .read(preferencesProvider.notifier)
                          .update((pr) => pr.copyWith(useBiometrics: v)),
                      title: const Text('Parmak izi / yüz ile aç'),
                      subtitle: const Text(
                        'Kapatırsan yalnızca PIN sorulur.',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  if (prefs.lockEnabled) ...[
                    SizedBox(height: r.gapSm),
                    NeuButton(
                      label: 'PIN\'i değiştir',
                      icon: Icons.password_rounded,
                      filled: false,
                      compact: true,
                      expanded: true,
                      onPressed: () async {
                        final pin = await _askPin(context);
                        if (pin == null) return;
                        await ref
                            .read(secureStoreProvider)
                            .writePinHash(hashPin(pin, kPinSalt));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PIN güncellendi.'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            _NavTile(
              icon: Icons.shield_outlined,
              title: 'İzinler',
              subtitle: 'Hangi izin ne için — tek tek yönet',
              route: Routes.permissions,
            ),

            // ============ PROFİL ============
            const SectionHeader(
              title: 'Profil',
              icon: Icons.person_outline_rounded,
            ),
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.name ?? 'Profil yok',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                            Text(
                              [
                                if (profile?.birthYear != null)
                                  tf(
                                    '{0} yaş',
                                    [DateTime.now().year - profile!.birthYear!],
                                  ),
                                if (profile?.weightKg != null)
                                  '${profile!.weightKg!.toStringAsFixed(1)} kg',
                              ].join(' · '),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile.adaptive(
                    value: profile?.expertMode ?? false,
                    onChanged: profile == null
                        ? null
                        : (v) async {
                            final db = ref.read(databaseProvider);
                            await (db.update(db.profileRows)
                                  ..where((t) => t.id.equals(1)))
                                .write(
                              ProfileRowsCompanion(
                                expertMode: Value(v),
                              ),
                            );
                          },
                    title: const Text('Uzman modu'),
                    subtitle: const Text(
                      'Yapay zeka daha teknik dil kullanır, kılavuz '
                      'öneri numaralarını ve kanıt düzeylerini verir. '
                      'Teknik dergi akışları da indirilir.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            // ============ GÜNCELLEME ============
            const SectionHeader(
              title: 'Güncelleme',
              icon: Icons.system_update_alt_outlined,
            ),
            const UpdateCard(),

            // ============ VERİ ============
            const SectionHeader(
              title: 'Veri',
              icon: Icons.storage_outlined,
            ),
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    BackupService.warningTr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: r.gapMd),
                  NeuButton(
                    label: 'JSON yedeği al ve paylaş',
                    icon: Icons.download_outlined,
                    expanded: true,
                    onPressed: () async {
                      setState(
                        () => _statusTr = 'Yedek hazırlanıyor…',
                      );
                      try {
                        await ref
                            .read(backupServiceProvider)
                            .exportAndShare();
                        if (mounted) {
                          setState(() => _statusTr = 'Yedek paylaşıldı.');
                        }
                      } on Object catch (e) {
                        if (mounted) {
                          setState(
                            () => _statusTr = tf('Yedek alınamadı: {0}', [e]),
                          );
                        }
                      }
                    },
                  ),
                  SizedBox(height: r.gapSm),
                  NeuButton(
                    label: 'Yedekten geri yükle',
                    icon: Icons.upload_outlined,
                    filled: false,
                    expanded: true,
                    onPressed: () async {
                      final mode = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Geri yükleme biçimi'),
                          content: const Text(
                            'Mevcut verilerin ne olsun?\n\n'
                            '• BİRLEŞTİR: yedekteki kayıtlar eklenir, '
                            'mevcut veriler korunur (aynı kimlikli '
                            'kayıtlar güncellenir).\n\n'
                            '• DEĞİŞTİR: mevcut TÜM veriler SİLİNİR ve '
                            'yerine yedek yüklenir. Bu geri alınamaz.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, null),
                              child: const Text('Vazgeç'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, 'merge'),
                              child: const Text('Birleştir'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(context, 'replace'),
                              child: const Text('Değiştir'),
                            ),
                          ],
                        ),
                      );
                      if (mode == null || !context.mounted) return;

                      if (mode == 'replace') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Emin misin?'),
                            content: const Text(
                              'Telefondaki tüm kayıtlar (tahliller, '
                              'ölçümler, ilaçlar, yemek ve sıvı '
                              'kayıtları, sohbet geçmişi) SİLİNECEK. '
                              'Bu işlem geri alınamaz.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Vazgeç'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text('Sil ve yükle'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                      }

                      setState(
                        () => _statusTr = 'Geri yükleniyor…',
                      );
                      final report = await ref
                          .read(backupServiceProvider)
                          .importFromPicker(
                            replaceExisting: mode == 'replace',
                          );
                      if (mounted) {
                        setState(() => _statusTr = report.messageTr);
                      }
                    },
                  ),
                  SizedBox(height: r.gapSm),
                  NeuButton(
                    label: 'Harita/hava önbelleğini temizle',
                    icon: Icons.cleaning_services_outlined,
                    filled: false,
                    compact: true,
                    expanded: true,
                    onPressed: () async {
                      await ref.read(databaseProvider).cacheClear();
                      if (mounted) {
                        setState(
                          () => _statusTr = 'Önbellek temizlendi.',
                        );
                      }
                    },
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

            // ============ HAKKINDA ============
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppConfig.appName} ${AppConfig.appVersion}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: r.gapSm),
                  Text(
                    kPrivacyNoteTr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: r.gapSm),
                  Text(
                    'Tek profil · Giriş/üyelik yok · Sunucu yok · '
                    'Play Store\'da değil',
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

  Future<String?> _askPin(BuildContext context) async {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    String? error;

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('PIN belirle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: c1,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: const InputDecoration(
                  labelText: 'PIN (4-8 hane)',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: c2,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: const InputDecoration(
                  labelText: 'PIN tekrar',
                  counterText: '',
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(
                  error!,
                  style: TextStyle(color: context.palette.danger),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                if (c1.text.length < 4) {
                  setDialogState(
                    () => error = 'PIN en az 4 hane olmalı.',
                  );
                  return;
                }
                if (c1.text != c2.text) {
                  setDialogState(() => error = 'PIN\'ler aynı değil.');
                  return;
                }
                Navigator.pop(context, c1.text);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    return Padding(
      padding: EdgeInsets.only(bottom: r.gapSm),
      child: NeuCard(
        onTap: () => context.push(route),
        semanticLabel: '$title. $subtitle',
        color: highlight ? p.primarySoft : null,
        padding: EdgeInsets.all(r.gapMd),
        child: Row(
          children: [
            Icon(icon, color: p.primary, size: r.s(22)),
            SizedBox(width: r.gapMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Dil seçim düğmesi.
///
/// Dil adı ÇEVRİLMEZ ([Text.verbatim]): "Deutsch" her dilde Deutsch'tur.
/// Latin dışı adlar (العربية, हिन्दी, 中文) gömülü yazı tipinde yok;
/// Flutter o karakterleri sistem yazı tipinden alır — burada istenen
/// davranış tam olarak budur, yoksa seçici okunamazdı.
class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final radius = BorderRadius.circular(r.s(14));

    return Semantics(
      button: true,
      selected: selected,
      label: language.nativeName,
      child: Material(
        color: selected ? p.primary : p.surfaceGlass,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: r.s(14),
              vertical: r.s(9),
            ),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? p.primary : p.glassBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(
                    Icons.check_rounded,
                    size: r.s(16),
                    color: p.onPrimary,
                  ),
                  SizedBox(width: r.s(6)),
                ],
                Text.verbatim(
                  language.nativeName,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected ? p.onPrimary : p.textPrimary,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 21 → "21:00". Ayarlarda ve bildirim metninde aynı biçim kullanılır.
String formatHour(int hour) => '${hour.toString().padLeft(2, '0')}:00';
