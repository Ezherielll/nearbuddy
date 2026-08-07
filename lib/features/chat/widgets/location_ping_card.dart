import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart';

class LocationPingCard extends StatelessWidget {
  final double latitude;
  final double longitude;
  const LocationPingCard(
      {super.key, required this.latitude, required this.longitude});

  Future<void> _openMaps() async {
    final uri = Uri.parse('https://maps.google.com/maps?q=$latitude,$longitude');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(LucideIcons.mapPin, color: Colors.red, size: 18),
        const SizedBox(width: 4),
        Text(l10n.locationPingLabel,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
      Text(
        '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
      ShadButton.link(
        onPressed: _openMaps,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(LucideIcons.map, size: 16),
          const SizedBox(width: 4),
          Text(l10n.openInMaps),
        ]),
      ),
    ]);
  }
}
