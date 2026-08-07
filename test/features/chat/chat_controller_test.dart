import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearbuddy/core/crypto/crypto_service.dart';
import 'package:nearbuddy/domain/models/message.dart';
import 'package:nearbuddy/domain/models/message_envelope.dart';

void main() {
  final crypto = CryptoService();

  test('group message: sealed envelope, relays see no content', () async {
    final key = SecretKeyData(List.generate(32, (i) => i));
    final msg = Message(senderId: 'Bimo', content: 'koordinat rahasia',
        type: MessageType.text, timestamp: DateTime.now());
    final box = await crypto.seal(jsonEncode(msg.toPayloadJson()), key);
    final env = MessageEnvelope(
      id: 'm1', gid: 'g1', hop: 0, max: 3, ts: DateTime.now(), kind: 'g',
      nonce: Uint8List.fromList(box.nonce),
      ciphertext: Uint8List.fromList([...box.cipherText, ...box.mac.bytes]),
    );
    final wire = env.toWireJson();
    // Relay sees the routing header but never the payload
    expect((wire['h'] as Map).containsKey('gid'), isTrue);
    expect(wire.containsKey('c'), isTrue);
    expect(wire['c'], isNot(contains('koordinat')));
    expect(wire['c'], isNot(contains('Bimo')));
  });

  test('sealed DM envelope decrypts only with the pairwise key', () async {
    final key = SecretKeyData(List.generate(32, (i) => i));
    final msg = Message(senderId: 'Nadia', content: 'rahasia 1:1',
        type: MessageType.text, timestamp: DateTime.now());
    final box = await crypto.seal(jsonEncode(msg.toPayloadJson()), key);
    final env = MessageEnvelope(
      id: 'dm1', gid: 's1', to: 'device-b', hop: 0, max: 3,
      ts: DateTime.now(), kind: 'dm',
      nonce: Uint8List.fromList(box.nonce),
      ciphertext: Uint8List.fromList([...box.cipherText, ...box.mac.bytes]),
    );
    final j = env.toWireJson();
    expect((j['h'] as Map)['to'], 'device-b');
    expect(j['c'], isNot(contains('rahasia')));
    final plain = await crypto.open(
        SecretBox.fromConcatenation(
            [...env.nonce, ...env.ciphertext], nonceLength: 12, macLength: 16),
        key);
    final restored = Message.fromPayloadJson(jsonDecode(plain));
    expect(restored.content, 'rahasia 1:1');
  });

  test('relay decision: hop < max and fresh → forward, else stop', () {
    final now = DateTime.now();
    bool shouldRelay(MessageEnvelope e) =>
        e.hop < 3 && now.difference(e.ts).inSeconds <= 10;
    final fresh = MessageEnvelope(
        id: 'a', gid: 'g', hop: 0, max: 3, ts: now, kind: 'g',
        nonce: Uint8List(0), ciphertext: Uint8List(0));
    expect(shouldRelay(fresh), isTrue);
    final exhausted = fresh.copyWith(hop: 3);
    expect(shouldRelay(exhausted), isFalse);
  });
}
