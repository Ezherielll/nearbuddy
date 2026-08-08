import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:nearby_connections/nearby_connections.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../domain/services/peer_discovery_service.dart';
import 'unimplemented_peer_discovery_service.dart';

class NearbyConnectionsService implements PeerDiscoveryService {
  final _nearby = Nearby();
  final _peers = <String>{};
  final _names = <String, String>{};
  final _connCtrl =
      StreamController<({String endpointId, String nickname})>.broadcast();
  final _discCtrl = StreamController<String>.broadcast();
  final _plCtrl =
      StreamController<({String fromEndpointId, String payload})>.broadcast();
  final _peersCtrl = StreamController<Set<String>>.broadcast();
  final _devicesCtrl =
      StreamController<({String endpointId, String nickname})>.broadcast();
  final _deviceLostCtrl = StreamController<String>.broadcast();
  bool _scanning = false;

  @override Stream<({String endpointId, String nickname})> get onPeerConnected => _connCtrl.stream;
  @override Stream<String> get onPeerDisconnected => _discCtrl.stream;
  @override Stream<({String fromEndpointId, String payload})> get onPayloadReceived => _plCtrl.stream;
  @override Stream<Set<String>> get connectedPeersStream => _peersCtrl.stream;
  @override Stream<({String endpointId, String nickname})> get onDeviceFound => _devicesCtrl.stream;
  @override Stream<String> get onDeviceLost => _deviceLostCtrl.stream;
  @override Set<String> get connectedPeers => Set.from(_peers);

  void _add(String eid, String name) {
    _peers.add(eid); _names[eid] = name;
    _connCtrl.add((endpointId: eid, nickname: name));
    _peersCtrl.add(Set.from(_peers));
  }

  void _remove(String eid) {
    _peers.remove(eid); _names.remove(eid);
    _discCtrl.add(eid);
    _peersCtrl.add(Set.from(_peers));
  }

  void _onPayload(String eid, Payload p) {
    if (p.type == PayloadType.BYTES) {
      _plCtrl.add((fromEndpointId: eid, payload: String.fromCharCodes(p.bytes!)));
    }
  }

  @override
  Future<void> startSession({required String groupId, required String nickname, String? pin}) async {
    final svcId = AppConfig.nearbyServiceId(groupId);
    // PIN no longer rides in the advertisement name (D-15) — it is validated
    // in the E2EE hello handshake (KeyExchangeService, Task 11).
    final adName = nickname;

    await _nearby.startAdvertising(adName, Strategy.P2P_CLUSTER,
      onConnectionInitiated: (eid, info) async {
        _names[eid] = info.endpointName;
        await _nearby.acceptConnection(eid,
            onPayLoadRecieved: _onPayload, onPayloadTransferUpdate: (_, __) {});
      },
      onConnectionResult: (eid, status) { if (status == Status.CONNECTED) _add(eid, _names[eid] ?? eid); },
      onDisconnected: _remove,
      serviceId: svcId,
    );

    await _nearby.startDiscovery(adName, Strategy.P2P_CLUSTER,
      onEndpointFound: (eid, endpointName, _) {
        _names[eid] = endpointName;
        _nearby.requestConnection(adName, eid,
          onConnectionInitiated: (eid2, _) async =>
              _nearby.acceptConnection(eid2,
                  onPayLoadRecieved: _onPayload, onPayloadTransferUpdate: (_, __) {}),
          onConnectionResult: (eid2, status) { if (status == Status.CONNECTED) _add(eid2, _names[eid2] ?? eid2); },
          onDisconnected: _remove,
        );
      },
      onEndpointLost: (_) {},
      serviceId: svcId,
    );
  }

  @override
  Future<void> stopSession() async {
    await _nearby.stopAdvertising();
    await _nearby.stopDiscovery();
    await _nearby.stopAllEndpoints();
    _peers.clear(); _names.clear();
  }

  /// Ambient scan: advertise the nickname and report nearby NearBuddy
  /// devices without establishing connections. Uses the flavor-scoped scan
  /// service ID so dev/prod builds never see each other.
  @override
  Future<void> startScan() async {
    if (_scanning) return;
    _scanning = true;
    final svcId = AppConfig.scanServiceId;
    await _nearby.startAdvertising('', Strategy.P2P_CLUSTER,
      onConnectionInitiated: (_, __) async {},   // scan is passive — no accepts
      onConnectionResult: (_, __) {},
      onDisconnected: (_) {},
      serviceId: svcId,
    );
    await _nearby.startDiscovery('', Strategy.P2P_CLUSTER,
      onEndpointFound: (eid, endpointName, _) {
        _devicesCtrl.add((endpointId: eid, nickname: endpointName));
      },
      onEndpointLost: (eid) {
        if (eid != null) _deviceLostCtrl.add(eid);
      },
      serviceId: svcId,
    );
  }

  @override
  Future<void> stopScan() async {
    if (!_scanning) return;
    _scanning = false;
    await _nearby.stopAdvertising();
    await _nearby.stopDiscovery();
  }

  @override
  Future<Set<String>> sendToAll(String payload) async {
    final b = utf8.encode(payload);
    for (final eid in Set.from(_peers)) {
      await _nearby.sendBytesPayload(eid, b);
    }
    return Set.from(_peers);
  }

  @override
  Future<void> sendTo(String eid, String payload) =>
      _nearby.sendBytesPayload(eid, utf8.encode(payload));

  void dispose() {
    _connCtrl.close(); _discCtrl.close(); _plCtrl.close(); _peersCtrl.close();
    _devicesCtrl.close(); _deviceLostCtrl.close();
  }
}

final peerDiscoveryServiceProvider = Provider<PeerDiscoveryService>((ref) {
  // nearby_connections is Android-only. iOS gets an honest stub (MPC in v1.1);
  // the plugin's Dart code still compiles on iOS, only the channel is absent.
  if (Platform.isIOS) return UnimplementedPeerDiscoveryService();
  final s = NearbyConnectionsService();
  ref.onDispose(s.dispose);
  return s;
});
