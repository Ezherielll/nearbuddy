/// Abstract interface for peer-to-peer discovery and messaging.
/// Concrete implementation: NearbyConnectionsService.
abstract class PeerDiscoveryService {
  Future<void> startSession({
    required String groupId,
    required String nickname,
    String? pin,
  });
  Future<void> stopSession();
  Future<Set<String>> sendToAll(String jsonPayload);
  Future<void> sendTo(String endpointId, String jsonPayload);

  /// Ends ONE connection without touching the session's other peers
  /// (e.g. a joiner whose SAS/PIN was rejected — H2).
  Future<void> disconnectPeer(String endpointId);

  Stream<({String endpointId, String nickname})> get onPeerConnected;
  Stream<String> get onPeerDisconnected;
  Stream<({String fromEndpointId, String payload})> get onPayloadReceived;
  Stream<Set<String>> get connectedPeersStream;

  /// Current connected endpoint ids — synchronous snapshot, no waiting.
  Set<String> get connectedPeers;

  /// Ambient discovery used on Home before joining any group. Advertises
  /// the nickname and passively reports other NearBuddy devices nearby.
  /// Does NOT establish connections.
  Future<void> startScan();
  Future<void> stopScan();
  Stream<({String endpointId, String nickname})> get onDeviceFound;
  Stream<String> get onDeviceLost;
}
