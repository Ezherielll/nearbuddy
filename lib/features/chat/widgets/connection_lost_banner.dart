import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../theme/nearbuddy_color_scheme.dart';

/// Slim, non-blocking banner shown when the peer went out of range.
/// States facts honestly: connection lost, messages will wait for a manual
/// retry — the app does NOT auto-send later.
class ConnectionLostBanner extends StatelessWidget {
  final String title;
  final String hint;
  const ConnectionLostBanner({
    super.key,
    required this.title,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final theme = ShadTheme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.warning.withValues(alpha: 0.12),
        border: Border(
          top: BorderSide(color: cs.warning.withValues(alpha: 0.4), width: 1),
          bottom: BorderSide(color: cs.warning.withValues(alpha: 0.4), width: 1),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 3,
              color: cs.warning,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(LucideIcons.wifiOff, size: 16, color: cs.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.small.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.warning,
                            ),
                          ),
                          Text(
                            hint,
                            style: theme.textTheme.small.copyWith(
                              color: cs.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
