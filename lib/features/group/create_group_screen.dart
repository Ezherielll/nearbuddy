import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants.dart';
import '../../domain/services/key_exchange_service.dart';
import '../../l10n/app_localizations.dart';
import '../chat/widgets/verification_dialog.dart';
import '../shared/widgets/nearbuddy_button.dart';
import 'group_controller.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});
  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<ShadFormState>();
  bool _usePin = false;
  bool _loading = false;
  StreamSubscription<SasChallenge>? _sasSub;

  @override
  void initState() {
    super.initState();
    _sasSub = ref
        .read(keyExchangeServiceProvider)
        .onSasChallenge
        .listen(_onSas);
  }

  @override
  void dispose() {
    _sasSub?.cancel();
    super.dispose();
  }

  Future<void> _onSas(SasChallenge challenge) async {
    // Member side (owner): a mismatch rejects only that joiner (H2) — the
    // owner's group session stays up.
    await answerSasChallenge(context, ref, challenge);
  }

  Future<void> _create() async {
    final form = _formKey.currentState;
    if (form == null || !form.saveAndValidate()) return;
    final name = (form.value['name'] as String? ?? '').trim();
    if (name.isEmpty) return;
    final pinRaw = (form.value['pin'] as String? ?? '').trim();
    final pin = _usePin && pinRaw.length >= AppConstants.pinLengthMin ? pinRaw : null;
    setState(() => _loading = true);
    final err = await ref.read(groupControllerProvider).createGroup(name: name, pin: pin);
    if (!mounted) return;
    if (err != null) {
      setState(() => _loading = false);
      _showError(err);
      return;
    }
    // Replace (not push): the form screen has served its purpose — keep only
    // /home on the stack so back navigation goes straight to the main menu.
    context.pushReplacement(
        '/invite/${ref.read(currentGroupProvider)!.id}', extra: name);
  }

  void _showError(String err) {
    final l10n = AppLocalizations.of(context)!;
    final isPermission = err == 'permission';
    final code = err.startsWith('session:') ? err.substring(8) : '';
    ShadToaster.of(context).show(ShadToast.destructive(
      title: Text(
        isPermission
            ? l10n.permissionDenied
            : code.isEmpty
                ? l10n.sessionStartFailed
                : '${l10n.sessionStartFailed} ($code)',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createGroup)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ShadCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ShadForm(
                key: _formKey,
                autovalidateMode: ShadAutovalidateMode.always,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.createGroupDesc, style: theme.textTheme.muted),
                    const SizedBox(height: 20),
                    ShadInputFormField(
                      id: 'name',
                      label: Text(l10n.groupName),
                      placeholder: Text(l10n.groupName),
                      validator: (v) => v.trim().isEmpty ? l10n.groupName : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(l10n.groupPin,
                              style: theme.textTheme.p
                                  .copyWith(fontWeight: FontWeight.w500)),
                        ),
                        ShadSwitch(
                          value: _usePin,
                          onChanged: (v) => setState(() => _usePin = v),
                        ),
                      ],
                    ),
                    if (_usePin) ...[
                      const SizedBox(height: 16),
                      ShadInputFormField(
                        id: 'pin',
                        label: Text(l10n.groupPin),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(
                              AppConstants.pinLengthMax),
                        ],
                        validator: (v) => v.length < AppConstants.pinLengthMin
                            ? l10n.pinError
                            : null,
                      ),
                    ],
                    const SizedBox(height: 24),
                    NearBuddyButton(
                      label: l10n.createGroup,
                      loading: _loading,
                      onPressed: _create,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
