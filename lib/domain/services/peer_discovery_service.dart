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
  Stream<({String endpointId, String nickname})> get onPeerConnected;
  Stream<String> get onPeerDisconnected;
  Stream<({String fromEndpointId, String payload})> get onPayloadReceived;
  Stream<Set<String>> get connectedPeersStream;
}
