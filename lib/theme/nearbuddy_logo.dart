import 'dart:math' as math;

import 'package:flutter/material.dart';

/// NearBuddy radar-discovery logo — single source of truth for the brand mark.
///
/// Glyph: a white center dot (self) with a ~100° transparent sweep wedge, two
/// white dashed ripple arcs, and two peer dots — one linked by a thin line,
/// one riding ahead of the sweep. A message radiating across the mesh.
///
/// Brand palette follows `NearBuddyColorScheme`:
///   - background        #2563EB (the app's primary blue)
///   - glyph (all parts) white
/// Flat, no text. Renders at any square size (1024-unit design grid, scaled
/// to the canvas). `drawBackground: true` fills the blue backdrop
/// (full-bleed legacy icons / in-app chip); adaptive-foreground renders keep
/// it transparent — the adaptive icon's background color comes from the
/// Android `ic_launcher_background` color resource.
///
/// Regenerate launcher PNGs: `flutter test tool/logo_render_test.dart`
class NearBuddyLogoPainter extends CustomPainter {
  /// Design grid size — all geometry is authored in these units.
  static const double grid = 1024;

  /// Brand blue from the NearBuddy palette.
  static const Color brandBlue = Color(0xFF2563EB);

  /// Glyph white.
  static const Color white = Color(0xFFFFFFFF);

  /// Sweep wedge aperture (degrees).
  static const double sweepDeg = 100;

  /// Center of the design grid.
  static const Offset center = Offset(grid / 2, grid / 2);

  /// Paint the brand-blue backdrop (legacy icons / in-app chip). Adaptive
  /// foreground renders keep this `false` (transparent).
  final bool drawBackground;

  const NearBuddyLogoPainter({
    this.drawBackground = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (drawBackground) {
      canvas.drawRect(Offset.zero & size, Paint()..color = brandBlue);
    }

    final s = math.min(size.width, size.height);
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    canvas.scale(s / grid);
    _paintGlyph(canvas);
    canvas.restore();
  }

  void _paintGlyph(Canvas canvas) {
    // --- Sweep wedge (~100°, centered up-right) ---
    const wedgeStart = -45 - sweepDeg / 2;
    final wedgePath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: 380),
        wedgeStart * math.pi / 180,
        sweepDeg * math.pi / 180,
        false,
      )
      ..close();
    canvas.drawPath(
      wedgePath,
      Paint()..color = white.withValues(alpha: 0.22),
    );
    // Leading edge of the sweep (slightly stronger)
    final leadingEdge = Paint()
      ..color = white.withValues(alpha: 0.55)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    const leadAngle = (wedgeStart + sweepDeg) * math.pi / 180;
    canvas.drawLine(
      center,
      center + Offset(math.cos(leadAngle), math.sin(leadAngle)) * 380,
      leadingEdge,
    );

    // --- Two dashed ripple arcs ---
    _dashArc(canvas, radius: 230, startDeg: 0);
    _dashArc(canvas, radius: 330, startDeg: 22.5);

    // --- Peer dot connected by a thin line (down-left) ---
    const linkAngle = 135 * math.pi / 180;
    final peer1 =
        center + Offset(math.cos(linkAngle), math.sin(linkAngle)) * 300;
    canvas.drawLine(
      center,
      peer1,
      Paint()
        ..color = white.withValues(alpha: 0.7)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(peer1, 38, Paint()..color = white);

    // --- Peer dot ahead of the sweep (up-right, on the wedge arc) ---
    final peer2 = center +
        Offset(math.cos(-45 * math.pi / 180), math.sin(-45 * math.pi / 180)) *
            330;
    canvas.drawCircle(peer2, 44, Paint()..color = white);

    // --- Self dot (center) ---
    canvas.drawCircle(center, 64, Paint()..color = white);
  }

  void _dashArc(
    Canvas canvas, {
    required double radius,
    required double startDeg,
  }) {
    const dash = 20.0;
    const gap = 25.0;
    const count = 8;
    final paint = Paint()
      ..color = white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < count; i++) {
      final a0 = (startDeg + i * (dash + gap)) * math.pi / 180;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        a0,
        dash * math.pi / 180,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(NearBuddyLogoPainter oldDelegate) =>
      oldDelegate.drawBackground != drawBackground;
}

/// Convenience widget for in-app use of the logo (e.g. home, onboarding).
/// Wrap in [ClipRRect] for rounded-corner chips — the painter fills a square.
class NearBuddyLogo extends StatelessWidget {
  final double size;
  final bool drawBackground;

  const NearBuddyLogo({
    super.key,
    this.size = 112,
    this.drawBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: NearBuddyLogoPainter(drawBackground: drawBackground),
    );
  }
}
