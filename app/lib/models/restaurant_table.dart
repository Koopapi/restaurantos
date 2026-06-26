/// Mesa del salón. `status` ∈ disponible | ocupada | reservada | por_atender |
/// fuera_servicio (`docs/api.md`).
class RestaurantTable {
  final String id;
  final int number;
  final int capacity;
  final String status;
  final String? shape;
  final int? party;
  final String? waiterId;
  final String? reserveName;
  final String? reserveTime;

  const RestaurantTable({
    required this.id,
    required this.number,
    required this.capacity,
    required this.status,
    this.shape,
    this.party,
    this.waiterId,
    this.reserveName,
    this.reserveTime,
  });

  bool get isFree => status == 'disponible';

  factory RestaurantTable.fromJson(Map<String, dynamic> j) => RestaurantTable(
        id: j['id'] as String,
        number: (j['number'] as num).toInt(),
        capacity: (j['capacity'] as num?)?.toInt() ?? 0,
        status: j['status'] as String,
        shape: j['shape'] as String?,
        party: (j['party'] as num?)?.toInt(),
        waiterId: j['waiterId'] as String?,
        reserveName: j['reserveName'] as String?,
        reserveTime: j['reserveTime'] as String?,
      );
}
