import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearbuddy/core/crypto/crypto_service.dart';
import 'package:nearbuddy/core/crypto/key_manager.dart';
import 'package:nearbuddy/data/database/app_database.dart';
import 'package:nearbuddy/domain/models/key_payloads.dart';
import 'package:nearbuddy/domain/services/key_exchange_service.dart';
import 'package:nearbuddy/domain/services/peer_discovery_service.dart';

void main() {
  final crypto = CryptoService();

  test('key payload codecs roundtrip', () {
    final hello = KeyHello(pubKey: base64Encode([1, 2, 3]), nickname: 'Bimo', pin: null);
    expect(KeyHello.fromJson(hello.toJson()).nickname, 'Bimo');
    final key = KeyDelivery(gid: 'g1', key: base64Encode(List.generate(32, (i) => i)));
    expect(base64Decode(KeyDelivery.fromJson(key.toJson()).key).length, 32);
  });

  test('group key is delivered encrypted and decrypts on the receiver', () async {
    final owner = await crypto.generateKeyPair();
    final member = await crypto.generateKeyPair();
    final ownerPub = await owner.extractPublicKey();
    final memberPub = await member.extractPublicKey();

    final groupKey = List.generate(32, (i) => i);
    // owner packs: nonce(12) || ciphertext || MAC under the pairwise key
    final pairwise = await crypto.pairwiseKeyBytes(owner, memberPub);
    final box = await crypto.seal(base64Encode(groupKey), SecretKeyData(pairwise));
    final packed = [...box.nonce, ...box.cipherText, ...box.mac.bytes];
    // member unpacks via fromConcatenation
    final pairwise2 = await crypto.pairwiseKeyBytes(member, ownerPub);
    final opened = await crypto.open(
        SecretBox.fromConcatenation(packed, nonceLength: 12, macLength: 16),
        SecretKeyData(pairwise2));
    expect(base64Decode(opened), groupKey);
  });

  test('SAS mismatch produces different strings per peer', () async {
    final a = await crypto.generateKeyPair();
    final b = await crypto.generateKeyPair();
    final c = await crypto.generateKeyPair();
    final aPub = await a.extractPublicKey();
    final bPub = await b.extractPublicKey();
    final cPub = await c.extractPublicKey();
    expect(await crypto.sas(a, bPub), await crypto.sas(b, aPub));
    expect(await crypto.sas(a, cPub), isNot(await crypto.sas(a, bPub)));
  });

  test('sendGroupKeyTo sends nothing without a key, and a decryptable key with one', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final owner = await crypto.generateKeyPair();
    final member = await crypto.generateKeyPair();
    final memberPub = await member.extractPublicKey();
    final memberPubB64 = base64Encode(memberPub.bytes);

    // peer's public key is stored during the group handshake (Task 11 wiring)
    await db.groupsDao.upsertMember(MembersCompanion.insert(
      deviceId: 'dev-peer', groupId: 'g1', nickname: 'Nadia',
      lastSeen: DateTime.now(),
    ));
    await db.groupsDao.setMemberPublicKey('dev-peer', 'g1', memberPubB64);

    final peer = _FakePeer();
    final ownerSeed = await owner.extractPrivateKeyBytes();
    final svc = KeyExchangeService(
      crypto,
      KeyManager(_MemoryStore({'identity_priv_seed_b64': base64Encode(ownerSeed)})),
      db.groupsDao,
      peer,
    );

    // the joining peer introduces itself first (populates the endpoint pubkey)
    await svc.handleIncomingControl('ep-1', jsonEncode(KeyHello(
      pubKey: memberPubB64, nickname: 'Nadia', pin: null,
    ).toJson()));
    await svc.confirmSas(true, endpointId: 'ep-1');   // local user confirms the SAS digits

    // no group key yet → no KEY payload is sent (verify_ok already went out)
    await svc.sendGroupKeyTo('ep-1', 'g1');
    expect(peer.sentTo('ep-1').where((s) => s.contains('"t":"key"')), isEmpty);

    // with a group key → payload decrypts to the group key on the member side
    final groupKey = await svc.generateGroupKey('g1');
    await svc.sendGroupKeyTo('ep-1', 'g1');
    final delivery = KeyDelivery.fromJson(jsonDecode(
        peer.sentTo('ep-1').singleWhere((s) => s.contains('"t":"key"'))));
    expect(delivery.gid, 'g1');
    final ownerPub = await owner.extractPublicKey();
    final pairwise = await crypto.pairwiseKeyBytes(member, ownerPub);
    final opened = await crypto.open(
        SecretBox.fromConcatenation(base64Decode(delivery.key), nonceLength: 12, macLength: 16),
        SecretKeyData(pairwise));
    expect(base64Decode(opened), groupKey);
  });

  test('handleIncomingControl: hello → SAS challenge → key received → verify_ok fires', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final owner = await crypto.generateKeyPair();
    final member = await crypto.generateKeyPair();
    final ownerPubB64 = base64Encode((await owner.extractPublicKey()).bytes);

    final peer = _FakePeer();
    final memberSeed = await member.extractPrivateKeyBytes();
    final svc = KeyExchangeService(
      crypto,
      KeyManager(_MemoryStore({'identity_priv_seed_b64': base64Encode(memberSeed)})),
      db.groupsDao,
      peer,
    );

    String? sasChallenge;
    final sub = svc.onSasChallenge.listen((c) => sasChallenge = c.sas);
    addTearDown(sub.cancel);

    // owner introduces itself
    await svc.handleIncomingControl('ep-owner', jsonEncode(KeyHello(
      pubKey: ownerPubB64, nickname: 'Bimo', pin: null,
    ).toJson()));
    await pumpEventQueue();
    expect(sasChallenge, matches(RegExp(r'^\d{6}$')));

    // local user confirms — only then is a key accepted
    await svc.confirmSas(true, endpointId: 'ep-owner');
    await pumpEventQueue();
    expect(peer.sentTo('ep-owner').single, contains('verify_ok'));

    // owner delivers the group key sealed under the pairwise key
    final groupKey = List.generate(32, (i) => i);
    final pairwise = await crypto.pairwiseKeyBytes(member, await owner.extractPublicKey());
    final box = await crypto.seal(base64Encode(groupKey), SecretKeyData(pairwise));
    await svc.handleIncomingControl('ep-owner', jsonEncode(KeyDelivery(
      gid: 'g1',
      key: base64Encode([...box.nonce, ...box.cipherText, ...box.mac.bytes]),
    ).toJson()));
    expect(svc.groupKeyFor('g1'), groupKey);

    // owner's verify_ok fires onPeerVerified with the endpoint id
    String? verified;
    final sub2 = svc.onPeerVerified.listen((e) => verified = e);
    addTearDown(sub2.cancel);
    await svc.handleIncomingControl('ep-owner', jsonEncode(const {'t': 'verify_ok'}));
    await pumpEventQueue();
    expect(verified, 'ep-owner');
  });

  test('C2: handshake state is per-endpoint — verdicts and keys never cross peers', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final owner = await crypto.generateKeyPair();
    final memberA = await crypto.generateKeyPair();
    final memberB = await crypto.generateKeyPair();
    final pubA = base64Encode((await memberA.extractPublicKey()).bytes);
    final pubB = base64Encode((await memberB.extractPublicKey()).bytes);

    final peer = _FakePeer();
    final ownerSeed = await owner.extractPrivateKeyBytes();
    final svc = KeyExchangeService(
      crypto,
      KeyManager(_MemoryStore({'identity_priv_seed_b64': base64Encode(ownerSeed)})),
      db.groupsDao,
      peer,
    );

    final challenges = <(String, String)>[];
    final sub = svc.onSasChallenge.listen((c) => challenges.add((c.endpointId, c.sas)));
    addTearDown(sub.cancel);

    // two joiners connect and say hello
    await svc.handleIncomingControl('ep-a', jsonEncode(KeyHello(
      pubKey: pubA, nickname: 'A', pin: null,
    ).toJson()));
    await svc.handleIncomingControl('ep-b', jsonEncode(KeyHello(
      pubKey: pubB, nickname: 'B', pin: null,
    ).toJson()));
    await pumpEventQueue();
    expect(challenges.map((c) => c.$1), containsAll(['ep-a', 'ep-b']));

    // user verifies ONLY ep-a; the verdict must go to ep-a, not ep-b
    await svc.confirmSas(true, endpointId: 'ep-a');
    expect(peer.sentTo('ep-a').single, contains('verify_ok'));
    expect(peer.sentTo('ep-b'), isEmpty);

    // group key must be delivered ONLY to the verified endpoint
    final groupKey = await svc.generateGroupKey('g1');
    await svc.sendGroupKeyTo('ep-a', 'g1');
    await svc.sendGroupKeyTo('ep-b', 'g1');
    expect(peer.sentTo('ep-a').where((s) => s.contains('"t":"key"')), hasLength(1));
    expect(peer.sentTo('ep-b').where((s) => s.contains('"t":"key"')), isEmpty);

    // ep-b must NOT be able to deliver a key either (its SAS is unconfirmed)
    final pairwiseB = await crypto.pairwiseKeyBytes(memberB, await owner.extractPublicKey());
    final boxB = await crypto.seal(base64Encode(groupKey), SecretKeyData(pairwiseB));
    await svc.handleIncomingControl('ep-b', jsonEncode(KeyDelivery(
      gid: 'g2',
      key: base64Encode([...boxB.nonce, ...boxB.cipherText, ...boxB.mac.bytes]),
    ).toJson()));
    expect(svc.groupKeyFor('g2'), isNull);

    // ...but ep-a (confirmed) can
    final pairwiseA = await crypto.pairwiseKeyBytes(memberA, await owner.extractPublicKey());
    final boxA = await crypto.seal(base64Encode(groupKey), SecretKeyData(pairwiseA));
    await svc.handleIncomingControl('ep-a', jsonEncode(KeyDelivery(
      gid: 'g2',
      key: base64Encode([...boxA.nonce, ...boxA.cipherText, ...boxA.mac.bytes]),
    ).toJson()));
    expect(svc.groupKeyFor('g2'), groupKey);
  });

  test('H2: receiving verify_fail rejects only that peer — the session stays up', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final owner = await crypto.generateKeyPair();
    final member = await crypto.generateKeyPair();
    final pub = base64Encode((await member.extractPublicKey()).bytes);
    final ownerSeed = await owner.extractPrivateKeyBytes();

    final peer = _FakePeer();
    final svc = KeyExchangeService(
      crypto,
      KeyManager(_MemoryStore({'identity_priv_seed_b64': base64Encode(ownerSeed)})),
      db.groupsDao,
      peer,
    );

    await svc.handleIncomingControl('ep-bad', jsonEncode(KeyHello(
      pubKey: pub, nickname: 'Bad', pin: null,
    ).toJson()));

    String? rejected;
    final sub = svc.onJoinRejected.listen((e) => rejected = e);
    addTearDown(sub.cancel);

    await svc.handleIncomingControl('ep-bad', jsonEncode(const {'t': 'verify_fail'}));
    await pumpEventQueue();
    expect(rejected, 'ep-bad');
    // the member's own session must NOT be torn down
    expect(peer.stopCalls, 0);
    // a key from that peer is now rejected (endpoint state was removed)
    final pairwise = await crypto.pairwiseKeyBytes(member, await owner.extractPublicKey());
    final box = await crypto.seal(base64Encode(List.generate(32, (i) => i)), SecretKeyData(pairwise));
    await svc.handleIncomingControl('ep-bad', jsonEncode(KeyDelivery(
      gid: 'g1',
      key: base64Encode([...box.nonce, ...box.cipherText, ...box.mac.bytes]),
    ).toJson()));
    expect(svc.groupKeyFor('g1'), isNull);
  });
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
  final _sent = <String, List<String>>{};
  int stopCalls = 0;
  List<String> sentTo(String endpointId) => _sent[endpointId] ?? const [];

  @override
  Future<void> sendTo(String endpointId, String jsonPayload) async {
    (_sent[endpointId] ??= []).add(jsonPayload);
  }

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
  Future<void> stopSession() async {
    stopCalls++;
  }

  @override
  Future<Set<String>> sendToAll(String jsonPayload) async => {};

  @override
  Stream<({String endpointId, String nickname})> get onPeerConnected =>
      const Stream.empty();
  @override
  Stream<String> get onPeerDisconnected => const Stream.empty();
  @override
  Stream<({String fromEndpointId, String payload})> get onPayloadReceived =>
      const Stream.empty();
  @override
  Stream<Set<String>> get connectedPeersStream => const Stream.empty();
  @override
  Set<String> get connectedPeers => const {};
}
