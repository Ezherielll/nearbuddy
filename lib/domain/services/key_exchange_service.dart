import 'dart:async';
import 'dart:convert';
import 'dart:math';
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

final keyExchangeServiceProvider = Provider<KeyExchangeService>((ref) {
  final service = KeyExchangeService(
    ref.watch(cryptoServiceProvider),
    ref.watch(keyManagerProvider),
    ref.watch(groupsDaoProvider),
    ref.watch(peerDiscoveryServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// One SAS challenge: the digits to compare AND the endpoint they belong
/// to, so the user's verdict is always delivered to the right peer (C2).
class SasChallenge {
  final String endpointId;
  final String sas;
  const SasChallenge({required this.endpointId, required this.sas});
}

/// A join this device attempted was rejected by a member.
/// [reason]: 'pin' | 'nick' | 'full', or null when the member's user
/// rejected the SAS itself.
class JoinRejection {
  final String endpointId;
  final String? reason;
  const JoinRejection({required this.endpointId, this.reason});
}

/// Handshake state for ONE connected endpoint (C2): a joiner in a cluster
/// connects to several members at once, and each hello must not clobber
/// another's pubkey / SAS verdict. A peer is only trusted (gets / delivers
/// the group key) once ITS OWN endpoint's SAS was confirmed by the local user.
class _EndpointState {
  final SimplePublicKey pubKey;
  bool sasConfirmed = false;

  /// H6: nonce the MEMBER issued in pin_challenge; the SAS challenge for
  /// this endpoint is only raised after the joiner's pin_proof verifies.
  Uint8List? pinNonce;

  _EndpointState(this.pubKey);
}

/// Orchestrates the E2EE join handshake over a direct connection:
/// hello (pubkey) → pin challenge/proof when the group has one (H6) →
/// SAS display/verify → (key holder) encrypted group key delivery.
class KeyExchangeService {
  final CryptoService _crypto;
  final KeyManager _keys;
  final GroupsDao _groupsDao;
  final PeerDiscoveryService _peer;

  final _groupKeys = <String, Uint8List>{};
  final _sasChallengeCtrl = StreamController<SasChallenge>.broadcast();
  final _peerVerifiedCtrl = StreamController<String>.broadcast();
  final _joinRejectedCtrl = StreamController<JoinRejection>.broadcast();

  final _endpoints = <String, _EndpointState>{};
  StreamSubscription? _discSub;

  /// Join gate registered by GroupController (H7/M3/Task 11): returns a
  /// rejection reason ('nick' | 'full') or null to accept. Called with the
  /// peer's hello nickname BEFORE any pin/SAS challenge is raised; a reason
  /// rejects the join (verify_fail carries it) without showing a dialog.
  /// (PIN is NOT checked here — it travels via pin_challenge/pin_proof, H6.)
  Future<String?> Function(String nickname)? joinGate;

  /// H6: supplies the group PIN for this device — the stored/entered pin on
  /// both sides (member verifies proofs, joiner answers challenges). A null
  /// value means the group has no PIN (no challenge issued).
  String? Function()? pinProvider;

  KeyExchangeService(this._crypto, this._keys, this._groupsDao, this._peer) {
    // L3: drop handshake state for endpoints that disconnected.
    _discSub = _peer.onPeerDisconnected.listen(_endpoints.remove);
  }

  void dispose() => _discSub?.cancel();

  /// SAS challenges for the active joins; UI subscribes and calls
  /// [confirmSas] with the challenge's [SasChallenge.endpointId].
  Stream<SasChallenge> get onSasChallenge => _sasChallengeCtrl.stream;

    /// Fires with the endpointId once that peer confirmed the SAS match.
    /// This is the trigger for delivering the group key (Task 11 wiring).
    Stream<String> get onPeerVerified => _peerVerifiedCtrl.stream;

    /// Fires when a member rejected this device's join (wrong PIN / taken
    /// nickname / full group / SAS mismatch). UI shows the reason and aborts.
    Stream<JoinRejection> get onJoinRejected => _joinRejectedCtrl.stream;

  /// Sends our identity to a freshly-connected peer (Task 11 calls this on
  /// onPeerConnected). The PIN never rides in the hello (H6) — the member
  /// challenges us with pin_challenge when the group uses one.
  Future<void> sendHello(String endpointId, {required String nickname}) async {
    final pub = await (await _keys.ensureIdentityKey()).extractPublicKey();
    final hello = KeyHello(
      pubKey: base64Encode(pub.bytes),
      nickname: nickname,
    );
    await _peer.sendTo(endpointId, jsonEncode(hello.toJson()));
  }

  /// Local user's verdict on the SAS for a SPECIFIC endpoint (C2): the
  /// verdict goes to the peer whose digits the user actually compared.
  /// Mismatch rejects THAT endpoint only — verify_fail + disconnect — while
  /// the local group session (and every other member) stays up (H2).
  Future<void> confirmSas(bool match, {required String endpointId}) async {
    final state = _endpoints[endpointId];
    if (state == null) return;
    state.sasConfirmed = match;
    await _peer.sendTo(
        endpointId, jsonEncode({'t': match ? 'verify_ok' : 'verify_fail'}));
    if (!match) {
      _endpoints.remove(endpointId);
      await _peer.disconnectPeer(endpointId);
    }
  }

  Future<Uint8List> generateGroupKey(String groupId) async {
    final k = await _crypto.generateKeyPair();
    final bytes = Uint8List.fromList(await k.extractPrivateKeyBytes());
    _groupKeys[groupId] = bytes;
    return bytes;
  }

  Uint8List? groupKeyFor(String groupId) => _groupKeys[groupId];

  /// Delivery side of the group key. Call ONLY after THIS endpoint's
  /// `verify_ok` was received (SAS confirmed both ways) and, for PIN
  /// groups, the join PIN was validated (Task 11). No-op without a key
  /// or when that endpoint is not (or no longer) SAS-verified.
  Future<void> sendGroupKeyTo(String endpointId, String groupId) async {
    final key = _groupKeys[groupId];
    final state = _endpoints[endpointId];
    if (key == null || state == null || !state.sasConfirmed) return;
    final pairwise =
        await _crypto.pairwiseKeyBytes(await _keys.ensureIdentityKey(), state.pubKey);
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

  /// Raises the SAS challenge for an endpoint whose pubkey is known and
  /// (for PIN groups) whose pin_proof already verified (H6).
  Future<void> _raiseSas(String endpointId) async {
    final state = _endpoints[endpointId];
    if (state == null) return;
    final sas = await _crypto.sas(
        await _keys.ensureIdentityKey(), state.pubKey);
    _sasChallengeCtrl.add(SasChallenge(endpointId: endpointId, sas: sas));
  }

  /// H6: H(pin ‖ nonce) as hex — the PIN never travels in cleartext.
  Future<String> _pinProof(String pin, List<int> nonce) async {
    final digest = await Sha256()
        .hash([...utf8.encode(pin), ...nonce]);
    return digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Uint8List _randomNonce() {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(16, (_) => rng.nextInt(256)));
  }

  Future<void> handleIncomingControl(String fromEndpointId, String payload) async {
    final j = jsonDecode(payload) as Map<String, dynamic>;
    switch (j['t']) {
      case 'hello':
        final hello = KeyHello.fromJson(j);
        // join gate (nickname uniqueness, group size) before any challenge
        // is raised — a rejected join never reaches the dialogs (H7/M3)
        final reason = await joinGate?.call(hello.nickname);
        if (reason != null) {
          await _peer.sendTo(fromEndpointId, jsonEncode({
            't': 'verify_fail', if (reason.isNotEmpty) 'r': reason,
          }));
          await _peer.disconnectPeer(fromEndpointId);
          return;
        }
        final state = _EndpointState(
            SimplePublicKey(base64Decode(hello.pubKey), type: KeyPairType.x25519));
        _endpoints[fromEndpointId] = state;
        // H6: PIN groups challenge the joiner — no cleartext PIN on the wire.
        // The SAS challenge waits until the pin_proof verifies.
        final pin = pinProvider?.call();
        if (pin != null) {
          final nonce = _randomNonce();
          state.pinNonce = nonce;
          await _peer.sendTo(fromEndpointId, jsonEncode(
              {'t': 'pin_challenge', 'n': base64Encode(nonce)}));
        } else {
          await _raiseSas(fromEndpointId);
        }
      case 'pin_challenge':
        // joiner side: prove knowledge of the pin without sending it; an
        // empty proof (we don't have the pin) makes the member reject us
        // explicitly instead of the join silently timing out.
        final pin = pinProvider?.call();
        final nonceB64 = j['n'] as String?;
        if (nonceB64 == null) return;
        await _peer.sendTo(fromEndpointId, jsonEncode({
          't': 'pin_proof',
          'h': pin == null
              ? ''
              : await _pinProof(pin, base64Decode(nonceB64)),
        }));
      case 'pin_proof':
        // member side: verify the proof, then raise the SAS challenge
        final state = _endpoints[fromEndpointId];
        final nonce = state?.pinNonce;
        final pin = pinProvider?.call();
        if (state == null || nonce == null || pin == null) return;
        final expected = await _pinProof(pin, nonce);
        state.pinNonce = null;
        if (j['h'] != expected) {
          await _peer.sendTo(fromEndpointId, jsonEncode({
            't': 'verify_fail', 'r': 'pin',
          }));
          _endpoints.remove(fromEndpointId);
          await _peer.disconnectPeer(fromEndpointId);
          return;
        }
        await _raiseSas(fromEndpointId);
      case 'verify_ok':
        // peer confirmed the SAS — fire the trigger for group key delivery
        _peerVerifiedCtrl.add(fromEndpointId);
      case 'verify_fail':
        // 'r' is optional: the member's SAS mismatch carries no reason.
        _joinRejectedCtrl.add(JoinRejection(
            endpointId: fromEndpointId, reason: j['r'] as String?));
        // H2: reject ONLY this peer — never stopSession() here, the group
        // session belongs to every member.
        _endpoints.remove(fromEndpointId);
        await _peer.disconnectPeer(fromEndpointId);
      case 'key':
        // never accept keys from an endpoint whose SAS was not confirmed
        final state = _endpoints[fromEndpointId];
        if (state == null || !state.sasConfirmed) return;
        final delivery = KeyDelivery.fromJson(j);
        final pairwise =
            await _crypto.pairwiseKeyBytes(await _keys.ensureIdentityKey(), state.pubKey);
        final plain = await _crypto.open(
            SecretBox.fromConcatenation(base64Decode(delivery.key),
                nonceLength: 12, macLength: 16),
            SecretKeyData(pairwise));
        _groupKeys[delivery.gid] = Uint8List.fromList(base64Decode(plain));
    }
  }
}
