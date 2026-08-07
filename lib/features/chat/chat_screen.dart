import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants.dart';
import '../../data/database/app_database.dart';
import '../../domain/services/key_exchange_service.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../group/group_controller.dart';
import 'chat_controller.dart';
import 'widgets/message_bubble.dart';
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
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final group = ref.watch(currentGroupProvider);
    final controller = ref.read(chatControllerProvider);
    final myNick = ref.read(appPreferencesProvider).nickname ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(group?.name ?? ''),
        actions: [
          ShadIconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () async {
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
              ShadIconButton(
                icon: const Icon(LucideIcons.mapPin),
                onPressed: () => _sendLocationPing(controller),
              ),
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
                onPressed: () => _sendText(controller),
                child: const Icon(LucideIcons.send),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _sendText(ChatController c) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await c.sendTextMessage(text);
  }

  Future<void> _sendLocationPing(ChatController c) async {
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
    if (ok != true) return;
    final err = await c.sendLocationPing();
    if (err != null && mounted) {
      ShadToaster.of(context).show(ShadToast.destructive(title: Text(err)));
    }
  }
}
