import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_config.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/ui_kit.dart';
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
          padding: const EdgeInsets.all(Sp.xl),
          itemCount: accounts.length,
          separatorBuilder: (_, __) => const SizedBox(height: Sp.md),
          itemBuilder: (_, i) {
            final a = accounts[i];
            String label;
            IconData icon;
            if (a.serviceType == 'mesa') {
              final n = tables.where((t) => t.id == a.tableId);
              label = n.isNotEmpty ? 'Mesa ${n.first.number}' : 'Mesa';
              icon = Icons.table_restaurant;
            } else if (a.serviceType == 'llevar') {
              label = 'Para llevar';
              icon = Icons.takeout_dining;
            } else {
              label = 'Domicilio';
              icon = Icons.pedal_bike;
            }
            final pending = a.hasPending;
            return AppCard(
              padding: const EdgeInsets.all(Sp.md),
              onTap: () {
                ref.read(currentAccountIdProvider.notifier).state = a.id;
                final role =
                    ref.read(authControllerProvider).employee?.role ?? '';
                final idx = destinationsForRole(role)
                    .indexWhere((d) => d.label == 'POS');
                if (idx >= 0) ref.read(navIndexProvider.notifier).state = idx;
              },
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: BrandColors.orangeSoft,
                      borderRadius: BorderRadius.circular(Rad.md),
                    ),
                    child: Icon(icon, color: BrandColors.orangeInk),
                  ),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text('${a.lines.length} platillos',
                                style: const TextStyle(
                                    color: BrandColors.inkSoft, fontSize: 13)),
                            const SizedBox(width: Sp.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Sp.sm, vertical: 2),
                              decoration: BoxDecoration(
                                color: pending
                                    ? const Color(0x1AF59E0B)
                                    : const Color(0x1A22C55E),
                                borderRadius: BorderRadius.circular(Rad.pill),
                              ),
                              child: Text(
                                pending ? 'Por enviar' : 'Enviado',
                                style: TextStyle(
                                  color: pending
                                      ? const Color(0xFFB45309)
                                      : const Color(0xFF1E7D34),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Sp.sm),
                  Text(money(a.total),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: BrandColors.orangeInk)),
                  const SizedBox(width: Sp.xs),
                  const Icon(Icons.chevron_right, color: BrandColors.inkFaint),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 220.ms, delay: (i * 30).ms)
                .slideX(begin: 0.06, end: 0, curve: Curves.easeOut);
          },
        );
      },
    );
  }
}
