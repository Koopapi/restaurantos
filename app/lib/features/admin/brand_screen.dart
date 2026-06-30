import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_repository.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/common.dart';
import '../../widgets/ui_kit.dart';

const _swatches = [
  Color(0xFFFF9800), // naranja (El Pirrus)
  Color(0xFF6750A4), // violeta
  Color(0xFF2563EB), // azul
  Color(0xFF16A34A), // verde
  Color(0xFFDC2626), // rojo
  Color(0xFF0891B2), // cian
  Color(0xFFDB2777), // rosa
  Color(0xFFF59E0B), // ámbar
];

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Marca y Tema (solo admin): color de marca (white-label, re-tematiza la app
/// en vivo), reglas de negocio y vista previa. `PUT /api/config`.
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
  Color _color = BrandColors.orange;
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
    final wide = MediaQuery.sizeOf(context).width >= 840;

    return configAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.cloud_off, message: '$e'),
      data: (config) {
        if (!_loaded) {
          _brand.text = config.brandName;
          _taxRate.text = '${(config.taxRate * 100)}';
          _urgency.text = '${config.urgencyMinutes}';
          _maxQty.text = '${config.maxQtyPerLine}';
          _color = config.primaryColorValue;
          _loaded = true;
        }

        final form = ListView(
          padding: const EdgeInsets.all(Sp.xl),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Marca y Tema',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const Text('Personaliza la identidad de tu restaurante',
                          style: TextStyle(color: BrandColors.inkSoft)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: GradientButton(
                    label: 'Publicar',
                    icon: Icons.check_rounded,
                    onTap: _busy ? null : _save,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sp.lg),
            AppCard(
              padding: const EdgeInsets.all(Sp.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Color de marca',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: Sp.lg),
                  Wrap(
                    spacing: Sp.md,
                    runSpacing: Sp.md,
                    children: [
                      for (final c in _swatches)
                        _Swatch(
                          color: c,
                          selected: _hex(c) == _hex(_color),
                          onTap: () => setState(() => _color = c),
                        ),
                    ],
                  ),
                  const SizedBox(height: Sp.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Sp.lg, vertical: Sp.md),
                    decoration: BoxDecoration(
                      color: BrandColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(Rad.md),
                    ),
                    child: Row(
                      children: [
                        const Text('#',
                            style: TextStyle(
                                color: BrandColors.inkFaint,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: Sp.sm),
                        Text(_hex(_color).substring(1),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, letterSpacing: 1)),
                        const Spacer(),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                              color: _color,
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Sp.md),
            AppCard(
              padding: const EdgeInsets.all(Sp.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Logo del restaurante',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: Sp.md),
                  DottedZone(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Subir logo — próximamente')),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Sp.md),
            AppCard(
              padding: const EdgeInsets.all(Sp.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reglas de negocio',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: Sp.lg),
                  TextField(
                      controller: _brand,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                          labelText: 'Nombre del negocio')),
                  const SizedBox(height: Sp.md),
                  TextField(
                    controller: _taxRate,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Tasa de impuesto (%)', suffixText: '%'),
                  ),
                  const SizedBox(height: Sp.md),
                  TextField(
                    controller: _urgency,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Minutos de urgencia (KDS)'),
                  ),
                  const SizedBox(height: Sp.md),
                  TextField(
                    controller: _maxQty,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Cantidad máxima por línea'),
                  ),
                ],
              ),
            ),
          ],
        );

        final preview = _LivePreview(color: _color, brand: _brand.text);

        if (wide) {
          return Row(
            children: [
              Expanded(child: form),
              Container(
                width: 360,
                margin: const EdgeInsets.fromLTRB(0, Sp.xl, Sp.xl, Sp.xl),
                child: preview,
              ),
            ],
          );
        }
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            form,
            Padding(padding: const EdgeInsets.all(Sp.xl), child: preview),
          ],
        );
      },
    );
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final fields = <String, dynamic>{
      'brandName': _brand.text.trim(),
      'primaryColor': _hex(_color),
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
          const SnackBar(
              content: Text('Marca publicada · la app se actualizó')),
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

class _Swatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _Swatch(
      {required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
              color: selected ? BrandColors.ink : Colors.transparent, width: 3),
          boxShadow: selected ? Shadows.glow(color, opacity: 0.5) : null,
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 22)
            : null,
      ),
    );
  }
}

/// Zona punteada de subida (placeholder visual).
class DottedZone extends StatelessWidget {
  final VoidCallback onTap;
  const DottedZone({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 110,
        width: double.infinity,
        decoration: BoxDecoration(
          color: BrandColors.surfaceAlt,
          borderRadius: BorderRadius.circular(Rad.md),
          border: Border.all(color: BrandColors.hairline, width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, color: BrandColors.inkFaint, size: 28),
            SizedBox(height: Sp.sm),
            Text('Arrastra tu logo o haz clic para subir',
                style: TextStyle(color: BrandColors.inkSoft)),
            Text('SVG, PNG o JPG (máx. 2MB)',
                style: TextStyle(color: BrandColors.inkFaint, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// Vista previa en vivo de la marca (usa el color elegido directamente).
class _LivePreview extends StatelessWidget {
  final Color color;
  final String brand;
  const _LivePreview({required this.color, required this.brand});

  @override
  Widget build(BuildContext context) {
    final grad = brandGradient(color);
    return Container(
      decoration: BoxDecoration(
        color: BrandColors.surface,
        borderRadius: BorderRadius.circular(Rad.lg),
        boxShadow: Shadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(Sp.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: grad,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.restaurant_menu,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: Sp.sm),
                Expanded(
                  child: Text(
                    brand.isEmpty ? 'Tu Restaurante' : brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16),
                  ),
                ),
                const Row(
                  children: [
                    Text('Menú',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    SizedBox(width: Sp.sm),
                    Text('Pedidos',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Sp.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vista Previa en Vivo',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: BrandColors.ink)),
                const SizedBox(height: 2),
                const Text('Así se ve tu marca en la app',
                    style:
                        TextStyle(color: BrandColors.inkFaint, fontSize: 12)),
                const SizedBox(height: Sp.lg),
                Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: grad),
                    borderRadius: BorderRadius.circular(Rad.pill),
                    boxShadow: Shadows.glow(color, opacity: 0.35),
                  ),
                  child: const Text('Acción principal',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
                const SizedBox(height: Sp.md),
                Row(
                  children: [
                    _chip('Activo', color),
                    const SizedBox(width: Sp.sm),
                    _chip('Listo', const Color(0xFF22C55E)),
                    const SizedBox(width: Sp.sm),
                    _chip('Urgente', const Color(0xFFEF4444)),
                  ],
                ),
                const SizedBox(height: Sp.lg),
                Container(
                  padding: const EdgeInsets.all(Sp.md),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(Rad.md),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, color: color, size: 22),
                      const SizedBox(width: Sp.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('\$12,480',
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20)),
                          const Text('Ventas de hoy',
                              style: TextStyle(
                                  color: BrandColors.inkSoft, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 5),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(Rad.pill),
        ),
        child: Text(label,
            style:
                TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12)),
      );
}
