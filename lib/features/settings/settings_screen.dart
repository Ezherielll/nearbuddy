import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants.dart';
import '../../core/crypto/identity_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _nickCtrl;

  @override
  void initState() {
    super.initState();
    _nickCtrl = TextEditingController(
        text: ref.read(appPreferencesProvider).nickname);
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
      ShadToaster.of(context).show(ShadToast.destructive(title: Text(l10n.nicknameError)));
      return;
    }
    await ref.read(appPreferencesProvider).setNickname(v);
    if (!mounted) return;
    ShadToaster.of(context).show(ShadToast(title: Text(l10n.nicknameSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = ref.read(appPreferencesProvider);
    final locale = ref.watch(localeProvider);
    final deviceId = ref.watch(myDeviceIdProvider).valueOrNull ?? '—';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(children: [
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
        const Divider(),
        ListTile(
          title: Text(l10n.deviceIdLabel),
          subtitle: Text(deviceId,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l10n.changeNickname,
                style: ShadTheme.of(context).textTheme.h4),
            const SizedBox(height: 8),
            ShadInput(
              controller: _nickCtrl,
              placeholder: Text(l10n.nicknameHint),
            ),
            const SizedBox(height: 8),
            ShadButton(
              onPressed: _saveNickname,
              child: Text(l10n.continueLabel),
            ),
          ]),
        ),
      ]),
    );
  }
}
