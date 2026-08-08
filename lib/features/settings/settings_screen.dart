import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants.dart';
import '../../core/crypto/identity_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../theme/nearbuddy_color_scheme.dart';
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
    final cs = ShadTheme.of(context).colorScheme;
    final chosen = await showShadDialog<String>(
      context: context,
      builder: (ctx) => ShadDialog(
        description: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(LucideIcons.languages, size: 20, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.language,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: cs.foreground,
                      ),
                    ),
                    Text(
                      'Pilih bahasa antarmuka',
                      style: TextStyle(fontSize: 12, color: cs.mutedForeground),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _LanguageOption(
              label: 'Bahasa Indonesia',
              flag: '🇮🇩',
              selected: locale.languageCode == 'id',
              onTap: () => Navigator.of(ctx).pop('id'),
            ),
            const SizedBox(height: 6),
            _LanguageOption(
              label: 'English',
              flag: '🇺🇸',
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

  Future<void> _showThemeDialog() async {
    final prefs = ref.read(appPreferencesProvider);
    final current = ref.read(themeModeProvider);

    final chosen = await showModalBottomSheet<ThemeMode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ThemeBottomSheet(current: current),
    );

    if (chosen == null || chosen == current) return;
    await prefs.setThemeMode(switch (chosen) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
    if (!mounted) return;
    ref.read(themeModeProvider.notifier).state = chosen;
  }

  String _themeLabel(ThemeMode mode, AppLocalizations l10n) =>
      switch (mode) {
        ThemeMode.light => l10n.themeLight,
        ThemeMode.dark => l10n.themeDark,
        ThemeMode.system => l10n.themeSystem,
      };

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
      backgroundColor: cs.background,
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // PROFILE CARD
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.border, width: 1),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AvatarInitial(name: nickname, size: 72),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.4),
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  nickname,
                  style: theme.textTheme.h3.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.settingsProfileHint,
                  style: TextStyle(fontSize: 13, color: cs.mutedForeground),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ShadButton.outline(
                  onPressed: _showNicknameDialog,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.pencil, size: 14),
                      const SizedBox(width: 6),
                      Text(l10n.settingsChangeNickname),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // UMUM
          _SectionLabel(l10n.groupSection),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cs.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.border, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _SettingTile(
                icon: LucideIcons.languages,
                title: l10n.language,
                subtitle: locale.languageCode == 'id'
                    ? 'Bahasa Indonesia'
                    : 'English',
                onTap: _showLanguageDialog,
              ),
            ),
          ),

          // TAMPILAN
          _SectionLabel(l10n.appearanceSection),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cs.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.border, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _SettingTile(
                icon: LucideIcons.sunMoon,
                title: l10n.themeLabel,
                subtitle: _themeLabel(ref.watch(themeModeProvider), l10n),
                onTap: _showThemeDialog,
              ),
            ),
          ),

          // IDENTITAS
          _SectionLabel(l10n.identitySection),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cs.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.border, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  _SettingTile(
                    icon: LucideIcons.user,
                    title: l10n.changeNickname,
                    subtitle: nickname,
                    onTap: _showNicknameDialog,
                  ),
                  Divider(height: 1, color: cs.border, indent: 70, endIndent: 20),
                  _SettingTile(
                    icon: LucideIcons.fingerprint,
                    title: l10n.deviceIdLabel,
                    subtitle: '$deviceId\n${l10n.deviceIdHelp}',
                    trailing: ShadButton.outline(
                      onPressed: () => _copyDeviceId(deviceId),
                      child: Text(l10n.copyCode),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // KEAMANAN
          _SectionLabel(l10n.securitySection),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cs.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.border, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _SettingTile(
                icon: LucideIcons.shieldCheck,
                iconColor: cs.online,
                title: l10n.encryptionRow,
                subtitle: l10n.encryptionRowSubtitle,
                onTap: _showSecurityInfo,
              ),
            ),
          ),

          // TENTANG
          _SectionLabel(l10n.aboutSection),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: cs.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.border, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _SettingTile(
                icon: LucideIcons.info,
                title: l10n.appName,
                subtitle: l10n.appVersion(_appVersion),
                onTap: _showAbout,
              ),
            ),
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
    final cs = ShadTheme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: ShadTheme.of(context).textTheme.small.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: cs.mutedForeground,
                ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final effectiveColor = iconColor ?? cs.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: cs.primary.withValues(alpha: 0.05),
        highlightColor: cs.primary.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      effectiveColor.withValues(alpha: 0.15),
                      effectiveColor.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: effectiveColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.mutedForeground,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ] else if (onTap != null) ...[
                const SizedBox(width: 12),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: cs.border,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeBottomSheet extends StatefulWidget {
  final ThemeMode current;
  const _ThemeBottomSheet({required this.current});

  @override
  State<_ThemeBottomSheet> createState() => _ThemeBottomSheetState();
}

class _ThemeBottomSheetState extends State<_ThemeBottomSheet> {
  late ThemeMode _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: cs.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(LucideIcons.sunMoon, size: 20, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.themeLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Pilih tampilan aplikasi',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Segmented-style selector (3 stacked tiles)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: cs.muted,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  _ThemeTile(
                    icon: LucideIcons.sun,
                    label: l10n.themeLight,
                    subtitle: 'Tampilan cerah dan bersih',
                    selected: _selected == ThemeMode.light,
                    onTap: () => setState(() => _selected = ThemeMode.light),
                    cs: cs,
                  ),
                  const SizedBox(height: 4),
                  _ThemeTile(
                    icon: LucideIcons.moon,
                    label: l10n.themeDark,
                    subtitle: 'Nyaman di kondisi minim cahaya',
                    selected: _selected == ThemeMode.dark,
                    onTap: () => setState(() => _selected = ThemeMode.dark),
                    cs: cs,
                  ),
                  const SizedBox(height: 4),
                  _ThemeTile(
                    icon: LucideIcons.monitor,
                    label: l10n.themeSystem,
                    subtitle: 'Mengikuti pengaturan sistem',
                    selected: _selected == ThemeMode.system,
                    onTap: () => setState(() => _selected = ThemeMode.system),
                    cs: cs,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Apply button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(_selected),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: cs.primary,
                ),
                child: Center(
                  child: Text(
                    'Terapkan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.primaryForeground,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final ShadColorScheme cs;
  const _ThemeTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? cs.background : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(color: cs.primary.withValues(alpha: 0.3), width: 1)
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? cs.primary.withValues(alpha: 0.12)
                    : cs.border.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                size: 18,
                color: selected ? cs.primary : cs.mutedForeground,
              ),
            ),
            const SizedBox(width: 12),
            // Label + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? cs.foreground : cs.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: cs.mutedForeground),
                  ),
                ],
              ),
            ),
            // Check indicator
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: selected
                  ? Container(
                      key: const ValueKey('checked'),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.check,
                        size: 13,
                        color: cs.primaryForeground,
                      ),
                    )
                  : SizedBox.square(
                      key: const ValueKey('unchecked'),
                      dimension: 22,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.border, width: 1.5),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            left: BorderSide(
              color: selected ? cs.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? cs.primary.withValues(alpha: 0.15)
                    : cs.muted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                flag,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: cs.foreground,
                ),
              ),
            ),
            if (selected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.check,
                  size: 13,
                  color: cs.primaryForeground,
                ),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.border, width: 1.5),
                ),
              ),
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
    if (dirty != _dirty && mounted) {
      setState(() => _dirty = dirty);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = ShadTheme.of(context).colorScheme;

    return ShadDialog(
      description: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.user, size: 20, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.changeNickname,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: cs.foreground,
                      ),
                    ),
                    Text(
                      l10n.nicknameHint,
                      style: TextStyle(fontSize: 12, color: cs.mutedForeground),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ShadInput(
            controller: widget.controller,
            placeholder: Text(l10n.nicknameHint),
            leading: Icon(LucideIcons.atSign, size: 16, color: cs.mutedForeground),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${widget.controller.text.length}/20',
              style: TextStyle(fontSize: 11, color: cs.mutedForeground),
            ),
          ),
        ],
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

