import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories.dart';
import '../../models/restaurant_table.dart';
import '../../models/waitlist_entry.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/ui_kit.dart';

/// Lista de Espera (hostess): grupos en espera + alta de grupo. Sugiere la mesa
/// libre más pequeña que alcanza y la sienta (`/waitlist`).
class HostessScreen extends ConsumerWidget {
  const HostessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waitlistAsync = ref.watch(waitlistProvider);
    final tables = ref.watch(tablesProvider).value ?? const <RestaurantTable>[];
    final wide = MediaQuery.sizeOf(context).width >= 840;

    final list = waitlistAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
      data: (entries) {
        final waiting = entries.where((e) => e.isWaiting).toList();
        if (waiting.isEmpty) {
          return const EmptyState(
              icon: Icons.event_seat, message: 'Nadie en espera');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(Sp.xl),
          itemCount: waiting.length,
          separatorBuilder: (_, __) => const SizedBox(height: Sp.md),
          itemBuilder: (_, i) => _EntryCard(
            index: i + 1,
            entry: waiting[i],
            tables: tables,
            onSeat: () => _seat(context, ref, waiting[i]),
          )
              .animate()
              .fadeIn(duration: 220.ms, delay: (i * 30).ms)
              .slideX(begin: 0.06, end: 0, curve: Curves.easeOut),
        );
      },
    );

    final form = _AddForm(
      onAdd: (name, size, phone) => _add(context, ref, name, size, phone),
    );

    if (wide) {
      return Row(
        children: [
          Expanded(child: list),
          Container(
            width: 340,
            margin: const EdgeInsets.fromLTRB(0, Sp.lg, Sp.lg, Sp.lg),
            decoration: BoxDecoration(
              color: BrandColors.surface,
              borderRadius: BorderRadius.circular(Rad.lg),
              boxShadow: Shadows.card,
            ),
            clipBehavior: Clip.antiAlias,
            child: form,
          ),
        ],
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.lg, Sp.lg, 0),
          child: AppCard(child: form),
        ),
        Expanded(child: list),
      ],
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref, String name, int size,
      String? phone) async {
    try {
      await ref
          .read(serviceRepositoryProvider)
          .addWaitlist(name: name, size: size, phone: phone);
      ref.invalidate(waitlistProvider);
      ref.invalidate(tablesProvider);
    } catch (e) {
      if (context.mounted) showError(context, 'No se pudo agregar el grupo');
    }
  }

  Future<void> _seat(
      BuildContext context, WidgetRef ref, WaitlistEntry entry) async {
    final tableId = entry.suggestedTableId;
    if (tableId == null) {
      showError(context, 'No hay mesa libre que alcance para el grupo');
      return;
    }
    try {
      await ref
          .read(serviceRepositoryProvider)
          .seatWaitlist(entry.id, tableId: tableId);
      ref.invalidate(waitlistProvider);
      ref.invalidate(tablesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${entry.name} sentado')),
        );
      }
    } catch (e) {
      if (context.mounted) showError(context, 'No se pudo sentar al grupo');
    }
  }
}

class _EntryCard extends StatelessWidget {
  final int index;
  final WaitlistEntry entry;
  final List<RestaurantTable> tables;
  final VoidCallback onSeat;
  const _EntryCard(
      {required this.index,
      required this.entry,
      required this.tables,
      required this.onSeat});

  @override
  Widget build(BuildContext context) {
    int? suggestedNumber;
    if (entry.suggestedTableId != null) {
      for (final t in tables) {
        if (t.id == entry.suggestedTableId) {
          suggestedNumber = t.number;
          break;
        }
      }
    }
    final canSeat = suggestedNumber != null;

    return AppCard(
      padding: const EdgeInsets.all(Sp.lg),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BrandColors.orangeSoft,
              borderRadius: BorderRadius.circular(Rad.md),
            ),
            child: Text('$index',
                style: const TextStyle(
                    color: BrandColors.orangeInk,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.groups,
                        size: 14, color: BrandColors.inkFaint),
                    const SizedBox(width: 4),
                    Text('${entry.size} personas',
                        style: const TextStyle(
                            color: BrandColors.inkSoft, fontSize: 13)),
                    if (entry.phone != null) ...[
                      const SizedBox(width: Sp.md),
                      const Icon(Icons.phone,
                          size: 13, color: BrandColors.inkFaint),
                      const SizedBox(width: 4),
                      Text(entry.phone!,
                          style: const TextStyle(
                              color: BrandColors.inkSoft, fontSize: 13)),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Sp.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: canSeat
                        ? const Color(0x1A22C55E)
                        : BrandColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(Rad.pill),
                  ),
                  child: Text(
                    canSeat ? 'Mesa $suggestedNumber lista' : 'Sin mesa disponible',
                    style: TextStyle(
                      color: canSeat
                          ? const Color(0xFF1E7D34)
                          : BrandColors.inkFaint,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Sp.md),
          SizedBox(
            width: 132,
            child: GradientButton(
              label: 'Sentar',
              icon: Icons.event_seat,
              height: 48,
              onTap: canSeat ? onSeat : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddForm extends StatefulWidget {
  final void Function(String name, int size, String? phone) onAdd;
  const _AddForm({required this.onAdd});

  @override
  State<_AddForm> createState() => _AddFormState();
}

class _AddFormState extends State<_AddForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  int _size = 2;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    widget.onAdd(name, _size, _phone.text.trim());
    setState(() {
      _name.clear();
      _phone.clear();
      _size = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Sp.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Agregar a la lista',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: Sp.lg),
          TextField(
            controller: _name,
            decoration: const InputDecoration(hintText: 'Nombre del grupo'),
          ),
          const SizedBox(height: Sp.md),
          Row(
            children: [
              const Text('Personas',
                  style: TextStyle(
                      color: BrandColors.inkSoft, fontWeight: FontWeight.w600)),
              const Spacer(),
              QtyStepper(
                value: _size,
                onRemove: _size > 1 ? () => setState(() => _size--) : null,
                onAdd: _size < 20 ? () => setState(() => _size++) : null,
              ),
            ],
          ),
          const SizedBox(height: Sp.md),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'Teléfono (opcional)'),
          ),
          const SizedBox(height: Sp.lg),
          GradientButton(
            label: 'Agregar grupo',
            icon: Icons.person_add_alt,
            onTap: _submit,
          ),
        ],
      ),
    );
  }
}
