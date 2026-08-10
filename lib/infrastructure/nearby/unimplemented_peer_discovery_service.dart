import 'dart:async';
import '../../domain/services/peer_discovery_service.dart';

/// Honest iOS placeholder — Multipeer Connectivity support is scheduled for
/// v1.1 (PRD D-01). Every call fails loudly instead of pretending to work.
class UnimplementedPeerDiscoveryService implements PeerDiscoveryService {
  Never get _unsupported =>
      throw UnimplementedError('iOS: Multipeer Connectivity dijadwalkan v1.1');

  @override
  Future<void> startSession(
          {required String groupId,
          required String nickname,
          String? pin}) =>
      Future<void>.error(_unsupported);

  @override
  Future<void> stopSession() => Future<void>.error(_unsupported);

  @override
  Future<Set<String>> sendToAll(String jsonPayload) =>
      Future<Set<String>>.error(_unsupported);

  @override
  Future<void> sendTo(String endpointId, String jsonPayload) =>
      Future<void>.error(_unsupported);

  @override
  Future<void> disconnectPeer(String endpointId) =>
      Future<void>.error(_unsupported);

  @override
  Future<void> startScan() => Future<void>.error(_unsupported);

  @override
  Future<void> stopScan() => Future<void>.error(_unsupported);

  @override
  Stream<({String endpointId, String nickname})> get onPeerConnected =>
      const Stream.empty();

  @override
  Stream<String> get onPeerDisconnected => const Stream.empty();

  @override
  Stream<({String fromEndpointId, String payload})> get onPayloadReceived =>
      const Stream.empty();

  @override
  Stream<Set<String>> get connectedPeersStream => const Stream.empty();

  @override
  Set<String> get connectedPeers => const {};

  @override
  Stream<({String endpointId, String nickname})> get onDeviceFound =>
      const Stream.empty();

  @override
  Stream<String> get onDeviceLost => const Stream.empty();
}
