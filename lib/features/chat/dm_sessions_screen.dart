import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/nearbuddy_typography.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/avatar_initial.dart';
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
    final theme = ShadTheme.of(context);
    final cs = ShadTheme.of(context).colorScheme;
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
          ? EmptyState(
              icon: LucideIcons.messageCircle,
              title: l10n.homeEmptyTitle,
              description: l10n.dmEmpty,
              action: ShadButton(
                onPressed: _startDmDialog,
                leading: const Icon(LucideIcons.plus, size: 16),
                child: Text(l10n.dmNew),
              ),
            )
          : ListView.separated(
              itemCount: sessions.length,
              separatorBuilder: (_, __) => Divider(
                  height: 1, indent: 76, color: cs.border),
              itemBuilder: (_, i) {
                final s = sessions[i];
                return InkWell(
                  onTap: () => context.push('/dm/${s.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        AvatarInitial(name: s.peerNickname, size: 44),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.peerNickname,
                                  style: theme.textTheme.p
                                      .copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                s.peerDeviceId,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontFamily: AppFonts.mono,
                                    fontSize: 11,
                                    color: cs.mutedForeground),
                              ),
                            ],
                          ),
                        ),
                        Icon(LucideIcons.chevronRight,
                            size: 18, color: cs.mutedForeground),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _startDmDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final deviceIdCtrl = TextEditingController();
    final nickCtrl = TextEditingController();
    final created = await showShadDialog<bool>(
      context: context,
      builder: (ctx) => ShadDialog(
        title: Text(l10n.dmNew),
        description: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dmPeerNickname, style: theme.textTheme.small),
            const SizedBox(height: 6),
            ShadInput(controller: nickCtrl),
            const SizedBox(height: 14),
            Text(l10n.dmPeerDeviceId, style: theme.textTheme.small),
            const SizedBox(height: 6),
            ShadInput(
              controller: deviceIdCtrl,
              style: NearBuddyTypography.monoStyle,
            ),          ],
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
