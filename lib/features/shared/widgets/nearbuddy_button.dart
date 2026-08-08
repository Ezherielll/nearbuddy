import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Reusable primary CTA for NearBuddy.
///
/// ShadButton pins its height via the size theme (regular = 40) — large
/// vertical paddings overflow and clip the label. This wrapper sets an
/// explicit [height] (default 50) and horizontal-only padding, so labels are
/// always fully visible and vertically centered in every state (normal,
/// loading, disabled, pressed).
class NearBuddyButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? leadingIcon;
  final double height;
  const NearBuddyButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.leadingIcon,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final Widget content;
    if (loading) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cs.primaryForeground,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(child: Text(label)),
        ],
      );
    } else if (leadingIcon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(leadingIcon, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(label)),
        ],
      );
    } else {
      content = Text(label);
    }

    return ShadButton(
      onPressed: loading ? null : onPressed,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        child: content,
      ),
    );
  }
}
