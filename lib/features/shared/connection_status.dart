import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/nearby/nearby_connections_service.dart';
import '../home/scan_controller.dart';

/// Real-time connection state for the current session / ambient scan.
/// Derived honestly from the peer set: connected → searching (never seen a
/// peer) → out of range (saw a peer, now lost) → radio off (no permissions).
enum ConnectionStatus { connected, searching, outOfRange, radioOff }

final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) async* {
  final peer = ref.watch(peerDiscoveryServiceProvider);
  var everConnected = false;
  await for (final peers in peer.connectedPeersStream) {
    if (peers.isNotEmpty) everConnected = true;
    final radioOn = ref.read(radioAvailableProvider);
    yield !radioOn
        ? ConnectionStatus.radioOff
        : peers.isNotEmpty
            ? ConnectionStatus.connected
            : everConnected
                ? ConnectionStatus.outOfRange
                : ConnectionStatus.searching;
  }
});
