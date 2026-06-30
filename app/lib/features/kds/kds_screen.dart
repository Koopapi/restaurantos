import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories.dart';
import '../../models/app_config.dart';
import '../../models/ticket.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/ui_kit.dart';
import '../auth/auth_controller.dart';

/// Tablero KDS de una estación (cocina|barra). Columnas Pendiente / En
/// preparación / Lista. Cocina/Barista avanzan; el mesero solo entrega.
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
        final order = ['pendiente', 'en_proceso', 'lista'];
        final columns = {
          for (final s in order)
            s: tickets.where((t) => t.status == s).toList(),
        };

        if (!wide) {
          if (tickets.isEmpty) {
            return const EmptyState(
                icon: Icons.check_circle_outline,
                message: 'Sin comandas pendientes');
          }
          return ListView(
            padding: const EdgeInsets.all(Sp.md),
            children: [
              for (final t in tickets)
                Padding(
                  padding: const EdgeInsets.only(bottom: Sp.md),
                  child: _TicketCard(
                      ticket: t, urgencyMinutes: config.urgencyMinutes),
                ),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(Sp.md, Sp.sm, Sp.md, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in order)
                Expanded(
                  child: _Column(
                    status: s,
                    tickets: columns[s]!,
                    urgency: config.urgencyMinutes,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Column extends StatelessWidget {
  final String status;
  final List<Ticket> tickets;
  final int urgency;
  const _Column(
      {required this.status, required this.tickets, required this.urgency});

  @override
  Widget build(BuildContext context) {
    final viz = _statusViz(status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Sp.sm, Sp.sm, Sp.sm, Sp.md),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: viz.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: Sp.sm),
              Text(viz.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(width: Sp.sm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: viz.soft,
                  borderRadius: BorderRadius.circular(Rad.pill),
                ),
                child: Text('${tickets.length}',
                    style: TextStyle(
                        color: viz.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
            ],
          ),
        ),
        Expanded(
          child: tickets.isEmpty
              ? Center(
                  child: Text('—',
                      style: TextStyle(
                          color: BrandColors.inkFaint.withValues(alpha: 0.5),
                          fontSize: 28)),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.sm),
                  children: [
                    for (var i = 0; i < tickets.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Sp.md),
                        child: _TicketCard(
                                ticket: tickets[i], urgencyMinutes: urgency)
                            .animate()
                            .fadeIn(duration: 240.ms, delay: (i * 40).ms)
                            .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
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
    final viz = _statusViz(ticket.status);
    final elapsed = ticket.minutesElapsed(DateTime.now());
    final urgent = elapsed >= urgencyMinutes && ticket.status != 'lista';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Rad.lg),
        boxShadow: Shadows.card,
        border: Border(left: BorderSide(color: viz.color, width: 6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  ticket.station == 'barra'
                      ? Icons.local_bar
                      : Icons.outdoor_grill,
                  size: 20,
                  color: BrandColors.inkSoft,
                ),
                const SizedBox(width: Sp.sm),
                Text(ticket.label,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                _Timer(minutes: elapsed, urgent: urgent),
              ],
            ),
            const SizedBox(height: Sp.sm),
            Row(
              children: [
                if (ticket.waiterName != null)
                  Text('Mesero · ${ticket.waiterName}',
                      style: const TextStyle(
                          color: BrandColors.inkFaint, fontSize: 12.5)),
                const Spacer(),
                _StatusPill(viz: viz),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Sp.md),
              child: Divider(height: 1),
            ),
            for (final l in ticket.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: BrandColors.orangeSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${l.qty}×',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: BrandColors.orangeInk,
                              fontSize: 13)),
                    ),
                    const SizedBox(width: Sp.sm),
                    Expanded(
                      child: Text(l.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14.5)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: Sp.md),
            _ActionButton(ticket: ticket),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final _Viz viz;
  const _StatusPill({required this.viz});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 5),
      decoration: BoxDecoration(
        color: viz.soft,
        borderRadius: BorderRadius.circular(Rad.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: viz.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: Sp.xs),
          Text(viz.label,
              style: TextStyle(
                  color: viz.color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
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
    final color = urgent ? const Color(0xFFD92D20) : BrandColors.inkSoft;
    final bg = urgent ? const Color(0x1AD92D20) : BrandColors.surfaceAlt;
    Widget pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(Rad.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(urgent ? Icons.local_fire_department : Icons.timer_outlined,
              size: 14, color: color),
          const SizedBox(width: Sp.xs),
          Text('${minutes}m',
              style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
    if (urgent) {
      pill = pill
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(end: 1.07, duration: 700.ms, curve: Curves.easeInOut);
    }
    return pill;
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
        if (context.mounted) {
          showError(context, 'No se pudo actualizar la comanda');
        }
      }
    }

    final repo = ref.read(serviceRepositoryProvider);

    if (ticket.status == 'pendiente' && isStation) {
      return GradientButton(
        label: 'Iniciar preparación',
        icon: Icons.play_arrow_rounded,
        height: 48,
        onTap: () => run(() => repo.advanceTicket(ticket.id)),
      );
    }
    if (ticket.status == 'en_proceso' && isStation) {
      return GradientButton(
        label: 'Marcar listo',
        icon: Icons.check_rounded,
        height: 48,
        onTap: () => run(() => repo.advanceTicket(ticket.id)),
      );
    }
    if (ticket.status == 'lista' && isWaiter) {
      return GradientButton(
        label: 'Entregar',
        icon: Icons.room_service_rounded,
        height: 48,
        colors: const [Color(0xFF2EA043), Color(0xFF1A7F37)],
        glowColor: const Color(0xFF2EA043),
        onTap: () => run(() => repo.deliverTicket(ticket.id)),
      );
    }
    return const SizedBox.shrink();
  }
}

typedef _Viz = ({Color color, Color soft, String label});

_Viz _statusViz(String s) {
  switch (s) {
    case 'pendiente':
      return (
        color: const Color(0xFFF59E0B),
        soft: const Color(0x1AF59E0B),
        label: 'Pendiente'
      );
    case 'en_proceso':
      return (
        color: const Color(0xFF3B82F6),
        soft: const Color(0x1A3B82F6),
        label: 'En preparación'
      );
    case 'lista':
      return (
        color: const Color(0xFF22C55E),
        soft: const Color(0x1A22C55E),
        label: 'Lista'
      );
    default:
      return (
        color: BrandColors.inkFaint,
        soft: BrandColors.surfaceAlt,
        label: s
      );
  }
}
