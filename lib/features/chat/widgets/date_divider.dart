import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../l10n/app_localizations.dart';

/// Horizontal divider between message groups, labeled by day.
class DateDivider extends StatelessWidget {
  final DateTime date;
  const DateDivider({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = ShadTheme.of(context).colorScheme;
    final theme = ShadTheme.of(context);

    final now = DateTime.now();
    final local = date.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);

    final String label;
    if (day == today) {
      label = l10n.todayLabel;
    } else if (day == today.subtract(const Duration(days: 1))) {
      label = l10n.yesterdayLabel;
    } else {
      label = DateFormat.yMMMMd(l10n.localeName).format(local);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: cs.border, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: theme.textTheme.small),
          ),
          Expanded(child: Divider(color: cs.border, height: 1)),
        ],
      ),
    );
  }
}
