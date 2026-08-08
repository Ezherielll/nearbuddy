import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// NearBuddy typography system — single source of truth.
///
/// Three deliberate roles, each with a reason to exist:
///
///  * [AppFonts.display] — Hanken Grotesk. A warm humanist grotesk with
///    subtle character: modern without being trendy. Reserved for hero
///    headlines only (onboarding, major page titles), never for body copy.
///
///  * [AppFonts.body] — Plus Jakarta Sans. Designed for the Indonesian
///    context; its generous x-height and wide Latin coverage keep long
///    Indonesian words (and their English equivalents) readable down to
///    12–13 px. The app's workhorse for chat, settings, buttons, labels.
///
///  * [AppFonts.mono] — IBM Plex Mono. Technical values only: device IDs,
///    SAS verification codes, group codes. Deliberately absent everywhere
///    else so technical text feels intentional, not default.
///
/// All fonts are OFL-licensed, bundled locally in `assets/fonts` and served
/// as variable fonts (Plus Jakarta Sans / Hanken Grotesk) or static weights
/// (IBM Plex Mono). The app never fetches fonts at runtime — fully offline.
///
/// ## Scale (base 16, ratio ≈ 1.19, wider display step ≈ 1.43)
///
///   12 caption · 13 small/muted · 15.5 body · 16.5 large · 17 h4 ·
///   20 h3 · 24 h2 · 28 h1 · 40 display
///
/// Steps are deliberately irregular (not 12/14/16/18/20/24/28/32) so the
/// rhythm reads as hand-set rather than mechanically generated, while still
/// staying compact enough for a phone viewport in both ID and EN.
///
/// ## Weight strategy
///
///   400 body/metadata · 500 UI emphasis/labels · 600 headings & CTA ·
///   700 display only. Nothing above 700 — heavy type is a highlight, not
///   a default.
///
/// ## Line-height & tracking are contextual
///
///   chat 1.4 · body 1.55 · labels ≥1.3 (never 1.0) · headings 1.05–1.25.
///   Letter spacing stays neutral for body/small text; only 24 px+ headings
///   tighten (down to −0.4 at display) — negative tracking is never applied
///   globally.
abstract final class AppFonts {
  /// Primary body/UI family.
  static const String body = 'PlusJakartaSans';

  /// Display/headline family.
  static const String display = 'HankenGrotesk';

  /// Monospace family for technical values.
  static const String mono = 'IBMPlexMono';

  /// Android generic fallback for missing glyphs — never replaces the
  /// primary family (Flutter's implicit fallback would suffice, but being
  /// explicit keeps behavior predictable across devices).
  static const List<String> fallback = ['sans-serif'];
}

/// Deliberate type scale + contextual tokens for NearBuddy.
abstract final class NearBuddyTypography {
  // Scale values (see rationale above).
  static const double display = 40;
  static const double h1 = 28;
  static const double h2 = 24;
  static const double h3 = 20;
  static const double h4 = 17;
  static const double body = 15.5;
  static const double lead = 18;
  static const double large = 16.5;
  static const double small = 13;
  static const double muted = 13;
  static const double caption = 12;

  /// Chat message body — 16 px-ish, regular, 1.4 line-height: compact enough
  /// for messaging, comfortable for multiline Indonesian text.
  static const double chatBody = 16;

  /// Chat metadata (timestamps, statuses).
  static const double chatMeta = 11;

  /// Technical values (deviceId, SAS, group codes).
  static const double mono = 13;

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    required double height,
    double letterSpacing = 0,
    String? family,
    FontStyle style = FontStyle.normal,
  }) {
    return TextStyle(
      fontFamily: family ?? AppFonts.body,
      fontFamilyFallback: AppFonts.fallback,
      fontSize: size,
      fontWeight: weight,
      fontStyle: style,
      height: height,
      letterSpacing: letterSpacing,
      decoration: TextDecoration.none,
      textBaseline: TextBaseline.alphabetic,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  /// The ShadTextTheme mapped from the NearBuddy system. Shared verbatim by
  /// light and dark themes — only colors differ (via NearBuddyColorScheme).
  /// `family` propagates to Material's ThemeData.fontFamily, so AppBar,
  /// dialogs, inputs and raw Text widgets all inherit the body font.
  static final ShadTextTheme textTheme = ShadTextTheme.custom(
    // Display — Hanken Grotesk, the only place 700 is used.
    h1Large: _base(
      size: display,
      weight: FontWeight.w700,
      height: 1.05,
      letterSpacing: -0.4,
      family: AppFonts.display,
    ),
    // Titles — one full weight step below display.
    h1: _base(size: h1, weight: FontWeight.w600, height: 1.12, letterSpacing: -0.2),
    h2: _base(size: h2, weight: FontWeight.w600, height: 1.15, letterSpacing: -0.1),
    h3: _base(size: h3, weight: FontWeight.w600, height: 1.2),
    h4: _base(size: h4, weight: FontWeight.w600, height: 1.25),
    // Body — the workhorse.
    p: _base(size: body, weight: FontWeight.w400, height: 1.55),
    lead: _base(size: lead, weight: FontWeight.w400, height: 1.5),
    large: _base(size: large, weight: FontWeight.w500, height: 1.4),
    // Small/labels — never 1.0 line-height; 13 px keeps ≥12 px floor.
    small: _base(size: small, weight: FontWeight.w500, height: 1.35, letterSpacing: 0.05),
    muted: _base(size: muted, weight: FontWeight.w400, height: 1.45),
    // Structural roles (unused by NearBuddy screens; kept consistent).
    blockquote: _base(
      size: body,
      weight: FontWeight.w400,
      height: 1.5,
      style: FontStyle.italic,
    ),
    table: _base(size: 13.5, weight: FontWeight.w500, height: 1.4),
    list: _base(size: body, weight: FontWeight.w400, height: 1.5),
    family: AppFonts.body,
  );

  /// Chat bubble message body.
  static const TextStyle chatBodyStyle = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: chatBody,
    fontWeight: FontWeight.w400,
    height: 1.4,
    decoration: TextDecoration.none,
  );

  /// Chat metadata (timestamps, delivery state) — subtle weight over opacity.
  static const TextStyle chatMetaStyle = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: chatMeta,
    fontWeight: FontWeight.w500,
    height: 1.3,
    decoration: TextDecoration.none,
  );

  /// Technical values — deviceId, SAS codes, group codes.
  static const TextStyle monoStyle = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: mono,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
    decoration: TextDecoration.none,
  );

  /// Compact technical values (badges, chips).
  static const TextStyle monoSmallStyle = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: caption,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
    decoration: TextDecoration.none,
  );
}
