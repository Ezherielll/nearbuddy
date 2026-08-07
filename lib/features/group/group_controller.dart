import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/crypto/key_manager.dart';
import '../../core/utils/permission_handler_service.dart';
import '../../core/utils/uuid_generator.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/groups_dao.dart';
import '../../data/preferences/app_preferences.dart';
import '../../domain/models/group_session.dart';
import '../../domain/models/key_payloads.dart';
import '../../domain/services/key_exchange_service.dart';
import '../../domain/services/peer_discovery_service.dart';
import '../../infrastructure/nearby/nearby_connections_service.dart';
import '../../main.dart';

final currentGroupProvider = StateProvider<GroupSession?>((ref) => null);
final groupControllerProvider = Provider<GroupController>((ref) => GroupController(ref));

class GroupController {
  final Ref _ref;
  GroupController(this._ref);

  /// The active screen registers its SAS dialog handler here (single writer
  /// at a time) so the handshake dialog is shown without duplicate listeners.
  Future<void> Function(String sas)? sasRequestHandler;

  StreamSubscription? _payloadSub;
  StreamSubscription? _peerConnectedSub;
  StreamSubscription? _peerVerifiedSub;

  GroupsDao get _dao => _ref.read(groupsDaoProvider);
  PeerDiscoveryService get _peer => _ref.read(peerDiscoveryServiceProvider);
  AppPreferences get _prefs => _ref.read(appPreferencesProvider);
  KeyExchangeService get _kx => _ref.read(keyExchangeServiceProvider);

  /// Returns null on success, or an error code ('permission' | 'session')
  /// that the screen maps to l10n strings.
  Future<String?> createGroup({required String name, String? pin}) async {
    final ok = await _ref
        .read(permissionHandlerServiceProvider)
        .requestNearbyPermissions();
    if (!ok) return 'permission';
    try {
      final id = UuidGenerator.generate();
      await _kx.generateGroupKey(id);   // owner holds the group key
      await _dao.insertGroup(GroupsCompanion.insert(
        id: id, name: name, pin: Value(pin),
        createdAt: DateTime.now(), isOwner: const Value(true),
      ));
      await _peer.startSession(
          groupId: id, nickname: _prefs.nickname ?? 'Unknown', pin: pin);
      _ref.read(currentGroupProvider.notifier).state =
          GroupSession(id: id, name: name, pin: pin, createdAt: DateTime.now(), isOwner: true);
      _listen();
      return null;
    } catch (_) {
      return 'session';
    }
  }

  Future<String?> joinGroup({
    required String groupId,
    required String groupName,
    String? pin,
  }) async {
    final ok = await _ref
        .read(permissionHandlerServiceProvider)
        .requestNearbyPermissions();
    if (!ok) return 'permission';
    try {
      await _peer.startSession(
          groupId: groupId, nickname: _prefs.nickname ?? 'Unknown', pin: pin);
      await _dao.insertGroup(GroupsCompanion.insert(
        id: groupId, name: groupName, pin: Value(pin), createdAt: DateTime.now(),
      ));
      _ref.read(currentGroupProvider.notifier).state =
          GroupSession(id: groupId, name: groupName, pin: pin, createdAt: DateTime.now());
      _listen();
      return null;
    } catch (_) {
      return 'session';
    }
  }

  Future<void> leaveGroup() async {
    _payloadSub?.cancel();
    _peerConnectedSub?.cancel();
    _peerVerifiedSub?.cancel();
    await _peer.stopSession();
    _ref.read(currentGroupProvider.notifier).state = null;
  }

  void _listen() {
    _payloadSub?.cancel();
    _payloadSub = _peer.onPayloadReceived.listen((e) async {
      try {
        final j = jsonDecode(e.payload) as Map<String, dynamic>;
        if (!j.containsKey('t')) return;      // envelope — ChatController (T12)
        await _kx.handleIncomingControl(e.fromEndpointId, e.payload);
        if (j['t'] == 'hello') {
          // persist the peer's identity: deviceId is derived from the pubkey
          await _persistMember(KeyHello.fromJson(j));
        }
      } catch (_) {}
    });

    _peerConnectedSub?.cancel();
    _peerConnectedSub = _peer.onPeerConnected.listen((p) {
      final g = _ref.read(currentGroupProvider);
      if (g != null) {
        _kx.sendHello(p.endpointId,
            nickname: _prefs.nickname ?? 'Unknown', pin: g.pin);
      }
    });

    // SAS challenge → active screen shows the dialog → confirmSas
    _kx.pinValidator = (pin) async {
      final g = _ref.read(currentGroupProvider);
      if (g == null) return true;
      final group = await _dao.groupById(g.id);
      if (group?.pin == null) return true;
      return pin == group!.pin;
    };

    _peerVerifiedSub?.cancel();
    _peerVerifiedSub = _kx.onPeerVerified.listen((endpointId) {
      final g = _ref.read(currentGroupProvider);
      if (g != null) {
        _kx.sendGroupKeyTo(endpointId, g.id);   // key holder delivers
      }
    });
  }

  Future<void> _persistMember(KeyHello hello) async {
    final g = _ref.read(currentGroupProvider);
    if (g == null) return;
    final deviceId =
        await KeyManager.deviceIdFromPubKey(base64Decode(hello.pubKey));
    await _dao.upsertMember(MembersCompanion.insert(
      deviceId: deviceId, groupId: g.id, nickname: hello.nickname,
      lastSeen: DateTime.now(),
    ));
    await _dao.setMemberPublicKey(deviceId, g.id, hello.pubKey);
  }
}
