import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearbuddy/core/crypto/crypto_service.dart';
import 'package:nearbuddy/core/crypto/identity_providers.dart';
import 'package:nearbuddy/core/crypto/key_manager.dart';
import 'package:nearbuddy/core/utils/permission_handler_service.dart';
import 'package:nearbuddy/data/database/app_database.dart';
import 'package:nearbuddy/data/preferences/app_preferences.dart';
import 'package:nearbuddy/domain/models/message_envelope.dart';
import 'package:nearbuddy/domain/services/key_exchange_service.dart';
import 'package:nearbuddy/domain/services/peer_discovery_service.dart';
import 'package:nearbuddy/features/chat/chat_controller.dart';
import 'package:nearbuddy/features/group/group_controller.dart';
import 'package:nearbuddy/infrastructure/nearby/nearby_connections_service.dart';
import 'package:nearbuddy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Task 16 automated coverage: an in-process mesh of N real production nodes
/// (GroupController / ChatController / KeyExchangeService / crypto / Drift)
/// with ONLY the radio transport faked ([_MeshPeer] links). Each scenario
/// exercises the full E2EE stack: hello → PIN → SAS → key delivery → chat /
/// relay / DM / ack, plus the rejoin-after-restart path.
void main() {
  test('T16-1: PIN join with two-way SAS delivers the key; chat A→B works', () async {
    final a = await _node('A', nickname: 'Bimo');
    final b = await _node('B', nickname: 'Nadia');
    addTearDown(() async {
      await a.dispose();
      await b.dispose();
    });

    final gid = await _createGroup(a, 'G1', pin: '1234');
    await _join(b, gid, pin: '1234');

    _autoConfirmSas(a);
    _autoConfirmSas(b);
    _meshConnect(a, b);
    await _settle();

    // SAS both ways → the member delivered the encrypted group key
    expect(b.kx.groupKeyFor(gid), isNotNull);
    expect(a.kx.groupKeyFor(gid), isNotNull);

    await a.chat.sendTextMessage('halo dunia');
    await _settle();
    final rows = await b.db.messagesDao.watchMessages(gid).first;
    expect(rows, hasLength(1));
    expect(rows.single.content, 'halo dunia');
    expect(rows.single.senderId, 'Bimo');
  });

  test('T16-2: wrong PIN rejects the join with r:pin; the member session stays intact', () async {
    final a = await _node('A', nickname: 'Bimo');
    final b = await _node('B', nickname: 'Nadia');
    addTearDown(() async {
      await a.dispose();
      await b.dispose();
    });

    final gid = await _createGroup(a, 'G1', pin: '1234');
    await _join(b, gid, pin: '9999'); // wrong PIN

    JoinRejection? got;
    final sub = b.kx.onJoinRejected.listen((e) => got = e);
    addTearDown(sub.cancel);
    _autoConfirmSas(a);
    _meshConnect(a, b);
    await _settle();

    expect(got, isNotNull);
    expect(got!.reason, 'pin');
    // the member's session and key are untouched (H6)
    expect(a.container.read(currentGroupProvider)?.id, gid);
    expect(a.kx.groupKeyFor(gid), isNotNull);
    // the joiner never received the key
    expect(b.kx.groupKeyFor(gid), isNull);
  });

  test('T16-3: SAS mismatch rejects only the joiner; the member session stays up (H2)', () async {
    final a = await _node('A', nickname: 'Bimo');
    final b = await _node('B', nickname: 'Nadia');
    addTearDown(() async {
      await a.dispose();
      await b.dispose();
    });

    final gid = await _createGroup(a, 'G1'); // no PIN → SAS raised directly
    await _join(b, gid);

    JoinRejection? got;
    final sub = b.kx.onJoinRejected.listen((e) => got = e);
    addTearDown(sub.cancel);
    // A's user says the digits do NOT match
    a.kx.onSasChallenge
        .listen((c) => a.kx.confirmSas(false, endpointId: c.endpointId));
    _meshConnect(a, b);
    await _settle();

    expect(got, isNotNull);
    expect(got!.reason, isNull); // SAS mismatch carries no reason
    // H2 end-to-end: the member keeps its session, key and group row
    expect(a.container.read(currentGroupProvider)?.id, gid);
    expect(a.kx.groupKeyFor(gid), isNotNull);
    expect(b.kx.groupKeyFor(gid), isNull);
  });

  test('T16-4: two-hop relay A→B→C stores on C (hop incremented); the relaying member stores too', () async {
    final a = await _node('A', nickname: 'Bimo');
    final b = await _node('B', nickname: 'Nadia');
    final c = await _node('C', nickname: 'Citra');
    addTearDown(() async {
      await a.dispose();
      await b.dispose();
      await c.dispose();
    });

    final gid = await _createGroup(a, 'G1');
    await _join(b, gid);
    await _join(c, gid);

    _autoConfirmSas(a);
    _autoConfirmSas(b);
    _autoConfirmSas(c);
    _meshConnect(a, b);
    _meshConnect(b, c);
    await _settle();
    expect(c.kx.groupKeyFor(gid), isNotNull);

    await a.chat.sendTextMessage('pesan dua hop');
    await _settle();

    // C received via B's relay (hop 0 → 1)
    final cRows = await c.db.messagesDao.watchMessages(gid).first;
    expect(cRows, hasLength(1));
    expect(cRows.single.content, 'pesan dua hop');

    // B — a member on the path — also stores the message (it has the key)
    final bRows = await b.db.messagesDao.watchMessages(gid).first;
    expect(bRows, hasLength(1));
    expect(bRows.single.content, 'pesan dua hop');

    // the envelope B forwarded to C carried hop=1
    final relayed = b.peer.allSent
        .where((s) => s.contains('"v":2'))
        .map((s) => MessageEnvelope.fromWireJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    expect(relayed, hasLength(1));
    expect(relayed.single.hop, 1);
  });

  test('T16-5: DM A→B with C in the mesh — C stores nothing, B acks with mac, A row → delivered', () async {
    final a = await _node('A', nickname: 'Bimo');
    final b = await _node('B', nickname: 'Nadia');
    final c = await _node('C', nickname: 'Citra');
    addTearDown(() async {
      await a.dispose();
      await b.dispose();
      await c.dispose();
    });

    final gid = await _createGroup(a, 'G1');
    await _join(b, gid);
    await _join(c, gid);

    _autoConfirmSas(a);
    _autoConfirmSas(b);
    _autoConfirmSas(c);
    _meshConnect(a, b);
    _meshConnect(a, c); // C is "around" — it sees the flooded DM
    await _settle();

    await a.db.sessionsDao.upsertSession(SessionsCompanion.insert(
      id: 'sess-ab', peerDeviceId: b.deviceId, peerNickname: 'Nadia',
      createdAt: DateTime.now(),
    ));
    await a.chat.sendDm('sess-ab', b.deviceId, 'dm rahasia');
    await _settle();

    // B (the real recipient) stored and decrypted it
    final bRows = await b.db.messagesDao.watchMessages('sess-ab').first;
    expect(bRows, hasLength(1));
    expect(bRows.single.content, 'dm rahasia');

    // C — an observer on the mesh — stored NOTHING and created no session
    expect(await c.db.messagesDao.watchMessages('sess-ab').first, isEmpty);
    expect(await c.db.sessionsDao.sessionForPeer(b.deviceId), isNull);

    // A's outgoing row flipped to delivered via B's mac-authenticated ack (H1)
    final aRows = await a.db.messagesDao.watchMessages('sess-ab').first;
    expect(aRows.single.status, 'delivered');
  });

  test('T16-6: restart loses the key (decryptFailed placeholder); same-device rejoin is accepted (H7 device-scoped gate) and chat resumes', () async {
    final a = await _node('A', nickname: 'Bimo');
    final b = await _node('B', nickname: 'Nadia');
    addTearDown(() async {
      await a.dispose();
      await b.dispose();
    });

    final gid = await _createGroup(a, 'G1');
    await _join(b, gid);
    _autoConfirmSas(a);
    _autoConfirmSas(b);
    _meshConnect(a, b);
    await _settle();
    expect(b.kx.groupKeyFor(gid), isNotNull);
    final bSeed = b.seedB64;

    // "restart": a fresh container with the SAME identity seed (same
    // deviceId, stable pubkey) — the in-memory group key is gone.
    final b2 = await _node('B2', seedB64: bSeed, nickname: 'Nadia');
    addTearDown(b2.dispose);
    expect(b2.deviceId, b.deviceId);
    await _join(b2, gid); // rejoin flow (wires the join gate + hello)

    // A message arriving BEFORE the rejoin handshake finishes cannot be
    // decrypted — H5 persists a visible placeholder instead of dropping it.
    _autoConfirmSas(a);
    _autoConfirmSas(b2);
    _meshConnect(a, b2);
    await a.chat.sendTextMessage('sebelum rejoin');
    await _settle();

    final early = await b2.db.messagesDao.watchMessages(gid).first;
    expect(early, hasLength(1));
    expect(early.single.decryptFailed, isTrue);

    // The join gate accepted B2: its own (stale, still-active) member row
    // must not count as "nickname taken" (device-scoped H7 gate).
    expect(b2.kx.groupKeyFor(gid), isNotNull);

    await a.chat.sendTextMessage('setelah rejoin');
    await _settle();
    final after = await b2.db.messagesDao.watchMessages(gid).first;
    expect(after, hasLength(2));
    expect(after.first.decryptFailed, isTrue);
    expect(after.last.decryptFailed, isFalse);
    expect(after.last.content, 'setelah rejoin');
  });

  test('T16-7: a DIFFERENT device reusing a taken nickname is rejected r:nick; the original member stays active', () async {
    final a = await _node('A', nickname: 'Bimo');
    final b = await _node('B', nickname: 'Nadia');
    final c = await _node('C', nickname: 'Nadia'); // same nickname, other device
    addTearDown(() async {
      await a.dispose();
      await b.dispose();
      await c.dispose();
    });

    final gid = await _createGroup(a, 'G1');
    await _join(b, gid);
    await _join(c, gid);
    _autoConfirmSas(a);
    _autoConfirmSas(b);
    _meshConnect(a, b);
    await _settle();
    expect(b.kx.groupKeyFor(gid), isNotNull);

    JoinRejection? got;
    final sub = c.kx.onJoinRejected.listen((e) => got = e);
    addTearDown(sub.cancel);
    _autoConfirmSas(a);
    _meshConnect(a, c);
    await _settle();

    // C rejected BEFORE any SAS dialog (H7) with reason 'nick'
    expect(got, isNotNull);
    expect(got!.reason, 'nick');
    expect(c.kx.groupKeyFor(gid), isNull);

    // B — the original member — is untouched and the group still works
    final members = await a.db.groupsDao.watchMembersInGroup(gid).first;
    final bRow = members.firstWhere((m) => m.deviceId == b.deviceId);
    expect(bRow.isActive, isTrue);
    expect(b.kx.groupKeyFor(gid), isNotNull);

    await a.chat.sendTextMessage('masih hidup');
    await _settle();
    expect(await b.db.messagesDao.watchMessages(gid).first, hasLength(1));
  });
}

Future<void> _settle() async {
  await Future<void>.delayed(const Duration(milliseconds: 100));
  await pumpEventQueue();
}

/// Auto-confirms every SAS challenge raised on [node] (the dialog UI is
/// bypassed — the dialog itself is covered by unit tests).
StreamSubscription<void> _autoConfirmSas(_MeshNode node) =>
    node.kx.onSasChallenge.listen((c) {
      node.kx.confirmSas(true, endpointId: c.endpointId);
    });

/// Owner creates the group (session + join gate + hello wiring).
Future<String> _createGroup(_MeshNode owner, String name, {String? pin}) async {
  final err = await owner.group.createGroup(name: name, pin: pin);
  expect(err, isNull, reason: 'createGroup failed: $err');
  return owner.container.read(currentGroupProvider)!.id;
}

/// [joiner] runs the join flow (adopts the session, wires its gate/hello).
Future<void> _join(_MeshNode joiner, String gid, {String? pin}) async {
  final err = await joiner.group.joinGroup(groupId: gid, groupName: 'G1', pin: pin);
  expect(err, isNull, reason: 'joinGroup failed: $err');
}

/// Links two nodes with ONE shared endpoint id: both sides fire
/// onPeerConnected with it, and payloads carry it in both directions —
/// replies always route back to the peer (state keying stays consistent).
void _meshConnect(_MeshNode a, _MeshNode b) {
  final ep = 'ep-${a.label}-${b.label}';
  a.peer._routes[ep] = b;
  b.peer._routes[ep] = a;
  a.peer._peers.add(ep);
  b.peer._peers.add(ep);
  a.peer._connCtrl.add((endpointId: ep, nickname: b.nickname));
  b.peer._connCtrl.add((endpointId: ep, nickname: a.nickname));
  a.peer._peersCtrl.add(Set.from(a.peer._peers));
  b.peer._peersCtrl.add(Set.from(b.peer._peers));
}

/// One node = one full production stack (controllers, KX, crypto, Drift) on
/// an isolated ProviderContainer, sharing only the faked radio.
class _MeshNode {
  final String label;
  final String nickname;
  final _MeshPeer peer;
  final KeyManager keyManager;
  final KeyExchangeService kx;
  final GroupController group;
  final ChatController chat;
  final AppDatabase db;
  final ProviderContainer container;
  final String deviceId;
  final String seedB64;

  _MeshNode({
    required this.label,
    required this.nickname,
    required this.peer,
    required this.keyManager,
    required this.kx,
    required this.group,
    required this.chat,
    required this.db,
    required this.container,
    required this.deviceId,
    required this.seedB64,
  });

  Future<void> dispose() async {
    container.dispose();
    await db.close();
  }
}

Future<_MeshNode> _node(String label, {String? seedB64, String? nickname}) async {
  final nick = nickname ?? label;
  SharedPreferences.setMockInitialValues({'nickname': nick});
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final crypto = CryptoService();
  final peer = _MeshPeer(label);
  final seed = seedB64 ??
      base64Encode(await (await crypto.generateKeyPair()).extractPrivateKeyBytes());
  final keyManager = KeyManager(_MemoryStore({'identity_priv_seed_b64': seed}));
  final kx = KeyExchangeService(crypto, keyManager, db.groupsDao, peer);
  final prefs = AppPreferences(await SharedPreferences.getInstance());

  final container = ProviderContainer(overrides: [
    peerDiscoveryServiceProvider.overrideWithValue(peer),
    cryptoServiceProvider.overrideWithValue(crypto),
    keyManagerProvider.overrideWithValue(keyManager),
    appDatabaseProvider.overrideWithValue(db),
    appPreferencesProvider.overrideWithValue(prefs),
    keyExchangeServiceProvider.overrideWithValue(kx),
    permissionHandlerServiceProvider.overrideWithValue(_FakePermissions()),
  ]);

  final node = _MeshNode(
    label: label,
    nickname: nick,
    peer: peer,
    keyManager: keyManager,
    kx: kx,
    group: container.read(groupControllerProvider),
    chat: container.read(chatControllerProvider),
    db: db,
    container: container,
    deviceId: '',
    seedB64: seed,
  );

  // deviceId is key-derived and async; compute it once after wiring.
  final pub = await (await keyManager.ensureIdentityKey()).extractPublicKey();
  final deviceId = await KeyManager.deviceIdFromPubKey(pub.bytes);
  return _MeshNode(
    label: label,
    nickname: nick,
    peer: peer,
    keyManager: keyManager,
    kx: kx,
    group: node.group,
    chat: node.chat,
    db: db,
    container: container,
    deviceId: deviceId,
    seedB64: seed,
  );
}

class _FakePermissions extends PermissionHandlerService {
  @override
  Future<bool> requestNearbyPermissions() async => true;
  @override
  Future<bool> requestLocationPermission() async => true;
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

/// Fake radio: `_routes` maps local endpoint ids to the peer node they lead
/// to. sendTo/sendToAll deliver into the target's onPayloadReceived — the
/// rest of the stack is real production code.
class _MeshPeer implements PeerDiscoveryService {
  final String label;
  
  final _routes = <String, _MeshNode>{};
  final _peers = <String>{};
  final allSent = <String>[];

  final _payloadCtrl =
      StreamController<({String fromEndpointId, String payload})>.broadcast();
  final _connCtrl =
      StreamController<({String endpointId, String nickname})>.broadcast();
  final _discCtrl = StreamController<String>.broadcast();
  final _peersCtrl = StreamController<Set<String>>.broadcast();

  _MeshPeer(this.label);

  void _deliver(String fromEndpointId, String payload) =>
      _payloadCtrl.add((fromEndpointId: fromEndpointId, payload: payload));

  @override
  Stream<({String fromEndpointId, String payload})> get onPayloadReceived =>
      _payloadCtrl.stream;

  @override
  Future<void> sendTo(String endpointId, String jsonPayload) async {
    allSent.add(jsonPayload);
    final target = _routes[endpointId];
    if (target != null) target.peer._deliver(endpointId, jsonPayload);
  }

  @override
  Future<Set<String>> sendToAll(String jsonPayload) async {
    allSent.add(jsonPayload);
    for (final e in _routes.entries) {
      e.value.peer._deliver(e.key, jsonPayload);
    }
    return Set.from(_routes.keys);
  }

  @override
  Future<void> disconnectPeer(String endpointId) async {
    final target = _routes.remove(endpointId);
    _peers.remove(endpointId);
    _peersCtrl.add(Set.from(_peers));
    _discCtrl.add(endpointId);
    // tear down the reverse side too so the peer observes the disconnect
    if (target != null) {
      target.peer._routes.remove(endpointId);
      target.peer._peers.remove(endpointId);
      target.peer._peersCtrl.add(Set.from(target.peer._peers));
      target.peer._discCtrl.add(endpointId);
    }
  }

  @override
  Stream<({String endpointId, String nickname})> get onPeerConnected =>
      _connCtrl.stream;

  @override
  Stream<String> get onPeerDisconnected => _discCtrl.stream;

  @override
  Stream<Set<String>> get connectedPeersStream => _peersCtrl.stream;

  @override
  Set<String> get connectedPeers => Set.from(_peers);

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
}
