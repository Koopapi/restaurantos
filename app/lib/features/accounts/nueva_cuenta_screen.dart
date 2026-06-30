import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories.dart';
import '../../models/restaurant_table.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/ui_kit.dart';
import '../auth/auth_controller.dart';
import '../home/destinations.dart';

/// Nueva Cuenta: elige el tipo de servicio (Para Aquí / Llevar / Domicilio) y
/// abre la cuenta, redirigiendo al POS.
class NuevaCuentaScreen extends ConsumerStatefulWidget {
  const NuevaCuentaScreen({super.key});

  @override
  ConsumerState<NuevaCuentaScreen> createState() => _NuevaCuentaScreenState();
}

class _NuevaCuentaScreenState extends ConsumerState<NuevaCuentaScreen> {
  String _service = 'mesa';
  String? _tableId;
  int _guests = 2;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tables = ref.watch(tablesProvider).value ?? const <RestaurantTable>[];
    final free = tables.where((t) => t.isFree).toList();

    return ListView(
      padding: const EdgeInsets.all(Sp.xl),
      children: [
        Text('Nueva Cuenta',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const Text('¿Qué tipo de pedido?',
            style: TextStyle(color: BrandColors.inkSoft)),
        const SizedBox(height: Sp.lg),
        _ServiceCard(
          icon: Icons.table_restaurant,
          title: 'Para Aquí',
          subtitle: 'Asignar a una mesa',
          selected: _service == 'mesa',
          onTap: () => setState(() => _service = 'mesa'),
        ),
        const SizedBox(height: Sp.md),
        _ServiceCard(
          icon: Icons.takeout_dining,
          title: 'Para Llevar',
          subtitle: 'Pedido para recoger',
          selected: _service == 'llevar',
          onTap: () => setState(() => _service = 'llevar'),
        ),
        const SizedBox(height: Sp.md),
        _ServiceCard(
          icon: Icons.pedal_bike,
          title: 'Domicilio',
          subtitle: 'Entrega a dirección',
          selected: _service == 'domicilio',
          onTap: () => setState(() => _service = 'domicilio'),
        ),
        const SizedBox(height: Sp.xl),
        if (_service == 'mesa') ...[
          const Text('Mesa disponible',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: Sp.md),
          if (free.isEmpty)
            const Text('No hay mesas disponibles',
                style: TextStyle(color: BrandColors.inkFaint))
          else
            Wrap(
              spacing: Sp.sm,
              runSpacing: Sp.sm,
              children: [
                for (final t in free)
                  _TablePick(
                    table: t,
                    selected: t.id == _tableId,
                    onTap: () => setState(() => _tableId = t.id),
                  ),
              ],
            ),
          const SizedBox(height: Sp.lg),
          Row(
            children: [
              const Text('Comensales',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              QtyStepper(
                value: _guests,
                onRemove: _guests > 1 ? () => setState(() => _guests--) : null,
                onAdd: () => setState(() => _guests++),
              ),
            ],
          ),
        ] else ...[
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre del cliente'),
          ),
          const SizedBox(height: Sp.md),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
          ),
          if (_service == 'domicilio') ...[
            const SizedBox(height: Sp.md),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Dirección'),
            ),
          ],
        ],
        const SizedBox(height: Sp.xl),
        _busy
            ? const Center(child: CircularProgressIndicator())
            : GradientButton(
                label: 'Abrir cuenta',
                icon: Icons.check_rounded,
                onTap: _canCreate ? _create : null,
              ),
      ],
    );
  }

  bool get _canCreate {
    if (_service == 'mesa') return _tableId != null;
    if (_service == 'domicilio') {
      return _name.text.trim().isNotEmpty && _address.text.trim().isNotEmpty;
    }
    return true; // llevar
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final acc = await ref.read(serviceRepositoryProvider).createAccount(
            serviceType: _service,
            tableId: _service == 'mesa' ? _tableId : null,
            guests: _service == 'mesa' ? _guests : null,
            customerName: _service == 'mesa' ? null : _name.text.trim(),
            phone: _service == 'mesa' ? null : _phone.text.trim(),
            address: _service == 'domicilio' ? _address.text.trim() : null,
          );
      ref.invalidate(tablesProvider);
      ref.invalidate(openAccountsProvider);
      ref.read(currentAccountIdProvider.notifier).state = acc.id;
      final role = ref.read(authControllerProvider).employee?.role ?? '';
      final idx = destinationsForRole(role).indexWhere((d) => d.label == 'POS');
      if (idx >= 0) ref.read(navIndexProvider.notifier).state = idx;
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, 'No se pudo abrir la cuenta');
      }
    }
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Dur.fast,
        padding: const EdgeInsets.all(Sp.lg),
        decoration: BoxDecoration(
          color: selected ? BrandColors.orangeSoft : BrandColors.surface,
          borderRadius: BorderRadius.circular(Rad.lg),
          boxShadow: Shadows.card,
          border: Border.all(
              color: selected ? BrandColors.orange : Colors.transparent,
              width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? BrandColors.orange : BrandColors.surfaceAlt,
                borderRadius: BorderRadius.circular(Rad.md),
              ),
              child: Icon(icon,
                  color: selected ? Colors.white : BrandColors.inkSoft),
            ),
            const SizedBox(width: Sp.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(subtitle,
                      style: const TextStyle(color: BrandColors.inkSoft)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: BrandColors.orange),
          ],
        ),
      ),
    );
  }
}

class _TablePick extends StatelessWidget {
  final RestaurantTable table;
  final bool selected;
  final VoidCallback onTap;
  const _TablePick(
      {required this.table, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Dur.fast,
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: Sp.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? BrandColors.orange : BrandColors.surface,
          borderRadius: BorderRadius.circular(Rad.md),
          boxShadow: selected ? Shadows.glow(BrandColors.orange) : Shadows.soft,
          border: Border.all(
              color: selected ? BrandColors.orange : BrandColors.hairline),
        ),
        child: Column(
          children: [
            Text('Mesa ${table.number}',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : BrandColors.ink)),
            Text('${table.capacity} asientos',
                style: TextStyle(
                    fontSize: 11,
                    color: selected ? Colors.white70 : BrandColors.inkFaint)),
          ],
        ),
      ),
    );
  }
}
