import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/api_config.dart';
import 'api_client.dart';

/// Evento de tiempo real recibido por WebSocket: `{ type, data, at }`.
class RtEvent {
  final String type;
  final dynamic data;
  const RtEvent(this.type, this.data);
}

/// Mantiene la conexión WebSocket autenticada y expone los eventos como un
/// stream broadcast. Reconecta solo cuando cambia el token (login/logout).
class RealtimeService {
  final String token;
  WebSocketChannel? _channel;
  final _controller = StreamController<RtEvent>.broadcast();
  StreamSubscription? _sub;

  RealtimeService(this.token) {
    _connect();
  }

  Stream<RtEvent> get events => _controller.stream;

  void _connect() {
    try {
      final channel = WebSocketChannel.connect(ApiConfig.wsUri(token));
      _channel = channel;
      _sub = channel.stream.listen(
        (raw) {
          try {
            final map = jsonDecode(raw as String) as Map<String, dynamic>;
            _controller.add(RtEvent(map['type'] as String, map['data']));
          } catch (_) {/* ignora frames no-JSON */}
        },
        onError: (_) {},
        onDone: () {},
      );
    } catch (_) {/* sin realtime; la UI sigue funcionando vía REST */}
  }

  void dispose() {
    _sub?.cancel();
    _channel?.sink.close();
    _controller.close();
  }
}

/// Servicio realtime ligado al token de sesión. Se reconstruye al cambiar el
/// token (login/logout) y se cierra al desmontarse.
final realtimeServiceProvider = Provider<RealtimeService?>((ref) {
  final token = ref.watch(authTokenProvider);
  if (token == null) return null;
  final service = RealtimeService(token);
  ref.onDispose(service.dispose);
  return service;
});

/// Último evento recibido (para que los providers se invaliden y refresquen).
final realtimeEventsProvider = StreamProvider<RtEvent>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  if (service == null) return const Stream.empty();
  return service.events;
});
