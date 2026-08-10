import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerService {
  /// `restricted` is returned on some devices for neverForLocation-flagged
  /// permissions (BLUETOOTH_SCAN / NEARBY_WIFI_DEVICES) - Nearby still works
  /// in that state, so treat it as granted.
  static bool ok(PermissionStatus s) =>
      s.isGranted || s.isLimited || s.isRestricted;

  /// Permissions that truly require the user's consent — the flow FAILS when
  /// any of these is not granted.
  static const List<Permission> _androidConsentPermissions = [
    Permission.bluetoothAdvertise,
    Permission.bluetoothConnect,
    Permission.locationWhenInUse,
  ];

  /// Also requested, but never gating: BLUETOOTH_SCAN and NEARBY_WIFI_DEVICES
  /// are declared with `neverForLocation` in the manifest. On most Android
  /// builds they auto-grant at install — but after an app-data clear or on
  /// some devices they come back `denied`, which makes Nearby's Wi-Fi medium
  /// fail with 8029/8013 (startDiscovery throws). They must be REQUESTED so
  /// the system (re)grants them; requesting is a silent no-dialog grant, and
  /// `restricted`/`denied` afterwards is tolerated (BLE medium still works).
  static const List<Permission> _androidNonGating = [
    Permission.bluetoothScan,
    Permission.nearbyWifiDevices,
  ];

  /// Check-then-request: permissions already usable are never re-requested,
  /// so granting once (e.g. on Home) does not make the system dialog pop up
  /// again when creating/joining a group later.
  Future<bool> requestNearbyPermissions() async {
    // Android uses Nearby Connections permissions; iOS uses bluetooth +
    // location (Multipeer Connectivity is stubbed until v1.1).
    final requestable = Platform.isIOS
        ? const [Permission.bluetooth, Permission.locationWhenInUse]
        : [..._androidConsentPermissions, ..._androidNonGating];
    final pending = <Permission>[];
    for (final p in requestable) {
      if (!ok(await p.status)) pending.add(p);
    }
    if (pending.isNotEmpty) {
      try {
        await pending.request();
      } catch (_) {
        // PlatformException — fail closed below, never crash.
      }
    }
    // Only the consent permissions gate the flow.
    for (final p in _androidConsentPermissions) {
      if (!ok(await p.status)) return false;
    }
    return true;
  }

  Future<bool> requestLocationPermission() async {
    if (ok(await Permission.locationWhenInUse.status)) return true;
    try {
      final s = await Permission.locationWhenInUse.request();
      return ok(s);
    } catch (_) {
      return false;
    }
  }
}

// Riverpod provider - used by ChatController
final permissionHandlerServiceProvider =
    Provider<PermissionHandlerService>((_) => PermissionHandlerService());
