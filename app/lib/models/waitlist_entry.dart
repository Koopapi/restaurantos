/// Entrada de la lista de espera (hostess). `status` ∈ esperando | sentado.
class WaitlistEntry {
  final String id;
  final String name;
  final int size;
  final String? phone;
  final String status;
  final String? suggestedTableId;

  const WaitlistEntry({
    required this.id,
    required this.name,
    required this.size,
    required this.status,
    this.phone,
    this.suggestedTableId,
  });

  bool get isWaiting => status == 'esperando';

  factory WaitlistEntry.fromJson(Map<String, dynamic> j) => WaitlistEntry(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        size: (j['size'] as num?)?.toInt() ?? 1,
        phone: j['phone'] as String?,
        status: (j['status'] as String?) ?? 'esperando',
        suggestedTableId: j['suggestedTableId'] as String?,
      );
}
