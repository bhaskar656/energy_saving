import 'package:flutter/material.dart';

/// Central eco-friendly colour palette for the Energy Saving Reminder app.
///
/// Every screen draws its accents from here so the green + teal identity
/// stays consistent across headers, cards, charts and navigation.
abstract final class AppPalette {
  // Core brand colours.
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDeep = Color(0xFF059669);
  static const Color forest = Color(0xFF065F46);
  static const Color green = Color(0xFF22C55E);
  static const Color greenDeep = Color(0xFF15803D);
  static const Color teal = Color(0xFF14B8A6);
  static const Color tealDeep = Color(0xFF0D9488);
  static const Color sky = Color(0xFF38BDF8);
  static const Color skyDeep = Color(0xFF0284C7);
  static const Color leaf = Color(0xFF84CC16);

  // Supporting accents used to colour-code cards and charts.
  static const Color amber = Color(0xFFF59E0B);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color coral = Color(0xFFF97316);

  // Soft backgrounds.
  static const Color mint = Color(0xFFD7F7E8);
  static const Color mintSurface = Color(0xFFEDF9F3);
  static const Color mintSurfaceAlt = Color(0xFFE2F4EA);
  static const Color mintBorder = Color(0xFFBFE9D5);

  // Shape.
  static const double cardRadius = 22;
  static const double tileRadius = 16;
  static const double chipRadius = 12;
  static const double pillRadius = 999;

  /// Signature header gradient: vibrant green into emerald into teal.
  static const LinearGradient heroGradient = LinearGradient(
    colors: [greenDeep, emeraldDeep, tealDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Softer gradient for cards that must stay readable.
  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [emerald, teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient skyGradient = LinearGradient(
    colors: [sky, skyDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunGradient = LinearGradient(
    colors: [amber, coral],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient leafGradient = LinearGradient(
    colors: [leaf, emeraldDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient violetGradient = LinearGradient(
    colors: [violet, skyDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Builds a two-stop gradient that always ends in the teal brand tone so
  /// arbitrary accent colours still feel part of the same identity.
  static LinearGradient gradientFor(Color accent) {
    return LinearGradient(
      colors: [accent, Color.lerp(accent, tealDeep, 0.45)!],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Very light accent wash used as a card background.
  static LinearGradient washFor(Color accent, {double strength = 1}) {
    return LinearGradient(
      colors: [
        accent.withValues(alpha: 0.13 * strength),
        accent.withValues(alpha: 0.03 * strength),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Soft coloured drop shadow used by every raised surface.
  static List<BoxShadow> shadowFor(Color accent, {double opacity = 0.14}) {
    return [
      BoxShadow(
        color: accent.withValues(alpha: opacity),
        blurRadius: 22,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: accent.withValues(alpha: opacity * 0.35),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Neutral shadow for white surfaces.
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: forest.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: forest.withValues(alpha: 0.03),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
}