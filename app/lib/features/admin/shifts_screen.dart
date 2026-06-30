import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_repository.dart';
import '../../models/shift.dart';
import '../../state/admin_providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/ui_kit.dart';

const _dayLetters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
const _months = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
];

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

({String label, Color color, String time}) _typeViz(String type) {
  switch (type) {
    case 'matutino':
      return (label: 'Matutino', color: const Color(0xFF3B82F6), time: '09:00 – 17:00');
    case 'vespertino':
      return (label: 'Vespertino', color: const Color(0xFF8B5CF6), time: '14:00 – 22:00');
    default:
      return (label: 'Completo', color: const Color(0xFF22C55E), time: '09:00 – 21:00');
  }
}

int _shiftHours(Shift s) {
  if (s.start != null && s.end != null) {
    final a = s.start!.split(':');
    final b = s.end!.split(':');
    if (a.length == 2 && b.length == 2) {
      final mins = (int.tryParse(b[0]) ?? 0) * 60 +
          (int.tryParse(b[1]) ?? 0) -
          (int.tryParse(a[0]) ?? 0) * 60 -
          (int.tryParse(a[1]) ?? 0);
      if (mins > 0) return (mins / 60).round();
    }
  }
  return s.type == 'completo' ? 12 : 8;
}

class ShiftsScreen extends ConsumerStatefulWidget {
  const ShiftsScreen({super.key});

  @override
  ConsumerState<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends ConsumerState<ShiftsScreen> {
  int _weekOffset = 0;
  int _selectedDay = 0; // 0..6 (lunes..domingo)

  DateTime get _weekStart {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return monday.add(Duration(days: _weekOffset * 7));
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().weekday - 1; // hoy dentro de la semana actual
  }

  @override
  Widget build(BuildContext context) {
    final shiftsAsync = ref.watch(shiftsProvider);
    final employees = ref.watch(employeesProvider).value ?? const [];
    final days = [for (var i = 0; i < 7; i++) _weekStart.add(Duration(days: i))];
    final selectedIso = _iso(days[_selectedDay]);

    String nameOf(String id) {
      for (final e in employees) {
        if (e.id == id) return e.name;
      }
      return id;
    }

    return shiftsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
      data: (allShifts) {
        final weekIso = days.map(_iso).toSet();
        final weekShifts =
            allShifts.where((s) => weekIso.contains(s.date)).toList();
        final dayShifts =
            allShifts.where((s) => s.date == selectedIso).toList();
        final totalHours =
            weekShifts.fold<int>(0, (h, s) => h + _shiftHours(s));
        final assigned = weekShifts.map((s) => s.employeeId).toSet().length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.lg, Sp.xl, Sp.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gestionar Turnos',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const Text('Organiza los horarios de tu equipo',
                            style: TextStyle(color: BrandColors.inkSoft)),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _addShift(context, selectedIso),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Turno'),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  ),
                ],
              ),
            ),
            // Navegación de semana
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => setState(() => _weekOffset--),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '${days.first.day} ${_months[days.first.month - 1]} – ${days.last.day} ${_months[days.last.month - 1]} ${days.last.year}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  onPressed: () => setState(() => _weekOffset++),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: Sp.sm),
            // Selector de día
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Sp.xl),
              child: Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _DayChip(
                          letter: _dayLetters[i],
                          day: days[i].day,
                          selected: i == _selectedDay,
                          onTap: () => setState(() => _selectedDay = i),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Sp.md),
            Expanded(
              child: dayShifts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 48, color: BrandColors.inkFaint),
                          const SizedBox(height: Sp.md),
                          const Text('No hay turnos para este día',
                              style: TextStyle(color: BrandColors.inkSoft)),
                          const SizedBox(height: Sp.md),
                          OutlinedButton(
                            onPressed: () => _addShift(context, selectedIso),
                            child: const Text('Agregar turno'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(Sp.xl, 0, Sp.xl, Sp.xl),
                      itemCount: dayShifts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: Sp.sm),
                      itemBuilder: (_, i) => _ShiftTile(
                        shift: dayShifts[i],
                        employeeName: nameOf(dayShifts[i].employeeId),
                        onDelete: () => _delete(dayShifts[i].id),
                      ),
                    ),
            ),
            // Resumen de la semana
            Container(
              padding: const EdgeInsets.all(Sp.lg),
              decoration: const BoxDecoration(
                color: BrandColors.surface,
                border: Border(top: BorderSide(color: BrandColors.hairline)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summary('Turnos semana', '${weekShifts.length}'),
                  _summary('Total horas', '${totalHours}h'),
                  _summary('Empleados asignados', '$assigned'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summary(String label, String value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 16, color: BrandColors.orangeInk),
          const SizedBox(width: Sp.sm),
          Text('$label: ',
              style: const TextStyle(color: BrandColors.inkSoft)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      );

  Future<void> _delete(String id) async {
    try {
      await ref.read(adminRepositoryProvider).deleteShift(id);
      ref.invalidate(shiftsProvider);
    } catch (e) {
      if (mounted) showError(context, 'No se pudo eliminar el turno');
    }
  }

  Future<void> _addShift(BuildContext context, String date) async {
    final employees = ref.read(employeesProvider).value ?? const [];
    if (employees.isEmpty) {
      showError(context, 'No hay empleados');
      return;
    }
    var employeeId = employees.first.id;
    var type = 'completo';
    final start = TextEditingController();
    final end = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Nuevo turno'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: employeeId,
                decoration: const InputDecoration(labelText: 'Empleado'),
                items: [
                  for (final e in employees)
                    DropdownMenuItem(value: e.id, child: Text(e.name))
                ],
                onChanged: (v) => employeeId = v ?? employeeId,
              ),
              const SizedBox(height: Sp.md),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: 'matutino', child: Text('Matutino')),
                  DropdownMenuItem(
                      value: 'vespertino', child: Text('Vespertino')),
                  DropdownMenuItem(value: 'completo', child: Text('Completo')),
                ],
                onChanged: (v) => type = v ?? type,
              ),
              const SizedBox(height: Sp.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: start,
                      decoration: const InputDecoration(
                          labelText: 'Inicio', hintText: '09:00'),
                    ),
                  ),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: TextField(
                      controller: end,
                      decoration: const InputDecoration(
                          labelText: 'Fin', hintText: '17:00'),
                    ),
                  ),
                ],
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
        await ref.read(adminRepositoryProvider).createShift(
              employeeId: employeeId,
              date: date,
              type: type,
              start: start.text.trim(),
              end: end.text.trim(),
            );
        ref.invalidate(shiftsProvider);
      } catch (e) {
        if (context.mounted) showError(context, 'No se pudo crear el turno');
      }
    }
  }
}

class _DayChip extends StatelessWidget {
  final String letter;
  final int day;
  final bool selected;
  final VoidCallback onTap;
  const _DayChip(
      {required this.letter,
      required this.day,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Dur.fast,
        padding: const EdgeInsets.symmetric(vertical: Sp.md),
        decoration: BoxDecoration(
          color: selected ? BrandColors.orange : BrandColors.surface,
          borderRadius: BorderRadius.circular(Rad.md),
          boxShadow: selected ? Shadows.glow(BrandColors.orange) : Shadows.soft,
          border: Border.all(
              color: selected ? BrandColors.orange : BrandColors.hairline),
        ),
        child: Column(
          children: [
            Text(letter,
                style: TextStyle(
                    color: selected ? Colors.white : BrandColors.inkSoft,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
            const SizedBox(height: 2),
            Text('$day',
                style: TextStyle(
                    color: selected ? Colors.white : BrandColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class _ShiftTile extends StatelessWidget {
  final Shift shift;
  final String employeeName;
  final VoidCallback onDelete;
  const _ShiftTile(
      {required this.shift,
      required this.employeeName,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final v = _typeViz(shift.type);
    final time = (shift.start != null && shift.end != null)
        ? '${shift.start} – ${shift.end}'
        : v.time;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 40,
            decoration: BoxDecoration(
                color: v.color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employeeName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Sp.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: v.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(Rad.pill),
                      ),
                      child: Text(v.label,
                          style: TextStyle(
                              color: v.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 11)),
                    ),
                    const SizedBox(width: Sp.sm),
                    Text(time,
                        style: const TextStyle(
                            color: BrandColors.inkSoft, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: BrandColors.inkFaint),
          ),
        ],
      ),
    );
  }
}
