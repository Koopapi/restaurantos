import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/admin.dart';
import '../../models/app_config.dart';
import '../../state/admin_providers.dart';
import '../../widgets/common.dart';

/// Dashboard operativo (`docs/design/` Dashboard): métricas, tendencia de
/// ventas, por tipo de servicio y operación en vivo.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(dashRangeProvider);
    final async = ref.watch(dashboardProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'hoy', label: Text('Hoy')),
                ButtonSegment(value: '7d', label: Text('7 días')),
                ButtonSegment(value: '30d', label: Text('30 días')),
              ],
              selected: {range},
              onSelectionChanged: (s) =>
                  ref.read(dashRangeProvider.notifier).state = s.first,
            ),
          ),
          const SizedBox(height: 16),
          async.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
            data: (d) => _Content(data: d),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final DashboardData data;
  const _Content({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Metric(
                icon: Icons.attach_money,
                value: money(data.sales),
                label: 'Ventas'),
            _Metric(
                icon: Icons.receipt_long,
                value: '${data.tickets}',
                label: 'Tickets'),
            _Metric(
                icon: Icons.trending_up,
                value: money(data.avgTicket),
                label: 'Ticket promedio'),
            _Metric(
                icon: Icons.volunteer_activism,
                value: money(data.tips),
                label: 'Propinas'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _TrendCard(trend: data.trend)),
            const SizedBox(width: 12),
            Expanded(child: _ServiceTypeCard(rows: data.byServiceType)),
          ],
        ),
        const SizedBox(height: 16),
        _LiveCard(data: data),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Metric({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Icon(icon,
                color: theme.colorScheme.onSecondaryContainer, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.headlineMedium),
          Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final List<({String label, num value})> trend;
  const _TrendCard({required this.trend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxV = trend.fold<num>(1, (m, e) => e.value > m ? e.value : m);
    final maxIdx = trend.isEmpty
        ? -1
        : trend.indexWhere((e) =>
            e.value == trend.fold<num>(0, (m, x) => x.value > m ? x.value : m));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tendencia de ventas', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: trend.isEmpty
                  ? const EmptyState(
                      icon: Icons.bar_chart, message: 'Sin datos en el rango')
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < trend.length; i++)
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    height: (140 * (trend[i].value / maxV))
                                        .clamp(4, 140)
                                        .toDouble(),
                                    decoration: BoxDecoration(
                                      color: i == maxIdx
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.primaryContainer,
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(6)),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(_short(trend[i].label),
                                      style: theme.textTheme.labelSmall,
                                      maxLines: 1),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _short(String isoDay) =>
      isoDay.length >= 10 ? isoDay.substring(5) : isoDay; // MM-DD
}

class _ServiceTypeCard extends StatelessWidget {
  final List<({String type, num amount})> rows;
  const _ServiceTypeCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const labels = {
      'mesa': 'Para aquí',
      'llevar': 'Para llevar',
      'domicilio': 'Domicilio'
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Por tipo de servicio', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              Text('Sin ventas',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
            else
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(labels[r.type] ?? r.type),
                      Text(money(r.amount),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final DashboardData data;
  const _LiveCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Operación en vivo', style: theme.textTheme.titleLarge),
                const Spacer(),
                Icon(Icons.circle, size: 10, color: context.semanticGreen),
                const SizedBox(width: 6),
                Text('tiempo real',
                    style: TextStyle(color: context.semanticGreen)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _live('${data.tablesOccupied}/${data.tablesTotal}',
                    'Mesas ocupadas', Icons.table_restaurant),
                _live('${data.activeAccounts}', 'Cuentas activas',
                    Icons.receipt_long),
                _live('${data.kitchenTickets}', 'Comandas cocina',
                    Icons.soup_kitchen),
                _live('${data.barTickets}', 'Comandas barra', Icons.local_bar),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _live(String value, String label, IconData icon) => Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: theme.textTheme.titleLarge),
                    Text(label, style: theme.textTheme.labelMedium),
                  ],
                ),
              ],
            ),
          );
        },
      );
}

extension on BuildContext {
  Color get semanticGreen => Theme.of(this).brightness == Brightness.dark
      ? const Color(0xFF7BE0A0)
      : const Color(0xFF1E7D34);
}
