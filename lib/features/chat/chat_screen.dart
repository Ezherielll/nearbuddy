import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../data/database/app_database.dart';
import '../../domain/models/group_session.dart';
import '../../domain/services/key_exchange_service.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../group/group_controller.dart';
import '../shared/widgets/avatar_initial.dart';
import '../../features/shared/connection_status.dart';
import '../../theme/nearbuddy_color_scheme.dart';
import 'chat_controller.dart';
import 'widgets/connection_lost_banner.dart';
import 'widgets/date_divider.dart';
import 'widgets/leave_confirm_dialog.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_composer.dart';
import 'widgets/verification_dialog.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String groupId;
  const ChatScreen({super.key, required this.groupId});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _locLoading = false;
  StreamSubscription<SasChallenge>? _sasSub;

  @override
  void initState() {
    super.initState();
    // Wire the SAS verification challenge to this screen. The subscription is
    // cancelled in dispose — the async handler re-checks mounted after every
    // await so `ref`/context are never used after the widget is disposed.
    _sasSub = ref
        .read(keyExchangeServiceProvider)
        .onSasChallenge
        .listen(_onSas);
    _ensureSession();
  }

  /// The chat may be opened from the group list, where createGroup/joinGroup
  /// never ran — without a current group, ChatController drops outgoing
  /// messages silently. Adopt the routed group as the active session.
  Future<void> _ensureSession() async {
    final current = ref.read(currentGroupProvider);
    if (current != null && current.id == widget.groupId) return;
    final row = await ref.read(groupsDaoProvider).groupById(widget.groupId);
    if (!mounted || row == null) return;
    final existing = ref.read(currentGroupProvider);
    if (existing != null && existing.id == widget.groupId) return;
    ref.read(currentGroupProvider.notifier).state = GroupSession(
      id: row.id,
      name: row.name,
      pin: row.pin,
      createdAt: row.createdAt,
      isOwner: row.isOwner,
    );
  }

  @override
  void dispose() {
    _sasSub?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSas(SasChallenge challenge) async {
    if (!mounted) return;
    final ok = await showVerificationDialog(context, challenge.sas);
    if (!mounted) return;   // screen may be gone while the dialog was open
    // Verdict is bound to the endpoint whose digits the user compared (C2).
    await ref
        .read(keyExchangeServiceProvider)
        .confirmSas(ok, endpointId: challenge.endpointId);
    if (!ok && mounted) {
      await ref.read(groupControllerProvider).leaveGroup();
    }
  }

  Future<void> _confirmLeave() async {
    final ok = await showLeaveConfirmDialog(context);
    if (!ok || !mounted) return;
    await ref.read(groupControllerProvider).leaveGroup();
    if (!mounted) return;
    context.go('/home');
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
    final l10n = AppLocalizations.of(context)!;
    final cs = ShadTheme.of(context).colorScheme;
    final group = ref.watch(currentGroupProvider);
    final controller = ref.read(chatControllerProvider);
    final myNick = ref.read(appPreferencesProvider).nickname ?? '';
    final peerName = group?.name ?? '';
    final status = ref.watch(connectionStatusProvider).valueOrNull ??
        ConnectionStatus.searching;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Back from a conversation always returns Home — the chat may have
        // been reached via push (create/invite/join) or go().
        context.go('/home');
      },
      child: Scaffold(
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
              if (v == 'disconnect') _confirmLeave();
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'info',
                enabled: false,
                child: Row(
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
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'disconnect',
                child: Row(
                  children: [
                    Icon(LucideIcons.logOut, size: 16, color: cs.destructive),
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
            stream: controller.watchMessages(widget.groupId),
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
            title: l10n.connectionLost(peerName),
            hint: l10n.messageWillWait,
          ),
        MessageComposer(
          controller: _msgCtrl,
          onSend: (text) => controller.sendTextMessage(text),
          onSendLocation: _sendLocationPing,
          locationLoading: _locLoading,
        ),
      ]),
      ),
    );
  }

  Future<void> _sendLocationPing() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showShadDialog<bool>(
      context: context,
      builder: (ctx) => ShadDialog(
        title: Text(l10n.sendLocation),
        description: Text(l10n.sendLocationConfirm),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.verifyMismatch),
          ),
          ShadButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.sendLocation),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _locLoading = true);
    final err = await ref.read(chatControllerProvider).sendLocationPing();
    if (!mounted) return;
    setState(() => _locLoading = false);
    if (err != null) {
      ShadToaster.of(context).show(ShadToast.destructive(title: Text(err)));
    }
  }
}
