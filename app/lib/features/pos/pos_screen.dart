import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/account.dart';
import '../../models/app_config.dart';
import '../../models/menu_item.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import 'ingredient_modal.dart';
import 'checkout_sheet.dart';

/// Punto de venta: menú + carrito de la cuenta actual (`docs/design/` POS).
class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountId = ref.watch(currentAccountIdProvider);
    if (accountId == null) {
      return const EmptyState(
          icon: Icons.point_of_sale,
          message: 'Abre una cuenta desde Mesas para empezar');
    }

    final accountAsync = ref.watch(currentAccountProvider(accountId));
    final menuAsync = ref.watch(menuProvider);
    final wide = MediaQuery.sizeOf(context).width >= 840;

    return accountAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
      data: (account) {
        if (!account.isOpen) {
          // La cuenta se cerró (pagada/cancelada): limpia la selección.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(currentAccountIdProvider.notifier).state = null;
          });
          return const EmptyState(
              icon: Icons.check_circle, message: 'Cuenta cerrada');
        }
        final menu = menuAsync.value ?? const <MenuItem>[];
        final menuPanel = _MenuPanel(accountId: accountId, menu: menu);
        final cart = _CartPanel(account: account);

        if (wide) {
          return Row(
            children: [
              Expanded(flex: 3, child: menuPanel),
              const VerticalDivider(width: 1),
              SizedBox(width: 360, child: cart),
            ],
          );
        }
        // Teléfono: menú + barra inferior con total que abre el carrito.
        return Scaffold(
          body: menuPanel,
          bottomNavigationBar: _CartBar(account: account),
        );
      },
    );
  }
}

class _MenuPanel extends ConsumerStatefulWidget {
  final String accountId;
  final List<MenuItem> menu;
  const _MenuPanel({required this.accountId, required this.menu});

  @override
  ConsumerState<_MenuPanel> createState() => _MenuPanelState();
}

class _MenuPanelState extends ConsumerState<_MenuPanel> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final categories =
        <String>{for (final m in widget.menu) m.category}.toList();
    final cat = _category ?? (categories.isNotEmpty ? categories.first : null);
    final items = widget.menu.where((m) => m.category == cat).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Wrap(
            spacing: 8,
            children: [
              for (final c in categories)
                ChoiceChip(
                  label: Text(c),
                  selected: c == cat,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisExtent: 150,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => _ProductCard(
              item: items[i],
              onAdd: () => _addItem(items[i]),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addItem(MenuItem item) async {
    final notifier =
        ref.read(currentAccountProvider(widget.accountId).notifier);
    // Si el platillo tiene ingredientes o modificadores, abre el modal.
    if (item.ingredients.isNotEmpty || item.modifiers.isNotEmpty) {
      final result = await showItemCustomizer(context, item);
      if (result == null) return;
      await _safe(() => notifier.addLine(
            menuItemId: item.id,
            qty: result.qty,
            removedIngredients: result.removedIngredients,
            addedModifiers: result.addedModifiers,
            notes: result.notes,
          ));
    } else {
      await _safe(() => notifier.addLine(menuItemId: item.id, qty: 1));
    }
  }

  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) showError(context, 'No se pudo agregar el platillo');
    }
  }
}

class _ProductCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onAdd;
  const _ProductCard({required this.item, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = !item.available;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: disabled ? null : onAdd,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item.station == 'barra'
                      ? Icons.local_bar
                      : Icons.ramen_dining,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(disabled ? 'No disponible' : money(item.price),
                        style: theme.textTheme.titleMedium),
                  ),
                  IconButton.filled(
                    onPressed: disabled ? null : onAdd,
                    icon: const Icon(Icons.add),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panel "Pedido Actual" con líneas, totales y acciones.
class _CartPanel extends ConsumerWidget {
  final Account account;
  const _CartPanel({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final config = ref.watch(configProvider).value ?? AppConfig.fallback;
    final notifier = ref.read(currentAccountProvider(account.id).notifier);

    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text('Pedido Actual', style: theme.textTheme.titleLarge),
                const Spacer(),
                if (account.tableId != null)
                  const Icon(Icons.table_restaurant, size: 18),
              ],
            ),
          ),
          Expanded(
            child: account.lines.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long,
                    message: 'Agrega platillos del menú')
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: account.lines.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) =>
                        _LineTile(line: account.lines[i], notifier: notifier),
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _totalRow(theme, 'Subtotal', money(account.subtotal)),
                _totalRow(
                    theme,
                    '${config.taxLabel} (${(config.taxRate * 100).toStringAsFixed(1)}%)',
                    money(account.tax)),
                const SizedBox(height: 4),
                _totalRow(theme, 'Total', money(account.total), bold: true),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: account.hasPending
                        ? () => _send(context, notifier)
                        : null,
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar a Cocina/Barra'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: account.lines.isEmpty
                        ? null
                        : () => openCheckout(context, ref, account),
                    icon: const Icon(Icons.payments),
                    label: const Text('Cobrar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(ThemeData theme, String label, String value,
      {bool bold = false}) {
    final style = bold
        ? theme.textTheme.titleLarge
        : theme.textTheme.bodyMedium
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }

  Future<void> _send(
      BuildContext context, CurrentAccountNotifier notifier) async {
    try {
      await notifier.send();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comanda enviada a cocina/barra')),
        );
      }
    } catch (e) {
      if (context.mounted) showError(context, 'No se pudo enviar la comanda');
    }
  }
}

class _LineTile extends StatelessWidget {
  final AccountLine line;
  final CurrentAccountNotifier notifier;
  const _LineTile({required this.line, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = [
      ...line.removedIngredients.map((e) => 'sin $e'),
      ...line.addedModifiers.map((m) => '+${m.name}'),
    ].join(' · ');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title:
          Text(line.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(money(line.unitPrice)),
          if (detail.isNotEmpty)
            Text(detail,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          if (line.sent)
            Text('Enviado',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.primary)),
        ],
      ),
      trailing: line.sent
          ? Text('${line.qty}×', style: theme.textTheme.titleMedium)
          : QtyStepper(
              value: line.qty,
              onRemove: () => line.qty > 1
                  ? notifier.setQty(line.id, line.qty - 1)
                  : notifier.removeLine(line.id),
              onAdd: () => notifier.setQty(line.id, line.qty + 1),
            ),
    );
  }
}

/// Barra inferior (teléfono) que muestra el total y abre el carrito en hoja.
class _CartBar extends ConsumerWidget {
  final Account account;
  const _CartBar({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => FractionallySizedBox(
              heightFactor: 0.85,
              child: _CartPanel(account: account),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ver pedido (${account.lines.length})'),
              Text(money(account.total),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
