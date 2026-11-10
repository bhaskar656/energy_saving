import 'package:energy_saving/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Material 3 theme for the app: vibrant eco colours, rounded corners,
/// soft shadows and a soft-mint scaffold instead of a flat white page.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final colorScheme = _scheme(brightness);
    final baseTextTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
    ).textTheme;

    final radius = BorderRadius.circular(AppPalette.tileRadius);
    final outline = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isLight
          ? AppPalette.mintSurface
          : colorScheme.surface,
      canvasColor: isLight ? AppPalette.mintSurface : colorScheme.surface,
      splashFactory: InkSparkle.splashFactory,
      textTheme: baseTextTheme.copyWith(
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(height: 1.45),
        bodySmall: baseTextTheme.bodySmall?.copyWith(height: 1.4),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? AppPalette.mintSurface : colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppPalette.cardRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : colorScheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: outline,
        enabledBorder: outline,
        focusedBorder: outline.copyWith(
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
          borderRadius: radius,
        ),
        errorBorder: outline.copyWith(
          borderSide: BorderSide(color: colorScheme.error),
          borderRadius: radius,
        ),
        focusedErrorBorder: outline.copyWith(
          borderSide: BorderSide(color: colorScheme.error, width: 2),
          borderRadius: radius,
        ),
        prefixIconColor: colorScheme.primary,
        suffixIconColor: colorScheme.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppPalette.tileRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppPalette.tileRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppPalette.chipRadius),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppPalette.chipRadius),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 3,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppPalette.cardRadius),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: colorScheme.outlineVariant),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppPalette.tileRadius),
            ),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isLight
            ? AppPalette.mintSurfaceAlt
            : colorScheme.surfaceContainerHigh,
        side: BorderSide.none,
        labelStyle: baseTextTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppPalette.chipRadius),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: isLight ? AppPalette.mint : colorScheme.primaryContainer,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return baseTextTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : null,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        minVerticalPadding: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppPalette.chipRadius),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: isLight
            ? AppPalette.mintSurfaceAlt
            : colorScheme.surfaceContainerHighest,
        linearMinHeight: 8,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppPalette.cardRadius),
        ),
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? AppPalette.forest : colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: isLight ? Colors.white : colorScheme.onInverseSurface,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppPalette.chipRadius),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isLight ? AppPalette.forest : colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppPalette.chipRadius),
        ),
        textStyle: TextStyle(color: colorScheme.onInverseSurface),
      ),
    );
  }

  static ColorScheme _scheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: AppPalette.emerald,
      brightness: brightness,
    );

    if (brightness == Brightness.dark) {
      return base.copyWith(
        primary: AppPalette.emerald,
        onPrimary: AppPalette.forest,
        primaryContainer: AppPalette.emeraldDeep,
        onPrimaryContainer: const Color(0xFFE6FFF5),
        secondary: AppPalette.teal,
        onSecondary: const Color(0xFF04302B),
        secondaryContainer: AppPalette.tealDeep,
        onSecondaryContainer: const Color(0xFFDFFFF7),
        tertiary: AppPalette.sky,
        onTertiary: const Color(0xFF04283A),
        surface: const Color(0xFF081C15),
        surfaceContainerLowest: const Color(0xFF051410),
        surfaceContainerLow: const Color(0xFF0D241C),
        surfaceContainer: const Color(0xFF123026),
        surfaceContainerHigh: const Color(0xFF183C30),
        surfaceContainerHighest: const Color(0xFF1F4A3B),
        outline: const Color(0xFF6FA894),
        outlineVariant: const Color(0xFF2C5346),
      );
    }

    return base.copyWith(
      primary: AppPalette.emeraldDeep,
      onPrimary: Colors.white,
      primaryContainer: AppPalette.mint,
      onPrimaryContainer: AppPalette.forest,
      secondary: AppPalette.tealDeep,
      onSecondary: Colors.white,
      secondaryContainer: AppPalette.mintSurfaceAlt,
      onSecondaryContainer: AppPalette.forest,
      tertiary: AppPalette.skyDeep,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFDCEFFF),
      onTertiaryContainer: const Color(0xFF07354D),
      surface: Colors.white,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppPalette.mintSurface,
      surfaceContainer: AppPalette.mintSurfaceAlt,
      surfaceContainerHigh: const Color(0xFFD6EFE3),
      surfaceContainerHighest: AppPalette.mint,
      outline: const Color(0xFF7FB39C),
      outlineVariant: AppPalette.mintBorder,
    );
  }
}