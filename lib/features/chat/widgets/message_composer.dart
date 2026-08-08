import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/nearbuddy_color_scheme.dart';

/// Shared premium composer bar — used identically by group chat and DM chat.
/// [onSendLocation] is only provided in group chat.
class MessageComposer extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function(String text) onSend;
  final Future<void> Function()? onSendLocation;
  final bool locationLoading;
  final void Function(bool isTyping)? onTypingChange;
  const MessageComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.onSendLocation,
    this.locationLoading = false,
    this.onTypingChange,
  });

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  int _count = 0;
  bool _hasText = false;
  bool _typingSent = false;
  Timer? _typingOffTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _onChanged();
  }

  @override
  void dispose() {
    _typingOffTimer?.cancel();
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final count = widget.controller.text.length;
    final has = widget.controller.text.isNotEmpty;
    if (count == _count && has == _hasText) return;
    if (mounted) {
      setState(() {
        _count = count;
        _hasText = has;
      });
    }
    if (widget.onTypingChange != null) {
      if (has && !_typingSent) {
        _typingSent = true;
        widget.onTypingChange!(true);
      }
      _typingOffTimer?.cancel();
      _typingOffTimer = Timer(const Duration(seconds: 2), () {
        if (_typingSent) {
          _typingSent = false;
          widget.onTypingChange!(false);
        }
      });
    }
  }

  bool get _showCounter => _count > AppConstants.maxMessageLength * 0.8;

  Color _counterColor(double ratio) {
    final cs = ShadTheme.of(context).colorScheme;
    if (ratio >= 1) return cs.destructive;
    if (ratio >= 0.92) return cs.warning;
    return cs.mutedForeground;
  }

  Future<void> _send() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    widget.controller.clear();
    HapticFeedback.selectionClick();
    await widget.onSend(text);
  }

  void _sendLocation() {
    HapticFeedback.mediumImpact();
    widget.onSendLocation?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = ShadTheme.of(context).colorScheme;
    final ratio = _count / AppConstants.maxMessageLength;

    return Container(
      decoration: BoxDecoration(
        color: cs.card,
        border: Border(top: BorderSide(color: cs.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.onSendLocation != null)
                SizedBox.square(
                  dimension: 44,
                  child: Tooltip(
                    message: l10n.sendLocationTooltip,
                    child: ShadIconButton(
                      icon: widget.locationLoading
                          ? SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.primary,
                              ),
                            )
                          : const Icon(LucideIcons.mapPin, size: 20),
                      onPressed:
                          widget.locationLoading ? null : _sendLocation,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              Expanded(
                child: ShadTextarea(
                  controller: widget.controller,
                  maxLength: AppConstants.maxMessageLength,
                  placeholder: Text(l10n.send),
                  minHeight: 40,
                  maxHeight: 96,
                  onChanged: (_) {},
                  decoration: const ShadDecoration(
                    border: ShadBorder(
                      radius: BorderRadius.all(Radius.circular(22)),
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: _showCounter
                    ? Padding(
                        key: const ValueKey('counter'),
                        padding: const EdgeInsets.only(left: 6, bottom: 4),
                        child: Text(
                          '$_count/${AppConstants.maxMessageLength}',
                          style: TextStyle(
                            fontSize: 10,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: _counterColor(ratio),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('no-counter')),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: l10n.sendMessageTooltip,
                child: ShadButton(
                  onPressed: _hasText ? _send : null,
                  padding: const EdgeInsets.all(11),
                  child: Icon(LucideIcons.send,
                      size: 20,
                      color: _hasText ? cs.primaryForeground : cs.mutedForeground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
