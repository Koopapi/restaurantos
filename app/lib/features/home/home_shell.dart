import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../accounts/accounts_screen.dart';
import '../admin/brand_screen.dart';
import '../admin/dashboard_screen.dart';
import '../admin/employees_screen.dart';
import '../admin/inventory_screen.dart';
import '../admin/menu_admin_screen.dart';
import '../admin/purchasing_screen.dart';
import '../admin/reports_screen.dart';
import '../auth/auth_controller.dart';
import '../auth/employee.dart';
import '../hostess/hostess_screen.dart';
import '../kds/kds_screen.dart';
import '../pos/pos_screen.dart';
import '../tables/tables_screen.dart';
import 'destinations.dart';

/// Shell responsivo tras el login: `NavigationRail` en tablet (≥840dp) y
/// `NavigationBar` inferior en teléfono (<840dp). Renderiza la pantalla del
/// destino seleccionado según el rol.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(authControllerProvider).employee;
    if (employee == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final destinations = destinationsForRole(employee.role);
    final selected =
        ref.watch(navIndexProvider).clamp(0, destinations.length - 1);
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final current = destinations[selected];
    final body = _screenFor(current.label);

    void select(int i) => ref.read(navIndexProvider.notifier).state = i;

    if (destinations.length < 2) {
      return Scaffold(
        appBar: _TopBar(employee: employee, title: current.label),
        body: body,
      );
    }

    if (wide) {
      return Scaffold(
        appBar: _TopBar(employee: employee, title: current.label),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selected,
              onDestinationSelected: select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                      icon: Icon(d.icon), label: Text(d.label)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: _TopBar(employee: employee, title: current.label),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected.clamp(0, 4),
        onDestinationSelected: select,
        destinations: [
          for (final d in destinations.take(5))
            NavigationDestination(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }

  Widget _screenFor(String label) {
    switch (label) {
      case 'POS':
        return const PosScreen();
      case 'Mesas':
        return const TablesScreen();
      case 'Lista de espera':
        return const HostessScreen();
      case 'Cuentas':
      case 'Cobro':
        return const AccountsScreen();
      case 'Cocina':
      case 'Cocina KDS':
        return const KdsScreen(station: 'cocina');
      case 'Barra':
      case 'Barra KDS':
        return const KdsScreen(station: 'barra');
      case 'Dashboard':
        return const DashboardScreen();
      case 'Menú':
        return const MenuAdminScreen();
      case 'Inventario':
        return const InventoryScreen();
      case 'Compras':
        return const PurchasingScreen();
      case 'Empleados':
        return const EmployeesScreen();
      case 'Reportes':
        return const ReportsScreen();
      case 'Marca blanca':
        return const BrandScreen();
      default:
        return _Placeholder(label: label);
    }
  }
}

class _TopBar extends StatelessWidget implements PreferredSizeWidget {
  final Employee employee;
  final String title;
  const _TopBar({required this.employee, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      title: Text(title),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: employee.avatarColor ?? scheme.primary,
                child: Text(
                  employee.initials ??
                      (employee.name.isNotEmpty ? employee.name[0] : '?'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Text(employee.name),
            ],
          ),
        ),
        Consumer(
          builder: (context, ref, _) => IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String label;
  const _Placeholder({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(label, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Pantalla en construcción',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
