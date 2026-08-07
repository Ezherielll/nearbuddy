import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants.dart';
import '../../data/database/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import 'chat_controller.dart';
import 'widgets/message_bubble.dart';

class DmChatScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const DmChatScreen({super.key, required this.sessionId});
  @override
  ConsumerState<DmChatScreen> createState() => _DmChatScreenState();
}

class _DmChatScreenState extends ConsumerState<DmChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessionsDao = ref.read(sessionsDaoProvider);
    final controller = ref.read(chatControllerProvider);
    final myNick = ref.read(appPreferencesProvider).nickname ?? '';

    return FutureBuilder<SessionRow?>(
      future: sessionsDao.sessionById(widget.sessionId),
      builder: (ctx, snap) {
        final session = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(session?.peerNickname ?? ''),
            actions: [
              ShadIconButton(
                icon: const Icon(LucideIcons.trash2),
                onPressed: () async {
                  await sessionsDao.deleteSession(widget.sessionId);
                  if (!context.mounted) return;
                  context.go('/home');
                },
              ),
            ],
          ),
          body: Column(children: [
            Expanded(
              child: StreamBuilder<List<MessageRow>>(
                stream: controller.watchMessages(widget.sessionId),
                builder: (ctx, snap) {
                  final msgs = snap.data ?? [];
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());
                  return ListView.builder(
                    controller: _scrollCtrl,
                    itemCount: msgs.length,
                    itemBuilder: (_, i) => MessageBubble(
                        row: msgs[i], isMe: msgs[i].senderId == myNick),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(children: [
                  Expanded(
                    child: ShadTextarea(
                      controller: _msgCtrl,
                      maxLength: AppConstants.maxMessageLength,
                      placeholder: Text(l10n.send),
                      onChanged: (_) {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  ShadButton(
                    onPressed: () => _send(controller, session),
                    child: const Icon(LucideIcons.send),
                  ),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }

  Future<void> _send(ChatController c, SessionRow? session) async {
    if (session == null) return;
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    try {
      await c.sendDm(session.id, session.peerDeviceId, text);
    } on StateError {
      if (!mounted) return;
      ShadToaster.of(context).show(ShadToast.destructive(
        title: Text(AppLocalizations.of(context)!.dmKeyMissing),
      ));
    }
  }
}
