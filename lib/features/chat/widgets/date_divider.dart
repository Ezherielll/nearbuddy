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
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: cs.muted,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cs.mutedForeground,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}
