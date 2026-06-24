import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

/// Pantalla de inicio de sesión por **empleado + PIN** (4 dígitos).
///
/// Como `GET /api/employees` requiere rol gerente/admin, en esta fase el
/// empleado se identifica escribiendo su ID; al completar 4 dígitos se intenta
/// el login automáticamente. Credenciales demo abajo.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _employeeId = TextEditingController(text: 'emp_carlos');
  String _pin = '';

  static const _maxPin = 4;

  @override
  void dispose() {
    _employeeId.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final id = _employeeId.text.trim();
    if (id.isEmpty || _pin.length != _maxPin) return;
    final ok = await ref.read(authControllerProvider.notifier).login(
          employeeId: id,
          pin: _pin,
        );
    if (!ok && mounted) {
      setState(() => _pin = ''); // limpia el PIN al fallar
    }
    // La navegación al home la maneja el redirect del router al cambiar el estado.
  }

  void _onDigit(String d) {
    if (_pin.length >= _maxPin) return;
    setState(() => _pin += d);
    if (_pin.length == _maxPin) _submit();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.restaurant_menu,
                    size: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text('RestaurantOS', style: theme.textTheme.headlineSmall),
                Text('Inicia sesión con tu PIN',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 24),
                TextField(
                  controller: _employeeId,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'Empleado',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                _PinDots(length: _maxPin, filled: _pin.length),
                const SizedBox(height: 8),
                SizedBox(
                  height: 24,
                  child: auth.error != null
                      ? Text(auth.error!,
                          style: TextStyle(color: theme.colorScheme.error),
                          textAlign: TextAlign.center)
                      : null,
                ),
                const SizedBox(height: 8),
                if (auth.isBusy)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                else
                  _Keypad(onDigit: _onDigit, onBackspace: _onBackspace),
                const SizedBox(height: 16),
                Text(
                  'Demo: emp_carlos / 2222 (mesero) · emp_sofia / 6666 (admin)',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final on = i < filled;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? scheme.primary : Colors.transparent,
            border: Border.all(color: scheme.outline, width: 2),
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
            const SizedBox(width: 88, height: 88),
            _key('0'),
            SizedBox(
              width: 88,
              height: 88,
              child: IconButton(
                onPressed: onBackspace,
                icon: const Icon(Icons.backspace_outlined),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _key(String d) => Padding(
        padding: const EdgeInsets.all(6),
        child: SizedBox(
          width: 76,
          height: 76,
          child: OutlinedButton(
            onPressed: () => onDigit(d),
            style: OutlinedButton.styleFrom(
              shape: const CircleBorder(),
              textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            child: Text(d),
          ),
        ),
      );
}
