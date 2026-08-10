import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearbuddy/core/crypto/crypto_service.dart';
import 'package:nearbuddy/core/crypto/identity_providers.dart';
import 'package:nearbuddy/core/crypto/key_manager.dart';
import 'package:nearbuddy/data/database/app_database.dart';
import 'package:nearbuddy/data/preferences/app_preferences.dart';
import 'package:nearbuddy/domain/models/group_session.dart';
import 'package:nearbuddy/domain/models/message.dart';
import 'package:nearbuddy/domain/models/message_envelope.dart';
import 'package:nearbuddy/domain/services/key_exchange_service.dart';
import 'package:nearbuddy/domain/services/peer_discovery_service.dart';
import 'package:nearbuddy/features/chat/chat_controller.dart';
import 'package:nearbuddy/features/group/group_controller.dart';
import 'package:nearbuddy/infrastructure/nearby/nearby_connections_service.dart';
import 'package:nearbuddy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

final crypto = CryptoService();

void main() {

  test('C1: DM from a known member is received, session auto-created, ack + relay sent', () async {
    final env = await _harness((h) async {
      // sender is a known device: its pubkey sits in the members table
      await _registerMember(h, 'sender-dev', 'Nadia');

      // sender seals a DM addressed to ME under the pairwise key
      final envelope = await _sealDm(h, senderId: 'Nadia', to: h.myDeviceId,
          gid: 'sess-sender', content: 'halo rahasia', id: 'dm-1');
      h.peer.emit(jsonEncode(envelope.toWireJson()));
      await _settle();

      // 1) the message is persisted under the sender's session id
      final rows = await h.container.read(messagesDaoProvider).watchMessages('sess-sender').first;
      expect(rows, hasLength(1));
      expect(rows.single.content, 'halo rahasia');
      expect(rows.single.senderId, 'Nadia');
      // 2) a session for the sender was auto-created (C1)
      final session = await h.db.sessionsDao.sessionForPeer('sender-dev');
      expect(session, isNotNull);
      expect(session!.id, 'sess-sender');
      expect(session.peerNickname, 'Nadia');
      // 3) the DM was relayed (hop 0 -> hop 1)
      final relayed = h.peer.allSent
          .where((s) => s.contains('"v":2'))
          .toList();
      expect(relayed, hasLength(1));
      expect(jsonDecode(relayed.single), isA<Map>());
      final relayedEnv = MessageEnvelope.fromWireJson(
          jsonDecode(relayed.single) as Map<String, dynamic>);
      expect(relayedEnv.hop, 1);
      expect(relayedEnv.id, 'dm-1');
      // 4) a delivery receipt (ack) was flooded to the sender
      final ack = h.peer.allSent
          .where((s) => s.contains('"t":"ack"'))
          .toList();
      expect(ack, hasLength(1));
      expect(ack.single, contains('"id":"dm-1"'));
    });
    await env.dispose();
  });

  test('C1: DM addressed to another device is relayed but never persisted/acked', () async {
    final env = await _harness((h) async {
      await _registerMember(h, 'sender-dev', 'Nadia');
      final envelope = await _sealDm(h, senderId: 'Nadia', to: 'someone-else',
          gid: 'sess-sender', content: 'untuk orang lain', id: 'dm-2');
      h.peer.emit(jsonEncode(envelope.toWireJson()));
      await _settle();

      expect(await h.container.read(messagesDaoProvider).watchMessages('sess-sender').first, isEmpty);
      expect(await h.db.sessionsDao.sessionForPeer('sender-dev'), isNull);
      // relayed, but no ack
      expect(h.peer.allSent.where((s) => s.contains('"t":"ack"')), isEmpty);
      expect(h.peer.allSent.where((s) => s.contains('"v":2')), hasLength(1));
    });
    await env.dispose();
  });

  test('C1: DM from an unknown device (no pubkey on file) is dropped without crash', () async {
    final env = await _harness((h) async {
      // h.sender was never registered as a member — no pubkey to try
      final envelope = await _sealDm(h, senderId: 'Ghost', to: h.myDeviceId,
          gid: 'sess-ghost', content: 'siapakah kamu?', id: 'dm-3');
      h.peer.emit(jsonEncode(envelope.toWireJson()));
      await _settle();

      expect(await h.container.read(messagesDaoProvider).watchMessages('sess-ghost').first, isEmpty);
      // no session row was created for the actual sender identity
      final ghostId = await KeyManager.deviceIdFromPubKey(
          (await h.sender.extractPublicKey()).bytes);
      expect(await h.db.sessionsDao.sessionForPeer(ghostId), isNull);
      expect(h.peer.allSent.where((s) => s.contains('"t":"ack"')), isEmpty);
    });
    await env.dispose();
  });

  test('C1: group envelope for the current group is decrypted with the group key', () async {
    final env = await _harness((h) async {
      final groupKey = await h.kx.generateGroupKey('g1');
      final box = await crypto.seal(jsonEncode(Message(
        senderId: 'Bimo', content: 'pesan grup',
        type: MessageType.text, timestamp: DateTime.now(),
      ).toPayloadJson()), SecretKeyData(groupKey));
      final envelope = MessageEnvelope(
        id: 'm-1', gid: 'g1', hop: 0, max: 3, ts: DateTime.now(), kind: 'g',
        nonce: Uint8List.fromList(box.nonce),
        ciphertext: Uint8List.fromList([...box.cipherText, ...box.mac.bytes]),
      );
      h.peer.emit(jsonEncode(envelope.toWireJson()));
      await _settle();

      final rows = await h.container.read(messagesDaoProvider).watchMessages('g1').first;
      expect(rows, hasLength(1));
      expect(rows.single.content, 'pesan grup');
    });
    await env.dispose();
  });

  test('C1: relay of a stale or hop-exhausted envelope is skipped', () async {
    final env = await _harness((h) async {
      final groupKey = await h.kx.generateGroupKey('g1');
      final box = await crypto.seal(jsonEncode(Message(
        senderId: 'Bimo', content: 'stale',
        type: MessageType.text, timestamp: DateTime.now(),
      ).toPayloadJson()), SecretKeyData(groupKey));

      final old = MessageEnvelope(
        id: 'm-old', gid: 'g1', hop: 0, max: 3,
        ts: DateTime.now().subtract(const Duration(seconds: 30)),
        kind: 'g', nonce: Uint8List.fromList(box.nonce),
        ciphertext: Uint8List.fromList([...box.cipherText, ...box.mac.bytes]),
      );
      h.peer.emit(jsonEncode(old.toWireJson()));
      await _settle();
      expect(h.peer.allSent.where((s) => s.contains('"v":2')), isEmpty);

      final exhausted = MessageEnvelope(
        id: 'm-max', gid: 'g1', hop: 3, max: 3, ts: DateTime.now(),
        kind: 'g', nonce: Uint8List.fromList(box.nonce),
        ciphertext: Uint8List.fromList([...box.cipherText, ...box.mac.bytes]),
      );
      h.peer.emit(jsonEncode(exhausted.toWireJson()));
      await _settle();
      expect(h.peer.allSent.where((s) => s.contains('"v":2')), isEmpty);
    });
    await env.dispose();
  });
}

Future<void> _settle() async {
  await Future<void>.delayed(const Duration(milliseconds: 100));
  await pumpEventQueue();
}

/// Registers [h]'s sender keypair as a known member (pubkey on file).
Future<void> _registerMember(_Harness h, String deviceId, String nickname) async {
  final pub = await h.sender.extractPublicKey();
  await h.db.groupsDao.upsertMember(MembersCompanion.insert(
    deviceId: deviceId, groupId: 'g1', nickname: nickname,
    lastSeen: DateTime.now(),
  ));
  await h.db.groupsDao.setMemberPublicKey(deviceId, 'g1', base64Encode(pub.bytes));
}

/// Seals a DM as [h]'s sender under the pairwise key shared with ME.
Future<MessageEnvelope> _sealDm(_Harness h,
    {required String senderId, required String to, required String gid,
    required String content, required String id}) async {
  final myPub = await (await h.keyManager.ensureIdentityKey()).extractPublicKey();
  final pairwise = await crypto.pairwiseKeyBytes(h.sender, myPub);
  final box = await crypto.seal(jsonEncode(Message(
    senderId: senderId, content: content,
    type: MessageType.text, timestamp: DateTime.now(),
  ).toPayloadJson()), SecretKeyData(pairwise));
  return MessageEnvelope(
    id: id, gid: gid, to: to, hop: 0, max: 3, ts: DateTime.now(), kind: 'dm',
    nonce: Uint8List.fromList(box.nonce),
    ciphertext: Uint8List.fromList([...box.cipherText, ...box.mac.bytes]),
  );
}

class _Harness {
  final AppDatabase db;
  final _FakePeer peer;
  final KeyManager keyManager;
  final KeyExchangeService kx;
  final ProviderContainer container;
  final SimpleKeyPair sender;
  final String myDeviceId;

  _Harness(this.db, this.peer, this.keyManager, this.kx, this.container,
      this.sender, this.myDeviceId);

  Future<void> dispose() async {
    container.dispose();
    await db.close();
  }
}

Future<_Harness> _harness(
    Future<void> Function(_Harness h) body) async {
  SharedPreferences.setMockInitialValues({'nickname': 'Me'});
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final crypto = CryptoService();
  final peer = _FakePeer();

  // my identity: fixed seed so pubkey/deviceId are deterministic in-test
  final myPair = await crypto.generateKeyPair();
  final mySeed = await myPair.extractPrivateKeyBytes();
  final keyManager = KeyManager(
      _MemoryStore({'identity_priv_seed_b64': base64Encode(mySeed)}));

  final kx = KeyExchangeService(crypto, keyManager, db.groupsDao, peer);
  final prefs = AppPreferences(await SharedPreferences.getInstance());

  final container = ProviderContainer(overrides: [
    peerDiscoveryServiceProvider.overrideWithValue(peer),
    cryptoServiceProvider.overrideWithValue(crypto),
    keyManagerProvider.overrideWithValue(keyManager),
    appDatabaseProvider.overrideWithValue(db),
    appPreferencesProvider.overrideWithValue(prefs),
    keyExchangeServiceProvider.overrideWithValue(kx),
  ]);

  // the group chat path needs an active group
  container.read(currentGroupProvider.notifier).state = GroupSession(
      id: 'g1', name: 'G1', createdAt: DateTime.now());

  // instantiate the controller (starts the payload subscription)
  container.read(chatControllerProvider);

  final myDeviceId = await container.read(myDeviceIdProvider.future);
  final sender = await crypto.generateKeyPair();

  final h = _Harness(db, peer, keyManager, kx, container, sender, myDeviceId);
  await body(h);
  return h;
}

class _MemoryStore implements KeyValueStore {
  final Map<String, String> _m;
  _MemoryStore(this._m);
  @override
  Future<String?> read({required String key}) async => _m[key];
  @override
  Future<void> write({required String key, required String value}) async =>
      _m[key] = value;
}

class _FakePeer implements PeerDiscoveryService {
  final _payloadCtrl = StreamController<({String fromEndpointId, String payload})>.broadcast();
  final allSent = <String>[];

  void emit(String payload) =>
      _payloadCtrl.add((fromEndpointId: 'ep-1', payload: payload));

  @override
  Stream<({String fromEndpointId, String payload})> get onPayloadReceived =>
      _payloadCtrl.stream;

  @override
  Future<Set<String>> sendToAll(String jsonPayload) async {
    allSent.add(jsonPayload);
    return const {};
  }

  @override
  Future<void> sendTo(String endpointId, String jsonPayload) async {}

  @override
  Future<void> disconnectPeer(String endpointId) async {}

  @override
  Future<void> startScan() async {}

  @override
  Future<void> stopScan() async {}

  @override
  Stream<({String endpointId, String nickname})> get onDeviceFound =>
      const Stream.empty();

  @override
  Stream<String> get onDeviceLost => const Stream.empty();

  @override
  Future<void> startSession(
      {required String groupId, required String nickname, String? pin}) async {}

  @override
  Future<void> stopSession() async {}

  @override
  Stream<({String endpointId, String nickname})> get onPeerConnected =>
      const Stream.empty();

  @override
  Stream<String> get onPeerDisconnected => const Stream.empty();

  @override
  Stream<Set<String>> get connectedPeersStream => const Stream.empty();

  @override
  Set<String> get connectedPeers => const {};
}
