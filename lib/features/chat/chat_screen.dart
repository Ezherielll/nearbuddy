import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../data/database/app_database.dart';
import '../../domain/services/key_exchange_service.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../group/group_controller.dart';
import '../../features/shared/connection_status.dart';
import 'chat_controller.dart';
import 'widgets/connection_badge.dart';
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

  @override
  void initState() {
    super.initState();
    ref.read(groupControllerProvider).sasRequestHandler = _onSas;
  }

  @override
  void dispose() {
    ref.read(groupControllerProvider).sasRequestHandler = null;
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSas(String sas) async {
    if (!mounted) return;
    final ok = await showVerificationDialog(context, sas);
    await ref.read(keyExchangeServiceProvider).confirmSas(ok);
    if (!ok && mounted) await ref.read(groupControllerProvider).leaveGroup();
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
    final l10n = AppLocalizations.of(context)!;
    final cs = ShadTheme.of(context).colorScheme;
    final theme = ShadTheme.of(context);
    final group = ref.watch(currentGroupProvider);
    final controller = ref.read(chatControllerProvider);
    final myNick = ref.read(appPreferencesProvider).nickname ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(group?.name ?? '',
                style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConnectionBadge(
                    status:
                        ref.watch(connectionStatusProvider).valueOrNull ??
                            ConnectionStatus.searching),
                const SizedBox(width: 8),
                const EncryptedMarker(),
              ],
            ),
          ],
        ),
        actions: [
          ShadIconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () async {
              final ok = await showLeaveConfirmDialog(context);
              if (!ok || !context.mounted) return;
              await ref.read(groupControllerProvider).leaveGroup();
              if (!context.mounted) return;
              context.go('/home');
            },
          ),
        ],
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
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.messageCircle,
                            size: 40, color: cs.mutedForeground),
                        const SizedBox(height: 12),
                        Text(l10n.homeEmptyDesc,
                            style: theme.textTheme.muted,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }
              return ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _buildMessages(msgs, myNick),
              );
            },
          ),
        ),
        if (ref.watch(connectionStatusProvider).valueOrNull ==
            ConnectionStatus.outOfRange)
          ConnectionLostBanner(
            title: l10n.connectionLost(group?.name ?? ''),
            hint: l10n.messageWillWait,
          ),
        MessageComposer(
          controller: _msgCtrl,
          onSend: (text) => controller.sendTextMessage(text),
          onSendLocation: _sendLocationPing,
          locationLoading: _locLoading,
        ),
      ]),
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
