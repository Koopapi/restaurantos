import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'auth_repository.dart';
import 'employee.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated }

@immutable
class AuthState {
  final AuthStatus status;
  final Employee? employee;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.employee,
    this.error,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isBusy => status == AuthStatus.authenticating;

  AuthState copyWith({AuthStatus? status, Employee? employee, String? error}) =>
      AuthState(
        status: status ?? this.status,
        employee: employee ?? this.employee,
        error: error,
      );
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  /// Inicia sesión con empleado + PIN. Guarda el token para las próximas
  /// peticiones y deja la sesión en `authenticated`.
  Future<bool> login({required String employeeId, required String pin}) async {
    state = state.copyWith(status: AuthStatus.authenticating, error: null);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .login(employeeId: employeeId, pin: pin);
      ref.read(authTokenProvider.notifier).state = result.token;
      state = AuthState(
        status: AuthStatus.authenticated,
        employee: result.employee,
      );
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: apiErrorMessage(e),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.read(authTokenProvider.notifier).state = null;
    state = const AuthState();
  }
}
