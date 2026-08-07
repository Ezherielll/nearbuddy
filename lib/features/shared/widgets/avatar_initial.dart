import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../theme/nearbuddy_color_scheme.dart';

/// Deterministic initial-based avatar, colored from semantic tokens.
class AvatarInitial extends StatelessWidget {
  final String name;
  final double size;
  const AvatarInitial({super.key, required this.name, this.size = 40});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = ShadTheme.of(context).colorScheme;
    final colors = <Color>[
      cs.primary,
      cs.accent,
      cs.destructive,
      cs.warning,
      cs.ring,
    ];
    final color = colors[name.hashCode.abs() % colors.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        _initials,
        style: TextStyle(
          color: cs.primaryForeground,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
