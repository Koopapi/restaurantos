import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/home/destinations.dart';
import '../../models/restaurant_table.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/ui_kit.dart';

/// Salón de mesas: mapa coloreado por estado + panel de detalle (tablet).
/// El mesero abre/continúa una cuenta; la hostess asigna una mesa libre.
class TablesScreen extends ConsumerStatefulWidget {
  /// Selección inicial del panel de detalle (aux de preview/test).
  final String? initialSelectedId;
  const TablesScreen({super.key, this.initialSelectedId});

  @override
  ConsumerState<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends ConsumerState<TablesScreen> {
  String _filter = 'todas';
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialSelectedId;
  }

  static const _filters = [
    ('todas', 'Todas'),
    ('disponible', 'Disponible'),
    ('ocupada', 'Ocupada'),
    ('reservada', 'Reservada'),
    ('por_atender', 'Por atender'),
    ('fuera_servicio', 'Fuera de servicio'),
  ];

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesProvider);
    final wide = MediaQuery.sizeOf(context).width >= 840;

    return tablesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
      data: (tables) {
        final filtered = _filter == 'todas'
            ? tables
            : tables.where((t) => t.status == _filter).toList();
        int count(String s) => tables.where((t) => t.status == s).length;

        final grid = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.lg, Sp.lg, Sp.sm),
              child: Wrap(
                spacing: Sp.sm,
                runSpacing: Sp.sm,
                children: [
                  _Stat(
                      label: 'Total',
                      value: tables.length,
                      color: BrandColors.ink),
                  _Stat(
                      label: 'Ocupadas',
                      value: count('ocupada'),
                      color: const Color(0xFFEF4444)),
                  _Stat(
                      label: 'Disponibles',
                      value: count('disponible'),
                      color: const Color(0xFF22C55E)),
                  _Stat(
                      label: 'Reservadas',
                      value: count('reservada'),
                      color: const Color(0xFF3B82F6)),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Sp.xl),
                children: [
                  for (final f in _filters)
                    Padding(
                      padding: const EdgeInsets.only(right: Sp.sm),
                      child: _FilterChip(
                        label: f.$2,
                        selected: _filter == f.$1,
                        onTap: () => setState(() => _filter = f.$1),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyState(
                      icon: Icons.table_restaurant, message: 'Sin mesas')
                  : GridView.builder(
                      padding: const EdgeInsets.all(Sp.xl),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        mainAxisExtent: 130,
                        crossAxisSpacing: Sp.md,
                        mainAxisSpacing: Sp.md,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _TableTile(
                        table: filtered[i],
                        selected: wide && filtered[i].id == _selectedId,
                        onTap: () => _onTapTile(filtered[i], wide),
                      )
                          .animate()
                          .fadeIn(duration: 220.ms, delay: (i * 20).ms)
                          .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
                    ),
            ),
          ],
        );

        if (!wide) return grid;

        RestaurantTable? selected;
        for (final t in tables) {
          if (t.id == _selectedId) {
            selected = t;
            break;
          }
        }
        return Row(
          children: [
            Expanded(child: grid),
            Container(
              width: 340,
              margin: const EdgeInsets.fromLTRB(0, Sp.lg, Sp.lg, Sp.lg),
              decoration: BoxDecoration(
                color: BrandColors.surface,
                borderRadius: BorderRadius.circular(Rad.lg),
                boxShadow: Shadows.card,
              ),
              clipBehavior: Clip.antiAlias,
              child: _DetailPanel(
                table: selected,
                action: selected == null ? null : _primaryAction(selected),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onTapTile(RestaurantTable table, bool wide) {
    if (wide) {
      setState(() => _selectedId = table.id);
    } else {
      _primaryAction(table).onTap?.call();
    }
  }

  /// Acción principal disponible para una mesa según estado + rol.
  ({String label, IconData icon, VoidCallback? onTap}) _primaryAction(
      RestaurantTable table) {
    final role = ref.read(authControllerProvider).employee?.role ?? '';
    final isWaiter = role == 'mesero' || role == 'gerente' || role == 'admin';
    final isHostess = role == 'hostess' || role == 'gerente' || role == 'admin';

    if (table.status == 'ocupada' && isWaiter) {
      return (
        label: 'Ver cuenta',
        icon: Icons.receipt_long,
        onTap: () => _openOccupied(table)
      );
    }
    if ((table.isFree || table.status == 'por_atender') && isWaiter) {
      return (
        label: 'Abrir cuenta',
        icon: Icons.add,
        onTap: () => _openOrAssign(table, asWaiter: true)
      );
    }
    if ((table.isFree || table.status == 'por_atender') && isHostess) {
      return (
        label: 'Asignar mesa',
        icon: Icons.how_to_reg,
        onTap: () => _openOrAssign(table, asWaiter: false)
      );
    }
    return (label: 'Sin acciones', icon: Icons.block, onTap: null);
  }

  Future<void> _openOccupied(RestaurantTable table) async {
    final accounts = await ref.read(openAccountsProvider.future);
    String? accId;
    for (final a in accounts) {
      if (a.tableId == table.id) {
        accId = a.id;
        break;
      }
    }
    if (!mounted) return;
    if (accId != null) {
      _goToPos(accId);
    } else {
      showError(context, 'No se encontró una cuenta abierta para esta mesa');
    }
  }

  Future<void> _openOrAssign(RestaurantTable table,
      {required bool asWaiter}) async {
    final guests = await _askGuests(table);
    if (guests == null || !mounted) return;
    try {
      if (asWaiter) {
        final acc = await ref.read(serviceRepositoryProvider).createAccount(
            serviceType: 'mesa', tableId: table.id, guests: guests);
        ref.invalidate(tablesProvider);
        _goToPos(acc.id);
      } else {
        await ref
            .read(serviceRepositoryProvider)
            .assignTable(table.id, guests: guests);
        ref.invalidate(tablesProvider);
      }
    } catch (e) {
      if (mounted) showError(context, _msg(e));
    }
  }

  void _goToPos(String accountId) {
    ref.read(currentAccountIdProvider.notifier).state = accountId;
    final role = ref.read(authControllerProvider).employee?.role ?? '';
    final idx = destinationsForRole(role).indexWhere((d) => d.label == 'POS');
    if (idx >= 0) ref.read(navIndexProvider.notifier).state = idx;
  }

  Future<int?> _askGuests(RestaurantTable table) {
    var guests = table.party ?? 2;
    return showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Mesa ${table.number}'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Comensales'),
              const SizedBox(width: Sp.lg),
              QtyStepper(
                value: guests,
                onRemove: guests > 1 ? () => setLocal(() => guests--) : null,
                onAdd: guests < table.capacity
                    ? () => setLocal(() => guests++)
                    : null,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, guests),
                child: const Text('Continuar')),
          ],
        ),
      ),
    );
  }
}

String _msg(Object e) {
  final s = e.toString();
  return s.contains('CONFLICT') || s.contains('ocupada')
      ? 'La mesa ya está ocupada'
      : 'No se pudo completar la acción';
}

typedef _Viz = ({Color color, Color soft, String label, IconData icon});

_Viz _tableViz(String status) {
  switch (status) {
    case 'disponible':
      return (
        color: const Color(0xFF22C55E),
        soft: const Color(0x1A22C55E),
        label: 'Disponible',
        icon: Icons.check_circle
      );
    case 'ocupada':
      return (
        color: const Color(0xFFEF4444),
        soft: const Color(0x1AEF4444),
        label: 'Ocupada',
        icon: Icons.groups
      );
    case 'reservada':
      return (
        color: const Color(0xFF3B82F6),
        soft: const Color(0x1A3B82F6),
        label: 'Reservada',
        icon: Icons.event
      );
    case 'por_atender':
      return (
        color: const Color(0xFFF59E0B),
        soft: const Color(0x1AF59E0B),
        label: 'Por atender',
        icon: Icons.notifications_active
      );
    default:
      return (
        color: BrandColors.inkFaint,
        soft: BrandColors.surfaceAlt,
        label: 'Fuera de servicio',
        icon: Icons.block
      );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Rad.pill),
        boxShadow: Shadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(width: Sp.xs),
          Text(label,
              style: const TextStyle(
                  color: BrandColors.inkSoft, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Dur.fast,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: Sp.lg),
        decoration: BoxDecoration(
          color: selected ? BrandColors.orange : BrandColors.surface,
          borderRadius: BorderRadius.circular(Rad.pill),
          boxShadow: selected ? Shadows.glow(BrandColors.orange) : Shadows.soft,
          border: Border.all(
              color: selected ? BrandColors.orange : BrandColors.hairline),
        ),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : BrandColors.inkSoft)),
      ),
    );
  }
}

class _TableTile extends StatelessWidget {
  final RestaurantTable table;
  final bool selected;
  final VoidCallback onTap;
  const _TableTile(
      {required this.table, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final viz = _tableViz(table.status);
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Dur.fast,
        padding: const EdgeInsets.all(Sp.lg),
        decoration: BoxDecoration(
          color: viz.soft,
          borderRadius: BorderRadius.circular(Rad.lg),
          border: Border.all(color: viz.color, width: selected ? 2.5 : 1.5),
          boxShadow: selected ? Shadows.glow(viz.color, opacity: 0.3) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Mesa ${table.number}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                Icon(viz.icon, size: 18, color: viz.color),
              ],
            ),
            const SizedBox(height: 2),
            Text('${table.capacity} asientos',
                style:
                    const TextStyle(color: BrandColors.inkSoft, fontSize: 13)),
            const Spacer(),
            Text(
              table.status == 'reservada' && table.reserveTime != null
                  ? 'Reservada ${table.reserveTime}'
                  : viz.label,
              style: TextStyle(
                  color: viz.color, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  final RestaurantTable? table;
  final ({String label, IconData icon, VoidCallback? onTap})? action;
  const _DetailPanel({required this.table, required this.action});

  @override
  Widget build(BuildContext context) {
    final t = table;
    if (t == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(Sp.xl),
          child: EmptyState(
              icon: Icons.touch_app, message: 'Toca una mesa para ver detalle'),
        ),
      );
    }
    final viz = _tableViz(t.status);
    return Padding(
      padding: const EdgeInsets.all(Sp.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detalle de Mesa',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: BrandColors.inkSoft)),
          const SizedBox(height: Sp.lg),
          Row(
            children: [
              Text('Mesa ${t.number}',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 6),
                decoration: BoxDecoration(
                    color: viz.soft,
                    borderRadius: BorderRadius.circular(Rad.pill)),
                child: Text(viz.label,
                    style: TextStyle(
                        color: viz.color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Sp.lg),
            child: Divider(height: 1),
          ),
          _info('Capacidad', '${t.capacity} asientos'),
          if (t.party != null) _info('Comensales', '${t.party}'),
          if (t.reserveName != null) _info('Reserva', t.reserveName!),
          if (t.reserveTime != null) _info('Hora', t.reserveTime!),
          const Spacer(),
          if (action != null)
            GradientButton(
              label: action!.label,
              icon: action!.icon,
              onTap: action!.onTap,
            ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Sp.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: BrandColors.inkSoft)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
