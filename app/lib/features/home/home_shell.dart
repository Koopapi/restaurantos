import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/employee.dart';
import 'destinations.dart';

/// Shell responsivo tras el login: `NavigationRail` en tablet (≥840dp) y
/// `NavigationBar` inferior en teléfono (<840dp). Las pantallas de cada destino
/// son placeholders en esta fase (bootstrap).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final employee = ref.watch(authControllerProvider).employee;
    if (employee == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final destinations = destinationsForRole(employee.role);
    final safeIndex = _index.clamp(0, destinations.length - 1);
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final current = destinations[safeIndex];

    final body = _Placeholder(destination: current);

    // Roles con un solo destino (cocina/barista): sin barra de navegación.
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
              selectedIndex: safeIndex,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    label: Text(d.label),
                  ),
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
        selectedIndex: safeIndex,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final d in destinations.take(5))
            NavigationDestination(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
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
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
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
  final AppDestination destination;
  const _Placeholder({required this.destination});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(destination.icon, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(destination.label, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Pantalla en construcción',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
