import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/realtime.dart';
import '../data/repositories.dart';
import '../models/account.dart';
import '../models/app_config.dart';
import '../models/menu_item.dart';
import '../models/restaurant_table.dart';
import '../models/ticket.dart';
import '../models/waitlist_entry.dart';

// --- UI state ---
/// Índice del destino seleccionado en el shell (permite cambiar de pestaña
/// programáticamente, p.ej. al abrir una cuenta desde Mesas → POS).
final navIndexProvider = StateProvider<int>((ref) => 0);

/// Cuenta sobre la que trabaja el mesero (la que se muestra en el POS).
final currentAccountIdProvider = StateProvider<String?>((ref) => null);

// --- Config ---
final configProvider = FutureProvider<AppConfig>((ref) async {
  ref.listen(realtimeEventsProvider, (_, next) {
    if (next.valueOrNull?.type == 'config:updated') ref.invalidateSelf();
  });
  try {
    return await ref.watch(serviceRepositoryProvider).config();
  } catch (_) {
    return AppConfig.fallback;
  }
});

// --- Menú (estático durante el servicio) ---
final menuProvider = FutureProvider<List<MenuItem>>(
    (ref) => ref.watch(serviceRepositoryProvider).menu());

// --- Mesas ---
class TablesNotifier extends AsyncNotifier<List<RestaurantTable>> {
  @override
  Future<List<RestaurantTable>> build() async {
    ref.listen(realtimeEventsProvider, (_, next) {
      if (next.valueOrNull?.type.startsWith('table') ?? false) {
        ref.invalidateSelf();
      }
    });
    return ref.watch(serviceRepositoryProvider).tables();
  }
}

final tablesProvider =
    AsyncNotifierProvider<TablesNotifier, List<RestaurantTable>>(
        TablesNotifier.new);

// --- Cuentas abiertas ---
class OpenAccountsNotifier extends AsyncNotifier<List<Account>> {
  @override
  Future<List<Account>> build() async {
    ref.listen(realtimeEventsProvider, (_, next) {
      if (next.valueOrNull?.type.startsWith('account') ?? false) {
        ref.invalidateSelf();
      }
    });
    return ref.watch(serviceRepositoryProvider).accounts(status: 'abierta');
  }
}

final openAccountsProvider =
    AsyncNotifierProvider<OpenAccountsNotifier, List<Account>>(
        OpenAccountsNotifier.new);

// --- Cuenta actual (detalle + mutaciones) ---
class CurrentAccountNotifier extends FamilyAsyncNotifier<Account, String> {
  late String _id;

  @override
  Future<Account> build(String accountId) async {
    _id = accountId;
    ref.listen(realtimeEventsProvider, (_, next) {
      final e = next.valueOrNull;
      if (e != null &&
          e.type == 'account:updated' &&
          e.data is Map &&
          e.data['id'] == _id) {
        ref.invalidateSelf();
      }
    });
    return ref.watch(serviceRepositoryProvider).account(accountId);
  }

  ServiceRepository get _repo => ref.read(serviceRepositoryProvider);

  Future<void> addLine({
    required String menuItemId,
    required int qty,
    List<String>? removedIngredients,
    List<Modifier>? addedModifiers,
    String? notes,
  }) async {
    final updated = await _repo.addLine(_id,
        menuItemId: menuItemId,
        qty: qty,
        removedIngredients: removedIngredients,
        addedModifiers: addedModifiers,
        notes: notes);
    state = AsyncData(updated);
  }

  Future<void> setQty(String lineId, int qty) async {
    state = AsyncData(await _repo.updateLineQty(_id, lineId, qty));
  }

  Future<void> removeLine(String lineId) async {
    state = AsyncData(await _repo.deleteLine(_id, lineId));
  }

  Future<void> send() async {
    await _repo.sendAccount(_id);
    ref.invalidateSelf();
  }
}

final currentAccountProvider =
    AsyncNotifierProvider.family<CurrentAccountNotifier, Account, String>(
        CurrentAccountNotifier.new);

// --- Tickets por estación (KDS) ---
class TicketsNotifier extends FamilyAsyncNotifier<List<Ticket>, String> {
  @override
  Future<List<Ticket>> build(String station) async {
    ref.listen(realtimeEventsProvider, (_, next) {
      final t = next.valueOrNull?.type ?? '';
      if (t.startsWith('ticket') || t == 'dish:ready') ref.invalidateSelf();
    });
    final all =
        await ref.watch(serviceRepositoryProvider).tickets(station: station);
    // El KDS no muestra las entregadas.
    return all.where((t) => t.status != 'entregada').toList();
  }
}

final ticketsProvider =
    AsyncNotifierProvider.family<TicketsNotifier, List<Ticket>, String>(
        TicketsNotifier.new);

// --- Lista de espera (hostess) ---
class WaitlistNotifier extends AsyncNotifier<List<WaitlistEntry>> {
  @override
  Future<List<WaitlistEntry>> build() async {
    ref.listen(realtimeEventsProvider, (_, next) {
      final t = next.valueOrNull?.type ?? '';
      if (t.startsWith('waitlist') || t.startsWith('table')) {
        ref.invalidateSelf();
      }
    });
    return ref.watch(serviceRepositoryProvider).waitlist();
  }
}

final waitlistProvider =
    AsyncNotifierProvider<WaitlistNotifier, List<WaitlistEntry>>(
        WaitlistNotifier.new);
