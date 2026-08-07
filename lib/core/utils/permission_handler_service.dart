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
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  Future<bool> requestLocationPermission() async {
    final s = await Permission.locationWhenInUse.request();
    return s.isGranted || s.isLimited;
  }
}

// Riverpod provider — used by ChatController
final permissionHandlerServiceProvider =
    Provider<PermissionHandlerService>((_) => PermissionHandlerService());
