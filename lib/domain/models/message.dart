enum MessageType { text, location }

/// Encrypted payload — only the intended recipient can read this.
/// Routing fields (id/gid/to/hop/max/ts/kind) live in MessageEnvelope.
class Message {
  final String senderId;       // nickname (display label)
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final double? locationAccuracy;
  final List<String> deliveredTo;

  const Message({
    required this.senderId, required this.content, required this.type,
    required this.timestamp, this.latitude, this.longitude,
    this.locationAccuracy, this.deliveredTo = const [],
  });

  Map<String, dynamic> toPayloadJson() => {
    'sid': senderId, 'content': content, 'type': type.name,
    'ts': timestamp.millisecondsSinceEpoch, 'dlv': deliveredTo,
    if (latitude != null) 'lat': latitude,
    if (longitude != null) 'lng': longitude,
    if (locationAccuracy != null) 'acc': locationAccuracy,
  };

  factory Message.fromPayloadJson(Map<String, dynamic> j) => Message(
    senderId: j['sid'] as String, content: j['content'] as String,
    type: MessageType.values.firstWhere((e) => e.name == j['type']),
    timestamp: DateTime.fromMillisecondsSinceEpoch(j['ts'] as int),
    deliveredTo: List<String>.from(j['dlv'] ?? []),
    latitude: (j['lat'] as num?)?.toDouble(),
    longitude: (j['lng'] as num?)?.toDouble(),
    locationAccuracy: (j['acc'] as num?)?.toDouble(),
  );
}
