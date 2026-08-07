import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Pure-Dart crypto helpers: X25519 key agreement, AES-GCM seal/open,
/// HKDF pairwise derivation, and a 6-digit Short Authentication String.
class CryptoService {
  final X25519 _x25519 = X25519();
  final AesGcm _aes = AesGcm.with256bits();

  Future<SimpleKeyPair> generateKeyPair() => _x25519.newKeyPair();

  /// 32-byte shared secret derived from an X25519 agreement + HKDF-SHA256.
  Future<Uint8List> pairwiseKeyBytes(
      SimpleKeyPair mine, SimplePublicKey theirs) async {
    final shared =
        await _x25519.sharedSecretKey(keyPair: mine, remotePublicKey: theirs);
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final derived = await hkdf.deriveKey(
        secretKey: shared, info: utf8.encode('nearbuddy-pairwise-v2'));
    return Uint8List.fromList(await derived.extractBytes());
  }

  Future<SecretBox> seal(String plaintext, SecretKey key) =>
      _aes.encrypt(utf8.encode(plaintext), secretKey: key, nonce: _aes.newNonce());

  Future<String> open(SecretBox box, SecretKey key) async =>
      utf8.decode(await _aes.decrypt(box, secretKey: key));

  /// 6-digit SAS: both peers display the same value; user compares out-of-band.
  Future<String> sas(SimpleKeyPair mine, SimplePublicKey theirs) async {
    final shared =
        await _x25519.sharedSecretKey(keyPair: mine, remotePublicKey: theirs);
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 8);
    final derived = await hkdf.deriveKey(
        secretKey: shared, info: utf8.encode('nearbuddy-sas-v2'));
    final bytes = await derived.extractBytes();
    var num = 0;
    for (final b in bytes) {
      num = (num * 256 + b) % 1000000;
    }
    return num.toString().padLeft(6, '0');
  }
}
