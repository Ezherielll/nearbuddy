import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/constants.dart';
import '../../../core/emoji_catalog.dart';
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

  Future<void> _showEmojiSheet() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmojiPickerSheet(onEmojiTap: _insertEmoji),
    );
  }

  void _insertEmoji(String emoji) {
    final ctrl = widget.controller;
    final selection = ctrl.selection;
    final start = selection.isValid ? selection.start : ctrl.text.length;
    final end = selection.isValid ? selection.end : start;
    ctrl.text = ctrl.text.replaceRange(start, end, emoji);
    ctrl.selection = TextSelection.collapsed(offset: start + emoji.length);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = ShadTheme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.onSendLocation != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 2),
                  child: GestureDetector(
                    onTap: widget.locationLoading ? null : _sendLocation,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.muted,
                      ),
                      child: widget.locationLoading
                          ? Padding(
                              padding: const EdgeInsets.all(11),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.primary,
                              ),
                            )
                          : Icon(
                              LucideIcons.mapPin,
                              size: 20,
                              color: cs.mutedForeground,
                            ),
                    ),
                  ),
                ),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: cs.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cs.border, width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 44,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _showEmojiSheet,
                              child: Icon(
                                LucideIcons.smile,
                                size: 20,
                                color: cs.mutedForeground,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          maxLines: null,
                          maxLength: AppConstants.maxMessageLength,
                          buildCounter: (
                            _, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) =>
                              null,
                          decoration: InputDecoration(
                            hintText: l10n.messageHint,
                            hintStyle: TextStyle(
                              color: cs.mutedForeground,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                          ),
                          style: TextStyle(
                            color: cs.foreground,
                            fontSize: 15,
                          ),
                          onChanged: (_) => _onChanged(),
                        ),
                      ),
                      if (_showCounter)
                        Padding(
                          padding: const EdgeInsets.only(right: 10, bottom: 8),
                          child: Text(
                            '$_count/${AppConstants.maxMessageLength}',
                            style: TextStyle(
                              fontSize: 10,
                              color: _counterColor(
                                _count / AppConstants.maxMessageLength,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hasText ? const Color(0xFF3D5AFE) : cs.muted,
                ),
                child: GestureDetector(
                  onTap: _hasText ? _send : null,
                  child: Center(
                    child: Icon(
                      LucideIcons.send,
                      size: 20,
                      color: _hasText ? Colors.white : cs.mutedForeground,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet emoji picker: curated grid from [emojiCatalog].
/// The sheet stays open so multiple emojis can be inserted in a row.
class _EmojiPickerSheet extends StatelessWidget {
  final void Function(String emoji) onEmojiTap;

  const _EmojiPickerSheet({required this.onEmojiTap});

  static String _categoryLabel(AppLocalizations l10n, String key) =>
      switch (key) {
        'emojiCatSmileys' => l10n.emojiCatSmileys,
        'emojiCatGestures' => l10n.emojiCatGestures,
        'emojiCatHearts' => l10n.emojiCatHearts,
        'emojiCatAnimals' => l10n.emojiCatAnimals,
        'emojiCatSymbols' => l10n.emojiCatSymbols,
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = ShadTheme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.emojiPickerTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.muted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.x,
                      size: 18,
                      color: cs.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              children: [
                for (final category in emojiCatalog) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 10, 2, 6),
                    child: Text(
                      _categoryLabel(l10n, category.labelKey),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: cs.mutedForeground,
                      ),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisExtent: 44,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: category.emojis.length,
                    itemBuilder: (_, i) {
                      final emoji = category.emojis[i];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onEmojiTap(emoji),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
