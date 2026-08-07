/// Control messages exchanged between directly-connected peers only.
/// They are NEVER relayed by intermediate nodes.
class KeyHello {
  final String pubKey;   // base64 X25519 public key
  final String nickname;
  final String? pin;     // group PIN, if the group uses one
  const KeyHello({required this.pubKey, required this.nickname, this.pin});

  Map<String, dynamic> toJson() => {
    't': 'hello', 'pub': pubKey, 'nick': nickname, if (pin != null) 'pin': pin,
  };
  factory KeyHello.fromJson(Map<String, dynamic> j) => KeyHello(
    pubKey: j['pub'] as String,
    nickname: j['nick'] as String,
    pin: j['pin'] as String?,
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
