import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../theme/nearbuddy_color_scheme.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class DisclaimerScreen extends ConsumerWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final cs = ShadTheme.of(context).colorScheme;
    final prefs = ref.read(appPreferencesProvider);

    final bullets = [
      (icon: LucideIcons.wifiOff, text: l10n.disclaimerBullet1),
      (icon: LucideIcons.lock, text: l10n.disclaimerBullet2),
      (icon: LucideIcons.lifeBuoy, text: l10n.disclaimerBullet3),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: cs.onlineSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.shieldCheck, size: 56, color: cs.online),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                l10n.disclaimerTitle,
                style: theme.textTheme.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ...bullets.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cs.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(b.icon, size: 18, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(b.text, style: theme.textTheme.p),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.disclaimerBody,
                style: theme.textTheme.muted,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ShadButton(
                onPressed: () async {
                  await prefs.acceptDisclaimer();
                  if (context.mounted) context.go('/nickname');
                },
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.disclaimerAccept,
                    style: theme.textTheme.p
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
