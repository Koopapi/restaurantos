import 'package:flutter/material.dart';
import 'colors.dart';

/// Tema Material 3 de RestaurantOS — claro, alto contraste, acento violeta.
/// Botones grandes (56dp) y forma stadium para uso táctil en piso.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kSeedColor,
    brightness: Brightness.light,
  ).copyWith(
    surface: const Color(0xFFFFFFFF),
    onSurface: const Color(0xFF1B1B1F),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFFBF8FD),
    fontFamily: 'Roboto',
    extensions: const [SemanticColors.light],

    // Acción principal: grande y táctil.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 56),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 56),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: const ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF2ECF6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
