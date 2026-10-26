import 'package:flutter/material.dart';

/// Paleta y componentes extraídos de «Turco Parcial Design.pen».
/// Los widgets deben usar Theme.of(context), nunca colores sueltos.
abstract final class AppTheme {
  static const _seed = Color(0xFF00695C);
  static const _cardRadius = 16.0;
  static const _fieldRadius = 12.0;

  static final light = _buildTheme(_lightScheme);
  static final dark = _buildTheme(_darkScheme);

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: Brightness.light,
  ).copyWith(
    primary: const Color(0xFF006A60),
    onPrimary: const Color(0xFFFFFFFF),
    primaryContainer: const Color(0xFF9EF2E4),
    onPrimaryContainer: const Color(0xFF00201C),
    secondaryContainer: const Color(0xFFCCE8E2),
    onSecondaryContainer: const Color(0xFF05201C),
    tertiary: const Color(0xFF456179),
    tertiaryContainer: const Color(0xFFCDE5FF),
    onTertiaryContainer: const Color(0xFF001D32),
    onTertiary: const Color(0xFFFFFFFF),
    error: const Color(0xFFBA1A1A),
    onError: const Color(0xFFFFFFFF),
    errorContainer: const Color(0xFFFFDAD6),
    onErrorContainer: const Color(0xFF410002),
    surface: const Color(0xFFF4FBF9),
    surfaceContainer: const Color(0xFFE9EFED),
    surfaceContainerHigh: const Color(0xFFE3EAE8),
    onSurface: const Color(0xFF161D1C),
    onSurfaceVariant: const Color(0xFF3F4947),
    outline: const Color(0xFF6F7977),
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFF53DBC9),
    onPrimary: const Color(0xFF003731),
    primaryContainer: const Color(0xFF005047),
    onPrimaryContainer: const Color(0xFF74F8E5),
    secondaryContainer: const Color(0xFF314B47),
    onSecondaryContainer: const Color(0xFFCCE8E2),
    tertiary: const Color(0xFFADCAE6),
    tertiaryContainer: const Color(0xFF2D4960),
    onTertiaryContainer: const Color(0xFFCDE5FF),
    onTertiary: const Color(0xFF001D32),
    error: const Color(0xFFFFB4AB),
    onError: const Color(0xFF690005),
    errorContainer: const Color(0xFF93000A),
    onErrorContainer: const Color(0xFFFFDAD6),
    surface: const Color(0xFF0E1514),
    surfaceContainer: const Color(0xFF1A2120),
    onSurface: const Color(0xFFDDE4E2),
    onSurfaceVariant: const Color(0xFFBEC9C6),
    outline: const Color(0xFF899390),
  );

  static ThemeData _buildTheme(ColorScheme scheme) {
    final textTheme = TextTheme(
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: scheme.onSurfaceVariant,
      ),
    ).apply(fontFamily: 'Poppins');

    OutlineInputBorder fieldBorder(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(_fieldRadius),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: 'Poppins',
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_fieldRadius),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: fieldBorder(scheme.outline),
        enabledBorder: fieldBorder(scheme.outline),
        focusedBorder: fieldBorder(scheme.primary, width: 2),
        errorBorder: fieldBorder(scheme.error),
        focusedErrorBorder: fieldBorder(scheme.error, width: 2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        elevation: 0,
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
      ),
    );
  }
}
