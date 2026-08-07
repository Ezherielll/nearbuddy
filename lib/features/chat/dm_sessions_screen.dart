import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../l10n/app_localizations.dart';
import 'dm_controller.dart';

class DmSessionsScreen extends ConsumerStatefulWidget {
  const DmSessionsScreen({super.key});
  @override
  ConsumerState<DmSessionsScreen> createState() => _DmSessionsScreenState();
}

class _DmSessionsScreenState extends ConsumerState<DmSessionsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessions = ref.watch(dmSessionsProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dmSessions),
        actions: [
          ShadIconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: _startDmDialog,
          ),
        ],
      ),
      body: sessions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.dmEmpty,
                    style: ShadTheme.of(context).textTheme.muted,
                    textAlign: TextAlign.center),
              ),
            )
          : ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (_, i) {
                final s = sessions[i];
                return ListTile(
                  leading: const Icon(LucideIcons.messageCircle),
                  title: Text(s.peerNickname),
                  subtitle: Text(s.peerDeviceId,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                  onTap: () => context.push('/dm/${s.id}'),
                );
              },
            ),
    );
  }

  Future<void> _startDmDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final deviceIdCtrl = TextEditingController();
    final nickCtrl = TextEditingController();
    final created = await showShadDialog<bool>(
      context: context,
      builder: (ctx) => ShadDialog(
        title: Text(l10n.dmNew),
        description: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShadInput(
              controller: nickCtrl,
              placeholder: Text(l10n.dmPeerNickname),
            ),
            const SizedBox(height: 12),
            ShadInput(
              controller: deviceIdCtrl,
              placeholder: Text(l10n.dmPeerDeviceId),
            ),
          ],
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.verifyMismatch),
          ),
          ShadButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.continueLabel),
          ),
        ],
      ),
    );
    if (created != true) return;
    final deviceId = deviceIdCtrl.text.trim();
    final nickname = nickCtrl.text.trim();
    if (deviceId.isEmpty) return;
    final sessionId =
        await ref.read(dmControllerProvider).startDm(deviceId, nickname);
    if (mounted) context.push('/dm/$sessionId');
  }
}
