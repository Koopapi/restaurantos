import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/realtime.dart';
import '../data/admin_repository.dart';
import '../features/auth/employee.dart';
import '../models/admin.dart';
import '../models/shift.dart';

/// Rango seleccionado para Dashboard/Reportes (hoy | 7d/semana | 30d/mes).
final dashRangeProvider = StateProvider<String>((ref) => '7d');
final reportRangeProvider = StateProvider<String>((ref) => 'semana');

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) {
  ref.listen(realtimeEventsProvider, (_, next) {
    final t = next.valueOrNull?.type ?? '';
    if (t.startsWith('table') ||
        t.startsWith('account') ||
        t.startsWith('ticket')) {
      ref.invalidateSelf();
    }
  });
  return ref
      .watch(adminRepositoryProvider)
      .dashboard(ref.watch(dashRangeProvider));
});

final salesReportProvider = FutureProvider.autoDispose<SalesReport>((ref) => ref
    .watch(adminRepositoryProvider)
    .salesReport(ref.watch(reportRangeProvider)));

final topProductsProvider =
    FutureProvider.autoDispose<List<({String name, int qty, num revenue})>>(
        (ref) => ref
            .watch(adminRepositoryProvider)
            .topProducts(ref.watch(reportRangeProvider)));

final employeesReportProvider =
    FutureProvider.autoDispose<List<({String name, num sales, int tickets})>>(
        (ref) => ref
            .watch(adminRepositoryProvider)
            .employeesReport(ref.watch(reportRangeProvider)));

class InventoryNotifier extends AsyncNotifier<List<InventoryItem>> {
  @override
  Future<List<InventoryItem>> build() async {
    ref.listen(realtimeEventsProvider, (_, next) {
      if (next.valueOrNull?.type.startsWith('inventory') ?? false) {
        ref.invalidateSelf();
      }
    });
    return ref.watch(adminRepositoryProvider).inventory();
  }
}

final inventoryProvider =
    AsyncNotifierProvider<InventoryNotifier, List<InventoryItem>>(
        InventoryNotifier.new);

final suggestionsProvider = FutureProvider.autoDispose<
    ({
      List<PurchaseSuggestion> items,
      num totalEst
    })>((ref) => ref.watch(adminRepositoryProvider).suggestions());

final ordersProvider = FutureProvider.autoDispose<List<PurchaseOrder>>(
    (ref) => ref.watch(adminRepositoryProvider).orders());

class EmployeesNotifier extends AsyncNotifier<List<Employee>> {
  @override
  Future<List<Employee>> build() async {
    ref.listen(realtimeEventsProvider, (_, next) {
      if (next.valueOrNull?.type.startsWith('employee') ?? false) {
        ref.invalidateSelf();
      }
    });
    return ref.watch(adminRepositoryProvider).employees();
  }
}

final employeesProvider =
    AsyncNotifierProvider<EmployeesNotifier, List<Employee>>(
        EmployeesNotifier.new);

/// Todos los turnos (se filtran por día en la UI).
final shiftsProvider = FutureProvider.autoDispose<List<Shift>>(
    (ref) => ref.watch(adminRepositoryProvider).shifts());
