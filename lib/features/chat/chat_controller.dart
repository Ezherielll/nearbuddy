import 'dart:async';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/crypto/crypto_service.dart';
import '../../core/crypto/identity_providers.dart';
import '../../core/utils/uuid_generator.dart';
import '../../data/database/app_database.dart';
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

class ChatController {
  final Ref _ref;
  final _seen = <String, DateTime>{};
  StreamSubscription? _sub;

  ChatController(this._ref) {
    _listenToIncoming();
    Future.microtask(deleteOldMessages);
  }

  MessagesDao get _dao => _ref.read(messagesDaoProvider);
  SessionsDao get _sessionsDao => _ref.read(sessionsDaoProvider);
  PeerDiscoveryService get _peer => _ref.read(peerDiscoveryServiceProvider);
  AppPreferences get _prefs => _ref.read(appPreferencesProvider);
  KeyExchangeService get _kx => _ref.read(keyExchangeServiceProvider);
  CryptoService get _crypto => _ref.read(cryptoServiceProvider);
  String? get _gid => _ref.read(currentGroupProvider)?.id;

  Stream<List<MessageRow>> watchMessages(String groupId) =>
      _dao.watchMessages(groupId);

  Future<void> _listenToIncoming() async {
    _sub = _peer.onPayloadReceived.listen((e) async {
      try {
        final j = jsonDecode(e.payload) as Map<String, dynamic>;
        if (!j.containsKey('v')) return;   // control — GroupController handles
        final env = MessageEnvelope.fromWireJson(j);
        if (env.gid != _gid) return;
        if (!_dedup(env.id)) return;

        // Relay decision — BEFORE decryption (relays never need the key)
        final age = DateTime.now().difference(env.ts).inSeconds;
        if (env.hop < AppConstants.maxHops && age < AppConstants.relayTtlSeconds) {
          await _peer.sendToAll(
              jsonEncode(env.copyWith(hop: env.hop + 1).toWireJson()));
        }

        // Decrypt only if addressed to us (group) or to our device (DM)
        final myId = await _ref.read(myDeviceIdProvider.future);
        if (env.kind == 'dm' && env.to != myId) return;
        final key = await _decryptionKey(env);
        if (key == null) return;   // session/key missing — cannot decrypt
        final plain = await _crypto.open(
            SecretBox.fromConcatenation(
                [...env.nonce, ...env.ciphertext],
                nonceLength: 12, macLength: 16),
            key);
        final msg = Message.fromPayloadJson(jsonDecode(plain));
        await _persist(env, msg);
      } catch (_) {}
    });
  }

  Future<SecretKey?> _decryptionKey(MessageEnvelope env) async {
    if (env.kind == 'g') {
      final bytes = _kx.groupKeyFor(env.gid);
      return bytes == null ? null : SecretKeyData(bytes);
    }
    final session = await _sessionsDao.sessionById(env.gid);
    if (session == null) return null;
    try {
      return SecretKeyData(await _kx.pairwiseKeyFor(session.peerDeviceId));
    } on StateError {
      return null;
    }
  }

  Future<void> sendTextMessage(String content) async {
    final gid = _gid;
    if (gid == null) return;
    final keyBytes = _kx.groupKeyFor(gid);
    if (keyBytes == null) return;
    final msg = Message(
      senderId: _prefs.nickname ?? 'Unknown', content: content,
      type: MessageType.text, timestamp: DateTime.now(),
    );
    final box = await _crypto.seal(jsonEncode(msg.toPayloadJson()), SecretKeyData(keyBytes));
    final env = MessageEnvelope(
      id: UuidGenerator.generate(), gid: gid, hop: 0, max: AppConstants.maxHops,
      ts: DateTime.now(), kind: 'g',
      nonce: Uint8List.fromList(box.nonce),
      ciphertext: Uint8List.fromList([...box.cipherText, ...box.mac.bytes]),
    );
    await _persist(env, msg);
    _dedup(env.id);
    await _peer.sendToAll(jsonEncode(env.toWireJson()));
  }

  Future<void> sendDm(String sessionId, String peerDeviceId, String content) async {
    final msg = Message(
      senderId: _prefs.nickname ?? 'Unknown', content: content,
      type: MessageType.text, timestamp: DateTime.now(),
    );
    final key = SecretKeyData(await _kx.pairwiseKeyFor(peerDeviceId));
    final box = await _crypto.seal(jsonEncode(msg.toPayloadJson()), key);
    final env = MessageEnvelope(
      id: UuidGenerator.generate(), gid: sessionId, to: peerDeviceId,
      hop: 0, max: AppConstants.maxHops, ts: DateTime.now(), kind: 'dm',
      nonce: Uint8List.fromList(box.nonce),
      ciphertext: Uint8List.fromList([...box.cipherText, ...box.mac.bytes]),
    );
    await _persist(env, msg);
    _dedup(env.id);
    await _peer.sendToAll(jsonEncode(env.toWireJson()));
  }

  Future<void> _persist(MessageEnvelope env, Message msg) =>
      _dao.insertMessage(MessagesCompanion.insert(
        id: env.id, groupId: env.gid, senderId: msg.senderId,
        content: msg.content, type: msg.type.name, timestamp: msg.timestamp,
        hopCount: Value(env.hop), to: Value(env.to),
        latitude: Value(msg.latitude), longitude: Value(msg.longitude),
        locationAccuracy: Value(msg.locationAccuracy),
      ));

  bool _dedup(String id) {
    final now = DateTime.now();
    _seen.removeWhere((_, t) => now.difference(t).inSeconds >
        AppConstants.relayDeduplicationCacheSeconds);
    if (_seen.containsKey(id)) return false;
    _seen[id] = now;
    return true;
  }

  Future<void> deleteOldMessages() => _dao.deleteOlderThan(
      DateTime.now().subtract(const Duration(days: AppConstants.messageRetentionDays)));

  void dispose() => _sub?.cancel();
}
