/// Modificador de un platillo (extra/opción con posible costo).
class Modifier {
  final String id;
  final String name;
  final num price;

  const Modifier({required this.id, required this.name, required this.price});

  factory Modifier.fromJson(Map<String, dynamic> j) => Modifier(
        id: j['id'] as String,
        name: j['name'] as String,
        price: (j['price'] as num?) ?? 0,
      );
}

/// Platillo del menú (`docs/api.md`). `station` rutea la comanda: cocina | barra.
class MenuItem {
  final String id;
  final String name;
  final String description;
  final num price;
  final String category;
  final String? subcategory;
  final String station;
  final List<String> ingredients;
  final List<Modifier> modifiers;
  final bool available;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.station,
    this.subcategory,
    this.ingredients = const [],
    this.modifiers = const [],
    this.available = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        id: j['id'] as String,
        name: j['name'] as String,
        description: (j['description'] as String?) ?? '',
        price: (j['price'] as num?) ?? 0,
        category: (j['category'] as String?) ?? 'General',
        subcategory: j['subcategory'] as String?,
        station: (j['station'] as String?) ?? 'cocina',
        ingredients:
            (j['ingredients'] as List?)?.map((e) => e as String).toList() ??
                const [],
        modifiers: (j['modifiers'] as List?)
                ?.map((e) => Modifier.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        available: (j['available'] as bool?) ?? true,
      );
}
