/// Renglón de una comanda (nombre + cantidad).
class TicketLine {
  final String name;
  final int qty;
  const TicketLine({required this.name, required this.qty});

  factory TicketLine.fromJson(Map<String, dynamic> j) =>
      TicketLine(name: j['name'] as String, qty: (j['qty'] as num).toInt());
}

/// Comanda del KDS. `status` ∈ pendiente | en_proceso | lista | entregada.
class Ticket {
  final String id;
  final String accountId;
  final String station; // cocina | barra
  final String status;
  final List<TicketLine> lines;
  final String? waiterName;
  final String label; // "Mesa 3", "Para llevar", ...
  final String serviceType;
  final DateTime createdAt;
  final DateTime? readyAt;

  const Ticket({
    required this.id,
    required this.accountId,
    required this.station,
    required this.status,
    required this.lines,
    required this.label,
    required this.serviceType,
    required this.createdAt,
    this.waiterName,
    this.readyAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> j) => Ticket(
        id: j['id'] as String,
        accountId: j['accountId'] as String,
        station: j['station'] as String,
        status: j['status'] as String,
        lines: (j['lines'] as List?)
                ?.map((e) => TicketLine.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        waiterName: j['waiterName'] as String?,
        label: (j['label'] as String?) ?? '',
        serviceType: (j['serviceType'] as String?) ?? 'mesa',
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '')?.toLocal() ??
                DateTime.now(),
        readyAt: j['readyAt'] != null
            ? DateTime.tryParse(j['readyAt'] as String)
            : null,
      );

  /// Minutos transcurridos desde que entró la comanda.
  int minutesElapsed(DateTime now) => now.difference(createdAt).inMinutes;
}
