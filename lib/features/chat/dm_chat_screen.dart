import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../data/database/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../theme/nearbuddy_color_scheme.dart';
import '../../features/shared/connection_status.dart';
import 'chat_controller.dart';
import 'widgets/connection_badge.dart';
import 'widgets/date_divider.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_composer.dart';

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
    if (!_scrollCtrl.hasClients) return;
    if (MediaQuery.of(context).disableAnimations) {
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      return;
    }
    _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  List<Widget> _buildMessages(List<MessageRow> msgs, String myNick) {
    final children = <Widget>[];
    DateTime? lastDay;
    for (final m in msgs) {
      final day = DateTime(m.timestamp.year, m.timestamp.month, m.timestamp.day);
      if (lastDay == null || day != lastDay) {
        children.add(DateDivider(date: m.timestamp));
        lastDay = day;
      }
      children.add(MessageBubble(row: m, isMe: m.senderId == myNick));
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final theme = ShadTheme.of(context);
    final sessionsDao = ref.read(sessionsDaoProvider);
    final controller = ref.read(chatControllerProvider);
    final myNick = ref.read(appPreferencesProvider).nickname ?? '';
    final peerTyping =
        ref.watch(typingSessionProvider) == widget.sessionId;

    return FutureBuilder<SessionRow?>(
      future: sessionsDao.sessionById(widget.sessionId),
      builder: (ctx, snap) {
        final session = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(session?.peerNickname ?? '',
                    style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600)),
                if (peerTyping)
                  Text(
                    AppLocalizations.of(context)!.typingIndicator,
                    style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: cs.online),
                  )
                else
                  Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConnectionBadge(
                        status:
                            ref.watch(connectionStatusProvider).valueOrNull ??
                                ConnectionStatus.searching),
                    const SizedBox(width: 8),
                    const EncryptedMarker(),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        session?.peerDeviceId ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: cs.mutedForeground),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                  return ListView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _buildMessages(msgs, myNick),
                  );
                },
              ),
            ),
            MessageComposer(
              controller: _msgCtrl,
              onSend: (text) => _send(controller, session, text),
              onTypingChange: session == null
                  ? null
                  : (on) =>
                      controller.sendTyping(session.id, session.peerDeviceId, on),
            ),
          ]),
        );
      },
    );
  }

  Future<void> _send(ChatController c, SessionRow? session, String text) async {
    if (session == null) return;
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
