import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' hide Text;

import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/sms_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/responsive.dart';
import '../home/home_screen.dart' show showPermissionDialog;
import 'emergency_actions.dart';
import '../../core/i18n/text.dart';
import '../../core/i18n/i18n.dart';

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  bool _busy = false;
  String? _preview;
  String? _statusTr;

  /// Konumu tazeler (izin varsa), sonra mesajı oluşturur.
  Future<String> _buildMessage({bool refreshLocation = true}) async {
    var loc = ref.read(locationProvider);

    if (refreshLocation) {
      final permission = ref.read(permissionServiceProvider);
      if (await permission.status(AppPermission.location) ==
          AppPermissionStatus.granted) {
        try {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 15),
            ),
          );
          loc = LastLocation(
            latitude: pos.latitude,
            longitude: pos.longitude,
            placeName: loc?.placeName,
            at: DateTime.now(),
          );
          await ref.read(locationProvider.notifier).save(loc);
        } on Object {
          // Taze konum alınamadıysa son bilinen konum kullanılır.
        }
      }
    }

    return ref.read(caregiverServiceProvider).buildEmergencyMessage(
          latitude: loc?.latitude,
          longitude: loc?.longitude,
          placeName: loc?.placeName,
        );
  }

  Future<void> _previewMessage() async {
    setState(() {
      _busy = true;
      _statusTr = 'Konum alınıyor ve mesaj hazırlanıyor…';
    });
    final msg = await _buildMessage();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _preview = msg;
      _statusTr = null;
    });
  }

  Future<void> _sendSms({required bool direct}) async {
    final contacts = await ref.read(databaseProvider).getEmergencyContacts();
    if (contacts.isEmpty) {
      if (mounted) {
        setState(
          () => _statusTr = 'Acil durum kişisi tanımlı değil. '
              'Aşağıdan ekleyebilirsin.',
        );
      }
      return;
    }

    setState(() {
      _busy = true;
      _statusTr = 'Mesaj hazırlanıyor…';
    });
    final msg = await _buildMessage();
    if (!mounted) return;
    setState(() {
      _preview = msg;
      _statusTr = null;
    });

    final numbers = contacts.map((c) => c.phone).toList();

    if (!direct) {
      final opened = await ref
          .read(smsServiceProvider)
          .openComposer(phoneNumbers: numbers, message: msg);
      if (mounted) {
        setState(() {
          _busy = false;
          _statusTr = opened
              ? 'SMS uygulaması açıldı. Gönder tuşuna sen basacaksın.'
              : 'SMS uygulaması açılamadı.';
        });
      }
      return;
    }

    try {
      final sent = await ref
          .read(smsServiceProvider)
          .sendDirect(phoneNumbers: numbers, message: msg);
      if (mounted) {
        setState(() {
          _busy = false;
          _statusTr = tf('{0} kişiye SMS gönderildi.', [sent]);
        });
      }
    } on SmsFailure catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _statusTr = e.messageTr;
        });
      }
    }
  }

  Future<void> _requestSmsPermission() async {
    final ok = await showPermissionDialog(
      context,
      permissionInfo(AppPermission.sms),
    );
    if (!ok) return;
    await ref.read(permissionServiceProvider).request(AppPermission.sms);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final contacts =
        ref.watch(emergencyContactsProvider).value ?? const [];
    final profile = ref.watch(profileProvider).value;
    final prefs = ref.watch(preferencesProvider);

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(title: const Text('Acil durum')),
      body: SafeArea(
        child: PageBody(
          children: [
            // --- 112 ---
            Semantics(
              button: true,
              label: '112 Acil Çağrı Merkezini ara',
              child: InkWell(
                onTap: () => call112(context, ref),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: r.gapLg,
                    vertical: r.gapLg,
                  ),
                  decoration: BoxDecoration(
                    color: p.danger,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: p.danger.withValues(alpha: 0.35),
                        offset: const Offset(0, 6),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.phone_in_talk_rounded,
                        color: Colors.white,
                        size: r.s(40),
                      ),
                      SizedBox(height: r.gapSm),
                      Text(
                        '112\'yi ARA',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: Colors.white),
                      ),
                      SizedBox(height: r.gapXs),
                      Text(
                        'Telefon uygulaması açılır, aramayı sen başlatırsın',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- acil kişilere gönder ---
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Yakınlarına bilgi gönder',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: r.gapXs),
                  Text(
                    'Konumun ve kritik bilgilerin (hastalık, ilaçlar, '
                    'alerjiler, doktorun) tek mesajda gider.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: r.gapMd),
                  NeuButton(
                    label: _busy
                        ? 'Hazırlanıyor…'
                        : 'SMS uygulamasında aç (önerilen)',
                    icon: Icons.sms_outlined,
                    expanded: true,
                    onPressed:
                        _busy ? null : () => _sendSms(direct: false),
                  ),
                  SizedBox(height: r.gapSm),
                  FutureBuilder<AppPermissionStatus>(
                    future: ref
                        .read(permissionServiceProvider)
                        .status(AppPermission.sms),
                    builder: (context, snapshot) {
                      final granted =
                          snapshot.data == AppPermissionStatus.granted;
                      return NeuButton(
                        label: granted
                            ? 'Doğrudan gönder (dokunmadan)'
                            : 'Doğrudan gönderme izni ver',
                        icon: granted
                            ? Icons.send_rounded
                            : Icons.lock_open_rounded,
                        filled: false,
                        expanded: true,
                        onPressed: _busy
                            ? null
                            : (granted
                                ? () => _sendSms(direct: true)
                                : _requestSmsPermission),
                      );
                    },
                  ),
                  SizedBox(height: r.gapSm),
                  NeuButton(
                    label: 'Mesajı önce göster',
                    icon: Icons.visibility_outlined,
                    filled: false,
                    compact: true,
                    expanded: true,
                    onPressed: _busy ? null : _previewMessage,
                  ),
                  if (contacts.length == 1) ...[
                    SizedBox(height: r.gapSm),
                    NeuButton(
                      label: 'WhatsApp ile gönder',
                      icon: Icons.chat_outlined,
                      filled: false,
                      compact: true,
                      expanded: true,
                      onPressed: _busy
                          ? null
                          : () async {
                              final msg = await _buildMessage();
                              await ref
                                  .read(smsServiceProvider)
                                  .openWhatsApp(
                                    phoneNumber: contacts.first.phone,
                                    message: msg,
                                  );
                            },
                    ),
                  ],
                ],
              ),
            ),

            if (_statusTr != null)
              NeuCard(
                color: p.accentSoft.withValues(alpha: 0.6),
                child: Text(
                  _statusTr!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

            if (_preview != null)
              NeuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gönderilecek mesaj',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SizedBox(height: r.gapSm),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(r.gapSm),
                      decoration: BoxDecoration(
                        color: p.backgroundDeep.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SelectableText(
                        _preview!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    SizedBox(height: r.gapXs),
                    Text(
                      tf(
                        '{0} karakter · {1} SMS',
                        [
                          _preview!.length,
                          (_preview!.length / 160).ceil(),
                        ],
                      ),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),

            // --- doktoru ara ---
            if (profile?.doctorPhone?.isNotEmpty == true)
              NeuCard(
                onTap: () => ref
                    .read(smsServiceProvider)
                    .call(profile.doctorPhone!),
                child: Row(
                  children: [
                    Icon(Icons.local_hospital_outlined, color: p.primary),
                    SizedBox(width: r.gapSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Doktorunu ara',
                            style:
                                Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            '${profile!.doctorName ?? "Doktor"} · '
                            '${profile.doctorPhone}',
                            style:
                                Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.call_rounded, color: p.primary),
                  ],
                ),
              ),

            // --- kişiler ---
            SectionHeader(
              title: tf('Acil durum kişileri ({0})', [contacts.length]),
              icon: Icons.contact_emergency_outlined,
              trailing: TapIcon(
                icon: Icons.person_add_alt_rounded,
                semanticLabel: 'Kişi ekle',
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (context) => const _ContactSheet(),
                ),
              ),
            ),
            if (contacts.isEmpty)
              const EmptyState(
                title: 'Kişi yok',
                message: 'En az bir acil durum kişisi eklemen önerilir. '
                    'Acil durumda konumun ve kritik bilgilerin ona '
                    'gönderilir.',
                icon: Icons.person_off_outlined,
              )
            else
              for (final c in contacts)
                Padding(
                  padding: EdgeInsets.only(bottom: r.gapSm),
                  child: _ContactCard(contact: c),
                ),

            // --- otomatik SMS ayarı ---
            // iPhone'da işletim sistemi kendiliğinden SMS göndermeye izin
            // vermiyor; kapatılamayan bir anahtar göstermek yerine durumu
            // açıkça yazıyoruz.
            if (!SmsService.supportsDirectSend)
              NeuCard(
                color: p.accentSoft.withValues(alpha: 0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Otomatik SMS iPhone\'da yok',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: r.gapXs),
                    Text(
                      'iPhone, uygulamaların senin onayın olmadan SMS '
                      'göndermesine izin vermiyor — bu Apple\'ın kuralı, '
                      'aşılamıyor. Eşik aşıldığında uygulama mesajı hazır '
                      'hâlde Mesajlar\'da açar; gönder tuşuna sen basarsın. '
                      'Acil düğmesi de aynı şekilde çalışır.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            else
            NeuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile.adaptive(
                    value: prefs.autoSmsOnAlarm,
                    onChanged: (v) async {
                      if (v) {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Otomatik SMS\'i aç'),
                            content: const Text(
                              'Bir ölçüm alarm eşiğini aştığında, '
                              'işaretlediğin acil kişilere SENİN '
                              'ONAYINI BEKLEMEDEN SMS gönderilir.\n\n'
                              'Bunun için SMS gönderme izni gerekir. '
                              'İzin yoksa mesaj hazırlanır ve gönderimi '
                              'sana bırakılır.\n\n'
                              'Hangi eşiklerin SMS tetiklediğini '
                              'Klinik Ayarlar\'da her değerin yanında '
                              'görebilirsin.',
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
                                child: const Text('Aç'),
                              ),
                            ],
                          ),
                        );
                        if (ok != true) return;
                        await ref
                            .read(permissionServiceProvider)
                            .request(AppPermission.sms);
                      }
                      await ref
                          .read(preferencesProvider.notifier)
                          .update((pr) => pr.copyWith(autoSmsOnAlarm: v));
                    },
                    title: const Text(
                      'Eşik aşımında otomatik SMS',
                    ),
                    subtitle: const Text(
                      'VARSAYILAN KAPALI. Açarsan yalnızca aşağıda '
                      '"otomatik" işaretli kişilere gönderilir.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            NeuCard(
              color: p.backgroundDeep.withValues(alpha: 0.45),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bu ekran nasıl çalışır?',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: r.gapSm),
                  for (final line in [
                    '112 düğmesi telefon uygulamasını açar; '
                        'aramayı sen başlatırsın.',
                    'Mesaj cihazda oluşturulur, hiçbir sunucuya '
                        'gönderilmez.',
                    'Konum yalnızca mesajın içine bir harita bağlantısı '
                        'olarak girer.',
                    'Mesajı göndermeden önce her zaman '
                        'önizleyebilirsin.',
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
              label: 'Klinik Ayarlar — alarm eşikleri',
              icon: Icons.tune_rounded,
              filled: false,
              expanded: true,
              onPressed: () => context.push(Routes.clinicalSettings),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends ConsumerWidget {
  const _ContactCard({required this.contact});

  final EmergencyContactRow contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    return NeuCard(
      padding: EdgeInsets.all(r.gapMd),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      [
                        contact.phone,
                        if (contact.relation != null) contact.relation!,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              TapIcon(
                icon: Icons.call_rounded,
                semanticLabel: '${contact.name} ara',
                color: p.primary,
                onPressed: () =>
                    ref.read(smsServiceProvider).call(contact.phone),
              ),
              TapIcon(
                icon: Icons.delete_outline_rounded,
                semanticLabel: '${contact.name} sil',
                onPressed: () async {
                  final db = ref.read(databaseProvider);
                  await (db.delete(db.emergencyContactRows)
                        ..where((t) => t.id.equals(contact.id)))
                      .go();
                },
              ),
            ],
          ),
          SwitchListTile.adaptive(
            value: contact.autoSmsEnabled,
            onChanged: (v) async {
              final db = ref.read(databaseProvider);
              await (db.update(db.emergencyContactRows)
                    ..where((t) => t.id.equals(contact.id)))
                  .write(
                EmergencyContactRowsCompanion(autoSmsEnabled: Value(v)),
              );
            },
            title: const Text('Otomatik SMS alsın'),
            subtitle: const Text(
              'Yalnızca "Eşik aşımında otomatik SMS" ayarı da açıksa '
              'çalışır.',
            ),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _ContactSheet extends ConsumerStatefulWidget {
  const _ContactSheet();

  @override
  ConsumerState<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends ConsumerState<_ContactSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _relation = TextEditingController();
  bool _auto = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    return Padding(
      padding: EdgeInsets.only(
        left: r.pagePadding,
        right: r.pagePadding,
        top: r.gapLg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + r.gapLg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Acil durum kişisi',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: r.gapMd),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Ad'),
            ),
            SizedBox(height: r.gapSm),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Telefon',
                hintText: '0532 000 00 00',
              ),
            ),
            SizedBox(height: r.gapSm),
            TextField(
              controller: _relation,
              decoration: const InputDecoration(
                labelText: 'Yakınlık',
                hintText: 'Oğlu, kızı, eşi…',
              ),
            ),
            SizedBox(height: r.gapSm),
            SwitchListTile.adaptive(
              value: _auto,
              onChanged: (v) => setState(() => _auto = v),
              title: const Text('Otomatik SMS alsın'),
              contentPadding: EdgeInsets.zero,
            ),
            SizedBox(height: r.gapMd),
            NeuButton(
              label: 'Kaydet',
              icon: Icons.check_rounded,
              expanded: true,
              onPressed: _name.text.trim().isEmpty ||
                      _phone.text.trim().isEmpty
                  ? null
                  : () async {
                      final db = ref.read(databaseProvider);
                      final existing = await db.getEmergencyContacts();
                      await db.into(db.emergencyContactRows).insert(
                            EmergencyContactRowsCompanion.insert(
                              name: _name.text.trim(),
                              phone: _phone.text.trim(),
                              relation: Value(
                                _relation.text.trim().isEmpty
                                    ? null
                                    : _relation.text.trim(),
                              ),
                              autoSmsEnabled: Value(_auto),
                              sortOrder: Value(existing.length),
                            ),
                          );
                      if (context.mounted) Navigator.pop(context);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
