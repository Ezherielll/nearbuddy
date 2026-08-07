import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../l10n/app_localizations.dart';

/// Shows the 6-digit SAS and asks the user to confirm both devices match.
Future<bool> showVerificationDialog(BuildContext context, String sas) async {
  final l10n = AppLocalizations.of(context)!;
  final match = await showShadDialog<bool>(
    context: context,
    builder: (ctx) => ShadDialog(
      title: Text(l10n.verifyTitle),
      description: Text('${l10n.verifyBody}\n\n$sas'),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.verifyMismatch),
        ),
        ShadButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.verifyMatch),
        ),
      ],
    ),
  );
  return match ?? false;
}
