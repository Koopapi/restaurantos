import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_repository.dart';
import '../../models/admin.dart';
import '../../models/app_config.dart';
import '../../state/admin_providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/ui_kit.dart';

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
        padding: const EdgeInsets.all(Sp.xl),
        children: [
          Text('Compras Inteligentes',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const Text('Sugerencias automáticas según el inventario bajo mínimo',
              style: TextStyle(color: BrandColors.inkSoft)),
          const SizedBox(height: Sp.lg),
          sugg.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
            data: (data) => _Suggestions(data: data),
          ),
          const SizedBox(height: Sp.xl),
          const Text('Órdenes de compra',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: Sp.md),
          orders.when(
            loading: () => const SizedBox(),
            error: (e, _) => Text('$e'),
            data: (list) => list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(Sp.md),
                    child: Text('Sin órdenes todavía',
                        style: TextStyle(color: BrandColors.inkFaint)))
                : Column(
                    children: [
                      for (final o in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Sp.md),
                          child: _OrderCard(order: o),
                        )
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

({Color color, Color soft, String label}) _urgencyViz(String urgency) {
  switch (urgency) {
    case 'alta':
      return (
        color: const Color(0xFFEF4444),
        soft: const Color(0x1AEF4444),
        label: 'Alta'
      );
    case 'media':
      return (
        color: const Color(0xFFF59E0B),
        soft: const Color(0x1AF59E0B),
        label: 'Media'
      );
    default:
      return (
        color: BrandColors.inkFaint,
        soft: BrandColors.surfaceAlt,
        label: 'Baja'
      );
  }
}

class _Suggestions extends ConsumerWidget {
  final ({List<PurchaseSuggestion> items, num totalEst}) data;
  const _Suggestions({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (data.items.isEmpty) {
      return const AppCard(
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF22C55E)),
            SizedBox(width: Sp.md),
            Expanded(
                child: Text('Todo el inventario está por encima del mínimo.')),
          ],
        ),
      );
    }
    return AppCard(
      padding: const EdgeInsets.all(Sp.lg),
      child: Column(
        children: [
          for (final s in data.items) ...[
            Row(
              children: [
                Builder(builder: (_) {
                  final v = _urgencyViz(s.urgency);
                  return Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: v.color, shape: BoxShape.circle),
                  );
                }),
                const SizedBox(width: Sp.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                          'Sugerido: ${s.suggestedQty}${s.supplier != null ? ' · ${s.supplier}' : ''}',
                          style: const TextStyle(
                              color: BrandColors.inkFaint, fontSize: 12)),
                    ],
                  ),
                ),
                Text(money(s.estCost),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: BrandColors.orangeInk)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Sp.md),
              child: Divider(height: 1),
            ),
          ],
          Row(
            children: [
              const Text('Total estimado',
                  style: TextStyle(color: BrandColors.inkSoft)),
              const SizedBox(width: Sp.sm),
              Text(money(data.totalEst),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const Spacer(),
              SizedBox(
                width: 200,
                child: GradientButton(
                  label: 'Crear orden',
                  icon: Icons.add_shopping_cart,
                  height: 48,
                  onTap: () => _createOrder(context, ref),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _createOrder(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(adminRepositoryProvider).createOrder(
            data.items
                .map((s) =>
                    (inventoryItemId: s.inventoryItemId, qty: s.suggestedQty))
                .toList(),
          );
      ref.invalidate(ordersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orden creada (sugerida)')),
        );
      }
    } catch (e) {
      if (context.mounted) showError(context, 'No se pudo crear la orden');
    }
  }
}

({Color color, Color soft, String label}) _orderViz(String status) {
  switch (status) {
    case 'aprobada':
      return (
        color: const Color(0xFF3B82F6),
        soft: const Color(0x1A3B82F6),
        label: 'Aprobada'
      );
    case 'recibida':
      return (
        color: const Color(0xFF22C55E),
        soft: const Color(0x1A22C55E),
        label: 'Recibida'
      );
    default:
      return (
        color: const Color(0xFFF59E0B),
        soft: const Color(0x1AF59E0B),
        label: 'Sugerida'
      );
  }
}

class _OrderCard extends ConsumerWidget {
  final PurchaseOrder order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(adminRepositoryProvider);
    final v = _orderViz(order.status);
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

    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.xs),
          title: Text('${money(order.total)} · ${order.items.length} insumos',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: Sp.sm, vertical: 2),
                decoration: BoxDecoration(
                    color: v.soft,
                    borderRadius: BorderRadius.circular(Rad.pill)),
                child: Text(v.label,
                    style: TextStyle(
                        color: v.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(Sp.lg, 0, Sp.lg, Sp.md),
          children: [
            for (final it in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(it.name)),
                    Text('${it.qty}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            const SizedBox(height: Sp.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (order.status == 'sugerida')
                  FilledButton(
                      onPressed: () => act(() => repo.approveOrder(order.id)),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44)),
                      child: const Text('Aprobar')),
                if (order.status == 'aprobada')
                  FilledButton.icon(
                    icon: const Icon(Icons.inventory_2_outlined, size: 18),
                    label: const Text('Recibir (suma stock)'),
                    style:
                        FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: () => act(() => repo.receiveOrder(order.id)),
                  ),
                if (order.status == 'recibida')
                  const Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Color(0xFF22C55E), size: 18),
                      SizedBox(width: 4),
                      Text('Recibida',
                          style: TextStyle(
                              color: Color(0xFF1E7D34),
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
