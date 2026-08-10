import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants.dart';
import '../../core/crypto/crypto_service.dart';
import '../../core/crypto/identity_providers.dart';
import '../../core/crypto/key_manager.dart';
import '../../core/utils/permission_handler_service.dart';
import '../../core/utils/uuid_generator.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/groups_dao.dart';
import '../../data/database/daos/messages_dao.dart';
import '../../data/database/daos/sessions_dao.dart';
import '../../data/preferences/app_preferences.dart';
import '../../domain/models/message.dart';
import '../../domain/models/message_envelope.dart';
import '../../domain/services/key_exchange_service.dart';
import '../../domain/services/peer_discovery_service.dart';
import '../../infrastructure/nearby/nearby_connections_service.dart';
import '../../main.dart';
import '../group/group_controller.dart';

final chatControllerProvider =
    Provider<ChatController>((ref) => ChatController(ref));

/// sessionId whose peer is currently typing (DM only).
final typingSessionProvider = StateProvider<String?>((_) => null);

class ChatController {
  final Ref _ref;
  final _seen = <String, DateTime>{};
  StreamSubscription? _sub;

  ChatController(this._ref) {
    _listenToIncoming();
  }

  MessagesDao get _dao => _ref.read(messagesDaoProvider);
  SessionsDao get _sessionsDao => _ref.read(sessionsDaoProvider);
  GroupsDao get _groupsDao => _ref.read(groupsDaoProvider);
  PeerDiscoveryService get _peer => _ref.read(peerDiscoveryServiceProvider);
  AppPreferences get _prefs => _ref.read(appPreferencesProvider);
  KeyExchangeService get _kx => _ref.read(keyExchangeServiceProvider);
  CryptoService get _crypto => _ref.read(cryptoServiceProvider);
  KeyManager get _keys => _ref.read(keyManagerProvider);
  String? get _gid => _ref.read(currentGroupProvider)?.id;

  Stream<List<MessageRow>> watchMessages(String groupId) =>
      _dao.watchMessages(groupId);

  Future<void> _listenToIncoming() async {
    _sub = _peer.onPayloadReceived.listen((e) async {
      try {
        final j = jsonDecode(e.payload) as Map<String, dynamic>;
        if (j.containsKey('t')) {
          // control messages — ack is chat-scoped; the rest is group-scoped
          switch (j['t']) {
            case 'ack':
              await _handleAck(j['id'] as String, j['mac'] as String? ?? '');
            case 'typing':
              final myId = await _ref.read(myDeviceIdProvider.future);
              if (j['to'] == myId) {
                final on = j['on'] == true;
                final gid = j['gid'] as String?;
                if (on && gid != null) {
                  _ref.read(typingSessionProvider.notifier).state = gid;
                } else if (!on) {
                  // M9: clear only when the off-event matches the session
                  // whose indicator is currently shown — a typing-off for
                  // session X must not erase session Y's indicator.
                  final notifier =
                      _ref.read(typingSessionProvider.notifier);
                  if (gid == null ||
                      _ref.read(typingSessionProvider) == gid) {
                    notifier.state = null;
                  }
                }
              }
          }
          return;
        }
        if (!j.containsKey('v')) return;   // unknown control — GroupController handles
        final env = MessageEnvelope.fromWireJson(j);
        if (!_dedup(env.id)) return;

        // Relay decision — BEFORE decryption (relays never need the key).
        // Group AND DM envelopes are flooded the same way; the hop limit is
        // the envelope's own `max`, capped at the global 3-hop hard limit.
        final age = DateTime.now().difference(env.ts).inSeconds;
        final hopsAllowed = math.min(env.max, AppConstants.maxHops);
        if (env.hop < hopsAllowed && age < AppConstants.relayTtlSeconds) {
          await _peer.sendToAll(
              jsonEncode(env.copyWith(hop: env.hop + 1).toWireJson()));
        }

        // Decrypt only if addressed to us: group envelope of our current
        // group, or a DM whose cleartext `to` is our deviceId.
        final myId = await _ref.read(myDeviceIdProvider.future);
        final isForMe = env.kind == 'g' ? env.gid == _gid : env.to == myId;
        if (!isForMe) return;
        final String plain;
        final String? dmSenderDeviceId;
        if (env.kind == 'g') {
          final opened = await _openGroup(env);
          if (opened == null) {
            // H5: addressed to us but undecryptable (group key lost after
            // restart, tampered payload) — persist a visible placeholder
            // instead of silently dropping.
            await _persistFailedDecrypt(env);
            return;
          }
          plain = opened;
          dmSenderDeviceId = null;
        } else {
          final opened = await _openDm(env);
          if (opened == null) {
            await _persistFailedDecrypt(env);
            return;
          }
          plain = opened.plain;
          dmSenderDeviceId = opened.senderDeviceId;
        }
        final msg = Message.fromPayloadJson(jsonDecode(plain));
        await _persistIncoming(env, msg, dmSenderDeviceId: dmSenderDeviceId);
        // delivery receipt (DM only): authenticated with the pairwise key —
        // only the real recipient can produce a valid mac (H1)
        if (env.kind == 'dm') {
          final key = SecretKeyData(await _kx.pairwiseKeyFor(dmSenderDeviceId!));
          final mac = await _ackMac(key, env.id);
          await _peer.sendToAll(jsonEncode({
            't': 'ack', 'id': env.id, 'mac': base64Encode(mac),
          }));
        }
      } catch (_) {}
    });
  }

  /// Marks one of OUR outgoing DMs as delivered when the peer acks it.
  /// The ack is authenticated with the pairwise key shared with the DM
  /// recipient (HMAC over the envelope id) — an observer who only saw the
  /// cleartext envelope header cannot forge it (H1). Acks without a mac,
  /// for group rows, or for rows whose `to` is not a DM peer are ignored.
  Future<void> _handleAck(String id, String mac) async {
    final row = await _dao.messageById(id);
    if (row == null || row.to == null || mac.isEmpty) return;
    final Uint8List expected;
    try {
      final key = SecretKeyData(await _kx.pairwiseKeyFor(row.to!));
      expected = await _ackMac(key, id);
    } on StateError {
      return;   // not one of our DM peers
    }
    if (!_macEquals(expected, base64Decode(mac))) return;
    await _dao.markDelivered(id);
  }

  /// HMAC-SHA256 over the envelope id under the pairwise key (H1).
  Future<Uint8List> _ackMac(SecretKey key, String id) async {
    final mac = await Hmac.sha256().calculateMac(utf8.encode(id), secretKey: key);
    return Uint8List.fromList(mac.bytes);
  }

  /// Constant-time-ish comparison for MACs.
  bool _macEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Notifies the DM peer that we are (not) typing. Flooded with a `to`
  /// filter so no endpoint mapping is needed.
  Future<void> sendTyping(
      String sessionId, String peerDeviceId, bool on) async {
    await _peer.sendToAll(jsonEncode({
      't': 'typing',
      'on': on,
      'to': peerDeviceId,
      'gid': sessionId,
    }));
  }

  SecretBox _box(MessageEnvelope env) => SecretBox.fromConcatenation(
      [...env.nonce, ...env.ciphertext], nonceLength: 12, macLength: 16);

  Future<String?> _openGroup(MessageEnvelope env) async {
    final bytes = _kx.groupKeyFor(env.gid);
    if (bytes == null) return null;
    try {
      return await _crypto.open(_box(env), SecretKeyData(bytes));
    } on SecretBoxAuthenticationError {
      return null;
    }
  }

  /// Opens a DM. The receiver has no session row for the sender's sessionId
  /// (sessions only exist on the initiator), so when the session is unknown
  /// — or stale — the sender is discovered by trying every known member
  /// public key: the AES-GCM MAC rejects wrong keys (C1). Returns the
  /// plaintext and the matched sender deviceId, or null when no known peer
  /// can decrypt.
  Future<({String plain, String senderDeviceId})?> _openDm(
      MessageEnvelope env) async {
    final session = await _sessionsDao.sessionById(env.gid);
    if (session != null) {
      try {
        final key =
            SecretKeyData(await _kx.pairwiseKeyFor(session.peerDeviceId));
        return (plain: await _crypto.open(_box(env), key),
            senderDeviceId: session.peerDeviceId);
      } on StateError {
        // the peer's public key is gone — fall through to discovery
      } on SecretBoxAuthenticationError {
        // stale session row for this gid — the real sender may still be
        // discoverable among known members; fall through
      }
    }
    final mine = await _keys.ensureIdentityKey();
    final candidates = await _groupsDao.allMemberPublicKeys();
    for (final c in candidates) {
      try {
        final pub = SimplePublicKey(base64Decode(c.pubKeyB64),
            type: KeyPairType.x25519);
        final key = SecretKeyData(await _crypto.pairwiseKeyBytes(mine, pub));
        final plain = await _crypto.open(_box(env), key);
        return (plain: plain, senderDeviceId: c.deviceId);
      } on SecretBoxAuthenticationError {
        continue;   // wrong key — try the next known device
      } catch (_) {
        continue;   // corrupt stored key — never block other candidates
      }
    }
    return null;
  }

  /// Persists an incoming DM under a LOCAL session: reuses the existing
  /// session for the sender if any, otherwise creates one keyed on the
  /// sender's sessionId (so both sides share one thread id).
  Future<void> _persistIncoming(MessageEnvelope env, Message msg,
      {required String? dmSenderDeviceId}) async {
    var localGid = env.gid;
    if (dmSenderDeviceId != null) {
      final existing = await _sessionsDao.sessionForPeer(dmSenderDeviceId);
      if (existing != null) {
        localGid = existing.id;
      } else {
        await _sessionsDao.upsertSession(SessionsCompanion.insert(
          id: env.gid, peerDeviceId: dmSenderDeviceId,
          peerNickname: msg.senderId, createdAt: DateTime.now(),
        ));
      }
    }
    await _persist(env, msg, localGid: localGid);
  }

  Future<void> sendTextMessage(String content) async {
    if (_gid == null) return;
    final msg = Message(
      senderId: _prefs.nickname ?? 'Unknown', content: content,
      type: MessageType.text, timestamp: DateTime.now(),
    );
    await _sealAndSend(msg);
  }

  Future<void> sendDm(String sessionId, String peerDeviceId, String content) async {
    final msg = Message(
      senderId: _prefs.nickname ?? 'Unknown', content: content,
      type: MessageType.text, timestamp: DateTime.now(),
    );
    await _sealAndSend(msg,
        dmSessionId: sessionId, dmPeerDeviceId: peerDeviceId);
  }

  /// Re-sends a pending/failed outgoing message in place: the SAME envelope
  /// id is reused and the existing row's status flips sent/failed — a retry
  /// must never create a duplicate row (H3). Works for DM and group rows.
  Future<void> retryMessage(String id) async {
    final row = await _dao.messageById(id);
    if (row == null) return;
    final msg = Message(
      senderId: row.senderId,
      content: row.content,
      type: row.type == 'location' ? MessageType.location : MessageType.text,
      timestamp: row.timestamp,
      latitude: row.latitude,
      longitude: row.longitude,
      locationAccuracy: row.locationAccuracy,
    );
    final session = await _sessionsDao.sessionById(row.groupId);
    if (session != null) {
      await _sealAndSend(msg,
          dmSessionId: session.id, dmPeerDeviceId: session.peerDeviceId,
          envelopeId: row.id);
    } else {
      await _sealAndSend(msg, envelopeId: row.id);
    }
  }

  /// Shared seal+send path: group ('g') by default, DM when peer is given.
  /// Returns the generated envelope id, or null when nothing was sent.
  /// With [envelopeId] (retry) no new row is persisted — the existing row
  /// is flipped to 'sent'/'failed' instead (H3).
  Future<String?> _sealAndSend(Message msg,
      {String? dmSessionId, String? dmPeerDeviceId, String? envelopeId}) async {
    final SecretKey key;
    final String gid;
    final String? to;
    final String kind;
    if (dmPeerDeviceId != null) {
      key = SecretKeyData(await _kx.pairwiseKeyFor(dmPeerDeviceId));
      gid = dmSessionId!;
      to = dmPeerDeviceId;
      kind = 'dm';
    } else {
      final g = _gid;
      final keyBytes = g == null ? null : _kx.groupKeyFor(g);
      if (g == null || keyBytes == null) return null;
      key = SecretKeyData(keyBytes);
      gid = g;
      to = null;
      kind = 'g';
    }
    final box = await _crypto.seal(jsonEncode(msg.toPayloadJson()), key);
    final env = MessageEnvelope(
      id: envelopeId ?? UuidGenerator.generate(), gid: gid, to: to,
      hop: 0, max: AppConstants.maxHops, ts: DateTime.now(), kind: kind,
      nonce: Uint8List.fromList(box.nonce),
      ciphertext: Uint8List.fromList([...box.cipherText, ...box.mac.bytes]),
    );
    if (envelopeId == null) {
      // Delivery state: DM without peers in range is 'pending' (honest
      // "waiting" — the peer will ack when back); everything else is 'sent'.
      final status = kind == 'dm' && _peer.connectedPeers.isEmpty
          ? 'pending'
          : 'sent';
      await _persist(env, msg, status: status);
    }
    _dedup(env.id);
    try {
      await _peer.sendToAll(jsonEncode(env.toWireJson()));
      if (envelopeId != null) await _dao.markSent(envelopeId);
    } catch (_) {
      await _dao.markFailed(envelopeId ?? env.id);
    }
    return env.id;
  }

  /// Returns null on success, an error message otherwise.
  Future<String?> sendLocationPing(
      {String? dmSessionId, String? dmPeerDeviceId}) async {
    if (_gid == null && dmSessionId == null) return 'No active session';
    final ok = await _ref
        .read(permissionHandlerServiceProvider)
        .requestLocationPermission();
    if (!ok) return 'Location permission denied';
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10));
      final msg = Message(
        senderId: _prefs.nickname ?? 'Unknown',
        content: '${pos.latitude},${pos.longitude}',
        type: MessageType.location,
        timestamp: DateTime.now(),
        latitude: pos.latitude,
        longitude: pos.longitude,
        locationAccuracy: pos.accuracy,
      );
      await _sealAndSend(msg,
          dmSessionId: dmSessionId, dmPeerDeviceId: dmPeerDeviceId);
      return null;
    } catch (e) {
      return 'GPS error: $e';
    }
  }

  Future<void> _persist(MessageEnvelope env, Message msg,
      {String? status, String? localGid, bool decryptFailed = false}) =>
      _dao.insertMessage(MessagesCompanion.insert(
        id: env.id, groupId: localGid ?? env.gid, senderId: msg.senderId,
        content: msg.content, type: msg.type.name, timestamp: msg.timestamp,
        hopCount: Value(env.hop), to: Value(env.to),
        status: Value(status),
        decryptFailed: Value(decryptFailed),
        latitude: Value(msg.latitude), longitude: Value(msg.longitude),
        locationAccuracy: Value(msg.locationAccuracy),
      ));

  /// H5: the envelope was addressed to us but cannot be decrypted (group
  /// key gone after restart, or a tampered payload). The bubble renders the
  /// localized `decryptFailed` text instead of the raw (empty) content.
  Future<void> _persistFailedDecrypt(MessageEnvelope env) async {
    await _dao.insertMessage(MessagesCompanion.insert(
      id: env.id, groupId: env.gid, senderId: '',
      content: '', type: 'text', timestamp: env.ts,
      hopCount: Value(env.hop), to: Value(env.to),
      decryptFailed: const Value(true),
    ));
  }

  bool _dedup(String id) {
    final now = DateTime.now();
    _seen.removeWhere((_, t) => now.difference(t).inSeconds >
        AppConstants.relayDeduplicationCacheSeconds);
    if (_seen.containsKey(id)) return false;
    _seen[id] = now;
    return true;
  }

  void dispose() => _sub?.cancel();
}
