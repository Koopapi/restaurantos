import 'package:flutter/material.dart';

/// Paleta de marca — El Pirrus (naranja) sobre base CLARA (legibilidad bajo sol).
/// White-label: el primario se sobrescribe en runtime desde la config (Marca y Tema).
abstract class BrandColors {
  static const orange = Color(0xFFFF9800); // acento de marca (fills / realces)
  static const orangeBright = Color(0xFFFFA726);
  static const orangeDeep = Color(0xFFF57C00); // press / hover
  static const orangeInk = Color(0xFFB45309); // texto naranja sobre claro (AA)
  static const orangeSoft = Color(0x16FF9800); // ~9% wash para selección

  // Superficies claras de alto contraste
  static const bg = Color(0xFFF6F7F9); // fondo de la app
  static const surface = Color(0xFFFFFFFF); // cards / paneles
  static const surfaceAlt = Color(0xFFEFF1F4); // chips / inputs
  static const ink = Color(0xFF15171C); // texto principal
  static const inkSoft = Color(0xFF5B626E); // texto secundario
  static const inkFaint = Color(0xFF98A0AD); // terciario / placeholder
  static const hairline = Color(0xFFE7EAEF); // bordes finos
}

/// Escala de espacio (4 · 8 · 12 · 16 · 24 · 32).
abstract class Sp {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Radios.
abstract class Rad {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

/// Duraciones de animación.
abstract class Dur {
  static const fast = Duration(milliseconds: 160);
  static const med = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 520);
}

/// Sombras suaves estilo premium (no las de Material por defecto).
abstract class Shadows {
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x0A1B2538), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x141B2538), blurRadius: 20, offset: Offset(0, 12)),
  ];
  static const soft = <BoxShadow>[
    BoxShadow(color: Color(0x0F1B2538), blurRadius: 14, offset: Offset(0, 6)),
  ];
  static List<BoxShadow> glow(Color c, {double opacity = 0.35}) => [
        BoxShadow(
          color: c.withValues(alpha: opacity),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];
}
