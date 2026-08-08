import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerService {
  /// `restricted` is returned on some devices for neverForLocation-flagged
  /// permissions (BLUETOOTH_SCAN / NEARBY_WIFI_DEVICES) - Nearby still works
  /// in that state, so treat it as granted.
  static bool ok(PermissionStatus s) =>
      s.isGranted || s.isLimited || s.isRestricted;

  /// Permissions that truly require the user's consent. BLUETOOTH_SCAN and
  /// NEARBY_WIFI_DEVICES are declared with `neverForLocation` in the manifest:
  /// Android auto-grants them at install, so `permission_handler` may report
  /// `denied`/`restricted` on real devices even though they are usable — and
  /// calling `.request()` on them is a silent no-op. Gating the flow on them
  /// would show a permission banner that can never be cleared.
  static const List<Permission> _androidConsentPermissions = [
    Permission.bluetoothAdvertise,
    Permission.bluetoothConnect,
    Permission.locationWhenInUse,
  ];

  /// Check-then-request: permissions already usable are never re-requested,
  /// so granting once (e.g. on Home) does not make the system dialog pop up
  /// again when creating/joining a group later.
  Future<bool> requestNearbyPermissions() async {
    // Android uses Nearby Connections permissions; iOS uses bluetooth +
    // location (Multipeer Connectivity is stubbed until v1.1).
    final permissions = Platform.isIOS
        ? const [Permission.bluetooth, Permission.locationWhenInUse]
        : _androidConsentPermissions;
    final pending = <Permission>[];
    for (final p in permissions) {
      if (!ok(await p.status)) pending.add(p);
    }
    if (pending.isEmpty) return true;
    try {
      final results = await pending.request();
      return results.values.every(ok);
    } catch (_) {
      // PlatformException (e.g. permission APIs misbehaving on some OEM
      // builds) — fail closed without crashing; the caller shows retry UI.
      return false;
    }
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
