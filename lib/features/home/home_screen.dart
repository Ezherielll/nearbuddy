import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/utils/battery_monitor.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/nearbuddy_color_scheme.dart';
import '../shared/connection_status.dart';
import '../shared/widgets/avatar_initial.dart';
import 'scan_controller.dart';

/// Pulsing "online/connected" dot — honors reduced-motion.
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
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    checkRadioAvailability().then(
        (ok) => ref.read(radioAvailableProvider.notifier).state = ok);
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
    final isLow = ref.watch(lowBatteryProvider).valueOrNull ?? false;
    final status =
        ref.watch(connectionStatusProvider).valueOrNull ??
            ConnectionStatus.searching;
    final devices = ref.watch(nearbyDevicesProvider);
    final radioOn = ref.watch(radioAvailableProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 16),
              _StatusCard(
                status: status,
                radioOn: radioOn,
                isLow: isLow,
                lowLabel: l10n.lowBatteryMode,
                deviceCount: devices.length,
                devicesFound: l10n.devicesFound(devices.length),
                searchingLabel: l10n.connSearching,
                radioOffLabel: l10n.connRadioOff,
                expanded: _expanded,
                onTap: () => setState(() => _expanded = !_expanded),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: _expanded && devices.isNotEmpty
                    ? _DeviceList(devices: devices, detectedLabel: l10n.deviceDetected)
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              _ActionCard(
                icon: LucideIcons.users,
                title: l10n.createGroup,
                description: l10n.createGroupDesc,
                tint: cs.primary,
                onTap: () => context.push('/create-group'),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: LucideIcons.logIn,
                title: l10n.joinGroup,
                description: l10n.joinGroupDesc,
                tint: cs.online,
                onTap: () => context.push('/join-group'),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: LucideIcons.messageCircle,
                title: l10n.dmSessions,
                description: l10n.dmSessionsDesc,
                tint: cs.mutedForeground,
                onTap: () => context.push('/dms'),
              ),
              const SizedBox(height: 20),
              Text(l10n.devicesNearbySection,
                  style: theme.textTheme.small.copyWith(
                      fontWeight: FontWeight.w600, letterSpacing: 0.4)),
              const SizedBox(height: 8),
              _NearbyPreview(devices: devices, emptyLabel: l10n.devicesEmpty),
              const Spacer(),
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
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final ConnectionStatus status;
  final bool radioOn;
  final bool isLow;
  final String lowLabel;
  final int deviceCount;
  final String devicesFound;
  final String searchingLabel;
  final String radioOffLabel;
  final bool expanded;
  final VoidCallback onTap;
  const _StatusCard({
    required this.status,
    required this.radioOn,
    required this.isLow,
    required this.lowLabel,
    required this.deviceCount,
    required this.devicesFound,
    required this.searchingLabel,
    required this.radioOffLabel,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final (dotColor, label) = isLow
        ? (cs.warning, lowLabel)
        : switch (status) {
            ConnectionStatus.connected => deviceCount > 0
                ? (cs.online, devicesFound)
                : (cs.online, l10n.connConnected),
            ConnectionStatus.outOfRange => (cs.destructive, l10n.connOutOfRange),
            ConnectionStatus.radioOff => (cs.mutedForeground, radioOffLabel),
            ConnectionStatus.searching => (cs.warning, searchingLabel),
          };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.border),
        ),
        child: Row(
          children: [
            if (isLow)
              Icon(LucideIcons.batteryWarning, size: 18, color: dotColor)
            else
              _PulsingDot(color: dotColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style:
                      theme.textTheme.p.copyWith(fontWeight: FontWeight.w600)),
            ),
            if (!isLow)
              Icon(
                expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 16,
                color: cs.mutedForeground,
              ),
          ],
        ),
      ),
    );
  }
}

class _DeviceList extends StatelessWidget {
  final List<NearbyDevice> devices;
  final String detectedLabel;
  const _DeviceList({required this.devices, required this.detectedLabel});

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final theme = ShadTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: cs.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.border),
      ),
      child: Column(
        children: [
          for (final d in devices)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  AvatarInitial(name: d.nickname, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(d.nickname,
                        style: theme.textTheme.p
                            .copyWith(fontWeight: FontWeight.w500)),
                  ),
                  Text(detectedLabel, style: theme.textTheme.small),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NearbyPreview extends StatelessWidget {
  final List<NearbyDevice> devices;
  final String emptyLabel;
  const _NearbyPreview({required this.devices, required this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final theme = ShadTheme.of(context);
    final preview = devices.take(3).toList();

    if (preview.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.border),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.radar, size: 18, color: cs.mutedForeground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(emptyLabel, style: theme.textTheme.small),
            ),
          ],
        ),
      );
    }
    return Row(
      children: [
        for (var i = 0; i < preview.length; i++)
          Padding(
            padding: EdgeInsets.only(right: i == preview.length - 1 ? 0 : -8),
            child: AvatarInitial(name: preview[i].nickname, size: 36),
          ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            preview.map((d) => d.nickname).join(', '),
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.small,
          ),
        ),
      ],
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
              Icon(LucideIcons.chevronRight, size: 18, color: cs.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}
