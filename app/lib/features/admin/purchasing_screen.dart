import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_repository.dart';
import '../../models/admin.dart';
import '../../models/app_config.dart';
import '../../state/admin_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';

/// Compras IA: sugerencias (heurística del backend) + órdenes de compra.
class PurchasingScreen extends ConsumerWidget {
  const PurchasingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sugg = ref.watch(suggestionsProvider);
    final orders = ref.watch(ordersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(suggestionsProvider);
        ref.invalidate(ordersProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Sugerencias de compra',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          sugg.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
            data: (data) => _Suggestions(data: data),
          ),
          const SizedBox(height: 24),
          Text('Órdenes de compra',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          orders.when(
            loading: () => const SizedBox(),
            error: (e, _) => Text('$e'),
            data: (list) => list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Sin órdenes todavía'))
                : Column(
                    children: [for (final o in list) _OrderTile(order: o)]),
          ),
        ],
      ),
    );
  }
}

class _Suggestions extends ConsumerWidget {
  final ({List<PurchaseSuggestion> items, num totalEst}) data;
  const _Suggestions({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (data.items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Todo el inventario está por encima del mínimo. 🎉'),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          for (final s in data.items)
            ListTile(
              leading: _urgencyDot(context, s.urgency),
              title: Text(s.name),
              subtitle: Text(
                  'Sugerido: ${s.suggestedQty}${s.supplier != null ? " · ${s.supplier}" : ""}'),
              trailing: Text(money(s.estCost),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text('Total estimado: ${money(data.totalEst)}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Crear orden'),
                  onPressed: () async {
                    try {
                      await ref.read(adminRepositoryProvider).createOrder(
                            data.items
                                .map((s) => (
                                      inventoryItemId: s.inventoryItemId,
                                      qty: s.suggestedQty
                                    ))
                                .toList(),
                          );
                      ref.invalidate(ordersProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Orden creada (sugerida)')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showError(context, 'No se pudo crear la orden');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _urgencyDot(BuildContext context, String urgency) {
    final scheme = Theme.of(context).colorScheme;
    final color = urgency == 'alta'
        ? scheme.error
        : urgency == 'media'
            ? context.semantic.warning
            : scheme.outline;
    return CircleAvatar(radius: 6, backgroundColor: color);
  }
}

class _OrderTile extends ConsumerWidget {
  final PurchaseOrder order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(adminRepositoryProvider);
    Future<void> act(Future<void> Function() f) async {
      try {
        await f();
        ref.invalidate(ordersProvider);
        ref.invalidate(inventoryProvider);
      } catch (e) {
        if (context.mounted) {
          showError(context, 'No se pudo actualizar la orden');
        }
      }
    }

    return Card(
      child: ExpansionTile(
        title: Text('${money(order.total)} · ${order.items.length} insumos'),
        subtitle: Text('Estado: ${order.status}'),
        children: [
          for (final it in order.items)
            ListTile(
                dense: true, title: Text(it.name), trailing: Text('${it.qty}')),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (order.status == 'sugerida')
                  FilledButton(
                      onPressed: () => act(() => repo.approveOrder(order.id)),
                      child: const Text('Aprobar')),
                if (order.status == 'aprobada')
                  FilledButton.icon(
                    icon: const Icon(Icons.inventory),
                    label: const Text('Recibir (suma stock)'),
                    onPressed: () => act(() => repo.receiveOrder(order.id)),
                  ),
                if (order.status == 'recibida') const Text('Recibida ✓'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
