import 'package:flutter/material.dart';

/// Un destino de navegación (placeholder en esta fase; las pantallas reales
/// llegan en feature/app-service-cycle y feature/app-admin).
@immutable
class AppDestination {
  final String label;
  final IconData icon;
  const AppDestination(this.label, this.icon);
}

/// Destinos visibles según el rol (resumen de la matriz de `docs/api.md` y
/// la guía de navegación de la spec Flutter §5).
List<AppDestination> destinationsForRole(String role) {
  switch (role) {
    case 'mesero':
      return const [
        AppDestination('POS', Icons.point_of_sale),
        AppDestination('Cuentas', Icons.receipt_long),
        AppDestination('Mesas', Icons.table_restaurant),
        AppDestination('Cocina', Icons.soup_kitchen),
        AppDestination('Cobro', Icons.payments),
      ];
    case 'cocina':
      return const [AppDestination('Cocina KDS', Icons.soup_kitchen)];
    case 'barista':
      return const [AppDestination('Barra KDS', Icons.local_bar)];
    case 'hostess':
      return const [
        AppDestination('Mesas', Icons.table_restaurant),
        AppDestination('Lista de espera', Icons.groups),
      ];
    case 'gerente':
      return const [
        AppDestination('Dashboard', Icons.dashboard),
        AppDestination('Mesas', Icons.table_restaurant),
        AppDestination('Menú', Icons.menu_book),
        AppDestination('Inventario', Icons.inventory_2),
        AppDestination('Compras', Icons.shopping_cart),
        AppDestination('Empleados', Icons.badge),
        AppDestination('Reportes', Icons.bar_chart),
      ];
    case 'admin':
      return const [
        AppDestination('Dashboard', Icons.dashboard),
        AppDestination('Mesas', Icons.table_restaurant),
        AppDestination('Menú', Icons.menu_book),
        AppDestination('Inventario', Icons.inventory_2),
        AppDestination('Compras', Icons.shopping_cart),
        AppDestination('Empleados', Icons.badge),
        AppDestination('Reportes', Icons.bar_chart),
        AppDestination('Marca blanca', Icons.palette),
      ];
    default:
      return const [AppDestination('Inicio', Icons.home)];
  }
}
