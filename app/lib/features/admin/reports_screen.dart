import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_config.dart';
import '../../state/admin_providers.dart';
import '../../widgets/common.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportRangeProvider);
    final sales = ref.watch(salesReportProvider);
    final top = ref.watch(topProductsProvider);
    final byEmp = ref.watch(employeesReportProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'hoy', label: Text('Hoy')),
              ButtonSegment(value: 'semana', label: Text('Semana')),
              ButtonSegment(value: 'mes', label: Text('Mes')),
              ButtonSegment(value: 'trimestre', label: Text('Trim.')),
            ],
            selected: {range},
            onSelectionChanged: (s) =>
                ref.read(reportRangeProvider.notifier).state = s.first,
          ),
        ),
        const SizedBox(height: 16),
        sales.when(
          loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator())),
          error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
          data: (r) => Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _stat(context, money(r.totalSales), 'Ventas'),
                  _stat(context, '${r.tickets}', 'Tickets'),
                  _stat(context, money(r.avgTicket), 'Ticket promedio'),
                  _stat(context, money(r.tips), 'Propinas'),
                ],
              ),
              const SizedBox(height: 12),
              if (r.byPaymentMethod.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Por método de pago',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        for (final m in r.byPaymentMethod)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${m.method} (${m.count})'),
                                Text(money(m.amount),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ListCard(
          title: 'Platillos más vendidos',
          child: top.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (items) => Column(
              children: [
                for (final p in items)
                  ListTile(
                    dense: true,
                    title: Text(p.name),
                    trailing: Text('${p.qty} · ${money(p.revenue)}'),
                  ),
                if (items.isEmpty)
                  const ListTile(dense: true, title: Text('Sin datos')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ListCard(
          title: 'Ventas por empleado',
          child: byEmp.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (items) => Column(
              children: [
                for (final e in items)
                  ListTile(
                    dense: true,
                    title: Text(e.name),
                    trailing: Text('${money(e.sales)} · ${e.tickets} tickets'),
                  ),
                if (items.isEmpty)
                  const ListTile(dense: true, title: Text('Sin datos')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.headlineSmall),
          Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ListCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
