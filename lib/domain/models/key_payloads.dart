/// Control messages exchanged between directly-connected peers only.
/// They are NEVER relayed by intermediate nodes.
class KeyHello {
  final String pubKey;   // base64 X25519 public key
  final String nickname;
  // NOTE: no PIN here (H6) — the PIN never rides in cleartext; the member
  // challenges the joiner with pin_challenge and verifies H(pin‖nonce).
  const KeyHello({required this.pubKey, required this.nickname});

  Map<String, dynamic> toJson() => {
    't': 'hello', 'pub': pubKey, 'nick': nickname,
  };
  factory KeyHello.fromJson(Map<String, dynamic> j) => KeyHello(
    pubKey: j['pub'] as String,
    nickname: j['nick'] as String,
  );
}

class KeyDelivery {
  final String gid;   // the group this key belongs to
  final String key;   // base64( nonce(12) || ciphertext || MAC ) of the 32-byte group key
  const KeyDelivery({required this.gid, required this.key});

  Map<String, dynamic> toJson() => {'t': 'key', 'gid': gid, 'key': key};
  factory KeyDelivery.fromJson(Map<String, dynamic> j) =>
      KeyDelivery(gid: j['gid'] as String, key: j['key'] as String);
}

class KeyVerifyOk { const KeyVerifyOk(); }
class KeyVerifyFail { const KeyVerifyFail(); }
