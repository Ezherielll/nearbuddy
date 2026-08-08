import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../data/database/app_database.dart';
import '../../../l10n/app_localizations.dart';
import '../../shared/widgets/avatar_initial.dart';
import 'location_ping_card.dart';

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

  bool get _isLocation =>
      row.type == 'location' && row.latitude != null && row.longitude != null;

  Widget? _statusIcon(ShadColorScheme cs, AppLocalizations l10n) {
    if (!isMe) return null;
    final status = row.status;
    final (icon, color, tooltip) = switch (status) {
      'delivered' => (LucideIcons.checkCheck, cs.primary, l10n.messageDelivered),
      'pending' => (LucideIcons.clock, cs.mutedForeground, l10n.messagePending),
      'failed' => (LucideIcons.alertCircle, cs.destructive, l10n.messageFailed),
      _ => (LucideIcons.check, cs.mutedForeground, l10n.messageSent),
    };
    final retryable = status == 'pending' || status == 'failed';
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: retryable && onRetry != null ? () => onRetry!(row.id) : null,
        child: Icon(icon, size: 13, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final bubble = Container(
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? cs.primary : cs.card,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        border: isMe ? null : Border.all(color: cs.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMe && !_isLocation)
            Text(row.senderId,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.primary)),
          if (_isLocation)
            LocationPingCard(
              latitude: row.latitude!,
              longitude: row.longitude!,
              onDark: isMe,
            )
          else
            Padding(
              padding: EdgeInsets.only(top: !isMe ? 2 : 0),
              child: Text(
                row.content,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.3,
                  color: isMe ? cs.primaryForeground : cs.foreground,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_statusIcon(cs, l10n) != null) ...[
                _statusIcon(cs, l10n)!,
                const SizedBox(width: 4),
              ],
              Text(
                _fmt(row.timestamp),
                style: TextStyle(
                  fontSize: 11,
                  color: isMe
                      ? cs.primaryForeground.withValues(alpha: 0.75)
                      : cs.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (isMe) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Align(alignment: Alignment.centerRight, child: bubble),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AvatarInitial(name: row.senderId, size: 28),
            const SizedBox(width: 8),
            Flexible(child: bubble),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final hm = '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) return hm;
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')} $hm';
  }
}
