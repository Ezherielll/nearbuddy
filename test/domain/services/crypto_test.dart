import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearbuddy/core/crypto/crypto_service.dart';
import 'package:nearbuddy/core/crypto/key_manager.dart';

void main() {
  final crypto = CryptoService();

  test('AES-GCM seal/open roundtrip', () async {
    final key = SecretKeyData(List.generate(32, (i) => i));
    final box = await crypto.seal('halo rahasia', key);
    expect(await crypto.open(box, key), 'halo rahasia');
  });

  test('pairwise keys agree on both sides and differ from a third party', () async {
    final a = await crypto.generateKeyPair();
    final b = await crypto.generateKeyPair();
    final evil = await crypto.generateKeyPair();
    final aPub = await a.extractPublicKey();
    final bPub = await b.extractPublicKey();
    final evilPub = await evil.extractPublicKey();

    final kab = await crypto.pairwiseKeyBytes(a, bPub);
    final kba = await crypto.pairwiseKeyBytes(b, aPub);
    expect(kab, kba);
    final kae = await crypto.pairwiseKeyBytes(a, evilPub);
    expect(kab, isNot(equals(kae)));
  });

  test('SAS is symmetric and peer-dependent', () async {
    final a = await crypto.generateKeyPair();
    final b = await crypto.generateKeyPair();
    final aPub = await a.extractPublicKey();
    final bPub = await b.extractPublicKey();
    expect(await crypto.sas(a, bPub), await crypto.sas(b, aPub));
    expect(RegExp(r'^\d{6}$').hasMatch(await crypto.sas(a, bPub)), isTrue);
  });

  test('deviceId is stable, 16 hex chars', () async {
    final keyManager = KeyManager(FakeStorage());
    final id1 = await keyManager.deviceId();
    final id2 = await keyManager.deviceId();
    expect(id1, id2);
    expect(RegExp(r'^[0-9a-f]{16}$').hasMatch(id1), isTrue);
  });
}

class FakeStorage implements KeyValueStore {
  final _m = <String, String>{};
  @override
  Future<String?> read({required String key}) async => _m[key];
  @override
  Future<void> write({required String key, required String value}) async =>
      _m[key] = value;
}
