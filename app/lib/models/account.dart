import 'menu_item.dart';

/// Línea de una cuenta (un platillo con cantidad y personalizaciones).
class AccountLine {
  final String id;
  final String menuItemId;
  final String name;
  final int qty;
  final num unitPrice;
  final List<String> removedIngredients;
  final List<Modifier> addedModifiers;
  final String? notes;
  final String station;
  final bool sent;

  const AccountLine({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.qty,
    required this.unitPrice,
    required this.station,
    required this.sent,
    this.removedIngredients = const [],
    this.addedModifiers = const [],
    this.notes,
  });

  num get lineTotal => qty * unitPrice;

  factory AccountLine.fromJson(Map<String, dynamic> j) => AccountLine(
        id: j['id'] as String,
        menuItemId: j['menuItemId'] as String,
        name: j['name'] as String,
        qty: (j['qty'] as num).toInt(),
        unitPrice: (j['unitPrice'] as num?) ?? 0,
        station: (j['station'] as String?) ?? 'cocina',
        sent: (j['sent'] as bool?) ?? false,
        removedIngredients: (j['removedIngredients'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        addedModifiers: (j['addedModifiers'] as List?)
                ?.map((e) => Modifier.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        notes: j['notes'] as String?,
      );
}

/// Cuenta/orden sobre la que trabaja el mesero.
class Account {
  final String id;
  final String serviceType; // mesa | llevar | domicilio
  final String? tableId;
  final int? guests;
  final String waiterId;
  final String? customerName;
  final List<AccountLine> lines;
  final String status; // abierta | pagada | cancelada
  final num subtotal;
  final num tax;
  final num total;
  final Map<String, dynamic>? payment;

  const Account({
    required this.id,
    required this.serviceType,
    required this.waiterId,
    required this.lines,
    required this.status,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.tableId,
    this.guests,
    this.customerName,
    this.payment,
  });

  bool get isOpen => status == 'abierta';
  List<AccountLine> get pendingLines => lines.where((l) => !l.sent).toList();
  bool get hasPending => pendingLines.isNotEmpty;

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        serviceType: j['serviceType'] as String,
        tableId: j['tableId'] as String?,
        guests: (j['guests'] as num?)?.toInt(),
        waiterId: j['waiterId'] as String,
        customerName: j['customerName'] as String?,
        lines: (j['lines'] as List?)
                ?.map((e) => AccountLine.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        status: j['status'] as String,
        subtotal: (j['subtotal'] as num?) ?? 0,
        tax: (j['tax'] as num?) ?? 0,
        total: (j['total'] as num?) ?? 0,
        payment: j['payment'] as Map<String, dynamic>?,
      );
}
