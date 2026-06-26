import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_repository.dart';
import '../../state/admin_providers.dart';
import '../../widgets/common.dart';
import '../auth/employee.dart';

const _roles = ['mesero', 'cocina', 'barista', 'hostess', 'gerente', 'admin'];

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(employeesProvider);
    return Scaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
        data: (employees) => ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: employees.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _EmployeeTile(employee: employees[i]),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addEmployee(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo'),
      ),
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: [
                  for (final r in _roles)
                    DropdownMenuItem(value: r, child: Text(r))
                ],
                onChanged: (v) => role = v ?? 'mesero',
              ),
              const SizedBox(height: 12),
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

class _EmployeeTile extends ConsumerWidget {
  final Employee employee;
  const _EmployeeTile({required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: employee.avatarColor,
          child: Text(employee.initials ?? employee.name[0],
              style: const TextStyle(color: Colors.white)),
        ),
        title: Text(employee.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle:
            Text('${employee.role}${employee.active ? "" : " · inactivo"}'),
        trailing: Switch(
          value: employee.active,
          onChanged: (v) async {
            await ref
                .read(adminRepositoryProvider)
                .updateEmployee(employee.id, active: v);
            ref.invalidate(employeesProvider);
          },
        ),
      ),
    );
  }
}
