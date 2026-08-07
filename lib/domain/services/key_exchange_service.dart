import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/crypto/crypto_service.dart';
import '../../core/crypto/identity_providers.dart';
import '../../core/crypto/key_manager.dart';
import '../../data/database/app_database.dart';
import '../../data/database/daos/groups_dao.dart';
import '../../infrastructure/nearby/nearby_connections_service.dart';
import '../models/key_payloads.dart';
import '../services/peer_discovery_service.dart';

final keyExchangeServiceProvider = Provider<KeyExchangeService>((ref) =>
    KeyExchangeService(
      ref.watch(cryptoServiceProvider),
      ref.watch(keyManagerProvider),
      ref.watch(groupsDaoProvider),
      ref.watch(peerDiscoveryServiceProvider),
    ));

/// Orchestrates the E2EE join handshake over a direct connection:
/// hello (pubkey+pin) → SAS display/verify → (key holder) encrypted group key.
class KeyExchangeService {
  final CryptoService _crypto;
  final KeyManager _keys;
  final GroupsDao _groupsDao;
  final PeerDiscoveryService _peer;

  final _groupKeys = <String, Uint8List>{};
  final _endpointPubKeys = <String, SimplePublicKey>{};   // endpointId → pubkey
  final _sasChallengeCtrl = StreamController<String>.broadcast();
  final _peerVerifiedCtrl = StreamController<String>.broadcast();
  String? _pendingEndpoint;

  KeyExchangeService(this._crypto, this._keys, this._groupsDao, this._peer);

  /// SAS to display for the active join; UI subscribes and calls [confirmSas].
  Stream<String> get onSasChallenge => _sasChallengeCtrl.stream;

  /// Fires with the endpointId once that peer confirmed the SAS match.
  /// This is the trigger for delivering the group key (Task 11 wiring).
  Stream<String> get onPeerVerified => _peerVerifiedCtrl.stream;

  /// Sends our identity to a freshly-connected peer (Task 11 calls this on
  /// onPeerConnected). PIN rides in the hello only if the group uses one.
  Future<void> sendHello(String endpointId,
      {required String nickname, String? pin}) async {
    final pub = await (await _keys.ensureIdentityKey()).extractPublicKey();
    final hello = KeyHello(
      pubKey: base64Encode(pub.bytes),
      nickname: nickname,
      pin: pin,
    );
    await _peer.sendTo(endpointId, jsonEncode(hello.toJson()));
  }

  /// Local user's verdict on the SAS: sends verify_ok / verify_fail to the
  /// peer whose hello was last received. Mismatch aborts the session.
  Future<void> confirmSas(bool match) async {
    final endpoint = _pendingEndpoint;
    if (endpoint == null) return;
    await _peer.sendTo(
        endpoint, jsonEncode({'t': match ? 'verify_ok' : 'verify_fail'}));
    if (!match) {
      _endpointPubKeys.remove(endpoint);
      _pendingEndpoint = null;
    }
  }

  Future<Uint8List> generateGroupKey(String groupId) async {
    final k = await _crypto.generateKeyPair();
    final bytes = Uint8List.fromList(await k.extractPrivateKeyBytes());
    _groupKeys[groupId] = bytes;
    return bytes;
  }

  Uint8List? groupKeyFor(String groupId) => _groupKeys[groupId];

  /// Delivery side of the group key. Call ONLY after the endpoint's
  /// `verify_ok` was received (SAS confirmed both ways) and, for PIN
  /// groups, the join PIN was validated (Task 11). No-op without a key.
  Future<void> sendGroupKeyTo(String endpointId, String groupId) async {
    final key = _groupKeys[groupId];
    final pub = _endpointPubKeys[endpointId];
    if (key == null || pub == null) return;
    final pairwise =
        await _crypto.pairwiseKeyBytes(await _keys.ensureIdentityKey(), pub);
    final box = await _crypto.seal(base64Encode(key), SecretKeyData(pairwise));
    final packed = base64Encode([...box.nonce, ...box.cipherText, ...box.mac.bytes]);
    await _peer.sendTo(endpointId,
        jsonEncode(KeyDelivery(gid: groupId, key: packed).toJson()));
  }

  /// Pairwise key for a DM peer, derived from their stored public key.
  /// Throws [StateError] when the peer's public key is unknown (group
  /// handshake incomplete) — caller shows the `dmKeyMissing` toast (T13).
  Future<Uint8List> pairwiseKeyFor(String peerDeviceId) async {
    final b64 = await _groupsDao.memberPublicKey(peerDeviceId);
    if (b64 == null) throw StateError('no public key for $peerDeviceId');
    final pub = SimplePublicKey(base64Decode(b64), type: KeyPairType.x25519);
    return _crypto.pairwiseKeyBytes(await _keys.ensureIdentityKey(), pub);
  }

  Future<void> handleIncomingControl(String fromEndpointId, String payload) async {
    final j = jsonDecode(payload) as Map<String, dynamic>;
    switch (j['t']) {
      case 'hello':
        final hello = KeyHello.fromJson(j);
        _endpointPubKeys[fromEndpointId] =
            SimplePublicKey(base64Decode(hello.pubKey), type: KeyPairType.x25519);
        _pendingEndpoint = fromEndpointId;
        final sas = await _crypto.sas(
            await _keys.ensureIdentityKey(), _endpointPubKeys[fromEndpointId]!);
        _sasChallengeCtrl.add(sas);
      case 'verify_ok':
        // peer confirmed the SAS — fire the trigger for group key delivery
        _peerVerifiedCtrl.add(fromEndpointId);
      case 'verify_fail':
        await _peer.stopSession();
      case 'key':
        final delivery = KeyDelivery.fromJson(j);
        final pub = _endpointPubKeys[fromEndpointId];
        if (pub == null) return;
        final pairwise =
            await _crypto.pairwiseKeyBytes(await _keys.ensureIdentityKey(), pub);
        final plain = await _crypto.open(
            SecretBox.fromConcatenation(base64Decode(delivery.key),
                nonceLength: 12, macLength: 16),
            SecretKeyData(pairwise));
        _groupKeys[delivery.gid] = Uint8List.fromList(base64Decode(plain));
    }
  }
}
