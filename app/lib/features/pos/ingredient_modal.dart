import 'package:flutter/material.dart';

import '../../models/menu_item.dart';
import '../../widgets/common.dart';

/// Resultado de personalizar un platillo antes de agregarlo.
class CustomizeResult {
  final int qty;
  final List<String> removedIngredients;
  final List<Modifier> addedModifiers;
  final String? notes;
  const CustomizeResult({
    required this.qty,
    required this.removedIngredients,
    required this.addedModifiers,
    this.notes,
  });
}

/// Modal de ingredientes: `Dialog` en tablet (≥840dp) / bottom sheet en
/// teléfono (spec §4). Quitar ingrediente = chip deseleccionado (tachado).
Future<CustomizeResult?> showItemCustomizer(
    BuildContext context, MenuItem item) {
  final wide = MediaQuery.sizeOf(context).width >= 840;
  final content = _CustomizeForm(item: item);
  if (wide) {
    return showDialog<CustomizeResult>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: content,
        ),
      ),
    );
  }
  return showModalBottomSheet<CustomizeResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => content,
  );
}

class _CustomizeForm extends StatefulWidget {
  final MenuItem item;
  const _CustomizeForm({required this.item});

  @override
  State<_CustomizeForm> createState() => _CustomizeFormState();
}

class _CustomizeFormState extends State<_CustomizeForm> {
  late final Set<String> _keptIngredients = {...widget.item.ingredients};
  final Set<String> _selectedModifiers = {};
  final _notes = TextEditingController();
  int _qty = 1;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: theme.textTheme.headlineSmall),
          if (item.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(item.description,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
          if (item.ingredients.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Ingredientes', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final ing in item.ingredients)
                  FilterChip(
                    label: Text(
                      ing,
                      style: _keptIngredients.contains(ing)
                          ? null
                          : TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: theme.colorScheme.error),
                    ),
                    selected: _keptIngredients.contains(ing),
                    onSelected: (sel) => setState(() {
                      sel
                          ? _keptIngredients.add(ing)
                          : _keptIngredients.remove(ing);
                    }),
                  ),
              ],
            ),
          ],
          if (item.modifiers.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Extras', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final mod in item.modifiers)
                  FilterChip(
                    label: Text(mod.price > 0
                        ? '${mod.name} (+\$${mod.price})'
                        : mod.name),
                    selected: _selectedModifiers.contains(mod.id),
                    onSelected: (sel) => setState(() {
                      sel
                          ? _selectedModifiers.add(mod.id)
                          : _selectedModifiers.remove(mod.id);
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Notas (opcional)'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              QtyStepper(
                value: _qty,
                onRemove: _qty > 1 ? () => setState(() => _qty--) : null,
                onAdd: () => setState(() => _qty++),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _submit,
                child: const Text('Agregar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    final removed = widget.item.ingredients
        .where((i) => !_keptIngredients.contains(i))
        .toList();
    final mods = widget.item.modifiers
        .where((m) => _selectedModifiers.contains(m.id))
        .toList();
    Navigator.pop(
      context,
      CustomizeResult(
        qty: _qty,
        removedIngredients: removed,
        addedModifiers: mods,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
    );
  }
}
