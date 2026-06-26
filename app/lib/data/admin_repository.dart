import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../features/auth/employee.dart';
import '../models/admin.dart';
import '../models/app_config.dart';
import '../models/menu_item.dart';

/// Acceso REST a la capa de administración (`docs/api-admin.md`).
class AdminRepository {
  final Dio _dio;
  AdminRepository(this._dio);

  // --- Dashboard / reportes ---
  Future<DashboardData> dashboard(String range) async {
    final r = await _dio.get<Map<String, dynamic>>('/dashboard',
        queryParameters: {'range': range});
    return DashboardData.fromJson(r.data!);
  }

  Future<SalesReport> salesReport(String range) async {
    final r = await _dio.get<Map<String, dynamic>>('/reports/sales',
        queryParameters: {'range': range});
    return SalesReport.fromJson(r.data!);
  }

  Future<List<({String name, int qty, num revenue})>> topProducts(
      String range) async {
    final r = await _dio.get<Map<String, dynamic>>('/reports/products',
        queryParameters: {'range': range});
    return ((r.data!['topItems'] as List?) ?? const [])
        .map((e) => (
              name: e['name'] as String,
              qty: (e['qty'] as num).toInt(),
              revenue: (e['revenue'] as num?) ?? 0
            ))
        .toList();
  }

  Future<List<({String name, num sales, int tickets})>> employeesReport(
      String range) async {
    final r = await _dio.get<Map<String, dynamic>>('/reports/employees',
        queryParameters: {'range': range});
    return ((r.data!['byEmployee'] as List?) ?? const [])
        .map((e) => (
              name: e['name'] as String,
              sales: (e['sales'] as num?) ?? 0,
              tickets: (e['tickets'] as num?)?.toInt() ?? 0
            ))
        .toList();
  }

  // --- Inventario ---
  Future<List<InventoryItem>> inventory({String? status}) async {
    final r = await _dio.get<List<dynamic>>('/inventory',
        queryParameters: {if (status != null) 'status': status});
    return r.data!
        .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateInventory(String id, {num? stock, num? minStock}) async {
    await _dio.put('/inventory/$id', data: {
      if (stock != null) 'stock': stock,
      if (minStock != null) 'minStock': minStock,
    });
  }

  Future<void> setAutoReorder(String id, bool value) async {
    await _dio
        .patch('/inventory/$id/auto-reorder', data: {'autoReorder': value});
  }

  // --- Compras ---
  Future<({List<PurchaseSuggestion> items, num totalEst})> suggestions() async {
    final r = await _dio.get<Map<String, dynamic>>('/purchasing/suggestions');
    final items = ((r.data!['items'] as List?) ?? const [])
        .map((e) => PurchaseSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
    return (items: items, totalEst: (r.data!['totalEst'] as num?) ?? 0);
  }

  Future<List<PurchaseOrder>> orders() async {
    final r = await _dio.get<List<dynamic>>('/purchasing/orders');
    return r.data!
        .map((e) => PurchaseOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createOrder(
      List<({String inventoryItemId, num qty})> items) async {
    await _dio.post('/purchasing/orders', data: {
      'items': items
          .map((i) => {'inventoryItemId': i.inventoryItemId, 'qty': i.qty})
          .toList(),
    });
  }

  Future<void> approveOrder(String id) async =>
      _dio.post('/purchasing/orders/$id/approve');
  Future<void> receiveOrder(String id) async =>
      _dio.post('/purchasing/orders/$id/receive');

  // --- Empleados ---
  Future<List<Employee>> employees() async {
    final r = await _dio.get<List<dynamic>>('/employees');
    return r.data!
        .map((e) => Employee.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createEmployee({
    required String name,
    required String role,
    required String pin,
    String? shift,
  }) async {
    await _dio.post('/employees', data: {
      'name': name,
      'role': role,
      'pin': pin,
      if (shift != null) 'shift': shift
    });
  }

  Future<void> updateEmployee(String id,
      {String? name, String? role, bool? active}) async {
    await _dio.put('/employees/$id', data: {
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (active != null) 'active': active,
    });
  }

  // --- Menú admin ---
  Future<void> setMenuAvailability(String id, bool available) async {
    await _dio.patch('/menu/$id/availability', data: {'available': available});
  }

  Future<void> updateMenuItem(String id, {num? price}) async {
    await _dio.put('/menu/$id', data: {if (price != null) 'price': price});
  }

  Future<MenuItem> createMenuItem({
    required String name,
    required num price,
    required String category,
    required String station,
  }) async {
    final r = await _dio.post<Map<String, dynamic>>('/menu', data: {
      'name': name,
      'price': price,
      'category': category,
      'station': station,
    });
    return MenuItem.fromJson(r.data!);
  }

  // --- Config / marca blanca ---
  Future<AppConfig> updateConfig(Map<String, dynamic> fields) async {
    final r = await _dio.put<Map<String, dynamic>>('/config', data: fields);
    return AppConfig.fromJson(r.data!);
  }
}

final adminRepositoryProvider =
    Provider<AdminRepository>((ref) => AdminRepository(ref.watch(dioProvider)));
