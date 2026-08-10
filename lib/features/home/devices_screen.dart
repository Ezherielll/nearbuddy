import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/nearbuddy_color_scheme.dart';
import '../shared/connection_status.dart';
import '../shared/widgets/avatar_initial.dart';
import '../shared/widgets/empty_state.dart';
import 'scan_controller.dart';

/// Full list of devices found by the ambient scan, with honest per-device
/// state (connected vs available) and a retry action.
class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});
  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  late final ScanController _scan;

  @override
  void initState() {
    super.initState();
    _scan = ref.read(scanControllerProvider);
    checkRadioAvailability().then((ok) {
      if (!mounted) return;  // screen may be gone before the check resolves
      ref.read(radioAvailableProvider.notifier).state = ok;
    });
    _scan.start();
  }

  @override
  void dispose() {
    _scan.stop();
    super.dispose();
  }

  Future<void> _retry() async {
    await _scan.stop();
    await _scan.start();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final cs = ShadTheme.of(context).colorScheme;
    final devices = ref.watch(nearbyDevicesProvider);
    final connectedPeers =
        ref.watch(connectedPeersProvider).valueOrNull ?? const {};
    final status =
        ref.watch(connectionStatusProvider).valueOrNull ??
            ConnectionStatus.searching;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.devicesNearbySection)),
      body: devices.isEmpty
          ? EmptyState(
              icon: LucideIcons.radar,
              title: l10n.devicesEmptyTitle,
              description: l10n.devicesEmptyHint,
              action: ShadButton.outline(
                onPressed: _retry,
                child: Text(l10n.searchAgain),
              ),
            )
          : Column(
              children: [
                if (status == ConnectionStatus.searching)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(l10n.connSearching, style: theme.textTheme.small),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: devices.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, indent: 72, color: cs.border),
                    itemBuilder: (_, i) {
                      final d = devices[i];
                      final connected = connectedPeers.contains(d.endpointId);
                      return Padding(
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
                            Icon(LucideIcons.circle,
                                size: 9,
                                color: connected ? cs.online : cs.primary),
                            const SizedBox(width: 5),
                            Text(
                              connected
                                  ? l10n.devicesConnected
                                  : l10n.devicesAvailable,
                              style: TextStyle(
                                  fontSize: 12, color: cs.mutedForeground),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
