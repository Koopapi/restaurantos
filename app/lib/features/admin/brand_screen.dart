import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_repository.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// Marca blanca + reglas de negocio (solo admin): `PUT /api/config`.
class BrandScreen extends ConsumerStatefulWidget {
  const BrandScreen({super.key});

  @override
  ConsumerState<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends ConsumerState<BrandScreen> {
  final _brand = TextEditingController();
  final _taxRate = TextEditingController();
  final _urgency = TextEditingController();
  final _maxQty = TextEditingController();
  bool _loaded = false;
  bool _busy = false;

  @override
  void dispose() {
    _brand.dispose();
    _taxRate.dispose();
    _urgency.dispose();
    _maxQty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(configProvider);
    return configAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
      data: (config) {
        if (!_loaded) {
          _brand.text = config.brandName;
          _taxRate.text = '${(config.taxRate * 100)}';
          _urgency.text = '${config.urgencyMinutes}';
          _maxQty.text = '${config.maxQtyPerLine}';
          _loaded = true;
        }
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Marca blanca y reglas',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _brand,
                      decoration: const InputDecoration(
                          labelText: 'Nombre del negocio')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _taxRate,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Tasa de impuesto (%)', suffixText: '%'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urgency,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Minutos de urgencia (KDS)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _maxQty,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Cantidad máxima por línea'),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _save,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Guardar cambios'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final fields = <String, dynamic>{
      'brandName': _brand.text.trim(),
      if (num.tryParse(_taxRate.text) != null)
        'taxRate': num.parse(_taxRate.text) / 100,
      if (int.tryParse(_urgency.text) != null)
        'urgencyMinutes': int.parse(_urgency.text),
      if (int.tryParse(_maxQty.text) != null)
        'maxQtyPerLine': int.parse(_maxQty.text),
    };
    try {
      await ref.read(adminRepositoryProvider).updateConfig(fields);
      ref.invalidate(configProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada')),
        );
      }
    } catch (e) {
      if (mounted) {
        showError(
            context,
            e.toString().contains('403')
                ? 'Solo admin puede cambiar la marca'
                : 'No se pudo guardar');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
