import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearbuddy/domain/services/peer_discovery_service.dart';
import 'package:nearbuddy/features/home/scan_controller.dart';
import 'package:nearbuddy/infrastructure/nearby/nearby_connections_service.dart';

class _FakeScanPeer implements PeerDiscoveryService {
  final _foundCtrl =
      StreamController<({String endpointId, String nickname})>.broadcast();
  final _lostCtrl = StreamController<String>.broadcast();
  bool scanStarted = false;
  bool scanStopped = false;

  @override
  Future<void> startScan() async => scanStarted = true;
  @override
  Future<void> stopScan() async => scanStopped = true;
  @override
  Stream<({String endpointId, String nickname})> get onDeviceFound =>
      _foundCtrl.stream;
  @override
  Stream<String> get onDeviceLost => _lostCtrl.stream;

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
}

void main() {
  late _FakeScanPeer peer;
  late ProviderContainer container;

  setUp(() {
    peer = _FakeScanPeer();
    container = ProviderContainer(overrides: [
      peerDiscoveryServiceProvider.overrideWithValue(peer),
    ]);
    addTearDown(container.dispose);
  });

  test('start() begins scan and surfaces found devices', () async {
    final ctrl = container.read(scanControllerProvider);
    await ctrl.start();
    expect(peer.scanStarted, isTrue);

    peer._foundCtrl.add((endpointId: 'ep-1', nickname: 'Bimo'));
    peer._foundCtrl.add((endpointId: 'ep-2', nickname: 'Nadia'));
    await Future<void>.delayed(Duration.zero);

    final devices = container.read(nearbyDevicesProvider);
    expect(devices.length, 2);
    expect(devices.first.nickname, 'Bimo');
  });

  test('stop() clears devices and stops the scan', () async {
    final ctrl = container.read(scanControllerProvider);
    await ctrl.start();
    peer._foundCtrl.add((endpointId: 'ep-1', nickname: 'Bimo'));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(nearbyDevicesProvider), hasLength(1));

    await ctrl.stop();
    expect(peer.scanStopped, isTrue);
    expect(container.read(nearbyDevicesProvider), isEmpty);
  });

  test('device lost removes a single device', () async {
    final ctrl = container.read(scanControllerProvider);
    await ctrl.start();
    peer._foundCtrl.add((endpointId: 'ep-1', nickname: 'Bimo'));
    peer._foundCtrl.add((endpointId: 'ep-2', nickname: 'Nadia'));
    await Future<void>.delayed(Duration.zero);
    peer._lostCtrl.add('ep-1');
    await Future<void>.delayed(Duration.zero);

    final devices = container.read(nearbyDevicesProvider);
    expect(devices.single.endpointId, 'ep-2');
  });
}
