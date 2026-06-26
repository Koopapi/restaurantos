import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_repository.dart';
import '../../models/app_config.dart';
import '../../models/menu_item.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// Administración del menú: disponibilidad y precio por platillo.
class MenuAdminScreen extends ConsumerWidget {
  const MenuAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(menuProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
      data: (items) {
        final byCat = <String, List<MenuItem>>{};
        for (final m in items) {
          byCat.putIfAbsent(m.category, () => []).add(m);
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final entry in byCat.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                child: Text(entry.key,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              for (final item in entry.value) _MenuTile(item: item),
            ],
          ],
        );
      },
    );
  }
}

class _MenuTile extends ConsumerWidget {
  final MenuItem item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: Text(item.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${money(item.price)} · ${item.station}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar precio',
              onPressed: () => _editPrice(context, ref),
            ),
            Tooltip(
              message: 'Disponible',
              child: Switch(
                value: item.available,
                onChanged: (v) async {
                  await ref
                      .read(adminRepositoryProvider)
                      .setMenuAvailability(item.id, v);
                  ref.invalidate(menuProvider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editPrice(BuildContext context, WidgetRef ref) async {
    final c = TextEditingController(text: '${item.price}');
    final result = await showDialog<num>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item.name),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration:
              const InputDecoration(labelText: 'Precio', prefixText: '\$'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, num.tryParse(c.text)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result != null) {
      await ref
          .read(adminRepositoryProvider)
          .updateMenuItem(item.id, price: result);
      ref.invalidate(menuProvider);
    }
  }
}
