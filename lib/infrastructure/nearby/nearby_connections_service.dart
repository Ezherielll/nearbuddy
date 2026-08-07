import 'dart:async';
import 'dart:convert';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../domain/services/peer_discovery_service.dart';

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

  @override Stream<({String endpointId, String nickname})> get onPeerConnected => _connCtrl.stream;
  @override Stream<String> get onPeerDisconnected => _discCtrl.stream;
  @override Stream<({String fromEndpointId, String payload})> get onPayloadReceived => _plCtrl.stream;
  @override Stream<Set<String>> get connectedPeersStream => _peersCtrl.stream;

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
    final adName = (pin != null && pin.isNotEmpty) ? '$nickname|$pin' : nickname;

    await _nearby.startAdvertising(adName, Strategy.P2P_CLUSTER,
      onConnectionInitiated: (eid, info) async {
        if (pin != null && pin.isNotEmpty && !info.endpointName.endsWith('|$pin')) {
          await _nearby.rejectConnection(eid); return;
        }
        _names[eid] = info.endpointName.contains('|')
            ? info.endpointName.split('|').first : info.endpointName;
        await _nearby.acceptConnection(eid,
            onPayLoadRecieved: _onPayload, onPayloadTransferUpdate: (_, __) {});
      },
      onConnectionResult: (eid, status) { if (status == Status.CONNECTED) _add(eid, _names[eid] ?? eid); },
      onDisconnected: _remove,
      serviceId: svcId,
    );

    await _nearby.startDiscovery(adName, Strategy.P2P_CLUSTER,
      onEndpointFound: (eid, endpointName, _) {
        final peerName = endpointName.contains('|') ? endpointName.split('|').first : endpointName;
        _names[eid] = peerName;
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
  }
}

final peerDiscoveryServiceProvider = Provider<PeerDiscoveryService>((ref) {
  final s = NearbyConnectionsService();
  ref.onDispose(s.dispose);
  return s;
});
