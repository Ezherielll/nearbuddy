import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../shared/widgets/nearbuddy_button.dart';

class NicknameScreen extends ConsumerStatefulWidget {
  const NicknameScreen({super.key});
  @override
  ConsumerState<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends ConsumerState<NicknameScreen> {
  final _formKey = GlobalKey<ShadFormState>();

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.saveAndValidate()) return;
    final val = (form.value['nickname'] as String? ?? '').trim();
    await ref.read(appPreferencesProvider).setNickname(val);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);
    final cs = ShadTheme.of(context).colorScheme;

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
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(LucideIcons.shield, size: 36, color: cs.primaryForeground),
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.appName,
                  style: theme.textTheme.h1, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(l10n.tagline,
                  style: theme.textTheme.muted, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ShadCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ShadForm(
                    key: _formKey,
                    autovalidateMode: ShadAutovalidateMode.always,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.nicknameTitle, style: theme.textTheme.h4),
                        const SizedBox(height: 16),
                        ShadInputFormField(
                          id: 'nickname',
                          placeholder: Text(l10n.nicknameHint),
                          autovalidateMode: AutovalidateMode.always,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(
                                AppConstants.nicknameLengthMax),
                          ],
                          validator: (v) {
                            final val = v.trim();
                            if (val.length < AppConstants.nicknameLengthMin ||
                                val.length > AppConstants.nicknameLengthMax) {
                              return l10n.nicknameError;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        NearBuddyButton(
                          label: l10n.continueLabel,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
