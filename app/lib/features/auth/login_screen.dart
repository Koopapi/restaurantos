import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/tokens.dart';
import '../../widgets/ui_kit.dart';
import 'auth_controller.dart';

/// Inicio de sesión por **empleado + PIN** (4 dígitos), con diseño claro premium.
///
/// Tablet: panel de marca (degradado) + tarjeta de PIN. Teléfono: tarjeta sola.
/// Al completar 4 dígitos se intenta el login automáticamente.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _employeeId = TextEditingController(text: 'emp_carlos');
  String _pin = '';
  int _errorPulse = 0;

  static const _maxPin = 4;

  static const _quick = [
    ('Carlos · Mesero', 'emp_carlos'),
    ('Sofía · Admin', 'emp_sofia'),
    ('Ana · Cocina', 'emp_ana'),
  ];

  @override
  void dispose() {
    _employeeId.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final id = _employeeId.text.trim();
    if (id.isEmpty || _pin.length != _maxPin) {
      return;
    }
    final ok = await ref
        .read(authControllerProvider.notifier)
        .login(employeeId: id, pin: _pin);
    if (!ok && mounted) {
      HapticFeedback.heavyImpact();
      setState(() {
        _pin = '';
        _errorPulse++;
      });
    }
    // La navegación al home la maneja el redirect del router al cambiar el estado.
  }

  void _onDigit(String d) {
    if (_pin.length >= _maxPin) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _pin += d);
    if (_pin.length == _maxPin) {
      _submit();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  const Expanded(flex: 5, child: _BrandPanel()),
                  Expanded(flex: 4, child: Center(child: _loginCard())),
                ],
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Sp.xl),
                  child: _loginCard(showLogo: true),
                ),
              ),
      ),
    );
  }

  Widget _loginCard({bool showLogo = false}) {
    final auth = ref.watch(authControllerProvider);

    Widget dots = _PinDots(length: _maxPin, filled: _pin.length);
    if (_errorPulse > 0) {
      dots = dots
          .animate(key: ValueKey(_errorPulse))
          .shakeX(duration: 420.ms, hz: 4, amount: 7);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: Sp.xl, vertical: Sp.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showLogo) ...[
              const Center(child: BrandMark(size: 64)),
              const SizedBox(height: Sp.lg),
            ],
            Text(
              'Bienvenido',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: Sp.xs),
            const Text(
              'Ingresa tu PIN para entrar a tu turno',
              textAlign: TextAlign.center,
              style: TextStyle(color: BrandColors.inkSoft),
            ),
            const SizedBox(height: Sp.xl),
            TextField(
              controller: _employeeId,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'Empleado',
                prefixIcon: Icon(Icons.badge_outlined, color: BrandColors.inkFaint),
              ),
            ),
            const SizedBox(height: Sp.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: Sp.sm,
              runSpacing: Sp.sm,
              children: [
                for (final (label, id) in _quick)
                  _QuickChip(
                    label: label,
                    selected: _employeeId.text == id,
                    onTap: () => setState(() {
                      _employeeId.text = id;
                      _pin = '';
                    }),
                  ),
              ],
            ),
            const SizedBox(height: Sp.xl),
            dots,
            SizedBox(
              height: 28,
              child: Center(
                child: auth.error != null
                    ? Text(
                        auth.error!,
                        style: const TextStyle(
                          color: Color(0xFFD92D20),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: Sp.sm),
            SizedBox(
              height: 264,
              child: auth.isBusy
                  ? const Center(child: CircularProgressIndicator())
                  : _Keypad(onDigit: _onDigit, onBackspace: _onBackspace),
            ),
            const SizedBox(height: Sp.md),
            const Text(
              'Demo · PIN: Carlos 2222 · Sofía 6666 · Ana 3333',
              textAlign: TextAlign.center,
              style: TextStyle(color: BrandColors.inkFaint, fontSize: 12),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 420.ms)
          .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
    );
  }
}

/// Panel de marca (solo tablet): degradado naranja, logo, eslogan y círculos
/// decorativos para dar profundidad.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(Sp.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [BrandColors.orangeBright, BrandColors.orangeDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Rad.xl),
        boxShadow: Shadows.glow(BrandColors.orange, opacity: 0.3),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _circle(220, Colors.white.withValues(alpha: 0.10)),
          ),
          Positioned(
            bottom: -50,
            left: -30,
            child: _circle(180, Colors.white.withValues(alpha: 0.08)),
          ),
          Padding(
            padding: const EdgeInsets.all(Sp.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.restaurant_menu,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: Sp.md),
                    const Text(
                      'RestaurantOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Tu piso,\nen tiempo real.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 500.ms).slideX(
                      begin: -0.08,
                      end: 0,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: Sp.md),
                Text(
                  'Mesas, comandas, cocina y cobro — sincronizados al instante en cada tableta.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Sp.xl),
                const Row(
                  children: [
                    _Feature(icon: Icons.bolt, label: 'Tiempo real'),
                    SizedBox(width: Sp.xl),
                    _Feature(icon: Icons.tablet_mac, label: 'Touch-first'),
                    SizedBox(width: Sp.xl),
                    _Feature(icon: Icons.insights, label: 'Reportes'),
                  ],
                ),
                const Spacer(),
                Text(
                  'El Pirrus · Marisquería',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double d, Color c) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Feature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: Sp.xs),
        Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _QuickChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Dur.fast,
        padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: Sp.sm),
        decoration: BoxDecoration(
          color: selected ? BrandColors.orangeSoft : BrandColors.surfaceAlt,
          borderRadius: BorderRadius.circular(Rad.pill),
          border: Border.all(
            color: selected ? BrandColors.orange : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? BrandColors.orangeInk : BrandColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  final int length;
  final int filled;
  const _PinDots({required this.length, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final on = i < filled;
        return AnimatedContainer(
          duration: Dur.med,
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.symmetric(horizontal: 9),
          width: on ? 20 : 18,
          height: on ? 20 : 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? BrandColors.orange : Colors.transparent,
            border: Border.all(
              color: on ? BrandColors.orange : BrandColors.inkFaint,
              width: 2,
            ),
            boxShadow: on ? Shadows.glow(BrandColors.orange, opacity: 0.4) : null,
          ),
        );
      }),
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  const _Keypad({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 3; row++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var col = 0; col < 3; col++) _key(keys[row * 3 + col]),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 78, height: 64),
            _key('0'),
            _key('', backspace: true),
          ],
        ),
      ],
    );
  }

  Widget _key(String d, {bool backspace = false}) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: PressableScale(
        onTap: backspace ? onBackspace : () => onDigit(d),
        child: Container(
          width: 68,
          height: 54,
          decoration: BoxDecoration(
            color: BrandColors.surface,
            borderRadius: BorderRadius.circular(Rad.lg),
            boxShadow: Shadows.soft,
            border: Border.all(color: BrandColors.hairline),
          ),
          child: Center(
            child: backspace
                ? const Icon(Icons.backspace_outlined,
                    color: BrandColors.inkSoft, size: 22)
                : Text(
                    d,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: BrandColors.ink,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
