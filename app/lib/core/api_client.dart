import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';

/// Token JWT de la sesión actual (lo setea el AuthController al iniciar sesión).
/// Vive aparte del cliente para evitar dependencias circulares: el interceptor
/// lo lee en cada request.
final authTokenProvider = StateProvider<String?>((ref) => null);

/// Cliente HTTP compartido. Inyecta `Authorization: Bearer <token>` cuando hay
/// sesión y normaliza los errores del backend (`{ error: { code, message } }`).
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: Headers.jsonContentType,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(authTokenProvider);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  return dio;
});

/// Extrae el mensaje legible de un error del backend.
String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      return (data['error']['message'] as String?) ?? 'Error del servidor';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar con el servidor. Revisa la URL/red.';
    }
  }
  return 'Ocurrió un error inesperado';
}
