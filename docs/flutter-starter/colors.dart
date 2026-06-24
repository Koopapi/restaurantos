import 'package:flutter/material.dart';

/// Semilla de marca (Material You). Configurable por tenant (marca blanca).
const kSeedColor = Color(0xFF6750A4);

/// Colores semánticos de operación que Material 3 no incluye
/// (success / warning / info). Se exponen como ThemeExtension.
@immutable
class SemanticColors extends ThemeExtension<SemanticColors> {
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color infoContainer;
  final Color onInfoContainer;

  const SemanticColors({
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  /// Tema claro de alto contraste (legibilidad bajo luz solar en piso).
  static const light = SemanticColors(
    success: Color(0xFF1E7D34),
    successContainer: Color(0xFFB7F1B6),
    onSuccessContainer: Color(0xFF052109),
    warning: Color(0xFF8A5A00),
    warningContainer: Color(0xFFFFE08A),
    onWarningContainer: Color(0xFF2A1800),
    info: Color(0xFF2E5AAC),
    infoContainer: Color(0xFFD8E2FF),
    onInfoContainer: Color(0xFF11366B),
  );

  @override
  SemanticColors copyWith({
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? infoContainer,
    Color? onInfoContainer,
  }) {
    return SemanticColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
    );
  }

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
    );
  }
}

/// Acceso cómodo: `context.semantic.success`
extension SemanticColorsX on BuildContext {
  SemanticColors get semantic => Theme.of(this).extension<SemanticColors>()!;
}
