import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class DisclaimerScreen extends ConsumerWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final prefs = ref.read(appPreferencesProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(LucideIcons.triangleAlert,
                  size: 72, color: Color(0xFFF5A623)),
              const SizedBox(height: 24),
              Text(l10n.disclaimerTitle,
                  style: theme.textTheme.h2.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(l10n.disclaimerBody,
                  style: theme.textTheme.p, textAlign: TextAlign.center),
              const SizedBox(height: 40),
              ShadButton(
                onPressed: () async {
                  await prefs.acceptDisclaimer();
                  if (context.mounted) context.go('/nickname');
                },
                child: Text(l10n.disclaimerAccept),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
