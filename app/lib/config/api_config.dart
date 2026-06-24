/// Configuración de red del backend.
///
/// La URL base es configurable en tiempo de compilación con `--dart-define`:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:4000
///
/// Por defecto apunta a `10.0.2.2`, que es el alias del **emulador de Android**
/// para el `localhost` de la máquina anfitriona (donde corre el backend Docker).
/// En un dispositivo físico usa la IP LAN de tu Mac (ver app/README.md).
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000',
  );

  /// Base de los endpoints REST: `http://host:4000/api`.
  static String get apiBaseUrl => '$baseUrl/api';

  /// URL del WebSocket autenticado: `ws://host:4000/ws?token=...`.
  static Uri wsUri(String token) {
    final ws = baseUrl.replaceFirst(RegExp(r'^http'), 'ws');
    return Uri.parse('$ws/ws?token=$token');
  }
}
