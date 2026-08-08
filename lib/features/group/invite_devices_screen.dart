import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../l10n/app_localizations.dart';
import '../home/scan_controller.dart';
import '../shared/widgets/avatar_initial.dart';
import '../shared/widgets/empty_state.dart';

/// Post-create step: pick devices nearby to invite. Selected devices connect
/// automatically once they join — invitation is a local, honest step, not a
/// fake remote invite protocol.
class InviteDevicesScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;
  const InviteDevicesScreen(
      {super.key, required this.groupId, required this.groupName});
  @override
  ConsumerState<InviteDevicesScreen> createState() =>
      _InviteDevicesScreenState();
}

class _InviteDevicesScreenState extends ConsumerState<InviteDevicesScreen> {
  final _selected = <String>{};

  @override
  void initState() {
    super.initState();
    ref.read(scanControllerProvider).start();
  }

  @override
  void dispose() {
    ref.read(scanControllerProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final cs = ShadTheme.of(context).colorScheme;
    final devices = ref.watch(nearbyDevicesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inviteDevices)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text('${widget.groupName} — ${l10n.inviteDevicesHint}',
                style: theme.textTheme.small),
          ),
          Expanded(
            child: devices.isEmpty
                ? EmptyState(
                    icon: LucideIcons.radar,
                    title: l10n.devicesEmptyTitle,
                    description: l10n.devicesEmptyHint,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: devices.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, indent: 72, color: cs.border),
                    itemBuilder: (_, i) {
                      final d = devices[i];
                      final checked = _selected.contains(d.endpointId);
                      return InkWell(
                        onTap: () => setState(() {
                          checked
                              ? _selected.remove(d.endpointId)
                              : _selected.add(d.endpointId);
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              AvatarInitial(name: d.nickname, size: 40),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(d.nickname,
                                    style: theme.textTheme.p
                                        .copyWith(fontWeight: FontWeight.w500)),
                              ),
                              ShadCheckbox(
                                value: checked,
                                onChanged: (v) => setState(() {
                                  v == true
                                      ? _selected.add(d.endpointId)
                                      : _selected.remove(d.endpointId);
                                }),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ShadButton(
                onPressed: () => context.go('/chat/${widget.groupId}'),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.startChat,
                    style: theme.textTheme.p
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
