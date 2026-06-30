import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_config.dart';
import '../../state/admin_providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/ui_kit.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(reportRangeProvider);
    final sales = ref.watch(salesReportProvider);
    final top = ref.watch(topProductsProvider);
    final byEmp = ref.watch(employeesReportProvider);

    return ListView(
      padding: const EdgeInsets.all(Sp.xl),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Reportes y Análisis',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exportar CSV — próximamente')),
              ),
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Exportar'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            ),
          ],
        ),
        const SizedBox(height: Sp.md),
        Align(
          alignment: Alignment.centerLeft,
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
        const SizedBox(height: Sp.lg),
        sales.when(
          loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator())),
          error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
          data: (r) => Column(
            children: [
              Wrap(
                spacing: Sp.md,
                runSpacing: Sp.md,
                children: [
                  _Metric(value: money(r.totalSales), label: 'Ventas totales'),
                  _Metric(value: '${r.tickets}', label: 'Tickets'),
                  _Metric(value: money(r.avgTicket), label: 'Ticket promedio'),
                  _Metric(value: money(r.tips), label: 'Propinas'),
                ],
              ),
              const SizedBox(height: Sp.lg),
              _Section(
                title: 'Por método de pago',
                child: r.byPaymentMethod.isEmpty
                    ? const _Empty()
                    : Column(
                        children: [
                          for (final m in r.byPaymentMethod)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.payments_outlined,
                                      size: 18, color: BrandColors.orangeInk),
                                  const SizedBox(width: Sp.sm),
                                  Text('${m.method} · ${m.count}'),
                                  const Spacer(),
                                  Text(money(m.amount),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Sp.md),
        _Section(
          title: 'Platillos más vendidos',
          child: top.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (items) => items.isEmpty
                ? const _Empty()
                : Column(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              _rank(i + 1),
                              const SizedBox(width: Sp.md),
                              Expanded(child: Text(items[i].name)),
                              Text('${items[i].qty} · ${money(items[i].revenue)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: BrandColors.inkSoft)),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: Sp.md),
        _Section(
          title: 'Ventas por empleado',
          child: byEmp.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('$e'),
            data: (items) => items.isEmpty
                ? const _Empty()
                : Column(
                    children: [
                      for (final e in items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text(e.name)),
                              Text('${money(e.sales)} · ${e.tickets} tickets',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: BrandColors.inkSoft)),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _rank(int n) => Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: BrandColors.orangeSoft,
            borderRadius: BorderRadius.circular(8)),
        child: Text('$n',
            style: const TextStyle(
                color: BrandColors.orangeInk,
                fontWeight: FontWeight.w800,
                fontSize: 12)),
      );
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  const _Metric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: BrandColors.inkSoft, fontSize: 13)),
            const SizedBox(height: Sp.xs),
            Text(value,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(Sp.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: Sp.md),
          child,
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: Sp.lg),
        child: Text('Sin datos en el período',
            style: TextStyle(color: BrandColors.inkFaint)),
      );
}
