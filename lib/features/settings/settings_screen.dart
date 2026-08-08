import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants.dart';
import '../../core/crypto/identity_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../shared/widgets/avatar_initial.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _appVersion = '1.0.0';

  Future<void> _copyDeviceId(String deviceId) async {
    await Clipboard.setData(ClipboardData(text: deviceId));
    if (!mounted) return;
    ShadToaster.of(context).show(
        ShadToast(title: Text(AppLocalizations.of(context)!.deviceIdCopied)));
  }

  Future<void> _showLanguageDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.read(appPreferencesProvider);
    final locale = ref.read(localeProvider);
    final chosen = await showShadDialog<String>(
      context: context,
      builder: (ctx) => ShadDialog(
        title: Text(l10n.language),
        description: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(
              label: 'Bahasa Indonesia',
              selected: locale.languageCode == 'id',
              onTap: () => Navigator.of(ctx).pop('id'),
            ),
            _LanguageOption(
              label: 'English',
              selected: locale.languageCode == 'en',
              onTap: () => Navigator.of(ctx).pop('en'),
            ),
          ],
        ),
      ),
    );
    if (chosen == null || chosen == locale.languageCode) return;
    await prefs.setLanguageCode(chosen);
    if (!mounted) return;
    ref.read(localeProvider.notifier).state = Locale(chosen);
  }

  Future<void> _showNicknameDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.read(appPreferencesProvider);
    final ctrl = TextEditingController(text: prefs.nickname);
    final saved = await showShadDialog<bool>(
      context: context,
      builder: (ctx) => _NicknameDialog(controller: ctrl),
    );
    ctrl.dispose();
    if (saved != true) return;
    final v = ctrl.text.trim();
    if (v.length < AppConstants.nicknameLengthMin ||
        v.length > AppConstants.nicknameLengthMax) {
      if (!mounted) return;
      ShadToaster.of(context)
          .show(ShadToast.destructive(title: Text(l10n.nicknameError)));
      return;
    }
    await prefs.setNickname(v);
    if (!mounted) return;
    ShadToaster.of(context).show(ShadToast(title: Text(l10n.nicknameSaved)));
  }

  Future<void> _showSecurityInfo() async {
    final l10n = AppLocalizations.of(context)!;
    await showShadDialog<void>(
      context: context,
      builder: (ctx) => ShadDialog(
        title: Text(l10n.securityDialogTitle),
        description: Text(l10n.securityDialogBody),
        actions: [
          ShadButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancelLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _showAbout() async {
    final l10n = AppLocalizations.of(context)!;
    await showShadDialog<void>(
      context: context,
      builder: (ctx) => ShadDialog(
        title: Text(l10n.aboutNearBuddy),
        description: Text(l10n.tagline),
        actions: [
          ShadButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancelLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final cs = ShadTheme.of(context).colorScheme;
    final prefs = ref.read(appPreferencesProvider);
    final locale = ref.watch(localeProvider);
    final deviceId = ref.watch(myDeviceIdProvider).valueOrNull ?? '—';
    final nickname = prefs.nickname ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // PROFILE
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              children: [
                AvatarInitial(name: nickname, size: 64),
                const SizedBox(height: 10),
                Text(nickname,
                    style: theme.textTheme.h3,
                    textAlign: TextAlign.center),
                const SizedBox(height: 2),
                Text(l10n.settingsProfileHint,
                    style: theme.textTheme.small,
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ShadButton.outline(
                  onPressed: _showNicknameDialog,
                  child: Text(l10n.settingsChangeNickname),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // UMUM
          _SectionLabel(l10n.groupSection),
          _SettingTile(
            icon: LucideIcons.languages,
            title: l10n.language,
            subtitle: locale.languageCode == 'id'
                ? 'Bahasa Indonesia'
                : 'English',
            trailing: Icon(LucideIcons.chevronRight,
                size: 18, color: cs.mutedForeground),
            onTap: _showLanguageDialog,
          ),
          // IDENTITAS
          _SectionLabel(l10n.identitySection),
          _SettingTile(
            icon: LucideIcons.user,
            title: l10n.changeNickname,
            subtitle: nickname,
            trailing: Icon(LucideIcons.chevronRight,
                size: 18, color: cs.mutedForeground),
            onTap: _showNicknameDialog,
          ),
          _SettingTile(
            icon: LucideIcons.fingerprint,
            title: l10n.deviceIdLabel,
            subtitle: '$deviceId\n${l10n.deviceIdHelp}',
            trailing: ShadButton.outline(
              onPressed: () => _copyDeviceId(deviceId),
              child: Text(l10n.copyCode),
            ),
          ),
          // KEAMANAN
          _SectionLabel(l10n.securitySection),
          _SettingTile(
            icon: LucideIcons.shieldCheck,
            title: l10n.encryptionRow,
            subtitle: l10n.encryptionRowSubtitle,
            trailing: Icon(LucideIcons.chevronRight,
                size: 18, color: cs.mutedForeground),
            onTap: _showSecurityInfo,
          ),
          // TENTANG
          _SectionLabel(l10n.aboutSection),
          _SettingTile(
            icon: LucideIcons.info,
            title: l10n.appName,
            subtitle: l10n.appVersion(_appVersion),
            trailing: Icon(LucideIcons.chevronRight,
                size: 18, color: cs.mutedForeground),
            onTap: _showAbout,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(label,
          style: ShadTheme.of(context).textTheme.small.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: ShadTheme.of(context).colorScheme.mutedForeground)),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final theme = ShadTheme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: cs.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.p
                          .copyWith(fontWeight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(
                            fontSize: 12, color: cs.mutedForeground)),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            if (selected)
              Icon(LucideIcons.check, size: 18, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

class _NicknameDialog extends ConsumerStatefulWidget {
  final TextEditingController controller;
  const _NicknameDialog({required this.controller});

  @override
  ConsumerState<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends ConsumerState<_NicknameDialog> {
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final dirty = widget.controller.text.trim() !=
        (ref.read(appPreferencesProvider).nickname ?? '');
    if (dirty != _dirty) setState(() => _dirty = dirty);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ShadDialog(
      title: Text(l10n.changeNickname),
      description: ShadInput(
        controller: widget.controller,
        placeholder: Text(l10n.nicknameHint),
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancelLabel),
        ),
        ShadButton(
          onPressed: _dirty ? () => Navigator.of(context).pop(true) : null,
          child: Text(l10n.continueLabel),
        ),
      ],
    );
  }
}
