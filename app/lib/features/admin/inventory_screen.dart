import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_repository.dart';
import '../../models/admin.dart';
import '../../state/admin_providers.dart';
import '../../theme/colors.dart';
import '../../widgets/common.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _onlyLow = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(inventoryProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
      data: (items) {
        final list = _onlyLow ? items.where((i) => i.isLow).toList() : items;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Solo bajo mínimo'),
                    selected: _onlyLow,
                    onSelected: (v) => setState(() => _onlyLow = v),
                  ),
                  const Spacer(),
                  Text('${items.where((i) => i.isLow).length} bajo mínimo',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _InventoryTile(item: list[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InventoryTile extends ConsumerWidget {
  final InventoryItem item;
  const _InventoryTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.semantic;
    final scheme = Theme.of(context).colorScheme;
    final badge = item.isLow
        ? (
            bg: scheme.errorContainer,
            fg: scheme.onErrorContainer,
            label: 'Bajo'
          )
        : (bg: s.successContainer, fg: s.onSuccessContainer, label: 'OK');

    return Card(
      child: ListTile(
        title: Text(item.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${item.category} · ${item.stock} ${item.unit} (mín ${item.minStock})'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusBadge(label: badge.label, bg: badge.bg, fg: badge.fg),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Auto-pedido',
              child: Switch(
                value: item.autoReorder,
                onChanged: (v) => ref
                    .read(adminRepositoryProvider)
                    .setAutoReorder(item.id, v)
                    .then(
                      (_) => ref.invalidate(inventoryProvider),
                    ),
              ),
            ),
          ],
        ),
        onTap: () => _editStock(context, ref),
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
