/// Colección de menú (p.ej. "Menú Almuerzo"). Una activa a la vez.
class MenuCollection {
  final String id;
  final String name;
  final bool active;
  final String? schedule;
  final List<String> itemIds;

  const MenuCollection({
    required this.id,
    required this.name,
    required this.active,
    required this.itemIds,
    this.schedule,
  });

  factory MenuCollection.fromJson(Map<String, dynamic> j) => MenuCollection(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        active: (j['active'] as bool?) ?? false,
        schedule: j['schedule'] as String?,
        itemIds: ((j['itemIds'] as List?) ?? const [])
            .map((e) => e as String)
            .toList(),
      );
}
