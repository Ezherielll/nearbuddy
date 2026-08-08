import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerService {
  Future<bool> requestNearbyPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
      Permission.locationWhenInUse,
    ].request();
    // `restricted` is returned on some devices for neverForLocation-flagged
    // permissions (BLUETOOTH_SCAN / NEARBY_WIFI_DEVICES) — Nearby still
    // works in that state, so treat it as granted.
    return statuses.values
        .every((s) => s.isGranted || s.isLimited || s.isRestricted);
  }

  Future<bool> requestLocationPermission() async {
    final s = await Permission.locationWhenInUse.request();
    return s.isGranted || s.isLimited || s.isRestricted;
  }
}

// Riverpod provider — used by ChatController
final permissionHandlerServiceProvider =
    Provider<PermissionHandlerService>((_) => PermissionHandlerService());
