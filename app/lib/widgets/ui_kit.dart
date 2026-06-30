import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Tarjeta blanca con sombra suave (look premium, no el Card de Material).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color color;
  final List<BoxShadow> shadow;
  final BorderSide border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Sp.lg),
    this.radius = Rad.lg,
    this.onTap,
    this.color = BrandColors.surface,
    this.shadow = Shadows.card,
    this.border = BorderSide.none,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: border,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow,
      ),
      child: Material(
        color: color,
        clipBehavior: Clip.antiAlias,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Escala suavemente al presionar — microinteracción táctil para botones/cards.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.95,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;
  void _set(bool v) {
    if (widget.onTap != null) {
      setState(() => _down = v);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: Dur.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Marca: cuadro redondeado con degradado naranja y glow.
class BrandMark extends StatelessWidget {
  final double size;
  final bool glow;
  const BrandMark({super.key, this.size = 56, this.glow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [BrandColors.orangeBright, BrandColors.orangeDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.30),
        boxShadow: glow ? Shadows.glow(BrandColors.orange, opacity: 0.45) : null,
      ),
      child: Icon(Icons.restaurant_menu, color: Colors.white, size: size * 0.5),
    );
  }
}

/// Botón héroe con degradado + glow (acción principal de una pantalla).
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final double height;
  final List<Color>? colors;
  final Color? glowColor;
  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.height = 56,
    this.colors,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final grad = colors ?? const [BrandColors.orangeBright, BrandColors.orangeDeep];
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: enabled
                ? grad
                : const [BrandColors.surfaceAlt, BrandColors.surfaceAlt],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(Rad.pill),
          boxShadow: enabled
              ? Shadows.glow(glowColor ?? BrandColors.orange, opacity: 0.4)
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    color: enabled ? Colors.white : BrandColors.inkFaint,
                    size: 20),
                const SizedBox(width: Sp.sm),
              ],
              Text(
                label,
                style: TextStyle(
                  color: enabled ? Colors.white : BrandColors.inkFaint,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
