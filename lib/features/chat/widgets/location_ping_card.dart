// Stub — full implementation in Task 14
import 'package:flutter/material.dart';
class LocationPingCard extends StatelessWidget {
  final double latitude, longitude;
  const LocationPingCard({super.key, required this.latitude, required this.longitude});
  @override
  Widget build(BuildContext context) => Text('$latitude, $longitude',
      style: const TextStyle(fontFamily: 'monospace', fontSize: 12));
}
