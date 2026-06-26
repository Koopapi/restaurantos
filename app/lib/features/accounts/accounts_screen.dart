import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_config.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import '../auth/auth_controller.dart';
import '../home/destinations.dart';

/// Lista de cuentas abiertas. Tocar una la abre en el POS (para editar/cobrar).
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(openAccountsProvider);
    final tables = ref.watch(tablesProvider).value ?? const [];

    return accountsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
      data: (accounts) {
        if (accounts.isEmpty) {
          return const EmptyState(
              icon: Icons.receipt_long, message: 'No hay cuentas abiertas');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: accounts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final a = accounts[i];
            String label;
            if (a.serviceType == 'mesa') {
              final n = tables.where((t) => t.id == a.tableId);
              label = n.isNotEmpty ? 'Mesa ${n.first.number}' : 'Mesa';
            } else {
              label = a.serviceType == 'llevar' ? 'Para llevar' : 'Domicilio';
            }
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${a.lines.length}')),
                title: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    '${a.lines.length} platillos · ${a.hasPending ? "por enviar" : "enviado"}'),
                trailing: Text(money(a.total),
                    style: Theme.of(context).textTheme.titleMedium),
                onTap: () {
                  ref.read(currentAccountIdProvider.notifier).state = a.id;
                  final role =
                      ref.read(authControllerProvider).employee?.role ?? '';
                  final idx = destinationsForRole(role)
                      .indexWhere((d) => d.label == 'POS');
                  if (idx >= 0) ref.read(navIndexProvider.notifier).state = idx;
                },
              ),
            );
          },
        );
      },
    );
  }
}
