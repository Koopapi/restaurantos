import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/admin.dart';
import '../../models/app_config.dart';
import '../../state/admin_providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/ui_kit.dart';

/// Dashboard operativo: métricas, tendencia de ventas, tipo de servicio,
/// platillos más vendidos y operación en vivo.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(dashRangeProvider);
    final async = ref.watch(dashboardProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Sp.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const Text('Resumen del negocio',
                        style: TextStyle(color: BrandColors.inkSoft)),
                  ],
                ),
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'hoy', label: Text('Hoy')),
                  ButtonSegment(value: '7d', label: Text('7 días')),
                  ButtonSegment(value: '30d', label: Text('30 días')),
                ],
                selected: {range},
                onSelectionChanged: (s) =>
                    ref.read(dashRangeProvider.notifier).state = s.first,
              ),
            ],
          ),
          const SizedBox(height: Sp.lg),
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
    final wide = MediaQuery.sizeOf(context).width >= 840;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Sp.md,
          runSpacing: Sp.md,
          children: [
            _Metric(
                icon: Icons.payments,
                value: data.sales,
                isMoney: true,
                label: 'Ventas'),
            _Metric(
                icon: Icons.receipt_long,
                value: data.tickets,
                label: 'Tickets'),
            _Metric(
                icon: Icons.trending_up,
                value: data.avgTicket,
                isMoney: true,
                label: 'Ticket promedio'),
            _Metric(
                icon: Icons.volunteer_activism,
                value: data.tips,
                isMoney: true,
                label: 'Propinas'),
          ],
        ),
        const SizedBox(height: Sp.lg),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _TrendCard(trend: data.trend)),
              const SizedBox(width: Sp.md),
              Expanded(child: _ServiceTypeCard(rows: data.byServiceType)),
            ],
          )
        else ...[
          _TrendCard(trend: data.trend),
          const SizedBox(height: Sp.md),
          _ServiceTypeCard(rows: data.byServiceType),
        ],
        const SizedBox(height: Sp.md),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _TopDishesCard(dishes: data.topDishes)),
              const SizedBox(width: Sp.md),
              Expanded(flex: 2, child: _LiveCard(data: data)),
            ],
          )
        else ...[
          _TopDishesCard(dishes: data.topDishes),
          const SizedBox(height: Sp.md),
          _LiveCard(data: data),
        ],
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final num value;
  final bool isMoney;
  final String label;
  const _Metric(
      {required this.icon,
      required this.value,
      required this.label,
      this.isMoney = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: BrandColors.orangeSoft,
                borderRadius: BorderRadius.circular(Rad.md),
              ),
              child: Icon(icon, color: BrandColors.orangeInk, size: 22),
            ),
            const SizedBox(height: Sp.md),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text(
                isMoney ? money(v) : v.round().toString(),
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
            ),
            Text(label, style: const TextStyle(color: BrandColors.inkSoft)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;
  const _SectionCard({required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(Sp.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: Sp.lg),
          child,
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
    final maxV = trend.fold<num>(1, (m, e) => e.value > m ? e.value : m);
    var maxIdx = -1;
    for (var i = 0; i < trend.length; i++) {
      if (trend[i].value == maxV) {
        maxIdx = i;
        break;
      }
    }
    return _SectionCard(
      title: 'Tendencia de ventas',
      child: SizedBox(
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
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(
                                  begin: 0,
                                  end: (140 * (trend[i].value / maxV))
                                      .clamp(4, 140)
                                      .toDouble()),
                              duration: Duration(milliseconds: 500 + i * 60),
                              curve: Curves.easeOutCubic,
                              builder: (_, h, __) => Container(
                                height: h,
                                decoration: BoxDecoration(
                                  gradient: i == maxIdx
                                      ? const LinearGradient(
                                          colors: [
                                            BrandColors.orangeBright,
                                            BrandColors.orangeDeep
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        )
                                      : null,
                                  color: i == maxIdx
                                      ? null
                                      : const Color(0xFFFFE2BD),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8)),
                                  boxShadow: i == maxIdx
                                      ? Shadows.glow(BrandColors.orange,
                                          opacity: 0.35)
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: Sp.sm),
                            Text(_short(trend[i].label),
                                style: const TextStyle(
                                    fontSize: 11, color: BrandColors.inkSoft),
                                maxLines: 1),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  String _short(String isoDay) =>
      isoDay.length >= 10 ? isoDay.substring(5) : isoDay;
}

class _ServiceTypeCard extends StatelessWidget {
  final List<({String type, num amount})> rows;
  const _ServiceTypeCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    const labels = {
      'mesa': 'Para aquí',
      'llevar': 'Para llevar',
      'domicilio': 'Domicilio'
    };
    const dots = {
      'mesa': BrandColors.orange,
      'llevar': Color(0xFF3B82F6),
      'domicilio': Color(0xFF22C55E),
    };
    return _SectionCard(
      title: 'Por tipo de servicio',
      child: Column(
        children: [
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Sp.lg),
              child: Text('Sin ventas en el período',
                  style: TextStyle(color: BrandColors.inkFaint)),
            )
          else
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                          color: dots[r.type] ?? BrandColors.inkFaint,
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: Sp.sm),
                    Text(labels[r.type] ?? r.type),
                    const Spacer(),
                    Text(money(r.amount),
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _TopDishesCard extends StatelessWidget {
  final List<({String name, int qty})> dishes;
  const _TopDishesCard({required this.dishes});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Platillos más vendidos',
      child: Column(
        children: [
          if (dishes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Sp.lg),
              child: Text('Aún no hay ventas',
                  style: TextStyle(color: BrandColors.inkFaint)),
            )
          else
            for (var i = 0; i < dishes.length && i < 5; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: BrandColors.orangeSoft,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: BrandColors.orangeInk,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ),
                    const SizedBox(width: Sp.md),
                    Expanded(child: Text(dishes[i].name)),
                    Text('${dishes[i].qty}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final DashboardData data;
  const _LiveCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Operación en vivo',
      trailing: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 9, color: Color(0xFF22C55E)),
          SizedBox(width: 5),
          Text('tiempo real',
              style: TextStyle(
                  color: Color(0xFF1E7D34),
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ],
      ),
      child: Wrap(
        spacing: Sp.md,
        runSpacing: Sp.md,
        children: [
          _live('${data.tablesOccupied}/${data.tablesTotal}', 'Mesas ocupadas',
              Icons.table_restaurant, BrandColors.orange),
          _live('${data.activeAccounts}', 'Cuentas activas', Icons.receipt_long,
              const Color(0xFF3B82F6)),
          _live('${data.kitchenTickets}', 'Comandas cocina',
              Icons.outdoor_grill, const Color(0xFFF59E0B)),
          _live('${data.barTickets}', 'Comandas barra', Icons.local_bar,
              const Color(0xFF22C55E)),
        ],
      ),
    );
  }

  Widget _live(String value, String label, IconData icon, Color color) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        color: BrandColors.surfaceAlt,
        borderRadius: BorderRadius.circular(Rad.md),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(Rad.sm)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: Sp.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(
                      color: BrandColors.inkSoft, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
