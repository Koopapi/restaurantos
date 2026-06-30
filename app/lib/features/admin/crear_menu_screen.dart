import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_repository.dart';
import '../../models/app_config.dart';
import '../../models/menu_item.dart';
import '../../state/admin_providers.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/ui_kit.dart';

/// Crear Nuevo Menú (colección): nombre, horario y selección de platillos.
class CrearMenuScreen extends ConsumerStatefulWidget {
  const CrearMenuScreen({super.key});

  @override
  ConsumerState<CrearMenuScreen> createState() => _CrearMenuScreenState();
}

class _CrearMenuScreenState extends ConsumerState<CrearMenuScreen> {
  final _name = TextEditingController();
  final _schedule = TextEditingController();
  final _selected = <String>{};
  String _search = '';
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _schedule.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuProvider);
    final wide = MediaQuery.sizeOf(context).width >= 840;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Nuevo Menú')),
      body: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
        data: (menu) {
          final q = _search.trim().toLowerCase();
          final items = q.isEmpty
              ? menu
              : menu
                  .where((m) =>
                      m.name.toLowerCase().contains(q) ||
                      m.category.toLowerCase().contains(q))
                  .toList();

          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.lg, Sp.xl, Sp.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _name,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                          labelText: 'Nombre del menú',
                          hintText: 'Ej: Menú Ejecutivo'),
                    ),
                    const SizedBox(height: Sp.md),
                    TextField(
                      controller: _schedule,
                      decoration: const InputDecoration(
                          labelText: 'Horario (opcional)',
                          hintText: 'Ej: 13:00 - 17:00'),
                    ),
                    const SizedBox(height: Sp.lg),
                    Row(
                      children: [
                        const Text('Selecciona platillos',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text('${_selected.length} seleccionados',
                            style: const TextStyle(
                                color: BrandColors.orangeInk,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: Sp.sm),
                    TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: const InputDecoration(
                        hintText: 'Buscar platillos del catálogo…',
                        prefixIcon:
                            Icon(Icons.search, color: BrandColors.inkFaint),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.fromLTRB(Sp.xl, Sp.sm, Sp.xl, Sp.xl),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Sp.sm),
                  itemBuilder: (_, i) => _DishPick(
                    item: items[i],
                    selected: _selected.contains(items[i].id),
                    onTap: () => setState(() {
                      if (!_selected.remove(items[i].id)) {
                        _selected.add(items[i].id);
                      }
                    }),
                  ),
                ),
              ),
            ],
          );

          final summary = _Summary(
            name: _name.text,
            schedule: _schedule.text,
            count: _selected.length,
            busy: _busy,
            onCreate:
                _selected.isEmpty || _name.text.trim().isEmpty ? null : _create,
          );

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: left),
                Container(
                  width: 320,
                  margin: const EdgeInsets.fromLTRB(0, Sp.lg, Sp.lg, Sp.lg),
                  child: summary,
                ),
              ],
            );
          }
          return Column(
            children: [
              Expanded(child: left),
              Padding(padding: const EdgeInsets.all(Sp.lg), child: summary),
            ],
          );
        },
      ),
    );
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).createCollection(
            name: _name.text.trim(),
            schedule: _schedule.text.trim(),
            itemIds: _selected.toList(),
          );
      ref.invalidate(collectionsProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menú creado')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context, 'No se pudo crear el menú');
      }
    }
  }
}

class _DishPick extends StatelessWidget {
  final MenuItem item;
  final bool selected;
  final VoidCallback onTap;
  const _DishPick(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Sp.lg, vertical: Sp.md),
      onTap: onTap,
      border: selected
          ? const BorderSide(color: BrandColors.orange, width: 1.5)
          : BorderSide.none,
      color: selected ? BrandColors.orangeSoft : BrandColors.surface,
      child: Row(
        children: [
          AnimatedContainer(
            duration: Dur.fast,
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: selected ? BrandColors.orange : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                  color: selected ? BrandColors.orange : BrandColors.inkFaint,
                  width: 2),
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(item.category,
                    style: const TextStyle(
                        color: BrandColors.inkFaint, fontSize: 12)),
              ],
            ),
          ),
          Text(money(item.price),
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: BrandColors.orangeInk)),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final String name;
  final String schedule;
  final int count;
  final bool busy;
  final VoidCallback? onCreate;
  const _Summary({
    required this.name,
    required this.schedule,
    required this.count,
    required this.busy,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Rad.lg),
        boxShadow: Shadows.card,
      ),
      padding: const EdgeInsets.all(Sp.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resumen del Menú',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: Sp.lg),
          _row('Nombre', name.isEmpty ? '—' : name),
          _row('Platillos', '$count'),
          _row('Horario', schedule.isEmpty ? 'Todo el día' : schedule),
          const SizedBox(height: Sp.xl),
          busy
              ? const Center(child: CircularProgressIndicator())
              : GradientButton(
                  label: 'Crear Menú',
                  icon: Icons.check_rounded,
                  onTap: onCreate,
                ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Sp.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: BrandColors.inkSoft)),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}
