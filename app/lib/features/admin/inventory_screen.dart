import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_repository.dart';
import '../../models/admin.dart';
import '../../models/app_config.dart';
import '../../state/admin_providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/ui_kit.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _onlyLow = false;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(inventoryProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
      data: (items) {
        final q = _search.trim().toLowerCase();
        final list = items.where((i) {
          if (_onlyLow && !i.isLow) return false;
          if (q.isNotEmpty) {
            return i.name.toLowerCase().contains(q) ||
                i.category.toLowerCase().contains(q) ||
                (i.supplier?.toLowerCase().contains(q) ?? false);
          }
          return true;
        }).toList();

        final lowCount = items.where((i) => i.isLow).length;
        final autoCount = items.where((i) => i.autoReorder).length;
        final value = items.fold<num>(0, (s, i) => s + i.stock * i.cost);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.lg, Sp.xl, Sp.sm),
              child: Wrap(
                spacing: Sp.md,
                runSpacing: Sp.md,
                children: [
                  _Stat(value: '${items.length}', label: 'Artículos', color: BrandColors.ink),
                  _Stat(value: '$lowCount', label: 'Bajo mínimo', color: const Color(0xFFEF4444), alert: lowCount > 0),
                  _Stat(value: '$autoCount', label: 'Auto-pedido', color: const Color(0xFF3B82F6)),
                  _Stat(value: money(value), label: 'Valor', color: BrandColors.orangeInk),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.xl, 0, Sp.xl, Sp.md),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: const InputDecoration(
                        hintText: 'Buscar insumo, categoría o proveedor…',
                        prefixIcon:
                            Icon(Icons.search, color: BrandColors.inkFaint),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: Sp.md),
                  _Toggle(
                    label: 'Bajo mínimo',
                    selected: _onlyLow,
                    onTap: () => setState(() => _onlyLow = !_onlyLow),
                  ),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const EmptyState(
                      icon: Icons.inventory_2, message: 'Sin insumos')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(Sp.xl, 0, Sp.xl, Sp.xl),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: Sp.sm),
                      itemBuilder: (_, i) => _InventoryTile(item: list[i])
                          .animate()
                          .fadeIn(duration: 200.ms, delay: (i * 18).ms),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool alert;
  const _Stat(
      {required this.value,
      required this.label,
      required this.color,
      this.alert = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(Sp.lg),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Rad.lg),
        boxShadow: Shadows.card,
        border: alert
            ? Border.all(color: const Color(0xFFEF4444), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: BrandColors.inkSoft, fontSize: 13)),
          const SizedBox(height: Sp.xs),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Toggle(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Dur.fast,
        height: 48,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: Sp.lg),
        decoration: BoxDecoration(
          color: selected ? BrandColors.orange : BrandColors.surface,
          borderRadius: BorderRadius.circular(Rad.md),
          boxShadow: selected ? Shadows.glow(BrandColors.orange) : Shadows.soft,
          border: Border.all(
              color: selected ? BrandColors.orange : BrandColors.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 18,
                color: selected ? Colors.white : BrandColors.inkSoft),
            const SizedBox(width: Sp.xs),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : BrandColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _InventoryTile extends ConsumerWidget {
  final InventoryItem item;
  const _InventoryTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final low = item.isLow;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
      onTap: () => _editStock(context, ref),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(
                    '${item.category}${item.supplier != null ? ' · ${item.supplier}' : ''}',
                    style: const TextStyle(
                        color: BrandColors.inkFaint, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text('${item.stock} ${item.unit}',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: low ? const Color(0xFFB45309) : BrandColors.ink)),
                const SizedBox(width: 6),
                Text('· mín ${item.minStock}',
                    style: const TextStyle(
                        color: BrandColors.inkFaint, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 4),
            decoration: BoxDecoration(
              color: low ? const Color(0x1AF59E0B) : const Color(0x1A22C55E),
              borderRadius: BorderRadius.circular(Rad.pill),
            ),
            child: Text(low ? 'Bajo' : 'OK',
                style: TextStyle(
                    color: low
                        ? const Color(0xFFB45309)
                        : const Color(0xFF1E7D34),
                    fontWeight: FontWeight.w800,
                    fontSize: 12)),
          ),
          const SizedBox(width: Sp.md),
          Tooltip(
            message: 'Auto-pedido',
            child: Switch(
              value: item.autoReorder,
              onChanged: (v) => ref
                  .read(adminRepositoryProvider)
                  .setAutoReorder(item.id, v)
                  .then((_) => ref.invalidate(inventoryProvider)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editStock(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: '${item.stock}');
    final result = await showDialog<num>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.name),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Stock (${item.unit})'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, num.tryParse(controller.text)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result != null) {
      await ref
          .read(adminRepositoryProvider)
          .updateInventory(item.id, stock: result);
      ref.invalidate(inventoryProvider);
    }
  }
}
