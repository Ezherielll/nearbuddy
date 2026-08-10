import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearbuddy/domain/services/peer_discovery_service.dart';
import 'package:nearbuddy/features/home/scan_controller.dart';
import 'package:nearbuddy/features/shared/connection_status.dart';
import 'package:nearbuddy/infrastructure/nearby/nearby_connections_service.dart';

class _FakePeer implements PeerDiscoveryService {
  // Single-subscription: events added before the provider listens are
  // buffered — deterministic for tests.
  final _peersCtrl = StreamController<Set<String>>();
  @override
  Stream<Set<String>> get connectedPeersStream => _peersCtrl.stream;
  @override
  Set<String> get connectedPeers => const {};

  @override
  Future<void> startScan() async {}
  @override
  Future<void> stopScan() async {}
  @override
  Stream<({String endpointId, String nickname})> get onDeviceFound =>
      const Stream.empty();
  @override
  Stream<String> get onDeviceLost => const Stream.empty();
  @override
  Future<void> startSession(
      {required String groupId, required String nickname, String? pin}) async {}
  @override
  Future<void> stopSession() async {}
  @override
  Future<Set<String>> sendToAll(String jsonPayload) async => {};
  @override
  Future<void> sendTo(String endpointId, String jsonPayload) async {}
  @override
  Future<void> disconnectPeer(String endpointId) async {}
  @override
  Stream<({String endpointId, String nickname})> get onPeerConnected =>
      const Stream.empty();
  @override
  Stream<String> get onPeerDisconnected => const Stream.empty();
  @override
  Stream<({String fromEndpointId, String payload})> get onPayloadReceived =>
      const Stream.empty();
}

void main() {
  late _FakePeer peer;
  late ProviderContainer container;

  ProviderContainer make({required bool radioOn}) {
    peer = _FakePeer();
    return ProviderContainer(overrides: [
      peerDiscoveryServiceProvider.overrideWithValue(peer),
      radioAvailableProvider.overrideWith((_) => radioOn),
    ]);
  }

  tearDown(() => container.dispose());

  Future<ConnectionStatus> next() =>
      container.read(connectionStatusProvider.future).then((s) => s);

  test('no peers and never connected → searching', () async {
    container = make(radioOn: true);
    final f = next();
    peer._peersCtrl.add({});
    expect(await f, ConnectionStatus.searching);
  });

  test('peers present → connected', () async {
    container = make(radioOn: true);
    final f = next();
    peer._peersCtrl.add({'ep-1'});
    expect(await f, ConnectionStatus.connected);
  });

  test('peers lost after having connected → outOfRange', () async {
    container = make(radioOn: true);
    final values = <ConnectionStatus>[];
    final sub = container.listen(connectionStatusProvider,
        (prev, next) => values.add(next.value ?? ConnectionStatus.searching));
    addTearDown(sub.close);

    peer._peersCtrl.add({'ep-1'});
    peer._peersCtrl.add({});
    await Future<void>.delayed(Duration.zero);

    expect(values, contains(ConnectionStatus.connected));
    expect(values, contains(ConnectionStatus.outOfRange));
  });

  test('radio off → radioOff regardless of peers', () async {
    container = make(radioOn: false);
    final f = next();
    peer._peersCtrl.add({'ep-1'});
    expect(await f, ConnectionStatus.radioOff);
  });
}
