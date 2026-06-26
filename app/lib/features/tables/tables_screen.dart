import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/home/destinations.dart';
import '../../models/restaurant_table.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// Salón de mesas: grid coloreado por estado (spec §7). El mesero abre/continúa
/// una cuenta; la hostess asigna una mesa libre (→ "por atender").
class TablesScreen extends ConsumerStatefulWidget {
  const TablesScreen({super.key});

  @override
  ConsumerState<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends ConsumerState<TablesScreen> {
  String _filter = 'todas';

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesProvider);
    final theme = Theme.of(context);

    return tablesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
      data: (tables) {
        final filtered = _filter == 'todas'
            ? tables
            : tables.where((t) => t.status == _filter).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final f in const [
                    ('todas', 'Todas'),
                    ('disponible', 'Disponible'),
                    ('ocupada', 'Ocupada'),
                    ('reservada', 'Reservada'),
                    ('por_atender', 'Por atender'),
                    ('fuera_servicio', 'Fuera de servicio'),
                  ])
                    ChoiceChip(
                      label: Text(f.$2),
                      selected: _filter == f.$1,
                      onSelected: (_) => setState(() => _filter = f.$1),
                    ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyState(
                      icon: Icons.table_restaurant, message: 'Sin mesas')
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 240,
                        mainAxisExtent: 132,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _TableTile(
                        table: filtered[i],
                        onTap: () => _onTapTable(filtered[i]),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('${tables.length} mesas',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onTapTable(RestaurantTable table) async {
    final role = ref.read(authControllerProvider).employee?.role ?? '';
    final isWaiter = role == 'mesero' || role == 'gerente' || role == 'admin';
    final isHostess = role == 'hostess' || role == 'gerente' || role == 'admin';

    if (table.status == 'fuera_servicio') return;

    // Mesa ocupada → ir a su cuenta (POS) para seguir o cobrar.
    if (table.status == 'ocupada' && isWaiter) {
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
      return;
    }

    // Mesa libre/por atender → mesero abre cuenta; hostess asigna.
    if (table.isFree || table.status == 'por_atender') {
      final guests = await _askGuests(table);
      if (guests == null || !mounted) return;
      try {
        if (isWaiter) {
          final acc = await ref.read(serviceRepositoryProvider).createAccount(
              serviceType: 'mesa', tableId: table.id, guests: guests);
          ref.invalidate(tablesProvider);
          _goToPos(acc.id);
        } else if (isHostess) {
          await ref
              .read(serviceRepositoryProvider)
              .assignTable(table.id, guests: guests);
          ref.invalidate(tablesProvider);
        }
      } catch (e) {
        if (mounted) showError(context, _msg(e));
      }
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
              const SizedBox(width: 16),
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

class _TableTile extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback onTap;
  const _TableTile({required this.table, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = tableStatusStyle(context, table.status);
    return Card(
      color: style.bg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mesa ${table.number}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: style.fg)),
              const SizedBox(height: 4),
              Text('${table.capacity} asientos',
                  style: TextStyle(color: style.fg.withValues(alpha: 0.8))),
              const Spacer(),
              StatusBadge(
                  label: style.label,
                  bg: style.fg.withValues(alpha: 0.15),
                  fg: style.fg),
            ],
          ),
        ),
      ),
    );
  }
}
