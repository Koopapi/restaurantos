# App — RestaurantOS (Flutter · Material 3)

Aplicación Android (tablet + teléfono) del POS y operación en vivo.

## Estado

Carpeta reservada para el proyecto Flutter. El proyecto se inicializa con:

```bash
# desde la raíz del repo
flutter create --org com.gazillioncode --project-name restaurantos --platforms=android app
```

Luego se incorporan, según la especificación `docs/specs/RestaurantOS-Flutter-Material3.md`:

- `lib/theme/` — `ColorScheme` Material 3 (claro, seed violeta `#6750A4`) + `SemanticColors` (success/warning/info).
- `lib/models/` — employee, table, menu_item, account, line, ticket.
- `lib/services/` — ApiClient (dio), RealtimeService (web_socket_channel), AuthService.
- `lib/state/` — providers Riverpod.
- `lib/widgets/` — design system (botones grandes, KDS ticket, table tile, line item, stepper, nav rail/bar).
- `lib/screens/` — login, mesas, pos + modal, pedido, cocina/barra KDS, cobro.
- `lib/router.dart`, `lib/main.dart` — navegación responsiva (NavigationRail/NavigationBar).

## Dependencias previstas

`go_router`, `flutter_riverpod`, `dio`, `web_socket_channel`.

## Diseño de referencia

`docs/design/` (pantallas Material 3) y `docs/design/M3-00-System-Design.png` (system design).
