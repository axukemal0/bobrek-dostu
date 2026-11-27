import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' hide Text;

import '../../clinical/evaluator.dart';
import '../../core/config/ai_config.dart';
import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/router/app_router.dart';
import '../../core/services/ai_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/neumorphic.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/responsive.dart';
import '../emergency/emergency_actions.dart';
import '../../core/i18n/text.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  bool _listening = false;
  Alert? _redFlag;

  static const List<String> suggestions = [
    'Potasyumu düşürmek için ne yapabilirim?',
    'Bu hafta tahlillerimde ne değişti?',
    'Dışarıda yemek yiyeceğim, nelere dikkat etmeliyim?',
    'Diyaliz arası kilo artışımı nasıl azaltabilirim?',
    'Fosfor bağlayıcımı neden yemekle almalıyım?',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _sending) return;
    final db = ref.read(databaseProvider);

    // Kural tabanlı acil belirti taraması — AI'dan ÖNCE çalışır,
    // böylece AI başarısız olsa bile 112 mesajı görünür.
    final flag = detectRedFlags(text);
    setState(() {
      _redFlag = flag;
      _sending = true;
    });
    _input.clear();

    await db.into(db.chatMessageRows).insert(
          ChatMessageRowsCompanion.insert(role: 'user', content: text.trim()),
        );
    _scrollToEnd();

    try {
      final context = await ref.read(aiContextProvider.future);
      final history = await db.watchChat(limit: 24).first;
      final model =
          ref.read(preferencesProvider).aiModel ?? AiConfig.defaultModel;

      final messages = <({String role, String text})>[
        for (final m in history)
          if (m.role == 'user' || m.role == 'assistant')
            (role: m.role, text: m.content),
      ];

      final reply = await ref.read(aiServiceProvider).sendChat(
            systemPrompt: context.systemPrompt,
            messages: messages,
            model: model,
          );

      await db.into(db.chatMessageRows).insert(
            ChatMessageRowsCompanion.insert(
              role: 'assistant',
              content: reply.text,
              model: Value(model),
              inputTokens: Value(reply.inputTokens),
              outputTokens: Value(reply.outputTokens),
            ),
          );
    } on AiFailure catch (e) {
      await db.into(db.chatMessageRows).insert(
            ChatMessageRowsCompanion.insert(
              role: 'system_note',
              content: e.messageTr,
            ),
          );
    } on Object catch (e) {
      // AiFailure DIŞINDAKİ hatalar (bağlam hazırlanırken, veritabanında)
      // önceden yakalanmıyordu: istisna sessizce yukarı gidiyor, ekranda
      // hiçbir şey olmuyordu. Kullanıcı için bu "yapay zeka çalışmıyor"
      // demekti ve hiçbir ipucu kalmıyordu.
      await db.into(db.chatMessageRows).insert(
            ChatMessageRowsCompanion.insert(
              role: 'system_note',
              content: 'Beklenmedik bir hata oldu ve soru gönderilemedi.\n\n'
                  '$e',
            ),
          );
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _voiceInput() async {
    final stt = ref.read(sttServiceProvider);
    if (_listening) {
      await stt.stop();
      setState(() => _listening = false);
      return;
    }
    final ok = await stt.listen(
      onResult: (text, isFinal) {
        setState(() => _input.text = text);
        if (isFinal) setState(() => _listening = false);
      },
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ses tanıma başlatılamadı (mikrofon izni?).'),
        ),
      );
      return;
    }
    setState(() => _listening = true);
  }

  Future<void> _showContext() async {
    final summary = await ref.read(aiContextProvider.future);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        expand: false,
        builder: (context, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yapay zekaya ne gönderiliyor?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 14),
              Text(
                summary.humanReadableTr,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              NeuButton(
                label: 'Veri paylaşımını değiştir',
                icon: Icons.tune_rounded,
                filled: false,
                expanded: true,
                onPressed: () {
                  Navigator.pop(context);
                  context.push(Routes.aiConnection);
                },
              ),
              const SizedBox(height: 18),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Teknik: tam sistem komutu',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      summary.systemPrompt,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final conn = ref.watch(aiConnectionProvider).value;
    final messages = ref.watch(chatMessagesProvider).value ?? const [];
    final profile = ref.watch(profileProvider).value;

    if (conn != AiConnectionState.ok) {
      return Scaffold(
        backgroundColor: p.background,
        appBar: AppBar(title: const Text('Yapay zeka')),
        body: SafeArea(
          child: PageBody(
            children: [
              EmptyState(
                title: 'Önce bağlantıyı kur',
                message: 'Yapay zeka özellikleri kendi Anthropic '
                    'anahtarınla çalışır. Anahtar olmadan uygulamanın '
                    'geri kalanı normal çalışır: besin takibi, sıvı, '
                    'tahlil, ilaç, takvim, grafikler ve doktor raporu '
                    'anahtar gerektirmez.',
                icon: Icons.key_off_outlined,
                action: NeuButton(
                  label: 'Yapay Zeka Bağlantısı',
                  icon: Icons.key_outlined,
                  onPressed: () => context.push(Routes.aiConnection),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: const Text('Yapay zeka'),
        actions: [
          if (profile?.expertMode == true)
            Padding(
              padding: EdgeInsets.only(right: r.gapXs),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: p.primarySoft,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    'uzman modu',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ),
          TapIcon(
            icon: Icons.privacy_tip_outlined,
            semanticLabel: 'Ne gönderiliyor?',
            onPressed: _showContext,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_redFlag != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  r.pagePadding,
                  r.gapSm,
                  r.pagePadding,
                  0,
                ),
                child: ContentColumn(
                  child: NeuCard(
                    color: p.danger.withValues(alpha: p.isDark ? 0.2 : 0.11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.emergency_rounded, color: p.danger),
                            SizedBox(width: r.gapSm),
                            Expanded(
                              child: Text(
                                _redFlag!.titleTr,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: p.danger),
                              ),
                            ),
                            TapIcon(
                              icon: Icons.close_rounded,
                              semanticLabel: 'Uyarıyı kapat',
                              onPressed: () =>
                                  setState(() => _redFlag = null),
                            ),
                          ],
                        ),
                        SizedBox(height: r.gapSm),
                        Text(
                          _redFlag!.messageTr,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        SizedBox(height: r.gapMd),
                        NeuButton(
                          label: '112\'yi ara',
                          icon: Icons.phone_in_talk_rounded,
                          tone: NeuTone.danger,
                          expanded: true,
                          onPressed: () => call112(context, ref),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            Expanded(
              child: messages.isEmpty
                  ? SingleChildScrollView(
                      padding: EdgeInsets.all(r.pagePadding),
                      child: ContentColumn(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            NeuCard(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Neler sorabilirsin',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  SizedBox(height: r.gapSm),
                                  Text(
                                    'Sorularını yanıtlarken profilin, '
                                    'son tahlillerin, ilaçların ve '
                                    'klinik ayarların dikkate alınır. '
                                    'Üstteki kalkan ikonuna dokunarak '
                                    'tam olarak ne gönderildiğini '
                                    'görebilirsin.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: r.gapMd),
                            for (final s in suggestions)
                              Padding(
                                padding:
                                    EdgeInsets.only(bottom: r.gapSm),
                                child: NeuCard(
                                  onTap: () => _send(s),
                                  padding: EdgeInsets.all(r.gapMd),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: r.s(17),
                                        color: p.accent,
                                      ),
                                      SizedBox(width: r.gapSm),
                                      Expanded(
                                        child: Text(
                                          s,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            SizedBox(height: r.gapMd),
                            NeuCard(
                              color: p.accentSoft.withValues(alpha: 0.5),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kurallar',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                  SizedBox(height: r.gapXs),
                                  for (final line in [
                                    'Teşhis koymaz.',
                                    'İlaç dozu değiştirmez, yeni ilaç önermez.',
                                    'Doktorun yerine geçmez.',
                                    'Tehlikeli belirtide "112\'yi ara" der.',
                                    'Emin olmadığında "bilmiyorum" der.',
                                  ])
                                    Text(
                                      '• $line',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: r.gapMd),
                            const MedicalDisclaimerBanner(),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: EdgeInsets.fromLTRB(
                        r.pagePadding,
                        r.gapMd,
                        r.pagePadding,
                        r.gapMd,
                      ),
                      itemCount: messages.length + (_sending ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == messages.length) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(top: r.gapSm),
                              child: NeuCard(
                                padding: EdgeInsets.all(r.gapMd),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: r.gapSm),
                                    const Text('Düşünüyor…'),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        return _MessageBubble(message: messages[i]);
                      },
                    ),
            ),

            // --- giriş ---
            Container(
              padding: EdgeInsets.fromLTRB(
                r.pagePadding,
                r.gapSm,
                r.pagePadding,
                r.gapSm,
              ),
              decoration: BoxDecoration(
                color: p.surface,
                border: Border(top: BorderSide(color: p.divider)),
              ),
              child: ContentColumn(
                child: Row(
                  children: [
                    TapIcon(
                      icon: _listening
                          ? Icons.mic_rounded
                          : Icons.mic_none_rounded,
                      semanticLabel: _listening
                          ? 'Dinlemeyi durdur'
                          : 'Sesle sor',
                      color: _listening ? p.danger : null,
                      onPressed: _voiceInput,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _input,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _send,
                        decoration: const InputDecoration(
                          hintText: 'Sorunu yaz…',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: r.gapXs),
                    TapIcon(
                      icon: Icons.send_rounded,
                      semanticLabel: 'Gönder',
                      color: p.primary,
                      onPressed:
                          _sending ? null : () => _send(_input.text),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  const _MessageBubble({required this.message});

  final ChatMessageRow message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final r = Responsive.fromContext(context);
    final isUser = message.role == 'user';
    final isNote = message.role == 'system_note';

    if (isNote) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: r.gapSm),
        child: NeuCard(
          color: p.danger.withValues(alpha: p.isDark ? 0.15 : 0.08),
          padding: EdgeInsets.all(r.gapMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: p.danger,
                size: r.s(18),
              ),
              SizedBox(width: r.gapSm),
              Expanded(
                child: Text(
                  message.content,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: r.gapSm),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: r.width * 0.84),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(r.gapMd),
                  decoration: BoxDecoration(
                    color: isUser ? p.primary : p.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 6),
                      bottomRight: Radius.circular(isUser ? 6 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: p.shadowDark,
                        offset: const Offset(2, 3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: SelectableText(
                    message.content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isUser ? p.onPrimary : p.textPrimary,
                        ),
                  ),
                ),
                if (!isUser)
                  Padding(
                    padding: EdgeInsets.only(top: r.gapXs, left: r.gapXs),
                    child: Row(
                      children: [
                        TapIcon(
                          icon: Icons.volume_up_outlined,
                          semanticLabel: 'Sesli oku',
                          size: 17,
                          onPressed: () => ref
                              .read(ttsServiceProvider)
                              .speak(message.content),
                        ),
                        if (message.outputTokens != null)
                          Text(
                            '${message.outputTokens} token',
                            style:
                                Theme.of(context).textTheme.labelSmall,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
