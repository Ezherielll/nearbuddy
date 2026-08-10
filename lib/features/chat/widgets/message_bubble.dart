import 'package:flutter/material.dart';
import '../../../data/database/app_database.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/widgets/avatar_initial.dart';
import 'nearbuddy_message_bubble.dart';

/// Adapter: Drift `MessageRow` → [NearBuddyMessageBubble] (presentation).
class MessageBubble extends StatelessWidget {
  final MessageRow row;
  final bool isMe;
  final bool grouped;
  final void Function(String messageId)? onRetry;
  const MessageBubble({
    super.key,
    required this.row,
    required this.isMe,
    this.grouped = false,
    this.onRetry,
  });

  MessageStatus get _status => switch (row.status) {
        'delivered' => MessageStatus.delivered,
        'pending' => MessageStatus.pendingConnection,
        'failed' => MessageStatus.failed,
        _ => MessageStatus.sent,
      };

  @override
  Widget build(BuildContext context) {
    // H5: rows that failed to decrypt render the localized notice instead
    // of raw content — never a retry affordance (it's not an outgoing row).
    final decryptFailed = row.decryptFailed;
    final isLocation = !decryptFailed &&
        row.type == 'location' &&
        row.latitude != null &&
        row.longitude != null;

    final bubble = NearBuddyMessageBubble(
      text: decryptFailed
          ? AppLocalizations.of(context)!.decryptFailed
          : row.content,
      timestamp: row.timestamp,
      isMe: isMe,
      status: _status,
      senderName: isMe ? null : row.senderId,
      isLocation: isLocation,
      latitude: row.latitude,
      longitude: row.longitude,
      tail: !grouped,
      onRetry: decryptFailed || onRetry == null
          ? null
          : () => onRetry!(row.id),
    );

    if (isMe) {
      return bubble;
    }

    if (grouped) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 44),
          Flexible(child: bubble),
          const SizedBox(width: 8),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 6, bottom: 2),
          child: AvatarInitial(name: row.senderId, size: 30),
        ),
        Flexible(child: bubble),
        const SizedBox(width: 8),
      ],
    );
  }
}

