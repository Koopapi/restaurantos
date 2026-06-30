import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_repository.dart';
import '../../models/app_config.dart';
import '../../models/menu_item.dart';
import '../../state/admin_providers.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/ui_kit.dart';
import 'crear_menu_screen.dart';

/// Menú y Platillos: menú activo, catálogo por categoría, detalle/edición y
/// acceso a Crear Nuevo Menú.
class MenuAdminScreen extends ConsumerStatefulWidget {
  /// Selección inicial del panel de detalle (aux de preview/test).
  final String? initialSelectedId;
  const MenuAdminScreen({super.key, this.initialSelectedId});

  @override
  ConsumerState<MenuAdminScreen> createState() => _MenuAdminScreenState();
}

class _MenuAdminScreenState extends ConsumerState<MenuAdminScreen> {
  String? _selectedId;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialSelectedId;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(menuProvider);
    final collections = ref.watch(collectionsProvider).value ?? const [];
    final wide = MediaQuery.sizeOf(context).width >= 840;

    String activeName = 'Menú principal';
    for (final c in collections) {
      if (c.active) {
        activeName = c.name;
        break;
      }
    }

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
      data: (items) {
        final q = _search.trim().toLowerCase();
        final filtered = q.isEmpty
            ? items
            : items
                .where((m) =>
                    m.name.toLowerCase().contains(q) ||
                    m.category.toLowerCase().contains(q))
                .toList();
        final byCat = <String, List<MenuItem>>{};
        for (final m in filtered) {
          byCat.putIfAbsent(m.category, () => []).add(m);
        }

        final list = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.lg, Sp.xl, Sp.sm),
              child: Row(
                children: [
                  Text(activeName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(width: Sp.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Sp.md, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0x1A22C55E),
                        borderRadius: BorderRadius.circular(Rad.pill)),
                    child: const Text('Activo',
                        style: TextStyle(
                            color: Color(0xFF1E7D34),
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const CrearMenuScreen()),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Nuevo Menú'),
                    style:
                        FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.xl, 0, Sp.xl, Sp.md),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                  hintText: 'Buscar platillo o categoría…',
                  prefixIcon: Icon(Icons.search, color: BrandColors.inkFaint),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Sp.xl, 0, Sp.xl, Sp.xl),
                children: [
                  for (final entry in byCat.entries) ...[
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(Sp.xs, Sp.md, 0, Sp.sm),
                      child: Text(entry.key,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: BrandColors.inkSoft)),
                    ),
                    for (final item in entry.value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Sp.sm),
                        child: _MenuTile(
                          item: item,
                          selected: wide && item.id == _selectedId,
                          onTap: () {
                            if (wide) {
                              setState(() => _selectedId = item.id);
                            } else {
                              _edit(context, item);
                            }
                          },
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        );

        if (!wide) return list;

        MenuItem? selected;
        for (final m in items) {
          if (m.id == _selectedId) {
            selected = m;
            break;
          }
        }
        return Row(
          children: [
            Expanded(child: list),
            Container(
              width: 340,
              margin: const EdgeInsets.fromLTRB(0, Sp.lg, Sp.lg, Sp.lg),
              decoration: BoxDecoration(
                color: BrandColors.surface,
                borderRadius: BorderRadius.circular(Rad.lg),
                boxShadow: Shadows.card,
              ),
              clipBehavior: Clip.antiAlias,
              child: _DetailPanel(item: selected, onEdit: _edit),
            ),
          ],
        );
      },
    );
  }

  Future<void> _edit(BuildContext context, MenuItem item) async {
    final name = TextEditingController(text: item.name);
    final price = TextEditingController(text: '${item.price}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar platillo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nombre')),
            const SizedBox(height: Sp.md),
            TextField(
              controller: price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Precio', prefixText: '\$ '),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(adminRepositoryProvider).updateMenuItem(
            item.id,
            name: name.text.trim(),
            price: num.tryParse(price.text),
          );
      ref.invalidate(menuProvider);
    }
  }
}

class _MenuTile extends ConsumerWidget {
  final MenuItem item;
  final bool selected;
  final VoidCallback onTap;
  const _MenuTile(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
      onTap: onTap,
      border: selected
          ? const BorderSide(color: BrandColors.orange, width: 1.5)
          : BorderSide.none,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BrandColors.orangeSoft,
              borderRadius: BorderRadius.circular(Rad.md),
            ),
            child: Icon(
                item.station == 'barra'
                    ? Icons.local_bar
                    : Icons.set_meal_outlined,
                color: BrandColors.orangeInk,
                size: 20),
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(item.station,
                    style: const TextStyle(
                        color: BrandColors.inkFaint, fontSize: 12)),
              ],
            ),
          ),
          Text(money(item.price),
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: BrandColors.orangeInk)),
          const SizedBox(width: Sp.md),
          Tooltip(
            message: 'Disponible en POS',
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
    );
  }
}

class _DetailPanel extends ConsumerWidget {
  final MenuItem? item;
  final Future<void> Function(BuildContext, MenuItem) onEdit;
  const _DetailPanel({required this.item, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = item;
    if (m == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(Sp.xl),
          child: EmptyState(
              icon: Icons.restaurant_menu,
              message: 'Toca un platillo para ver detalle'),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(Sp.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.name,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: Sp.xs),
          Text('${m.category} · ${m.station}',
              style: const TextStyle(color: BrandColors.inkSoft)),
          const SizedBox(height: Sp.md),
          Text(money(m.price),
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: BrandColors.orangeInk)),
          if (m.description.isNotEmpty) ...[
            const SizedBox(height: Sp.md),
            Text(m.description,
                style: const TextStyle(color: BrandColors.inkSoft)),
          ],
          if (m.ingredients.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Sp.lg),
              child: Divider(height: 1),
            ),
            const Text('Ingredientes',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: Sp.sm),
            Wrap(
              spacing: Sp.sm,
              runSpacing: Sp.sm,
              children: [
                for (final ing in m.ingredients)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Sp.md, vertical: 6),
                    decoration: BoxDecoration(
                        color: BrandColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(Rad.pill)),
                    child: Text(ing, style: const TextStyle(fontSize: 13)),
                  ),
              ],
            ),
          ],
          const Spacer(),
          Row(
            children: [
              const Text('Disponible en POS',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Switch(
                value: m.available,
                onChanged: (v) async {
                  await ref
                      .read(adminRepositoryProvider)
                      .setMenuAvailability(m.id, v);
                  ref.invalidate(menuProvider);
                },
              ),
            ],
          ),
          const SizedBox(height: Sp.sm),
          GradientButton(
            label: 'Editar platillo',
            icon: Icons.edit,
            onTap: () => onEdit(context, m),
          ),
        ],
      ),
    );
  }
}
