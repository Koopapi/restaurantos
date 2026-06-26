import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories.dart';
import '../../models/app_config.dart';
import '../../models/ticket.dart';
import '../../state/providers.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';
import '../auth/auth_controller.dart';

/// Tablero KDS de una estación (cocina|barra). Columnas Pendiente / En
/// preparación / Lista (spec §6). Cocina/Barista avanzan; el mesero solo entrega.
class KdsScreen extends ConsumerWidget {
  final String station; // 'cocina' | 'barra'
  const KdsScreen({super.key, required this.station});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsProvider(station));
    final config = ref.watch(configProvider).value ?? AppConfig.fallback;
    final wide = MediaQuery.sizeOf(context).width >= 840;

    return ticketsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
      data: (tickets) {
        if (tickets.isEmpty) {
          return const EmptyState(
              icon: Icons.check_circle_outline,
              message: 'Sin comandas pendientes');
        }
        final columns = <String, List<Ticket>>{
          'pendiente': tickets.where((t) => t.status == 'pendiente').toList(),
          'en_proceso': tickets.where((t) => t.status == 'en_proceso').toList(),
          'lista': tickets.where((t) => t.status == 'lista').toList(),
        };

        if (!wide) {
          // Teléfono: una sola lista ordenada por estado.
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final t in tickets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TicketCard(
                      ticket: t, urgencyMinutes: config.urgencyMinutes),
                ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in columns.entries)
              Expanded(
                  child: _Column(
                      title: entry.key,
                      tickets: entry.value,
                      urgency: config.urgencyMinutes)),
          ],
        );
      },
    );
  }
}

class _Column extends StatelessWidget {
  final String title;
  final List<Ticket> tickets;
  final int urgency;
  const _Column(
      {required this.title, required this.tickets, required this.urgency});

  @override
  Widget build(BuildContext context) {
    final style = ticketStatusStyle(context, title);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              CircleAvatar(radius: 5, backgroundColor: style.fg),
              const SizedBox(width: 8),
              Text('${style.label} · ${tickets.length}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final t in tickets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TicketCard(ticket: t, urgencyMinutes: urgency),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TicketCard extends ConsumerWidget {
  final Ticket ticket;
  final int urgencyMinutes;
  const _TicketCard({required this.ticket, required this.urgencyMinutes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final style = ticketStatusStyle(context, ticket.status);
    final elapsed = ticket.minutesElapsed(DateTime.now());
    final urgent = elapsed >= urgencyMinutes && ticket.status != 'lista';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: style.fg, width: 6)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant, size: 20),
                const SizedBox(width: 8),
                Text(ticket.label,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                _Timer(minutes: elapsed, urgent: urgent),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (ticket.waiterName != null)
                  Text('Mesero: ${ticket.waiterName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                const Spacer(),
                StatusBadge(label: style.label, bg: style.bg, fg: style.fg),
              ],
            ),
            const Divider(height: 20),
            for (final l in ticket.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('${l.qty}× ',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary)),
                    Expanded(child: Text(l.name)),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            _ActionButton(ticket: ticket),
          ],
        ),
      ),
    );
  }
}

class _Timer extends StatelessWidget {
  final int minutes;
  final bool urgent;
  const _Timer({required this.minutes, required this.urgent});

  @override
  Widget build(BuildContext context) {
    final s = context.semantic;
    final bg = urgent
        ? Theme.of(context).colorScheme.errorContainer
        : s.warningContainer;
    final fg = urgent
        ? Theme.of(context).colorScheme.onErrorContainer
        : s.onWarningContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: fg),
          const SizedBox(width: 4),
          Text('${minutes}m',
              style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Acción según rol + estado (regla: el mesero solo entrega).
class _ActionButton extends ConsumerWidget {
  final Ticket ticket;
  const _ActionButton({required this.ticket});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider).employee?.role ?? '';
    final isStation = role == 'cocina' ||
        role == 'barista' ||
        role == 'gerente' ||
        role == 'admin';
    final isWaiter = role == 'mesero' || role == 'gerente' || role == 'admin';

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } catch (e) {
        if (context.mounted)
          showError(context, 'No se pudo actualizar la comanda');
      }
    }

    final repo = ref.read(serviceRepositoryProvider);

    if (ticket.status == 'pendiente' && isStation) {
      return _btn(context, 'Iniciar preparación', Icons.play_arrow,
          onTap: () => run(() => repo.advanceTicket(ticket.id)));
    }
    if (ticket.status == 'en_proceso' && isStation) {
      return _btn(context, 'Marcar listo', Icons.check,
          onTap: () => run(() => repo.advanceTicket(ticket.id)));
    }
    if (ticket.status == 'lista' && isWaiter) {
      return _btn(context, 'Entregar', Icons.room_service,
          color: context.semantic.success,
          onTap: () => run(() => repo.deliverTicket(ticket.id)));
    }
    return const SizedBox.shrink();
  }

  Widget _btn(BuildContext context, String label, IconData icon,
      {required VoidCallback onTap, Color? color}) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: color != null
            ? FilledButton.styleFrom(backgroundColor: color)
            : null,
      ),
    );
  }
}
