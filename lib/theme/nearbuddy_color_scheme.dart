import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// NearBuddy semantic color tokens — "Privacy, always on."
/// Light: clean slate + messenger blue. Dark: deep slate, lightened primary.
/// Semantic values only; components must never hardcode hex colors.
class NearBuddyColorScheme extends ShadColorScheme {
  const NearBuddyColorScheme.light()
      : super(
          background: const Color(0xFFFFFFFF),
          foreground: const Color(0xFF0F172A),
          card: const Color(0xFFFFFFFF),
          cardForeground: const Color(0xFF0F172A),
          popover: const Color(0xFFFFFFFF),
          popoverForeground: const Color(0xFF0F172A),
          primary: const Color(0xFF2563EB),
          primaryForeground: const Color(0xFFFFFFFF),
          secondary: const Color(0xFFF1F5F9),
          secondaryForeground: const Color(0xFF1E293B),
          muted: const Color(0xFFF1F5F9),
          mutedForeground: const Color(0xFF64748B),
          accent: const Color(0xFF059669),
          accentForeground: const Color(0xFFFFFFFF),
          destructive: const Color(0xFFDC2626),
          destructiveForeground: const Color(0xFFFFFFFF),
          border: const Color(0xFFE2E8F0),
          input: const Color(0xFFCBD5E1),
          ring: const Color(0xFF2563EB),
          selection: const Color(0xFFBFDBFE),
          custom: const {
            'online': Color(0xFF059669),
            'onlineSoft': Color(0xFFECFDF5),
            'warning': Color(0xFFD97706),
          },
        );

  const NearBuddyColorScheme.dark()
      : super(
          background: const Color(0xFF0F172A),
          foreground: const Color(0xFFF1F5F9),
          card: const Color(0xFF1E293B),
          cardForeground: const Color(0xFFF8FAFC),
          popover: const Color(0xFF1E293B),
          popoverForeground: const Color(0xFFF8FAFC),
          primary: const Color(0xFF60A5FA),
          primaryForeground: const Color(0xFF0F172A),
          secondary: const Color(0xFF1E293B),
          secondaryForeground: const Color(0xFFE2E8F0),
          muted: const Color(0xFF1E293B),
          mutedForeground: const Color(0xFF94A3B8),
          accent: const Color(0xFF059669),
          accentForeground: const Color(0xFFECFDF5),
          destructive: const Color(0xFFEF4444),
          destructiveForeground: const Color(0xFFFFFFFF),
          border: const Color(0xFF334155),
          input: const Color(0xFF334155),
          ring: const Color(0xFF60A5FA),
          selection: const Color(0xFF1D4ED8),
          custom: const {
            'online': Color(0xFF34D399),
            'onlineSoft': Color(0xFF064E3B),
            'warning': Color(0xFFF59E0B),
          },
        );
}

extension NearBuddyColors on ShadColorScheme {
  /// Fallbacks keep components safe under any color scheme (e.g. tests that
  /// wrap screens with a built-in scheme whose `custom` map is empty).
  Color get online => custom['online'] ?? accent;
  Color get onlineSoft => custom['onlineSoft'] ?? muted;
  Color get warning => custom['warning'] ?? destructive;
}
