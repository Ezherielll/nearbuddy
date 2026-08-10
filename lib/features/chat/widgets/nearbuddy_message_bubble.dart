import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/nearbuddy_typography.dart';
import 'location_ping_card.dart';

/// Internal NearBuddy message delivery state — maps 1:1 to the DB `status`
/// column ('pending'|'sent'|'delivered'|'failed') plus the transient
/// 'sending' state. Presentation-only; never drives networking logic.
enum MessageStatus { sending, sent, delivered, failed, pendingConnection }

/// Presentation wrapper: translates NearBuddy message state into a bubble.
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

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final retryable = (status == MessageStatus.pendingConnection ||
            status == MessageStatus.failed) &&
        onRetry != null;

    final Widget bubble;
    if (isMe) {
      // Sent bubble (Telegram vibrant indigo-blue)
      bubble = Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
          minWidth: 80,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF3D5AFE),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocation && latitude != null && longitude != null)
              LocationPingCard(
                latitude: latitude!,
                longitude: longitude!,
                onDark: true,
              )
            else
              Text(
                text,
                style: NearBuddyTypography.chatBodyStyle.copyWith(
                  color: Colors.white,
                ),
              ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _time(context),
                  style: NearBuddyTypography.chatMetaStyle.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 3),
                if (status == MessageStatus.delivered)
                  Icon(
                    LucideIcons.checkCheck,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  )
                else if (status == MessageStatus.sent)
                  Icon(
                    LucideIcons.check,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  )
                else if (status == MessageStatus.pendingConnection ||
                    status == MessageStatus.sending)
                  Icon(
                    LucideIcons.clock,
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  )
                else if (status == MessageStatus.failed)
                  Icon(
                    LucideIcons.alertCircle,
                    size: 13,
                    color: Colors.red.shade300,
                  ),
              ],
            ),
          ],
        ),
      );
    } else {
      // Received bubble (card surface)
      bubble = Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: cs.card,
          border: Border.all(color: cs.border, width: 1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (senderName != null && senderName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  senderName!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ),
            if (isLocation && latitude != null && longitude != null)
              LocationPingCard(
                latitude: latitude!,
                longitude: longitude!,
                onDark: false,
              )
            else
              Text(
                text,
                style: NearBuddyTypography.chatBodyStyle.copyWith(
                  color: cs.foreground,
                ),
              ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _time(context),
                style: NearBuddyTypography.chatMetaStyle.copyWith(
                  color: cs.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 60 : 8,
        right: isMe ? 8 : 60,
        top: 2,
        bottom: 2,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: retryable ? onRetry : null,
              child: bubble,
            ),
            // L6: make the tap-to-retry affordance discoverable.
            if (retryable)
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.rotateCw,
                        size: 11, color: cs.mutedForeground),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.retryHint,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.mutedForeground,
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


