import 'dart:math' show cos, sin;

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
  late final ScanController _scan;

  @override
  void initState() {
    super.initState();
    // Capture the controller while `ref` is valid — never read `ref` in
    // dispose (Riverpod throws "Cannot use ref after widget was disposed").
    _scan = ref.read(scanControllerProvider);
    checkRadioAvailability().then((ok) {
      if (!mounted) return;  // widget may be gone before the permission check resolves
      ref.read(radioAvailableProvider.notifier).state = ok;
    });
    _scan.start();
  }

  @override
  void dispose() {
    _scan.stop();
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
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            // HEADER
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3D5AFE), Color(0xFF1A3FD8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child:
                      const Icon(LucideIcons.shield, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        l10n.tagline,
                        style: TextStyle(fontSize: 13, color: cs.mutedForeground),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.card,
                      border: Border.all(color: cs.border, width: 1),
                    ),
                    child: Icon(LucideIcons.settings, size: 20, color: cs.foreground),
                  ),
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
            const SizedBox(height: 24),
            _SectionLabel(
              l10n.devicesNearbySection,
              trailing: GestureDetector(
                onTap: _retryScan,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.refreshCw, size: 14, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      l10n.searchAgain,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 24),
            _SectionLabel(l10n.communicationSection),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionGridCard(
                    icon: LucideIcons.users,
                    iconColor: cs.primary,
                    title: l10n.createGroup,
                    description: l10n.createGroupDesc,
                    onTap: () => context.push('/create-group'),
                    cs: cs,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionGridCard(
                    icon: LucideIcons.messageCircle,
                    iconColor: cs.online,
                    title: l10n.dmSessions,
                    description: l10n.dmSessionsDesc,
                    onTap: () => context.push('/dms'),
                    cs: cs,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionGridCard(
                    icon: LucideIcons.qrCode,
                    iconColor: const Color(0xFF7C3AED),
                    title: l10n.joinGroup,
                    description: l10n.groupCode,
                    onTap: () => context.push('/join-group'),
                    cs: cs,
                  ),
                ),
              ],
            ),
            if (groups.isNotEmpty) ...[
              const SizedBox(height: 24),
              _SectionLabel(l10n.myGroupsSection),
              const SizedBox(height: 8),
              for (final g in groups) _GroupRow(group: g),
            ],
            const SizedBox(height: 24),
            // FOOTER BANNER
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.shield, size: 24, color: Colors.white),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: cs.card,
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.border),
                          ),
                          child: Icon(LucideIcons.lock, size: 11, color: cs.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Secure. Private. Direct.',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.homeEmptyDesc,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.mutedForeground,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(8, 0),
                    child: Opacity(
                      opacity: 0.12,
                      child: Icon(LucideIcons.shieldCheck, size: 64, color: cs.primary),
                    ),
                  ),
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
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(
        children: [
          // LEFT: radar/battery + status text
          Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isLow)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child:
                        Icon(LucideIcons.batteryWarning, size: 24, color: color),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: _RadarAnimation(color: color),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.mutedForeground,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // RIGHT: phone connection illustration
          const SizedBox(width: 110, child: _PhoneConnectionIllustration()),
        ],
      ),
    );
  }
}

/// Animated radar ping — honors reduced-motion (static icon fallback).
class _RadarAnimation extends StatefulWidget {
  final Color color;
  const _RadarAnimation({required this.color});
  @override
  State<_RadarAnimation> createState() => _RadarAnimationState();
}

class _RadarAnimationState extends State<_RadarAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return SizedBox(
        width: 48,
        height: 48,
        child: Icon(LucideIcons.radar, size: 24, color: widget.color),
      );
    }
    return SizedBox(
      width: 48,
      height: 48,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) =>
            CustomPaint(painter: _RadarPainter(_ctrl.value, widget.color)),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RadarPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    // 3 concentric rings at staggered phases
    for (int i = 0; i < 3; i++) {
      final phase = (progress - i * 0.33).clamp(0.0, 1.0);
      final r = maxR * phase;
      final opacity = (1.0 - phase) * 0.4;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Center dot with a small static circle background
    canvas.drawCircle(
      center,
      maxR * 0.28,
      Paint()..color = color.withValues(alpha: 0.12),
    );
    canvas.drawCircle(center, maxR * 0.14, Paint()..color = color);

    // Radar sweep line (thin line rotating from center)
    final angle = progress * 2 * 3.14159;
    final sweepEnd = Offset(
      center.dx + maxR * 0.5 * cos(angle - 1.5708),
      center.dy + maxR * 0.5 * sin(angle - 1.5708),
    );
    canvas.drawLine(
      center,
      sweepEnd,
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.progress != progress;
}

/// Two phone outlines connected by a dashed line (right side of the panel).
class _PhoneConnectionIllustration extends StatelessWidget {
  const _PhoneConnectionIllustration();

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    return SizedBox(
      height: 64,
      child: CustomPaint(painter: _PhoneConnPainter(cs.primary)),
    );
  }
}

class _PhoneConnPainter extends CustomPainter {
  final Color color;
  const _PhoneConnPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final phoneW = w * 0.22;
    final phoneH = h * 0.85;
    final phoneBg = color.withValues(alpha: 0.1);
    final framePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fillPaint = Paint()..color = phoneBg;

    // Left phone
    final leftRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, (h - phoneH) / 2, phoneW, phoneH),
      const Radius.circular(6),
    );
    canvas.drawRRect(leftRect, fillPaint);
    canvas.drawRRect(leftRect, framePaint);
    // Person icon inside left phone (simplified: circle + rectangle)
    final lCx = phoneW / 2;
    final lCy = (h - phoneH) / 2 + phoneH * 0.35;
    canvas.drawCircle(
      Offset(lCx, lCy),
      phoneW * 0.2,
      Paint()..color = color.withValues(alpha: 0.5),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          lCx - phoneW * 0.25,
          lCy + phoneW * 0.25,
          phoneW * 0.5,
          phoneH * 0.22,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = color.withValues(alpha: 0.5),
    );

    // Right phone (mirrored)
    final rightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w - phoneW, (h - phoneH) / 2, phoneW, phoneH),
      const Radius.circular(6),
    );
    canvas.drawRRect(rightRect, fillPaint);
    canvas.drawRRect(rightRect, framePaint);
    final rCx = w - phoneW / 2;
    final rCy = lCy;
    canvas.drawCircle(
      Offset(rCx, rCy),
      phoneW * 0.2,
      Paint()..color = color.withValues(alpha: 0.5),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rCx - phoneW * 0.25,
          rCy + phoneW * 0.25,
          phoneW * 0.5,
          phoneH * 0.22,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = color.withValues(alpha: 0.5),
    );

    // Dashed line between phones
    final dashPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashLen = 4.0;
    const gapLen = 4.0;
    double x = phoneW + 4;
    final endX = w - phoneW - 4;
    final midY = h / 2;
    while (x < endX) {
      canvas.drawLine(
        Offset(x, midY),
        Offset((x + dashLen).clamp(x, endX), midY),
        dashPaint,
      );
      x += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(_PhoneConnPainter old) => false;
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Widget? trailing;
  const _SectionLabel(this.label, {this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final labelWidget = Text(
      label,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: cs.foreground,
      ),
    );
    if (trailing == null) return labelWidget;
    return Row(
      children: [
        Expanded(child: labelWidget),
        trailing!,
      ],
    );
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
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
        decoration: BoxDecoration(
          color: cs.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.border),
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withValues(alpha: 0.08),
              ),
              child: Icon(
                LucideIcons.radar,
                size: 36,
                color: cs.primary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              emptyTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              emptyHint,
              style: TextStyle(
                fontSize: 13,
                color: cs.mutedForeground,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onSearchAgain,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: cs.primary,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.search, size: 16, color: cs.primaryForeground),
                    const SizedBox(width: 8),
                    Text(
                      searchAgain,
                      style: TextStyle(
                        color: cs.primaryForeground,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
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


/// Compact 3-column action card for the Home quick actions grid.
class _ActionGridCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;
  final ShadColorScheme cs;
  const _ActionGridCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
        decoration: BoxDecoration(
          color: cs.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: cs.mutedForeground,
                height: 1.4,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: cs.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: cs.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Watch the user's joined groups (drift stream → provider).
final myGroupsProvider = StreamProvider<List<GroupRow>>(
    (ref) => ref.watch(groupsDaoProvider).watchAllGroups());
