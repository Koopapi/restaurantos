# RestaurantOS — Guía de Implementación (Flutter + Material 3)

Guía para reconstruir el rediseño (archivo Pencil `pencil-new.pen`) en **Flutter con Material 3 (Material You)**. Primera fase **solo Android**, **tablet + teléfono**. Tema **claro de alto contraste** (elegido por legibilidad bajo luz solar directa en piso), acento **violeta** (seed `#6750A4`). Diseño nuevo: atractivo pero funcional, **botones grandes**, touch-first, glanceable para operación en vivo.

Cobertura: **15 pantallas tablet** y **8 pantallas teléfono**.

---

## 1. Por qué Material 3

- Nativo de Android → se ve y se siente correcto en el dispositivo objetivo.
- Theming centralizado con `ColorScheme` / `ThemeData` (un solo cambio = marca blanca).
- Objetivos táctiles y componentes accesibles por defecto (ideal para piso).
- Componentes completos: `FilledButton`, `Card`, `Chip`, `NavigationRail`, `NavigationBar`, `Switch`, `DataTable`, `Dialog`, `BottomSheet`, `Badge`, `SegmentedButton`.

No se requieren paquetes de UI extra. Opcionales útiles: `go_router` (navegación), `flutter_riverpod` o `bloc` (estado), `web_socket_channel` (realtime), `dynamic_color` (Material You del sistema, opcional).

---

## 2. Tema — ColorScheme (claro, seed violeta)

```dart
import 'package:flutter/material.dart';

const seed = Color(0xFF6750A4);

final restaurantTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  ).copyWith(
    surface: const Color(0xFFFFFFFF),       // alto contraste para sol
    surfaceContainerLowest: const Color(0xFFFFFFFF),
    surfaceContainerLow: const Color(0xFFF7F2FA),
    surfaceContainer: const Color(0xFFF2ECF6),
    onSurface: const Color(0xFF1B1B1F),
  ),
  scaffoldBackgroundColor: const Color(0xFFFBF8FD),
  fontFamily: 'Roboto',
  extensions: const [SemanticColors.light],
);
```

### Colores semánticos (estados de operación) vía ThemeExtension

Material no trae `success`/`warning`/`info`; se agregan como extensión:

```dart
@immutable
class SemanticColors extends ThemeExtension<SemanticColors> {
  final Color success, onSuccessContainer, successContainer;
  final Color warning, onWarningContainer, warningContainer;
  final Color info, onInfoContainer, infoContainer;
  const SemanticColors({
    required this.success, required this.successContainer, required this.onSuccessContainer,
    required this.warning, required this.warningContainer, required this.onWarningContainer,
    required this.info, required this.infoContainer, required this.onInfoContainer,
  });

  static const light = SemanticColors(
    success: Color(0xFF1E7D34), successContainer: Color(0xFFB7F1B6), onSuccessContainer: Color(0xFF052109),
    warning: Color(0xFF8A5A00), warningContainer: Color(0xFFFFE08A), onWarningContainer: Color(0xFF2A1800),
    info:    Color(0xFF2E5AAC), infoContainer:    Color(0xFFD8E2FF), onInfoContainer:    Color(0xFF11366B),
  );

  @override
  SemanticColors copyWith(...) => ...;   // implementar
  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) => this;
}
```

Mapa rápido del diseño → roles `ColorScheme`:

| Diseño (hex) | Rol Material |
|---|---|
| `#6750A4` | `primary` |
| `#FFFFFF` (texto sobre primary) | `onPrimary` |
| `#EADDFF` | `primaryContainer` |
| `#21005D` | `onPrimaryContainer` |
| `#E8DEF8` | `secondaryContainer` (chips/indicadores activos) |
| `#FFFFFF` | `surface` (cards) |
| `#F7F2FA` / `#F2ECF6` | `surfaceContainerLow` / `surfaceContainer` |
| `#1B1B1F` | `onSurface` |
| `#49454F` | `onSurfaceVariant` |
| `#79747E` / `#CAC4D0` | `outline` / `outlineVariant` |
| `#BA1A1A` / `#FFDAD6` | `error` / `errorContainer` |

### Tipografía y forma

- Fuente **Roboto** (default Material). Usar `Theme.of(context).textTheme`: `headlineSmall` (títulos 24), `titleMedium` (16), `displaySmall`/`headlineMedium` (métricas), `bodyLarge`/`bodyMedium` (14-15), `labelMedium`/`labelSmall` (12-13).
- **Botones tipo stadium** (M3): radio = mitad de la altura. Botones grandes de piso: `minimumSize: Size(0, 56)`.
- Radios: chips/celdas **8**, cards/modales **12-16**, hojas/diálogos **28**.
- Escala de espacio: **4 · 8 · 12 · 16 · 24 · 32** (usar múltiplos consistentes).

---

## 3. Mapeo de componentes (Pencil → Flutter)

| Componente Pencil | Widget Flutter Material 3 | Notas |
|---|---|---|
| `comp/BtnFilled` | `FilledButton.icon` | `minimumSize: Size(0,56)` para piso. Acción principal por pantalla. |
| `comp/BtnTonal` | `FilledButton.tonal` | Acciones secundarias (Cobrar, Dividir). |
| `comp/BtnOutlined` | `OutlinedButton.icon` | Cancelar / terciaria. |
| `comp/FilterChip` | `FilterChip` / `ChoiceChip` | Categorías y filtros; seleccionado = `secondaryContainer` + check. |
| `comp/StatusBadge` | `Container` pill (o `Badge`) | Estado con punto + texto sobre `*Container`. |
| `comp/Switch` | `Switch` | Auto-pedido, disponibilidad. |
| `comp/Stepper` | `IconButton.filledTonal` (−) + texto + `IconButton.filled` (+) | 48×48, táctil. |
| `comp/MetricCard` | `Card` (filled/elevated) | Icon-chip + valor + etiqueta. |
| `comp/ProductCard` | `Card` + `InkWell` | Thumb + nombre + precio + `IconButton.filled`. |
| `comp/LineItem` | `ListTile` o `Row` | Nombre + precio + Stepper. |
| `comp/KdsTicket` | `Card` + barra de acento + `Badge` | Acción según estado (ver §6). |
| `comp/TableTile` | `Card` (color por estado) | `InkWell` para abrir detalle. |
| `comp/NavRail` | `NavigationRail` (tablet) | `extended: false`, indicador pill, FAB en `leading`. |
| `comp/NavBar` | `NavigationBar` (teléfono) | 5 destinos; indicador pill M3. |
| Top bar de pantalla | `AppBar` / `SliverAppBar` | Título + acciones. |
| Modal ingredientes | `Dialog` (tablet) / `showModalBottomSheet` (teléfono) | Chips `FilterChip`; quitado = tachado en `error`. |
| Segmento Hoy/7d/30d | `SegmentedButton` | Selección única. |
| Tablas (Inventario, Empleados, Compras) | `DataTable` / `DataTable2` | O `Table` + filas; estados con badges. |
| Grilla de turnos | `Table` | Encabezado de días + chips de turno por celda. |
| Gráfica de barras | `BarChart` (`fl_chart`) o barras con `Container` | Barra del día actual en `primary`, resto `primaryContainer`. |

---

## 4. Responsivo (un solo código)

Usa `LayoutBuilder` / `MediaQuery` con un breakpoint:

```dart
Widget build(BuildContext context) {
  final wide = MediaQuery.sizeOf(context).width >= 840; // tablet/landscape
  return Scaffold(
    body: Row(children: [
      if (wide) NavigationRail(/* destinos */),
      Expanded(child: content),
      if (wide) detailPanel, // panel maestro-detalle solo en tablet
    ]),
    bottomNavigationBar: wide ? null : NavigationBar(/* 5 destinos */),
  );
}
```

| | Tablet (≥ 840 dp) | Teléfono (< 840 dp) |
|---|---|---|
| Navegación | `NavigationRail` (96 dp) | `NavigationBar` inferior |
| Detalle (Mesas, Menú) | Panel lateral derecho | Pantalla aparte / push |
| Modal | `Dialog` centrado | `showModalBottomSheet` (hoja inferior) |
| Grids | 3–4 columnas | 2 columnas |

La jerarquía se conserva en ambos: una intención dominante por pantalla, acción principal grande y abajo (alcanzable con una mano en teléfono).

---

## 5. Inventario de pantallas y navegación por rol

**Tablet (15):** Login · Dashboard · POS · Modal de ingredientes · Nueva Cuenta · Mesas · Cocina KDS · Barra KDS · Hostess/Lista de Espera · Cobro · Menú y Platillos · Crear Nuevo Menú · Inventario · Compras IA · Empleados · Gestionar Turnos · Exportar Reportes · Marca Blanca.

**Teléfono (8):** Login · POS · Modal (bottom sheet) · Pedido Actual · Mesas · Cocina KDS · Dashboard · Nueva Cuenta.

| Rol | Destinos |
|---|---|
| Mesero | POS, Nueva Cuenta, Pedido/Cuentas, Mesas (ver), Cobro, ver Cocina/Barra |
| Cocina | Cocina KDS |
| Barista | Barra KDS |
| Hostess | Mesas + Lista de Espera |
| Gerente | Operativo + Menú, Compras IA, Inventario, Empleados, Turnos, Reportes, Marca Blanca |
| Admin | Todo lo de Gerente + Dashboard |

Login por PIN enruta al destino por defecto del rol. **Autorización validada en backend.**

---

## 6. Estados del KDS (comanda)

Flujo: **Pendiente → En preparación → Lista → Entregada**.

| Estado | Acento / Badge (container) | Botón (acción) | Ejecuta |
|---|---|---|---|
| Pendiente | `warning` / `warningContainer` | "Iniciar preparación" (`FilledButton`, primary) | Cocina/Barra |
| En preparación | `info` / `infoContainer` | "Marcar listo" (primary) | Cocina/Barra |
| Lista | `success` / `successContainer` | "Entregar" (`FilledButton` con `backgroundColor: success`) | **Mesero** |

Regla a conservar: el **mesero no inicia ni marca listo**; solo **entrega**. El temporizador cambia a `warning`/`error` al superar `urgencyMinutes`. Ruteo: Comida → Cocina; Bebidas/Yukapioca → Barra.

---

## 7. Estados de mesa

| Estado | Color | Token |
|---|---|---|
| Disponible | verde | `success` / `successContainer` |
| Ocupada | rojo | `error` / `errorContainer` |
| Reservada | azul | `info` / `infoContainer` |
| Por atender | ámbar | `warning` / `warningContainer` |
| Fuera de servicio | gris | `surfaceContainer` / `outline` |

"Por atender" notifica a todos los meseros (persistente) hasta que uno la toma. La lista de espera sugiere la **mesa libre más pequeña que alcanza** para el grupo.

---

## 8. Notas de implementación

- **Realtime:** WebSocket (`web_socket_channel`) para comandas y mesas; el servidor asigna IDs. Reflejar cambios al instante en todos los dispositivos.
- **Estados de UI:** cada lista/tablero con loading (skeleton/`CircularProgressIndicator`), vacío (icono + mensaje, como en KDS), error y reconexión visibles.
- **Sol / piso:** tema claro de alto contraste, brillo alto; objetivos táctiles ≥ 48 dp; texto ≥ 14 sp; evitar grises de bajo contraste para datos críticos.
- **Marca blanca:** cambiar `seed` y regenerar `ColorScheme.fromSeed` por tenant (o usar `dynamic_color` para Material You del sistema). IVA, `urgencyMinutes` y `maxQtyPerLine` son configuración de negocio.
- **Plataforma:** fase 1 Android; el mismo código sirve luego para iOS/desktop con ajustes mínimos por ser Material 3.

---

## 9. Componentes reutilizables del .pen

`BtnFilled`, `BtnTonal`, `BtnOutlined`, `FilterChip`, `StatusBadge`, `Switch`, `Stepper`, `MetricCard`, `ProductCard`, `LineItem`, `KdsTicket`, `TableTile`, `NavRail`, `NavBar`. Cada uno mapea a un widget Material 3 (ver §3); editar el componente en Pencil propaga a todas las instancias, igual que un widget reutilizable bien encapsulado en Flutter.
