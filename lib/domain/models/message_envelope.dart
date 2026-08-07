import 'dart:convert';
import 'dart:typed_data';

/// Cleartext routing header + encrypted payload.
/// Relays may read the header (dedup, TTL, group filter, DM target) but
/// never the ciphertext.
class MessageEnvelope {
  final String id;          // UUID — dedup
  final String gid;         // groupId (kind 'g') or sessionId (kind 'dm')
  final String? to;         // recipient deviceId for DMs; null = group broadcast
  final int hop;
  final int max;
  final DateTime ts;
  final String kind;        // 'g' | 'dm' — selects the decryption key
  final Uint8List nonce;    // AES-GCM nonce
  final Uint8List ciphertext; // ciphertext || MAC

  const MessageEnvelope({
    required this.id, required this.gid, this.to,
    required this.hop, required this.max, required this.ts,
    required this.kind, required this.nonce, required this.ciphertext,
  });

  Map<String, dynamic> toWireJson() => {
    'v': 2,
    'h': {
      'id': id, 'gid': gid,
      if (to != null) 'to': to,
      'hop': hop, 'max': max, 'ts': ts.millisecondsSinceEpoch, 'k': kind,
    },
    'n': base64Encode(nonce),
    'c': base64Encode(ciphertext),
  };

  factory MessageEnvelope.fromWireJson(Map<String, dynamic> j) {
    final h = j['h'] as Map<String, dynamic>;
    return MessageEnvelope(
      id: h['id'] as String,
      gid: h['gid'] as String,
      to: h['to'] as String?,
      hop: (h['hop'] as num).toInt(),
      max: (h['max'] as num).toInt(),
      ts: DateTime.fromMillisecondsSinceEpoch((h['ts'] as num).toInt()),
      kind: h['k'] as String? ?? 'g',
      nonce: base64Decode(j['n'] as String),
      ciphertext: base64Decode(j['c'] as String),
    );
  }

  MessageEnvelope copyWith({int? hop}) => MessageEnvelope(
    id: id, gid: gid, to: to, hop: hop ?? this.hop, max: max, ts: ts,
    kind: kind, nonce: nonce, ciphertext: ciphertext,
  );
}
