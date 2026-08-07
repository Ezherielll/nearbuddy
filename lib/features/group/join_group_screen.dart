import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../domain/services/key_exchange_service.dart';
import '../../l10n/app_localizations.dart';
import '../chat/widgets/verification_dialog.dart';
import 'group_controller.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});
  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _formKey = GlobalKey<ShadFormState>();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    ref.read(groupControllerProvider).sasRequestHandler = _onSas;
  }

  @override
  void dispose() {
    ref.read(groupControllerProvider).sasRequestHandler = null;
    super.dispose();
  }

  Future<void> _onSas(String sas) async {
    if (!mounted) return;
    final ok = await showVerificationDialog(context, sas);
    await ref.read(keyExchangeServiceProvider).confirmSas(ok);
    if (!ok && mounted) await ref.read(groupControllerProvider).leaveGroup();
  }

  Future<void> _join() async {
    final form = _formKey.currentState;
    if (form == null || !form.saveAndValidate()) return;
    final code = (form.value['code'] as String? ?? '').trim();
    final pin = (form.value['pin'] as String? ?? '').trim();
    setState(() => _loading = true);
    await ref.read(groupControllerProvider).joinGroup(
      groupId: code,
      groupName: code,   // group name is unknown until join; code doubles as label
      pin: pin.isEmpty ? null : pin,
    );
    if (mounted) context.go('/chat/$code');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.joinGroup)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ShadForm(
            key: _formKey,
            autovalidateMode: ShadAutovalidateMode.always,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ShadInputFormField(
                  id: 'code',
                  label: Text(l10n.groupCode),
                  placeholder: Text(l10n.groupCodeHint),
                  validator: (v) => v.trim().isEmpty ? l10n.groupCode : null,
                ),
                const SizedBox(height: 16),
                ShadInputFormField(
                  id: 'pin',
                  label: Text(l10n.groupPin),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                  ],
                ),
                const SizedBox(height: 24),
                _loading
                    ? const ShadProgress()
                    : ShadButton(
                        onPressed: _join,
                        child: Text(l10n.joinGroup),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
