import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';
import 'tokens.dart';

/// Tema de RestaurantOS — base CLARA de alto contraste (sol directo en piso),
/// acento naranja de marca, tipografía Plus Jakarta Sans, botones grandes
/// (56dp) tipo stadium y superficies con sombra suave (look premium, no el
/// aspecto Material por defecto).
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kSeedColor,
    brightness: Brightness.light,
  ).copyWith(
    primary: BrandColors.orange,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFFFE7C2),
    onPrimaryContainer: const Color(0xFF552D00),
    surface: BrandColors.surface,
    onSurface: BrandColors.ink,
    onSurfaceVariant: BrandColors.inkSoft,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: BrandColors.surfaceAlt,
    surfaceContainer: BrandColors.surfaceAlt,
    surfaceContainerHigh: BrandColors.surfaceAlt,
    surfaceContainerHighest: const Color(0xFFE9ECF0),
    outline: BrandColors.hairline,
    outlineVariant: BrandColors.hairline,
    error: const Color(0xFFD92D20),
  );

  final base = ThemeData(brightness: Brightness.light);
  final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
    bodyColor: BrandColors.ink,
    displayColor: BrandColors.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: BrandColors.bg,
    textTheme: textTheme,
    extensions: const [SemanticColors.light],
    splashFactory: InkSparkle.splashFactory,
    dividerTheme: const DividerThemeData(
      color: BrandColors.hairline,
      thickness: 1,
      space: 1,
    ),

    // Acción principal: grande y táctil.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 56),
        backgroundColor: BrandColors.orange,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        elevation: 0,
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 56),
        foregroundColor: BrandColors.ink,
        side: const BorderSide(color: BrandColors.hairline, width: 1.5),
        shape: const StadiumBorder(),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: BrandColors.orangeInk),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: BrandColors.surfaceAlt,
      selectedColor: BrandColors.orangeSoft,
      side: BorderSide.none,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: BrandColors.ink,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(Rad.sm)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BrandColors.surfaceAlt,
      hintStyle: const TextStyle(color: BrandColors.inkFaint),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.lg),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Rad.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Rad.md),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Rad.md),
        borderSide: const BorderSide(color: BrandColors.orange, width: 2),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: BrandColors.bg,
      foregroundColor: BrandColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rad.md),
      ),
    ),
  );
}
