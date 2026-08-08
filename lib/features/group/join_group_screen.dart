import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../domain/services/key_exchange_service.dart';
import '../../l10n/app_localizations.dart';
import '../chat/widgets/verification_dialog.dart';
import '../home/scan_controller.dart';
import '../shared/widgets/avatar_initial.dart';
import 'group_controller.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});
  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _formKey = GlobalKey<ShadFormState>();
  bool _loading = false;
  bool _connecting = false;
  String _lastCode = '';
  Timer? _connectTimer;
  StreamSubscription<String>? _sasSub;
  StreamSubscription? _rejectedSub;

  @override
  void initState() {
    super.initState();
    _sasSub = ref
        .read(keyExchangeServiceProvider)
        .onSasChallenge
        .listen(_onSas);
    _rejectedSub = ref
        .read(keyExchangeServiceProvider)
        .onJoinRejected
        .listen((_) => _onJoinRejected());
  }

  @override
  void dispose() {
    _sasSub?.cancel();
    _rejectedSub?.cancel();
    _connectTimer?.cancel();
    super.dispose();
  }

  Future<void> _onSas(String sas) async {
    _connectTimer?.cancel();
    if (!mounted) return;
    final ok = await showVerificationDialog(context, sas);
    if (!mounted) return;
    await ref.read(keyExchangeServiceProvider).confirmSas(ok);
    if (!ok && mounted) await ref.read(groupControllerProvider).leaveGroup();
  }

  void _onJoinRejected() {
    _connectTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _connecting = false;
    });
    final l10n = AppLocalizations.of(context)!;
    ShadToaster.of(context)
        .show(ShadToast.destructive(title: Text(l10n.pinWrong)));
  }

  Future<void> _retryScan() async {
    final ctrl = ref.read(scanControllerProvider);
    await ctrl.stop();
    await ctrl.start();
  }

  Future<void> _join() async {
    final form = _formKey.currentState;
    if (form == null || !form.saveAndValidate()) return;
    final code = (form.value['code'] as String? ?? '').trim();
    final pin = (form.value['pin'] as String? ?? '').trim();
    setState(() => _loading = true);
    final err = await ref.read(groupControllerProvider).joinGroup(
      groupId: code,
      groupName: code,   // group name is unknown until join; code doubles as label
      pin: pin.isEmpty ? null : pin,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() => _loading = false);
      final l10n = AppLocalizations.of(context)!;
      ShadToaster.of(context).show(ShadToast.destructive(
        title: Text(err == 'permission' ? l10n.permissionDenied : l10n.sessionStartFailed),
      ));
      return;
    }
    // Session started — wait for a peer/SAS, with an honest timeout.
    setState(() {
      _loading = false;
      _connecting = true;
      _lastCode = code;
    });
    _connectTimer?.cancel();
    _connectTimer = Timer(const Duration(seconds: 15), _onConnectTimeout);
  }

  void _onConnectTimeout() {
    if (!mounted) return;
    setState(() => _connecting = false);
    ref.read(groupControllerProvider).leaveGroup();
    final l10n = AppLocalizations.of(context)!;
    showShadDialog<void>(
      context: context,
      builder: (ctx) => ShadDialog(
        title: Text(l10n.groupNotFound),
        description: Text(l10n.groupNotFoundHint),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancelLabel),
          ),
          ShadButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.retryLabel),
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
    final devices = ref.watch(nearbyDevicesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.joinGroup)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.joinGroupDesc, style: theme.textTheme.muted),
              const SizedBox(height: 16),
              // Nearby devices from the ambient scan — honest list: name +
              // "detected" only (the plugin exposes no signal strength).
              Text(l10n.devicesNearbySection,
                  style: theme.textTheme.small.copyWith(
                      fontWeight: FontWeight.w600, letterSpacing: 0.4)),
              const SizedBox(height: 8),
              if (devices.isEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.border),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.radar, size: 18, color: cs.mutedForeground),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(l10n.noDevicesFound,
                            style: theme.textTheme.small),
                      ),
                      ShadButton.ghost(
                        onPressed: _retryScan,
                        child: Text(l10n.retryLabel),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: cs.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.border),
                  ),
                  child: Column(
                    children: [
                      for (final d in devices)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          child: Row(
                            children: [
                              AvatarInitial(name: d.nickname, size: 32),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(d.nickname,
                                    style: theme.textTheme.p
                                        .copyWith(fontWeight: FontWeight.w500)),
                              ),
                              Text(l10n.deviceDetected,
                                  style: theme.textTheme.small),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              ShadCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                          validator: (v) =>
                              v.trim().isEmpty ? l10n.groupCode : null,
                        ),
                        const SizedBox(height: 16),
                        ShadInputFormField(
                          id: 'pin',
                          label: Text(l10n.groupPin),
                          keyboardType: TextInputType.number,
                          inputFormatters: [LengthLimitingTextInputFormatter(6)],
                        ),
                        const SizedBox(height: 24),
                        if (_connecting)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                l10n.connectingTo(_lastCode),
                                style: theme.textTheme.small,
                              ),
                            ],
                          )
                        else if (_loading)
                          const ShadProgress()
                        else
                          ShadButton(
                            onPressed: _join,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            child: Text(l10n.joinGroup,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
