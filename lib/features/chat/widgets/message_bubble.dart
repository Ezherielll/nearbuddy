import 'package:flutter/material.dart';
import '../../../data/database/app_database.dart';
import 'location_ping_card.dart';

class MessageBubble extends StatelessWidget {
  final MessageRow row;
  final bool isMe;
  const MessageBubble({super.key, required this.row, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!isMe)
            Text(row.senderId, style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: cs.primary)),
          if (row.type == 'location' &&
              row.latitude != null && row.longitude != null)
            LocationPingCard(latitude: row.latitude!, longitude: row.longitude!)
          else
            Text(row.content,
                style: TextStyle(color: isMe ? cs.onPrimary : null)),
          Text(_fmt(row.timestamp), style: TextStyle(
              fontSize: 10,
              color: isMe
                  ? cs.onPrimary.withValues(alpha: 0.7)
                  : cs.outline)),
        ]),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
