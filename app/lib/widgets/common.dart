import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Estilo (fondo, texto, etiqueta) por estado de mesa (spec §7).
({Color bg, Color fg, String label}) tableStatusStyle(
    BuildContext c, String status) {
  final s = c.semantic;
  final scheme = Theme.of(c).colorScheme;
  switch (status) {
    case 'disponible':
      return (
        bg: s.successContainer,
        fg: s.onSuccessContainer,
        label: 'Disponible'
      );
    case 'ocupada':
      return (
        bg: scheme.errorContainer,
        fg: scheme.onErrorContainer,
        label: 'Ocupada'
      );
    case 'reservada':
      return (bg: s.infoContainer, fg: s.onInfoContainer, label: 'Reservada');
    case 'por_atender':
      return (
        bg: s.warningContainer,
        fg: s.onWarningContainer,
        label: 'Por atender'
      );
    case 'fuera_servicio':
      return (
        bg: scheme.surfaceContainerHighest,
        fg: scheme.outline,
        label: 'Fuera de servicio'
      );
    default:
      return (
        bg: scheme.surfaceContainerHighest,
        fg: scheme.onSurface,
        label: status
      );
  }
}

/// Estilo por estado de comanda KDS (spec §6).
({Color bg, Color fg, String label}) ticketStatusStyle(
    BuildContext c, String status) {
  final s = c.semantic;
  switch (status) {
    case 'pendiente':
      return (
        bg: s.warningContainer,
        fg: s.onWarningContainer,
        label: 'Pendiente'
      );
    case 'en_proceso':
      return (
        bg: s.infoContainer,
        fg: s.onInfoContainer,
        label: 'En preparación'
      );
    case 'lista':
      return (bg: s.successContainer, fg: s.onSuccessContainer, label: 'Lista');
    case 'entregada':
      return (
        bg: s.successContainer,
        fg: s.onSuccessContainer,
        label: 'Entregada'
      );
    default:
      return (
        bg: Theme.of(c).colorScheme.surfaceContainerHighest,
        fg: Theme.of(c).colorScheme.onSurface,
        label: status
      );
  }
}

/// Píldora de estado con texto.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const StatusBadge(
      {super.key, required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style:
              TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Control de cantidad táctil: − valor +.
class QtyStepper extends StatelessWidget {
  final int value;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  const QtyStepper({super.key, required this.value, this.onAdd, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: onRemove,
          icon: const Icon(Icons.remove),
          visualDensity: VisualDensity.compact,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('$value',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        IconButton.filled(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

/// Estado vacío reutilizable (icono + mensaje).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(message,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Muestra un SnackBar de error consistente.
void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}
