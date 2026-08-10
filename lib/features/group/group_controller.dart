import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
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
      // The ambient scan advertises on the same ConnectionsClient — stop it
      // first, or the group session's startAdvertising fails with a
      // "already advertising" PlatformException.
      await _peer.stopScan();
      await _peer.startSession(
          groupId: id, nickname: _prefs.nickname ?? 'Unknown', pin: pin);
      // Insert only AFTER the session started: a failed startSession must
      // not leave a ghost group row behind.
      await _dao.insertGroup(GroupsCompanion.insert(
        id: id, name: name, pin: Value(pin),
        createdAt: DateTime.now(), isOwner: const Value(true),
      ));
      _ref.read(currentGroupProvider.notifier).state =
          GroupSession(id: id, name: name, pin: pin, createdAt: DateTime.now(), isOwner: true);
      _listen();
      return null;
    } catch (e) {
      debugPrint('createGroup: startSession failed — $e');
      await _peer.stopSession();
      return _errorCode(e);
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
      await _peer.stopScan();   // ambient scan would conflict with the session
      await _peer.startSession(
          groupId: groupId, nickname: _prefs.nickname ?? 'Unknown', pin: pin);
      await _dao.insertGroup(GroupsCompanion.insert(
        id: groupId, name: groupName, pin: Value(pin), createdAt: DateTime.now(),
      ));
      _ref.read(currentGroupProvider.notifier).state =
          GroupSession(id: groupId, name: groupName, pin: pin, createdAt: DateTime.now());
      _listen();
      return null;
    } catch (e) {
      debugPrint('joinGroup: startSession failed — $e');
      await _peer.stopSession();
      return _errorCode(e);
    }
  }

  /// Maps a session-start exception to a user-facing error token. Permission
  /// denial gets its own token; anything else carries the platform status
  /// code (e.g. 'session:8038') so the screen can show it and we can
  /// diagnose real-device failures without logcat.
  static String _errorCode(Object e) {
    if (e is PlatformException) {
      final msg = (e.message ?? '').toLowerCase();
      if (msg.contains('missing_permission') || msg.contains('denied')) {
        return 'permission';
      }
      final code = e.code.contains('Failure') ? '' : e.code;
      final status = RegExp(r'\b(\d{4})\b').firstMatch(msg)?.group(1);
      return 'session:${status ?? code}';
    }
    return 'session';
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
        // H6: the PIN never rides in the hello — a member challenges the
        // joiner with pin_challenge and verifies H(pin‖nonce).
        _kx.sendHello(p.endpointId, nickname: _prefs.nickname ?? 'Unknown');
      }
    });

    // SAS challenge → active screen shows the dialog → confirmSas
    // H6: the group PIN stays local; proofs are verified via pinProvider.
    _kx.pinProvider = () => _ref.read(currentGroupProvider)?.pin;

    // Join gate: nickname uniqueness (H7) + group size (M3). PIN is handled
    // by the challenge flow, not here. The joiner's OWN deviceId is excluded
    // so a rejoin of the same device (restart → stale active member row)
    // passes the nickname check; another device reusing the nickname is
    // still rejected. Returns a rejection reason; the joiner's verify_fail
    // carries it.
    _kx.joinGate = (nickname, joinerDeviceId) async {
      final g = _ref.read(currentGroupProvider);
      if (g == null) return null;
      if (await _dao.isNicknameTaken(nickname, g.id, joinerDeviceId)) {
        return 'nick';
      }
      if (await _dao.countActiveMembers(g.id) >= AppConstants.maxGroupSize) {
        return 'full';
      }
      return null;
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
