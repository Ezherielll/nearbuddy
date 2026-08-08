import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/nearbuddy_logo.dart';

/// About NearBuddy — the app's story, features and security in one calm page.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = ShadTheme.of(context).colorScheme;

    final highlights = [
      (icon: LucideIcons.wifiOff, text: l10n.disclaimerBullet1),
      (icon: LucideIcons.lock, text: l10n.disclaimerBullet2),
      (icon: LucideIcons.lifeBuoy, text: l10n.disclaimerBullet3),
    ];

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(title: Text(l10n.aboutNearBuddy)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        children: [
          // App logo
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: const NearBuddyLogo(size: 112, drawBackground: true),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.appName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.tagline,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: cs.mutedForeground),
          ),
          const SizedBox(height: 14),
          // Version chip
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: cs.muted,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.appVersion(AppConstants.appVersion),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.mutedForeground,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Description + highlights card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.aboutBody,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.foreground,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 18),
                Divider(height: 1, color: cs.border),
                const SizedBox(height: 18),
                for (final h in highlights)
                  Padding(
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
                          child: Icon(h.icon, size: 18, color: cs.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            h.text,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Security note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.shieldCheck, size: 18, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.securityBody,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: cs.mutedForeground,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
