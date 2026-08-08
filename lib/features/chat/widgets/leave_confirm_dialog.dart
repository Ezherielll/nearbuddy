import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../l10n/app_localizations.dart';

/// Confirms leaving a group / deleting a DM session before acting.
Future<bool> showLeaveConfirmDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showShadDialog<bool>(
    context: context,
    builder: (ctx) => ShadDialog(
      title: Text(l10n.leaveConfirmTitle),
      description: Text(l10n.leaveConfirmBody),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancelLabel),
        ),
        ShadButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.leaveLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}
