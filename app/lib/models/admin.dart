// Modelos de la capa de administración (`docs/api-admin.md`).

class InventoryItem {
  final String id;
  final String name;
  final String category;
  final String unit;
  final num stock;
  final num minStock;
  final String status; // ok | bajo
  final bool autoReorder;
  final String? supplier;
  final num cost;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.stock,
    required this.minStock,
    required this.status,
    required this.autoReorder,
    required this.cost,
    this.supplier,
  });

  bool get isLow => status == 'bajo';

  factory InventoryItem.fromJson(Map<String, dynamic> j) => InventoryItem(
        id: j['id'] as String,
        name: j['name'] as String,
        category: (j['category'] as String?) ?? 'General',
        unit: (j['unit'] as String?) ?? 'pieza',
        stock: (j['stock'] as num?) ?? 0,
        minStock: (j['minStock'] as num?) ?? 0,
        status: (j['status'] as String?) ?? 'ok',
        autoReorder: (j['autoReorder'] as bool?) ?? false,
        supplier: j['supplier'] as String?,
        cost: (j['cost'] as num?) ?? 0,
      );
}

class PurchaseSuggestion {
  final String inventoryItemId;
  final String name;
  final String? supplier;
  final num suggestedQty;
  final num estCost;
  final String urgency; // alta | media | baja

  const PurchaseSuggestion({
    required this.inventoryItemId,
    required this.name,
    required this.suggestedQty,
    required this.estCost,
    required this.urgency,
    this.supplier,
  });

  factory PurchaseSuggestion.fromJson(Map<String, dynamic> j) =>
      PurchaseSuggestion(
        inventoryItemId: j['inventoryItemId'] as String,
        name: j['name'] as String,
        supplier: j['supplier'] as String?,
        suggestedQty: (j['suggestedQty'] as num?) ?? 0,
        estCost: (j['estCost'] as num?) ?? 0,
        urgency: (j['urgency'] as String?) ?? 'baja',
      );
}

class PurchaseOrder {
  final String id;
  final String status; // sugerida | aprobada | recibida
  final List<({String name, num qty, num estCost})> items;
  final num total;

  const PurchaseOrder({
    required this.id,
    required this.status,
    required this.items,
    required this.total,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> j) => PurchaseOrder(
        id: j['id'] as String,
        status: j['status'] as String,
        total: (j['total'] as num?) ?? 0,
        items: ((j['items'] as List?) ?? const [])
            .map((e) => (
                  name: e['name'] as String,
                  qty: (e['qty'] as num?) ?? 0,
                  estCost: (e['estCost'] as num?) ?? 0,
                ))
            .toList(),
      );
}

class DashboardData {
  final num sales;
  final int tickets;
  final num avgTicket;
  final num tips;
  final List<({String label, num value})> trend;
  final List<({String type, num amount})> byServiceType;
  final List<({String name, int qty})> topDishes;
  final int tablesOccupied;
  final int tablesTotal;
  final int activeAccounts;
  final int kitchenTickets;
  final int barTickets;

  const DashboardData({
    required this.sales,
    required this.tickets,
    required this.avgTicket,
    required this.tips,
    required this.trend,
    required this.byServiceType,
    required this.topDishes,
    required this.tablesOccupied,
    required this.tablesTotal,
    required this.activeAccounts,
    required this.kitchenTickets,
    required this.barTickets,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) {
    final live = (j['live'] as Map<String, dynamic>?) ?? const {};
    return DashboardData(
      sales: (j['sales'] as num?) ?? 0,
      tickets: (j['tickets'] as num?)?.toInt() ?? 0,
      avgTicket: (j['avgTicket'] as num?) ?? 0,
      tips: (j['tips'] as num?) ?? 0,
      trend: ((j['trend'] as List?) ?? const [])
          .map((e) =>
              (label: e['label'] as String, value: (e['value'] as num?) ?? 0))
          .toList(),
      byServiceType: ((j['byServiceType'] as List?) ?? const [])
          .map((e) =>
              (type: e['type'] as String, amount: (e['amount'] as num?) ?? 0))
          .toList(),
      topDishes: ((j['topDishes'] as List?) ?? const [])
          .map((e) => (
                name: e['name'] as String,
                qty: (e['qty'] as num?)?.toInt() ?? 0
              ))
          .toList(),
      tablesOccupied: (live['tablesOccupied'] as num?)?.toInt() ?? 0,
      tablesTotal: (live['tablesTotal'] as num?)?.toInt() ?? 0,
      activeAccounts: (live['activeAccounts'] as num?)?.toInt() ?? 0,
      kitchenTickets: (live['kitchenTickets'] as num?)?.toInt() ?? 0,
      barTickets: (live['barTickets'] as num?)?.toInt() ?? 0,
    );
  }
}

class SalesReport {
  final num totalSales;
  final int tickets;
  final num avgTicket;
  final num tips;
  final List<({String method, num amount, int count})> byPaymentMethod;

  const SalesReport({
    required this.totalSales,
    required this.tickets,
    required this.avgTicket,
    required this.tips,
    required this.byPaymentMethod,
  });

  factory SalesReport.fromJson(Map<String, dynamic> j) => SalesReport(
        totalSales: (j['totalSales'] as num?) ?? 0,
        tickets: (j['tickets'] as num?)?.toInt() ?? 0,
        avgTicket: (j['avgTicket'] as num?) ?? 0,
        tips: (j['tips'] as num?) ?? 0,
        byPaymentMethod: ((j['byPaymentMethod'] as List?) ?? const [])
            .map((e) => (
                  method: e['method'] as String,
                  amount: (e['amount'] as num?) ?? 0,
                  count: (e['count'] as num?)?.toInt() ?? 0,
                ))
            .toList(),
      );
}
