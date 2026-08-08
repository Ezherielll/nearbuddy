import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../l10n/app_localizations.dart';
import 'location_ping_card.dart';

/// Internal NearBuddy message delivery state — maps 1:1 to the DB `status`
/// column ('pending'|'sent'|'delivered'|'failed') plus the transient
/// 'sending' state. Presentation-only; never drives networking logic.
enum MessageStatus { sending, sent, delivered, failed, pendingConnection }

/// Presentation wrapper: translates NearBuddy message state into a bubble.
/// Uses `chat_bubbles` (BubbleSpecialThree) purely as the rendering layer —
/// all state, retry, and identity styling stays in this wrapper.
class NearBuddyMessageBubble extends StatelessWidget {
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final MessageStatus status;
  final VoidCallback? onRetry;
  final String? senderName;
  final bool isLocation;
  final double? latitude;
  final double? longitude;
  /// Show the bubble tail; grouped messages omit it.
  final bool tail;

  const NearBuddyMessageBubble({
    super.key,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.status = MessageStatus.sent,
    this.onRetry,
    this.senderName,
    this.isLocation = false,
    this.latitude,
    this.longitude,
    this.tail = true,
  });

  String _time(BuildContext context) {
    final local = timestamp.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  /// Custom status row — icon + text (never color alone) so pending/failed
  /// states stay accessible. Sent/delivered use the package's built-in ticks.
  Widget? _statusRow(ShadColorScheme cs, AppLocalizations l10n) {
    if (!isMe) return null;
    switch (status) {
      case MessageStatus.pendingConnection:
        return _row(cs, LucideIcons.clock, cs.mutedForeground,
            l10n.messagePending, retryable: true);
      case MessageStatus.failed:
        return _row(cs, LucideIcons.alertCircle, cs.destructive,
            l10n.messageFailed, retryable: true);
      case MessageStatus.sending:
        return _row(cs, LucideIcons.clock, cs.mutedForeground,
            l10n.messagePending);
      case MessageStatus.sent:
      case MessageStatus.delivered:
        return null;
    }
  }

  Widget _row(ShadColorScheme cs, IconData icon, Color color, String label,
      {bool retryable = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 12, color: cs.mutedForeground)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final Widget bubble;
    if (isLocation && latitude != null && longitude != null) {
      // Location cards keep the custom rendering (map link + coords).
      bubble = Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? cs.primary : cs.secondary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: LocationPingCard(
          latitude: latitude!,
          longitude: longitude!,
          onDark: isMe,
        ),
      );
    } else {
      bubble = BubbleSpecialThree(
        text: text,
        isSender: isMe,
        color: isMe ? cs.primary : cs.secondary,
        textStyle: TextStyle(
          fontSize: 15,
          height: 1.3,
          color: isMe ? cs.primaryForeground : cs.foreground,
        ),
        tail: tail,
        sent: isMe && status == MessageStatus.sent,
        delivered: isMe && status == MessageStatus.delivered,
        timestamp: _time(context),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
      );
    }

    final statusRow = _statusRow(cs, l10n);
    final retryable =
        (status == MessageStatus.pendingConnection ||
            status == MessageStatus.failed) &&
            onRetry != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe && senderName != null && senderName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(senderName!,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.primary)),
              ),
            GestureDetector(
              onTap: retryable ? onRetry : null,
              child: bubble,
            ),
            if (statusRow != null) statusRow,
          ],
        ),
      ),
    );
  }
}
