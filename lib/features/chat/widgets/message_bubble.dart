import 'package:flutter/material.dart';
import '../../../data/database/app_database.dart';
import '../../shared/widgets/avatar_initial.dart';
import 'nearbuddy_message_bubble.dart';

/// Adapter: Drift `MessageRow` → [NearBuddyMessageBubble] (presentation).
class MessageBubble extends StatelessWidget {
  final MessageRow row;
  final bool isMe;
  final void Function(String messageId)? onRetry;
  const MessageBubble({
    super.key,
    required this.row,
    required this.isMe,
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[
          AvatarInitial(name: row.senderId, size: 28),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: NearBuddyMessageBubble(
            text: row.content,
            timestamp: row.timestamp,
            isMe: isMe,
            status: _status,
            senderName: isMe ? null : row.senderId,
            isLocation: isLocation,
            latitude: row.latitude,
            longitude: row.longitude,
            onRetry: onRetry == null ? null : () => onRetry!(row.id),
          ),
        ),
      ],
    );
  }
}
