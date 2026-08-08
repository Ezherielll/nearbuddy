import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/services/peer_discovery_service.dart';
import '../../infrastructure/nearby/nearby_connections_service.dart';

/// A device seen by the ambient scan. Only nicknames are known — Nearby
/// Connections does not expose signal strength, so we stay honest and show
/// "detected" instead of a fake RSSI.
typedef NearbyDevice = ({String endpointId, String nickname});

/// Lifecycle: Home calls [start] in initState and [stop] in dispose.
class ScanController {
  final Ref _ref;
  StreamSubscription? _foundSub;
  StreamSubscription? _lostSub;
  final _devices = <String, NearbyDevice>{};

  ScanController(this._ref);

  PeerDiscoveryService get _peer => _ref.read(peerDiscoveryServiceProvider);

  Future<void> start() async {
    _foundSub ??= _peer.onDeviceFound.listen((d) {
      _devices[d.endpointId] = d;
      _ref.read(nearbyDevicesProvider.notifier).add(d);
    });
    _lostSub ??= _peer.onDeviceLost.listen((eid) {
      _devices.remove(eid);
      _ref.read(nearbyDevicesProvider.notifier).remove(eid);
    });
    try {
      await _peer.startScan();
    } catch (_) {
      // Permission denied / radio off: the scan cannot run, but this must
      // never surface as an unhandled exception (the Home UI shows the
      // permission banner instead).
    }
  }

  Future<void> stop() async {
    await _peer.stopScan();
    await _foundSub?.cancel();
    await _lostSub?.cancel();
    _foundSub = null;
    _lostSub = null;
    _devices.clear();
    _ref.read(nearbyDevicesProvider.notifier).clear();
  }
}

final scanControllerProvider = Provider<ScanController>((ref) => ScanController(ref));

final nearbyDevicesProvider =
    StateNotifierProvider<NearbyDevicesNotifier, List<NearbyDevice>>(
        (_) => NearbyDevicesNotifier());

class NearbyDevicesNotifier extends StateNotifier<List<NearbyDevice>> {
  NearbyDevicesNotifier() : super(const []);

  void add(NearbyDevice d) {
    if (!state.any((x) => x.endpointId == d.endpointId)) {
      state = [...state, d];
    }
  }

  void remove(String endpointId) =>
      state = state.where((x) => x.endpointId != endpointId).toList();

  void clear() => state = const [];
}

/// Whether the radio (Bluetooth/Wi-Fi) is available. Defaults to true;
/// Home/ScanController set it after checking permission status. A plain
/// StateProvider keeps connection-status derivation synchronous and testable.
final radioAvailableProvider = StateProvider<bool>((_) => true);

/// Async check used at Home startup — updates [radioAvailableProvider].
/// `restricted` counts as available (neverForLocation flag on Bluetooth/
/// Nearby Wi-Fi still allows scanning).
Future<bool> checkRadioAvailability() async {
  bool ok(PermissionStatus st) => st.isGranted || st.isLimited || st.isRestricted;
  if (Platform.isIOS) {
    return ok(await Permission.bluetooth.status);
  }
  final s = await Permission.bluetoothScan.status;
  final advertise = await Permission.bluetoothAdvertise.status;
  final wifi = await Permission.nearbyWifiDevices.status;
  return ok(s) || ok(advertise) || ok(wifi);
}
