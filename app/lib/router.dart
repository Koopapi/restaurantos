import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_shell.dart';

/// Router con redirección basada en sesión: sin sesión → /login;
/// con sesión → /home. `refreshListenable` reconstruye las rutas cuando
/// cambia el estado de autenticación.
final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<bool>(
    ref.read(authControllerProvider).isAuthenticated,
  );
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (_, next) {
    refresh.value = next.isAuthenticated;
  });

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authed = ref.read(authControllerProvider).isAuthenticated;
      final onLogin = state.matchedLocation == '/login';
      if (!authed) return onLogin ? null : '/login';
      if (onLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeShell()),
    ],
  );
});
