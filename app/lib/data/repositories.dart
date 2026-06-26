import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/account.dart';
import '../models/app_config.dart';
import '../models/menu_item.dart';
import '../models/restaurant_table.dart';
import '../models/ticket.dart';

/// Acceso REST al ciclo de servicio (`docs/api.md`). Una sola clase para
/// mantener el cableado simple en esta fase.
class ServiceRepository {
  final Dio _dio;
  ServiceRepository(this._dio);

  // --- Config ---
  Future<AppConfig> config() async {
    final r = await _dio.get<Map<String, dynamic>>('/config');
    return AppConfig.fromJson(r.data!);
  }

  // --- Mesas ---
  Future<List<RestaurantTable>> tables() async {
    final r = await _dio.get<List<dynamic>>('/tables');
    return r.data!
        .map((e) => RestaurantTable.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RestaurantTable> assignTable(String id, {required int guests}) async {
    final r = await _dio.post<Map<String, dynamic>>('/tables/$id/assign',
        data: {'guests': guests});
    return RestaurantTable.fromJson(r.data!);
  }

  // --- Menú ---
  Future<List<MenuItem>> menu() async {
    final r = await _dio.get<List<dynamic>>('/menu');
    return r.data!
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // --- Cuentas ---
  Future<List<Account>> accounts({String? status}) async {
    final r = await _dio.get<List<dynamic>>('/accounts',
        queryParameters: {if (status != null) 'status': status});
    return r.data!
        .map((e) => Account.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Account> account(String id) async {
    final r = await _dio.get<Map<String, dynamic>>('/accounts/$id');
    return Account.fromJson(r.data!);
  }

  Future<Account> createAccount({
    required String serviceType,
    String? tableId,
    int? guests,
  }) async {
    final r = await _dio.post<Map<String, dynamic>>('/accounts', data: {
      'serviceType': serviceType,
      if (tableId != null) 'tableId': tableId,
      if (guests != null) 'guests': guests,
    });
    return Account.fromJson(r.data!);
  }

  Future<Account> addLine(
    String accountId, {
    required String menuItemId,
    required int qty,
    List<String>? removedIngredients,
    List<Modifier>? addedModifiers,
    String? notes,
  }) async {
    final r = await _dio
        .post<Map<String, dynamic>>('/accounts/$accountId/lines', data: {
      'menuItemId': menuItemId,
      'qty': qty,
      if (removedIngredients != null) 'removedIngredients': removedIngredients,
      if (addedModifiers != null)
        'addedModifiers':
            addedModifiers.map((m) => {'id': m.id, 'name': m.name}).toList(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return Account.fromJson(r.data!);
  }

  Future<Account> updateLineQty(
      String accountId, String lineId, int qty) async {
    final r = await _dio.patch<Map<String, dynamic>>(
        '/accounts/$accountId/lines/$lineId',
        data: {'qty': qty});
    return Account.fromJson(r.data!);
  }

  Future<Account> deleteLine(String accountId, String lineId) async {
    final r = await _dio
        .delete<Map<String, dynamic>>('/accounts/$accountId/lines/$lineId');
    return Account.fromJson(r.data!);
  }

  Future<void> sendAccount(String accountId) async {
    await _dio.post('/accounts/$accountId/send');
  }

  Future<Account> pay(
    String accountId, {
    required String method,
    num? amountReceived,
    num? tip,
  }) async {
    final r = await _dio
        .post<Map<String, dynamic>>('/accounts/$accountId/pay', data: {
      'method': method,
      if (amountReceived != null) 'amountReceived': amountReceived,
      if (tip != null) 'tip': tip,
    });
    return Account.fromJson(r.data!);
  }

  // --- Tickets (KDS) ---
  Future<List<Ticket>> tickets({String? station, String? status}) async {
    final r = await _dio.get<List<dynamic>>('/tickets', queryParameters: {
      if (station != null) 'station': station,
      if (status != null) 'status': status,
    });
    return r.data!
        .map((e) => Ticket.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> advanceTicket(String id) async =>
      _dio.post('/tickets/$id/advance');
  Future<void> deliverTicket(String id) async =>
      _dio.post('/tickets/$id/deliver');
}

final serviceRepositoryProvider = Provider<ServiceRepository>(
    (ref) => ServiceRepository(ref.watch(dioProvider)));
