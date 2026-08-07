import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/constants.dart';
import '../../domain/services/key_exchange_service.dart';
import '../../l10n/app_localizations.dart';
import '../chat/widgets/verification_dialog.dart';
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

  Future<void> _create() async {
    final form = _formKey.currentState;
    if (form == null || !form.saveAndValidate()) return;
    final name = (form.value['name'] as String? ?? '').trim();
    if (name.isEmpty) return;
    final pinRaw = (form.value['pin'] as String? ?? '').trim();
    final pin = _usePin && pinRaw.length >= AppConstants.pinLengthMin ? pinRaw : null;
    setState(() => _loading = true);
    await ref.read(groupControllerProvider).createGroup(name: name, pin: pin);
    if (mounted) {
      context.go('/chat/${ref.read(currentGroupProvider)!.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createGroup)),
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
                  id: 'name',
                  label: Text(l10n.groupName),
                  validator: (v) =>
                      v.trim().isEmpty ? l10n.groupName : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(l10n.groupPin,
                          style: ShadTheme.of(context).textTheme.p),
                    ),
                    ShadSwitch(
                      value: _usePin,
                      onChanged: (v) => setState(() => _usePin = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_usePin)
                  ShadInputFormField(
                    id: 'pin',
                    label: Text(l10n.groupPin),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(AppConstants.pinLengthMax),
                    ],
                    validator: (v) => v.length < AppConstants.pinLengthMin
                        ? l10n.pinError
                        : null,
                  ),
                const SizedBox(height: 24),
                _loading
                    ? const ShadProgress()
                    : ShadButton(
                        onPressed: _create,
                        child: Text(l10n.createGroup),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
