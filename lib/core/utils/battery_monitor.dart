import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';

class BatteryMonitor {
  final _battery = Battery();

  Stream<int> get batteryLevelStream async* {
    while (true) {
      yield await _battery.batteryLevel;
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  Future<bool> isLowBattery() async =>
      (await _battery.batteryLevel) <= AppConstants.lowBatteryThresholdPercent;
}

final batteryMonitorProvider = Provider<BatteryMonitor>((_) => BatteryMonitor());

final lowBatteryProvider = StreamProvider<bool>((ref) =>
    ref.watch(batteryMonitorProvider).batteryLevelStream
        .map((l) => l <= AppConstants.lowBatteryThresholdPercent));
