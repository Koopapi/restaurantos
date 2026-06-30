import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/account.dart';
import '../../models/app_config.dart';
import '../../models/menu_item.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/ui_kit.dart';
import 'ingredient_modal.dart';
import 'checkout_sheet.dart';

/// Punto de venta: menú + carrito de la cuenta actual.
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(currentAccountIdProvider.notifier).state = null;
          });
          return const EmptyState(
              icon: Icons.check_circle, message: 'Cuenta cerrada');
        }
        final menu = menuAsync.value ?? const <MenuItem>[];
        final menuPanel = _MenuPanel(account: account, menu: menu);
        final cart = _CartPanel(account: account);

        if (wide) {
          return Row(
            children: [
              Expanded(child: menuPanel),
              Container(
                width: 380,
                margin: const EdgeInsets.fromLTRB(0, Sp.lg, Sp.lg, Sp.lg),
                decoration: BoxDecoration(
                  color: BrandColors.surface,
                  borderRadius: BorderRadius.circular(Rad.lg),
                  boxShadow: Shadows.card,
                ),
                clipBehavior: Clip.antiAlias,
                child: cart,
              ),
            ],
          );
        }
        return Scaffold(
          backgroundColor: BrandColors.bg,
          body: menuPanel,
          bottomNavigationBar: _CartBar(account: account),
        );
      },
    );
  }
}

class _MenuPanel extends ConsumerStatefulWidget {
  final Account account;
  final List<MenuItem> menu;
  const _MenuPanel({required this.account, required this.menu});

  @override
  ConsumerState<_MenuPanel> createState() => _MenuPanelState();
}

class _MenuPanelState extends ConsumerState<_MenuPanel> {
  String? _category;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final categories =
        <String>{for (final m in widget.menu) m.category}.toList();
    final cat = _category ?? (categories.isNotEmpty ? categories.first : null);
    final q = _search.trim().toLowerCase();
    final items = widget.menu.where((m) {
      if (q.isNotEmpty) {
        return m.name.toLowerCase().contains(q) ||
            m.description.toLowerCase().contains(q);
      }
      return m.category == cat;
    }).toList();

    final acc = widget.account;
    final svc = _serviceMeta(acc.serviceType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.lg, Sp.lg, Sp.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Punto de Venta',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(svc.icon, size: 15, color: BrandColors.orangeInk),
                        const SizedBox(width: Sp.xs),
                        Text(
                          acc.tableId != null
                              ? 'Mesa ${acc.tableId} · ${acc.guests ?? '-'} comensales'
                              : svc.label,
                          style: const TextStyle(
                              color: BrandColors.inkSoft,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 280,
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(
                    hintText: 'Buscar platillo…',
                    prefixIcon: Icon(Icons.search, color: BrandColors.inkFaint),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Sp.xl),
            children: [
              for (final c in categories)
                Padding(
                  padding: const EdgeInsets.only(right: Sp.sm),
                  child: _CategoryChip(
                    label: c,
                    selected: q.isEmpty && c == cat,
                    onTap: () => setState(() {
                      _category = c;
                      _search = '';
                    }),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off, message: 'Sin resultados')
              : GridView.builder(
                  padding: const EdgeInsets.all(Sp.xl),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    mainAxisExtent: 196,
                    crossAxisSpacing: Sp.md,
                    mainAxisSpacing: Sp.md,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _ProductCard(
                    item: items[i],
                    onAdd: () => _addItem(items[i]),
                  )
                      .animate()
                      .fadeIn(duration: 240.ms, delay: (i * 25).ms)
                      .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
                ),
        ),
      ],
    );
  }

  Future<void> _addItem(MenuItem item) async {
    final notifier =
        ref.read(currentAccountProvider(widget.account.id).notifier);
    if (item.ingredients.isNotEmpty || item.modifiers.isNotEmpty) {
      final result = await showItemCustomizer(context, item);
      if (result == null) {
        return;
      }
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
      if (mounted) {
        showError(context, 'No se pudo agregar el platillo');
      }
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip(
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
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : BrandColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onAdd;
  const _ProductCard({required this.item, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final disabled = !item.available;
    return PressableScale(
      onTap: disabled ? null : onAdd,
      child: Opacity(
        opacity: disabled ? 0.55 : 1,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: BrandColors.surface,
            borderRadius: BorderRadius.circular(Rad.lg),
            boxShadow: Shadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 64,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFF1DE), Color(0xFFFFE2BD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  item.station == 'barra'
                      ? Icons.local_bar
                      : Icons.set_meal_outlined,
                  color: BrandColors.orangeDeep,
                  size: 30,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(Sp.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: BrandColors.inkFaint,
                              fontSize: 11.5,
                              height: 1.25),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              disabled ? 'No disponible' : money(item.price),
                              style: const TextStyle(
                                color: BrandColors.orangeInk,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: disabled
                                  ? BrandColors.surfaceAlt
                                  : BrandColors.orange,
                              borderRadius: BorderRadius.circular(Rad.md),
                              boxShadow: disabled
                                  ? null
                                  : Shadows.glow(BrandColors.orange,
                                      opacity: 0.35),
                            ),
                            child: Icon(Icons.add,
                                color: disabled
                                    ? BrandColors.inkFaint
                                    : Colors.white,
                                size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
    final svc = _serviceMeta(account.serviceType);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, Sp.sm),
          child: Row(
            children: [
              Text('Pedido Actual',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 6),
                decoration: BoxDecoration(
                  color: BrandColors.orangeSoft,
                  borderRadius: BorderRadius.circular(Rad.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(svc.icon, size: 14, color: BrandColors.orangeInk),
                    const SizedBox(width: Sp.xs),
                    Text(
                      account.tableId != null
                          ? 'Mesa ${account.tableId}'
                          : svc.label,
                      style: const TextStyle(
                          color: BrandColors.orangeInk,
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: account.lines.isEmpty
              ? const EmptyState(
                  icon: Icons.receipt_long,
                  message: 'Agrega platillos del menú')
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Sp.md, vertical: Sp.sm),
                  itemCount: account.lines.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 2),
                  itemBuilder: (_, i) =>
                      _LineTile(line: account.lines[i], notifier: notifier)
                          .animate()
                          .fadeIn(duration: 200.ms)
                          .slideX(begin: 0.1, end: 0, curve: Curves.easeOut),
                ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: BrandColors.surface,
            border: Border(top: BorderSide(color: BrandColors.hairline)),
          ),
          padding: const EdgeInsets.all(Sp.lg),
          child: Column(
            children: [
              _totalRow('Subtotal', money(account.subtotal)),
              _totalRow(
                  '${config.taxLabel} (${(config.taxRate * 100).toStringAsFixed(1)}%)',
                  money(account.tax)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: Sp.sm),
                child: Divider(height: 1),
              ),
              _totalRow('Total', money(account.total), bold: true),
              const SizedBox(height: Sp.md),
              GradientButton(
                label: 'Enviar a Cocina/Barra',
                icon: Icons.send_rounded,
                onTap:
                    account.hasPending ? () => _send(context, notifier) : null,
              ),
              const SizedBox(height: Sp.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: account.lines.isEmpty
                          ? null
                          : () => openCheckout(context, ref, account),
                      icon: const Icon(Icons.payments_outlined, size: 20),
                      label: const Text('Cobrar'),
                    ),
                  ),
                  const SizedBox(width: Sp.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: account.lines.length < 2
                          ? null
                          : () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Dividir cuenta — próximamente')),
                              ),
                      icon: const Icon(Icons.call_split, size: 20),
                      label: const Text('Dividir'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _totalRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 20 : 14,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: bold ? BrandColors.ink : BrandColors.inkSoft,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
      if (context.mounted) {
        showError(context, 'No se pudo enviar la comanda');
      }
    }
  }
}

class _LineTile extends StatelessWidget {
  final AccountLine line;
  final CurrentAccountNotifier notifier;
  const _LineTile({required this.line, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final detail = [
      ...line.removedIngredients.map((e) => 'sin $e'),
      ...line.addedModifiers.map((m) => '+${m.name}'),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
      decoration: BoxDecoration(
        color: BrandColors.surfaceAlt,
        borderRadius: BorderRadius.circular(Rad.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(money(line.unitPrice),
                    style: const TextStyle(
                        color: BrandColors.inkSoft, fontSize: 12.5)),
                if (detail.isNotEmpty)
                  Text(detail,
                      style: const TextStyle(
                          color: BrandColors.inkFaint, fontSize: 11)),
                if (line.sent)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            size: 12, color: BrandColors.orangeInk),
                        SizedBox(width: 3),
                        Text('Enviado',
                            style: TextStyle(
                                color: BrandColors.orangeInk,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Sp.sm),
          line.sent
              ? Text('${line.qty}×',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800))
              : QtyStepper(
                  value: line.qty,
                  onRemove: () => line.qty > 1
                      ? notifier.setQty(line.id, line.qty - 1)
                      : notifier.removeLine(line.id),
                  onAdd: () => notifier.setQty(line.id, line.qty + 1),
                ),
        ],
      ),
    );
  }
}

/// Barra inferior (teléfono) con total que abre el carrito en hoja.
class _CartBar extends ConsumerWidget {
  final Account account;
  const _CartBar({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Sp.md),
        child: GradientButton(
          label:
              'Ver pedido (${account.lines.length})   ·   ${money(account.total)}',
          icon: Icons.shopping_bag_outlined,
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: BrandColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(Rad.xl)),
            ),
            builder: (_) => FractionallySizedBox(
              heightFactor: 0.88,
              child: _CartPanel(account: account),
            ),
          ),
        ),
      ),
    );
  }
}

({IconData icon, String label}) _serviceMeta(String serviceType) {
  switch (serviceType) {
    case 'llevar':
      return (icon: Icons.takeout_dining, label: 'Para llevar');
    case 'domicilio':
      return (icon: Icons.pedal_bike, label: 'Domicilio');
    default:
      return (icon: Icons.table_restaurant, label: 'Para aquí');
  }
}
