import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearbuddy/core/crypto/crypto_service.dart';
import 'package:nearbuddy/domain/models/message.dart';
import 'package:nearbuddy/domain/models/message_envelope.dart';

void main() {
  final crypto = CryptoService();

  test('envelope roundtrip preserves header fields', () {
    final e = MessageEnvelope(
      id: 'msg-1', gid: 'g1', to: null, hop: 0, max: 3,
      ts: DateTime.utc(2026, 8, 8, 10), kind: 'g',
      nonce: Uint8List.fromList(List.generate(12, (i) => i)),
      ciphertext: Uint8List.fromList(List.generate(16, (i) => i)),
    );
    final r = MessageEnvelope.fromWireJson(e.toWireJson());
    expect(r.id, 'msg-1'); expect(r.gid, 'g1'); expect(r.to, isNull);
    expect(r.hop, 0); expect(r.max, 3); expect(r.kind, 'g');
    expect(r.nonce, e.nonce); expect(r.ciphertext, e.ciphertext);
  });

  test('envelope carries DM recipient in header', () {
    final e = MessageEnvelope(
      id: 'dm-1', gid: 's1', to: 'device-peer-1', hop: 0, max: 3,
      ts: DateTime.now(), kind: 'dm',
      nonce: Uint8List.fromList(List.generate(12, (i) => i)),
      ciphertext: Uint8List.fromList(List.generate(16, (i) => i)),
    );
    final j = e.toWireJson();
    expect((j['h'] as Map)['to'], 'device-peer-1');
  });

  test('sealed payload decrypts to the original Message', () async {
    final key = SecretKeyData(List.generate(32, (i) => i));
    final msg = Message(
      senderId: 'Bimo', content: 'Halo rahasia', type: MessageType.text,
      timestamp: DateTime.utc(2026, 8, 8, 10),
    );
    final box = await crypto.seal(jsonEncode(msg.toPayloadJson()), key);
    final plain = await crypto.open(box, key);
    final restored = Message.fromPayloadJson(jsonDecode(plain));
    expect(restored.senderId, 'Bimo');
    expect(restored.content, 'Halo rahasia');
  });

  test('copyWith increments hop and preserves id', () {
    final e = MessageEnvelope(
      id: 'r', gid: 'g1', hop: 1, max: 3, ts: DateTime.now(), kind: 'g',
      nonce: Uint8List(0), ciphertext: Uint8List(0),
    );
    expect(e.copyWith(hop: 2).hop, 2);
    expect(e.copyWith(hop: 2).id, 'r');
  });
}
