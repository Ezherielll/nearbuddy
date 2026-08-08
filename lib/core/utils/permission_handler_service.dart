import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerService {
  /// `restricted` is returned on some devices for neverForLocation-flagged
  /// permissions (BLUETOOTH_SCAN / NEARBY_WIFI_DEVICES) - Nearby still works
  /// in that state, so treat it as granted. `denied` requires a request.
  static bool ok(PermissionStatus s) =>
      s.isGranted || s.isLimited || s.isRestricted;

  /// Check-then-request: permissions already usable are never re-requested,
  /// so granting once (e.g. on Home) does not make the system dialog pop up
  /// again when creating/joining a group later.
  Future<bool> requestNearbyPermissions() async {
    // Android uses Nearby Connections permissions; iOS uses bluetooth +
    // location (Multipeer Connectivity is stubbed until v1.1).
    final permissions = Platform.isIOS
        ? const [Permission.bluetooth, Permission.locationWhenInUse]
        : const [
            Permission.bluetoothScan,
            Permission.bluetoothAdvertise,
            Permission.bluetoothConnect,
            Permission.nearbyWifiDevices,
            Permission.locationWhenInUse,
          ];
    final pending = <Permission>[];
    for (final p in permissions) {
      if (!ok(await p.status)) pending.add(p);
    }
    if (pending.isEmpty) return true;
    final results = await pending.request();
    return results.values.every(ok);
  }

  Future<bool> requestLocationPermission() async {
    if (ok(await Permission.locationWhenInUse.status)) return true;
    final s = await Permission.locationWhenInUse.request();
    return ok(s);
  }
}

// Riverpod provider - used by ChatController
final permissionHandlerServiceProvider =
    Provider<PermissionHandlerService>((_) => PermissionHandlerService());
