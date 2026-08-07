import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/utils/battery_monitor.dart';
import '../../l10n/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final isLow = ref.watch(lowBatteryProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Text(l10n.appName),
          if (isLow) ...[
            const SizedBox(width: 8),
            ShadBadge(
              child: Text(l10n.lowBatteryMode, style: const TextStyle(fontSize: 11)),
            ),
          ],
        ]),
        actions: [
          ShadIconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ShadButton(
                onPressed: () => context.push('/create-group'),
                leading: const Icon(LucideIcons.plus),
                child: Text(l10n.createGroup),
              ),
              const SizedBox(height: 12),
              ShadButton.outline(
                onPressed: () => context.push('/join-group'),
                leading: const Icon(LucideIcons.users),
                child: Text(l10n.joinGroup),
              ),
              const SizedBox(height: 12),
              ShadButton.ghost(
                onPressed: () => context.push('/dms'),
                leading: const Icon(LucideIcons.messageCircle),
                child: Text(l10n.dmSessions),
              ),
              const SizedBox(height: 24),
              Text(l10n.noNearbyGroups,
                  style: theme.textTheme.muted, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
