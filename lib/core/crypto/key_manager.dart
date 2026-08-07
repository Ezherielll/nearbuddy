import 'dart:convert';
import 'package:cryptography/cryptography.dart';

/// Minimal interface so KeyManager is testable without the plugin.
abstract class KeyValueStore {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
}

/// Persists the device identity keypair seed (base64) in secure storage.
/// deviceId is a stable, key-derived identifier (16 hex chars).
class KeyManager {
  static const _kIdentityPriv = 'identity_priv_seed_b64';
  final KeyValueStore _storage;
  KeyManager(this._storage);

  Future<SimpleKeyPair> ensureIdentityKey() async {
    final existing = await _storage.read(key: _kIdentityPriv);
    if (existing != null) {
      return X25519().newKeyPairFromSeed(base64Decode(existing));
    }
    final keyPair = await X25519().newKeyPair();
    final seed = await keyPair.extractPrivateKeyBytes();
    await _storage.write(key: _kIdentityPriv, value: base64Encode(seed));
    return keyPair;
  }

  /// Stable identifier derived from a public key (first 16 hex of sha256).
  /// Used to identify REMOTE peers from their hello pubkey.
  static Future<String> deviceIdFromPubKey(List<int> pubBytes) async {
    final digest = await Sha256().hash(pubBytes);
    return digest.bytes
        .take(8)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Future<String> deviceId() async {
    final keyPair = await ensureIdentityKey();
    final pub = await keyPair.extractPublicKey();
    return deviceIdFromPubKey(pub.bytes);
  }
}
