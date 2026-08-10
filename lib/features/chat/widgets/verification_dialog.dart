import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../domain/services/key_exchange_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/nearbuddy_typography.dart';

/// Drives one SAS challenge end-to-end: shows the digits and routes the
/// user's verdict to the EXACT endpoint they compared (C2). Returns the
/// verdict, or null when the screen was disposed while the dialog was open.
Future<bool?> answerSasChallenge(
    BuildContext context, WidgetRef ref, SasChallenge challenge) async {
  if (!context.mounted) return null;
  final ok = await showVerificationDialog(context, challenge.sas);
  if (!context.mounted) return null;
  await ref
      .read(keyExchangeServiceProvider)
      .confirmSas(ok, endpointId: challenge.endpointId);
  return ok;
}

/// The key E2EE moment: shows the 6-digit SAS (grouped XXX XXX) in a
/// premium monospace presentation and asks the user to compare devices.
Future<bool> showVerificationDialog(BuildContext context, String sas) async {
  final l10n = AppLocalizations.of(context)!;
  final cs = ShadTheme.of(context).colorScheme;
  final theme = ShadTheme.of(context);
  final grouped = sas.length == 6
      ? '${sas.substring(0, 3)} ${sas.substring(3)}'
      : sas;

  final match = await showShadDialog<bool>(
    context: context,
    builder: (ctx) => ShadDialog(
      title: Text(l10n.verifyTitle),
      description: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.verifyCopyHint,
              style: theme.textTheme.muted, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              color: cs.secondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.border),
            ),
            child: SelectableText(
              grouped,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.mono,
                fontSize: 36,
                fontWeight: FontWeight.w700,
                letterSpacing: 6,
                color: cs.foreground,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: ShadButton.link(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: sas));
                if (!ctx.mounted) return;
                ShadToaster.of(ctx).show(
                    ShadToast(title: Text(l10n.codeCopied)));
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.copy, size: 14),
                  const SizedBox(width: 4),
                  Text(l10n.copyCode),
                ],
              ),
            ),
          ),
        ],
      ),
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
