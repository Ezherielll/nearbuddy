import 'package:flutter/material.dart';
import '../../../data/database/app_database.dart';
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
    final isLocation =
        row.type == 'location' && row.latitude != null && row.longitude != null;

    final bubble = NearBuddyMessageBubble(
      text: row.content,
      timestamp: row.timestamp,
      isMe: isMe,
      status: _status,
      senderName: isMe ? null : row.senderId,
      isLocation: isLocation,
      latitude: row.latitude,
      longitude: row.longitude,
      onRetry: onRetry == null ? null : () => onRetry!(row.id),
    );

    // Grouped consecutive messages from the same sender: no avatar — keeps
    // the list light, like modern messengers. Spacing handled by the wrapper.
    if (grouped) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: bubble,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[
          const SizedBox(width: 12),
          AvatarInitial(name: row.senderId, size: 28),
          const SizedBox(width: 8),
        ] else
          const SizedBox(width: 12),
        Flexible(child: bubble),
        if (isMe) const SizedBox(width: 12),
      ],
    );
  }
}
