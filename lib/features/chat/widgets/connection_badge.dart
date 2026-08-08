import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/nearbuddy_color_scheme.dart';
import '../../shared/connection_status.dart';

/// Real-time connection status pill. Used consistently on Home, group chat
/// and DM chat so the "offline-first, connection is live" mental model is
/// the same everywhere.
class ConnectionBadge extends StatelessWidget {
  final ConnectionStatus status;
  final bool chatContext;
  const ConnectionBadge({super.key, required this.status})
      : chatContext = false;

  /// Chat-header variant: discovery ("searching") is network-level noise
  /// inside a conversation, so it renders as "Connecting…" (amber); a lost
  /// peer renders as "Not connected" (gray).
  const ConnectionBadge.chat({super.key, required this.status})
      : chatContext = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = ShadTheme.of(context).colorScheme;

    final (color, label) = chatContext
        ? switch (status) {
            ConnectionStatus.connected => (cs.online, l10n.connConnected),
            ConnectionStatus.searching => (cs.warning, l10n.connConnecting),
            ConnectionStatus.outOfRange =>
              (cs.mutedForeground, l10n.connDisconnected),
            ConnectionStatus.radioOff => (cs.mutedForeground, l10n.connRadioOff),
          }
        : switch (status) {
            ConnectionStatus.connected => (cs.online, l10n.connConnected),
            // searching = blue (information); connecting/warning = amber
            ConnectionStatus.searching => (cs.primary, l10n.connSearching),
            ConnectionStatus.outOfRange =>
              (cs.mutedForeground, l10n.connDisconnected),
            ConnectionStatus.radioOff => (cs.mutedForeground, l10n.connRadioOff),
          };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: cs.mutedForeground),
          ),
        ),
      ],
    );
  }
}

/// Small secondary "end-to-end encrypted" marker — the lock icon with the
/// encrypted label, kept secondary to the live connection status.
class EncryptedMarker extends StatelessWidget {
  const EncryptedMarker({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = ShadTheme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.lock, size: 11, color: cs.online),
        const SizedBox(width: 4),
        Text(l10n.encryptedLabel,
            style: TextStyle(fontSize: 11, color: cs.mutedForeground)),
      ],
    );
  }
}
