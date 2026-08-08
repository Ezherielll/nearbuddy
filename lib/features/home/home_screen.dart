import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/utils/battery_monitor.dart';
import '../../data/database/app_database.dart';
import '../../infrastructure/nearby/nearby_connections_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/nearbuddy_color_scheme.dart';
import '../shared/connection_status.dart';
import '../shared/widgets/avatar_initial.dart';
import 'scan_controller.dart';

/// Pulsing status dot — honors reduced-motion.
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _opacity = Tween(begin: 1.0, end: 0.35).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: widget.color, shape: BoxShape.circle));
    }
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 10,
        height: 10,
        decoration:
            BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    checkRadioAvailability().then((ok) {
      if (!mounted) return;  // widget may be gone before the permission check resolves
      ref.read(radioAvailableProvider.notifier).state = ok;
    });
    ref.read(scanControllerProvider).start();
  }

  @override
  void dispose() {
    ref.read(scanControllerProvider).stop();
    super.dispose();
  }

  Future<void> _retryScan() async {
    final ctrl = ref.read(scanControllerProvider);
    await ctrl.stop();
    await ctrl.start();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final cs = ShadTheme.of(context).colorScheme;
    final isLow = ref.watch(lowBatteryProvider).valueOrNull ?? false;
    final status =
        ref.watch(connectionStatusProvider).valueOrNull ??
            ConnectionStatus.searching;
    final devices = ref.watch(nearbyDevicesProvider);
    final radioOn = ref.watch(radioAvailableProvider);
    final groups = ref.watch(myGroupsProvider).valueOrNull ?? const [];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(LucideIcons.shield,
                      size: 22, color: cs.primaryForeground),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.appName, style: theme.textTheme.h3),
                      Text(l10n.tagline, style: theme.textTheme.small),
                    ],
                  ),
                ),
                ShadIconButton(
                  icon: const Icon(LucideIcons.settings),
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ConnectionPanel(
              status: status,
              radioOn: radioOn,
              isLow: isLow,
              lowLabel: l10n.lowBatteryMode,
              deviceCount: devices.length,
              devicesFound: l10n.devicesFound(devices.length),
            ),
            const SizedBox(height: 20),
            _SectionLabel(l10n.devicesNearbySection),
            const SizedBox(height: 8),
            _NearbySection(
              devices: devices,
              connectedPeers: ref.read(peerDiscoveryServiceProvider).connectedPeers,
              connectedLabel: l10n.devicesConnected,
              availableLabel: l10n.devicesAvailable,
              emptyTitle: l10n.devicesEmptyTitle,
              emptyHint: l10n.devicesEmptyHint,
              searchAgain: l10n.searchAgain,
              onSearchAgain: _retryScan,
              onSeeAll: () => context.push('/devices'),
              seeAllLabel: l10n.seeAllDevices,
            ),
            const SizedBox(height: 20),
            _SectionLabel(l10n.communicationSection),
            const SizedBox(height: 8),
            _ActionCard(
              icon: LucideIcons.users,
              title: l10n.createGroup,
              description: l10n.createGroupDesc,
              tint: cs.primary,
              onTap: () => context.push('/create-group'),
            ),
            const SizedBox(height: 10),
            _ActionCard(
              icon: LucideIcons.messageCircle,
              title: l10n.dmSessions,
              description: l10n.dmSessionsDesc,
              tint: cs.online,
              onTap: () => context.push('/dms'),
            ),
            const SizedBox(height: 8),
            Center(
              child: ShadButton.ghost(
                onPressed: () => context.push('/join-group'),
                child: Text('${l10n.joinGroup} — ${l10n.groupCode}',
                    style: theme.textTheme.small),
              ),
            ),
            if (groups.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionLabel(l10n.myGroupsSection),
              const SizedBox(height: 8),
              for (final g in groups) _GroupRow(group: g),
            ],
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Icon(LucideIcons.lock, size: 18, color: cs.mutedForeground),
                  const SizedBox(height: 8),
                  Text(l10n.homeEmptyDesc,
                      style: theme.textTheme.muted, textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Primary status panel — the most important information on Home.
class _ConnectionPanel extends StatelessWidget {
  final ConnectionStatus status;
  final bool radioOn;
  final bool isLow;
  final String lowLabel;
  final int deviceCount;
  final String devicesFound;
  const _ConnectionPanel({
    required this.status,
    required this.radioOn,
    required this.isLow,
    required this.lowLabel,
    required this.deviceCount,
    required this.devicesFound,
  });

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final (color, title, subtitle) = isLow
        ? (cs.warning, lowLabel, l10n.connRadioOff)
        : switch (status) {
            ConnectionStatus.connected => deviceCount > 0
                ? (cs.online, l10n.connConnected, devicesFound)
                : (cs.online, l10n.connConnected, l10n.devicesEmptyTitle),
            ConnectionStatus.outOfRange =>
              (cs.mutedForeground, l10n.connDisconnected, l10n.connOutOfRange),
            ConnectionStatus.radioOff =>
              (cs.mutedForeground, l10n.connRadioOff, ''),
            ConnectionStatus.searching =>
              (cs.primary, l10n.connSearching, l10n.devicesEmptyHint),
          };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.border),
      ),
      child: Row(
        children: [
          if (isLow)
            Icon(LucideIcons.batteryWarning, size: 22, color: color)
          else
            _PulsingDot(color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.p
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.small),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: ShadTheme.of(context).textTheme.small.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: ShadTheme.of(context).colorScheme.mutedForeground));
  }
}

class _NearbySection extends StatelessWidget {
  final List<NearbyDevice> devices;
  final Set<String> connectedPeers;
  final String connectedLabel;
  final String availableLabel;
  final String emptyTitle;
  final String emptyHint;
  final String searchAgain;
  final String seeAllLabel;
  final VoidCallback onSearchAgain;
  final VoidCallback onSeeAll;
  const _NearbySection({
    required this.devices,
    required this.connectedPeers,
    required this.connectedLabel,
    required this.availableLabel,
    required this.emptyTitle,
    required this.emptyHint,
    required this.searchAgain,
    required this.seeAllLabel,
    required this.onSearchAgain,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final theme = ShadTheme.of(context);

    if (devices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.border),
        ),
        child: Column(
          children: [
            Icon(LucideIcons.radar, size: 28, color: cs.mutedForeground),
            const SizedBox(height: 8),
            Text(emptyTitle,
                style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(emptyHint,
                style: theme.textTheme.small, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ShadButton.outline(
              onPressed: onSearchAgain,
              child: Text(searchAgain),
            ),
          ],
        ),
      );
    }

    final preview = devices.take(3).toList();
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: cs.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.border),
          ),
          child: Column(
            children: [
              for (final d in preview)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      AvatarInitial(name: d.nickname, size: 34),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(d.nickname,
                            style: theme.textTheme.p
                                .copyWith(fontWeight: FontWeight.w500)),
                      ),
                      _DeviceStatus(
                        connected: connectedPeers.contains(d.endpointId),
                        connectedLabel: connectedLabel,
                        availableLabel: availableLabel,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: ShadButton.ghost(
            onPressed: onSeeAll,
            child: Text(seeAllLabel, style: theme.textTheme.small),
          ),
        ),
      ],
    );
  }
}

class _DeviceStatus extends StatelessWidget {
  final bool connected;
  final String connectedLabel;
  final String availableLabel;
  const _DeviceStatus({
    required this.connected,
    required this.connectedLabel,
    required this.availableLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final color = connected ? cs.online : cs.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.circle, size: 9, color: color),
        const SizedBox(width: 5),
        Text(
          connected ? connectedLabel : availableLabel,
          style: TextStyle(fontSize: 12, color: cs.mutedForeground),
        ),
      ],
    );
  }
}

class _GroupRow extends ConsumerWidget {
  final GroupRow group;
  const _GroupRow({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = ShadTheme.of(context).colorScheme;
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final groupsDao = ref.read(groupsDaoProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/chat/${group.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              AvatarInitial(name: group.name, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        style: theme.textTheme.p
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    FutureBuilder<int>(
                      future: groupsDao
                          .watchMembersInGroup(group.id)
                          .first
                          .then((m) => m.length),
                      builder: (ctx, snap) => Text(
                        l10n.memberCount(snap.data ?? 0),
                        style: theme.textTheme.small,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: cs.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color tint;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = ShadTheme.of(context).colorScheme;
    return ShadCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: tint),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.p
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(description, style: theme.textTheme.small),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight,
                  size: 18, color: cs.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}

/// Watch the user's joined groups (drift stream → provider).
final myGroupsProvider = StreamProvider<List<GroupRow>>(
    (ref) => ref.watch(groupsDaoProvider).watchAllGroups());
