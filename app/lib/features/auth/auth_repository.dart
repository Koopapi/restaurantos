import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'employee.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);

/// Resultado de un login: token JWT + empleado.
class LoginResult {
  final String token;
  final Employee employee;
  const LoginResult(this.token, this.employee);
}

/// Acceso a los endpoints de autenticación (`docs/api.md`).
class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  /// POST /api/auth/login { employeeId, pin } → { token, employee }
  Future<LoginResult> login(
      {required String employeeId, required String pin}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'employeeId': employeeId, 'pin': pin},
    );
    final data = res.data!;
    return LoginResult(
      data['token'] as String,
      Employee.fromJson(data['employee'] as Map<String, dynamic>),
    );
  }

  /// POST /api/auth/logout (stateless: el cliente descarta su token).
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException {
      // El logout es best-effort; el token se descarta localmente igual.
    }
  }
}
