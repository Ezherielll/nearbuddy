import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../domain/services/key_exchange_service.dart';
import '../../l10n/app_localizations.dart';
import '../chat/widgets/verification_dialog.dart';
import '../home/scan_controller.dart';
import '../shared/widgets/avatar_initial.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/nearbuddy_button.dart';

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
  late final ScanController _scan;
  StreamSubscription<SasChallenge>? _sasSub;

  @override
  void initState() {
    super.initState();
    _scan = ref.read(scanControllerProvider);
    _scan.start();
    // M7: joiners can connect while the owner is still on this screen — the
    // SAS challenge must be answered here or the joiner times out.
    _sasSub = ref
        .read(keyExchangeServiceProvider)
        .onSasChallenge
        .listen(_onSas);
  }

  @override
  void dispose() {
    _sasSub?.cancel();
    _scan.stop();
    super.dispose();
  }

  Future<void> _onSas(SasChallenge challenge) async {
    // Member side (owner): a mismatch rejects only that joiner (H2) — the
    // owner's group session stays up.
    await answerSasChallenge(context, ref, challenge);
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
              child: NearBuddyButton(
                label: l10n.startChat,
                // Replace (not go): keeps /home on the stack, so system back
                // from the chat goes straight to the main menu instead of
                // re-entering the invite flow.
                onPressed: () =>
                    context.pushReplacement('/chat/${widget.groupId}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
