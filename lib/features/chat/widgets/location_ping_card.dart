import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/nearbuddy_typography.dart';

/// Location ping card — rendered inside a bubble; [onDark] adapts colors
/// for bubbles on the primary (own-message) background.
class LocationPingCard extends StatelessWidget {
  final double latitude;
  final double longitude;
  final bool onDark;
  const LocationPingCard({
    super.key,
    required this.latitude,
    required this.longitude,
    this.onDark = false,
  });

  Future<void> _openMaps() async {
    final uri = Uri.parse('https://maps.google.com/maps?q=$latitude,$longitude');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = ShadTheme.of(context).colorScheme;
    final fg = onDark ? cs.primaryForeground : cs.foreground;
    final subtle = onDark
        ? cs.primaryForeground.withValues(alpha: 0.75)
        : cs.mutedForeground;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.mapPin, size: 16, color: cs.destructive),
            const SizedBox(width: 4),
            Text(l10n.locationPingLabel,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: fg)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
          style: TextStyle(
              fontFamily: AppFonts.mono,
              fontSize: 11,
              color: subtle),
        ),
        ShadButton.link(
          onPressed: _openMaps,
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.map, size: 14, color: onDark ? cs.primaryForeground : cs.primary),
              const SizedBox(width: 4),
              Text(l10n.openInMaps,
                  style: TextStyle(
                      fontSize: 12,
                      color: onDark ? cs.primaryForeground : cs.primary)),
            ],
          ),
        ),
      ],
    );
  }
}
