import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_repository.dart';
import '../../state/admin_providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/ui_kit.dart';
import '../auth/employee.dart';

const _roles = ['mesero', 'cocina', 'barista', 'hostess', 'gerente', 'admin'];

Color _roleColor(String role) {
  switch (role) {
    case 'cocina':
      return const Color(0xFFEF4444);
    case 'barista':
      return const Color(0xFF0EA5E9);
    case 'hostess':
      return const Color(0xFF14B8A6);
    case 'gerente':
      return const Color(0xFF22C55E);
    case 'admin':
      return const Color(0xFFEC4899);
    default:
      return BrandColors.orange;
  }
}

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(employeesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
      data: (employees) {
        final q = _search.trim().toLowerCase();
        final list = q.isEmpty
            ? employees
            : employees
                .where((e) =>
                    e.name.toLowerCase().contains(q) ||
                    e.role.toLowerCase().contains(q))
                .toList();
        final active = employees.where((e) => e.active).length;
        final roles = employees.map((e) => e.role).toSet().length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.lg, Sp.xl, Sp.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Gestión de Empleados',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  FilledButton.icon(
                    onPressed: () => _addEmployee(context, ref),
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('Agregar'),
                    style:
                        FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.xl, 0, Sp.xl, Sp.md),
              child: Wrap(
                spacing: Sp.md,
                runSpacing: Sp.md,
                children: [
                  _Stat(value: '${employees.length}', label: 'Total'),
                  _Stat(
                      value: '$active',
                      label: 'Activos',
                      color: const Color(0xFF22C55E)),
                  _Stat(
                      value: '$roles',
                      label: 'Roles',
                      color: const Color(0xFF3B82F6)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.xl, 0, Sp.xl, Sp.md),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre o rol…',
                  prefixIcon: Icon(Icons.search, color: BrandColors.inkFaint),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(Sp.xl, 0, Sp.xl, Sp.xl),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: Sp.sm),
                itemBuilder: (_, i) => _EmployeeTile(employee: list[i])
                    .animate()
                    .fadeIn(duration: 200.ms, delay: (i * 18).ms),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addEmployee(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final pin = TextEditingController();
    var role = 'mesero';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nuevo empleado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: Sp.md),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: [
                  for (final r in _roles)
                    DropdownMenuItem(value: r, child: Text(r))
                ],
                onChanged: (v) => role = v ?? 'mesero',
              ),
              const SizedBox(height: Sp.md),
              TextField(
                controller: pin,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'PIN (4 dígitos)'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Crear')),
          ],
        ),
      ),
    );
    if (ok == true) {
      try {
        await ref.read(adminRepositoryProvider).createEmployee(
              name: name.text.trim(),
              role: role,
              pin: pin.text.trim(),
            );
        ref.invalidate(employeesProvider);
      } catch (e) {
        if (context.mounted) {
          showError(
              context,
              e.toString().contains('409')
                  ? 'PIN ya en uso'
                  : 'No se pudo crear (revisa PIN de 4 dígitos)');
        }
      }
    }
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _Stat(
      {required this.value, required this.label, this.color = BrandColors.ink});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(Sp.lg),
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Rad.lg),
        boxShadow: Shadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: BrandColors.inkSoft, fontSize: 13)),
          const SizedBox(height: Sp.xs),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _EmployeeTile extends ConsumerWidget {
  final Employee employee;
  const _EmployeeTile({required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = employee.avatarColor ?? _roleColor(employee.role);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              employee.initials ??
                  (employee.name.isNotEmpty ? employee.name[0] : '?'),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Sp.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: _roleColor(employee.role).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(Rad.pill),
                  ),
                  child: Text(employee.role,
                      style: TextStyle(
                          color: _roleColor(employee.role),
                          fontWeight: FontWeight.w700,
                          fontSize: 11)),
                ),
              ],
            ),
          ),
          if (employee.shift != null) ...[
            Text(employee.shift!,
                style: const TextStyle(
                    color: BrandColors.inkSoft, fontWeight: FontWeight.w600)),
            const SizedBox(width: Sp.lg),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: employee.active
                        ? const Color(0xFF22C55E)
                        : BrandColors.inkFaint,
                    shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(employee.active ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                      color: employee.active
                          ? const Color(0xFF1E7D34)
                          : BrandColors.inkFaint,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(width: Sp.sm),
          Switch(
            value: employee.active,
            onChanged: (v) async {
              await ref
                  .read(adminRepositoryProvider)
                  .updateEmployee(employee.id, active: v);
              ref.invalidate(employeesProvider);
            },
          ),
        ],
      ),
    );
  }
}
