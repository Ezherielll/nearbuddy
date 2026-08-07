import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/utils/battery_monitor.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/nearbuddy_color_scheme.dart';

/// Pulsing "online/connected" dot — honors reduced-motion.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
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
    final color = ShadTheme.of(context).colorScheme.online;
    if (MediaQuery.of(context).disableAnimations) {
      return Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
    }
    return FadeTransition(opacity: _opacity, child: Container(
      width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ));
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final cs = ShadTheme.of(context).colorScheme;
    final isLow = ref.watch(lowBatteryProvider).valueOrNull ?? false;

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
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isLow ? cs.onlineSoft : cs.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.border),
                ),
                child: Row(
                  children: [
                    if (isLow)
                      Icon(LucideIcons.batteryWarning, size: 18, color: cs.warning)
                    else
                      const _PulsingDot(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isLow ? l10n.lowBatteryMode : l10n.readyStatus,
                        style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _ActionCard(
                icon: LucideIcons.users,
                title: l10n.createGroup,
                description: l10n.createGroupDesc,
                onTap: () => context.push('/create-group'),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: LucideIcons.logIn,
                title: l10n.joinGroup,
                description: l10n.joinGroupDesc,
                onTap: () => context.push('/join-group'),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: LucideIcons.messageCircle,
                title: l10n.dmSessions,
                description: l10n.dmSessionsDesc,
                onTap: () => context.push('/dms'),
              ),
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
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
                  color: cs.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: cs.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600)),
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
