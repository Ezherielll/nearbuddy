import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../theme/nearbuddy_color_scheme.dart';
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
  late final TextEditingController _nickCtrl;
  bool _nickDirty = false;

  @override
  void initState() {
    super.initState();
    _nickCtrl = TextEditingController(
        text: ref.read(appPreferencesProvider).nickname);
    _nickCtrl.addListener(() {
      final dirty = _nickCtrl.text.trim() !=
          (ref.read(appPreferencesProvider).nickname ?? '');
      if (dirty != _nickDirty) setState(() => _nickDirty = dirty);
    });
  }

  @override
  void dispose() {
    _nickCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    final l10n = AppLocalizations.of(context)!;
    final v = _nickCtrl.text.trim();
    if (v.length < AppConstants.nicknameLengthMin ||
        v.length > AppConstants.nicknameLengthMax) {
      ShadToaster.of(context)
          .show(ShadToast.destructive(title: Text(l10n.nicknameError)));
      return;
    }
    await ref.read(appPreferencesProvider).setNickname(v);
    if (!mounted) return;
    ShadToaster.of(context).show(ShadToast(title: Text(l10n.nicknameSaved)));
  }

  Future<void> _copyDeviceId(String deviceId) async {
    await Clipboard.setData(ClipboardData(text: deviceId));
    if (!mounted) return;
    ShadToaster.of(context)
        .show(ShadToast(title: Text(AppLocalizations.of(context)!.codeCopied)));
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(label,
          style: ShadTheme.of(context).textTheme.small.copyWith(
              fontWeight: FontWeight.w600, letterSpacing: 0.4)),
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
        children: [
          _sectionHeader(l10n.groupSection),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ShadCard(child: Column(
              children: [
                ListTile(
                  title: Text(l10n.language),
                  trailing: ShadSelect<String>(
                    initialValue: locale.languageCode,
                    selectedOptionBuilder: (context, value) =>
                        Text(value == 'id' ? 'Bahasa Indonesia' : 'English'),
                    options: const [
                      ShadOption(value: 'id', child: Text('Bahasa Indonesia')),
                      ShadOption(value: 'en', child: Text('English')),
                    ],
                    onChanged: (code) async {
                      if (code == null) return;
                      await prefs.setLanguageCode(code);
                      ref.read(localeProvider.notifier).state = Locale(code);
                    },
                  ),
                ),
                Divider(height: 1, color: cs.border),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      AvatarInitial(name: nickname, size: 48),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.changeNickname,
                                style: theme.textTheme.p
                                    .copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            ShadInput(
                              controller: _nickCtrl,
                              placeholder: Text(l10n.nicknameHint),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ShadButton(
                        onPressed: _nickDirty ? _saveNickname : null,
                        child: Text(l10n.continueLabel),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ),
          ),
          _sectionHeader(l10n.identitySection),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ShadCard(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.deviceIdLabel,
                            style: theme.textTheme.p
                                .copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(deviceId,
                            style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                color: cs.mutedForeground)),
                        const SizedBox(height: 6),
                        Text(l10n.deviceIdHelp, style: theme.textTheme.small),
                      ],
                    ),
                  ),
                  ShadIconButton(
                    icon: const Icon(LucideIcons.copy, size: 16),
                    onPressed: () => _copyDeviceId(deviceId),
                  ),
                ],
              ),
            ),
            ),
          ),
          _sectionHeader(l10n.securitySection),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: ShadCard(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(LucideIcons.shieldCheck, size: 20, color: cs.online),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.encryptedLabel,
                            style: theme.textTheme.p
                                .copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(l10n.securityDesc, style: theme.textTheme.small),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}
