import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/sessions_dao.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../theme/nearbuddy_color_scheme.dart';
import '../../theme/nearbuddy_typography.dart';
import '../shared/widgets/avatar_initial.dart';
import '../../features/shared/connection_status.dart';
import 'chat_controller.dart';
import 'widgets/connection_lost_banner.dart';
import 'widgets/date_divider.dart';
import 'widgets/leave_confirm_dialog.dart';
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

  List<Widget> _buildMessages(
      List<MessageRow> msgs, String myNick, ChatController controller) {
    final children = <Widget>[];
    DateTime? lastDay;
    String? lastSender;
    for (final m in msgs) {
      final day = DateTime(m.timestamp.year, m.timestamp.month, m.timestamp.day);
      if (lastDay == null || day != lastDay) {
        children.add(DateDivider(date: m.timestamp));
        lastDay = day;
        lastSender = null;
      }
      final sameSenderAsPrev = m.senderId == lastSender;
      lastSender = m.senderId;
      children.add(MessageBubble(
        row: m,
        isMe: m.senderId == myNick,
        grouped: sameSenderAsPrev,
        onRetry: (id) => controller.retryMessage(id),
      ));
    }
    return children;
  }

  String _subtitleFor(ConnectionStatus s, AppLocalizations l10n) {
    switch (s) {
      case ConnectionStatus.connected:
        return l10n.connConnected;
      case ConnectionStatus.searching:
        return l10n.connConnecting;
      case ConnectionStatus.outOfRange:
        return l10n.connDisconnected;
      case ConnectionStatus.radioOff:
        return l10n.connRadioOff;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final sessionsDao = ref.read(sessionsDaoProvider);
    final controller = ref.read(chatControllerProvider);
    final myNick = ref.read(appPreferencesProvider).nickname ?? '';
    final peerTyping =
        ref.watch(typingSessionProvider) == widget.sessionId;
    final status = ref.watch(connectionStatusProvider).valueOrNull ??
        ConnectionStatus.searching;

    return FutureBuilder<SessionRow?>(
      future: sessionsDao.sessionById(widget.sessionId),
      builder: (ctx, snap) {
        final session = snap.data;
        final l10n = AppLocalizations.of(ctx)!;
        final peerName = session?.peerNickname ?? '';

        return Scaffold(
          backgroundColor: cs.background,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: cs.background,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, size: 22),
              onPressed: () => context.pop(),
            ),
            titleSpacing: 4,
            title: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AvatarInitial(name: peerName, size: 38),
                    if (status == ConnectionStatus.connected)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: cs.online,
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.background, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        peerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.foreground,
                        ),
                      ),
                      if (peerTyping)
                        Text(
                          l10n.typingIndicator,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: cs.online,
                          ),
                        )
                      else
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: status == ConnectionStatus.connected
                                    ? cs.online
                                    : cs.mutedForeground,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _subtitleFor(status, l10n),
                              style: TextStyle(
                                fontSize: 12,
                                color: status == ConnectionStatus.connected
                                    ? cs.online
                                    : cs.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.online.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cs.online.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.shieldCheck, size: 13, color: cs.online),
                    const SizedBox(width: 4),
                    Text(
                      l10n.menuEncryptedInfo.split(' ').first,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.online,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(LucideIcons.moreVertical, size: 20),
                tooltip: '',
                onSelected: (v) {
                  if (v == 'disconnect') _confirmDelete(sessionsDao);
                },
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    value: 'info',
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.lock, size: 14, color: cs.online),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.menuEncryptedInfo,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session?.peerDeviceId ?? '',
                          style: TextStyle(
                            fontFamily: AppFonts.mono,
                            fontSize: 11,
                            color: cs.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'disconnect',
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.trash2,
                          size: 16,
                          color: cs.destructive,
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.menuDisconnect),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: cs.border),
            ),
          ),
          body: Column(children: [
            Expanded(
              child: StreamBuilder<List<MessageRow>>(
                stream: controller.watchMessages(widget.sessionId),
                builder: (ctx, snap) {
                  final msgs = snap.data ?? [];
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());
                  if (msgs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.messageCircle,
                              size: 32,
                              color: cs.primary.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.chatEmptyTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: cs.foreground,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.chatEmptyBody(peerName),
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.mutedForeground,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                    children: _buildMessages(msgs, myNick, controller),
                  );
                },
              ),
            ),
            if (ref.watch(connectionStatusProvider).valueOrNull ==
                ConnectionStatus.outOfRange)
              ConnectionLostBanner(
                title: l10n.connectionLost(session?.peerNickname ?? ''),
                hint: l10n.messageWillWait,
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

  Future<void> _confirmDelete(SessionsDao sessionsDao) async {
    final ok = await showLeaveConfirmDialog(context);
    if (!ok || !mounted) return;
    await sessionsDao.deleteSession(widget.sessionId);
    if (!mounted) return;
    context.go('/home');
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
