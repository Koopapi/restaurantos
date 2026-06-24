# Handoff — trabajar todo desde VS Code

Guía única para continuar el proyecto en VS Code (con Claude Code) sin depender de la sesión de diseño. Todo lo necesario está en el repo.

## 1. Estado actual

| Área | Estado |
|------|--------|
| Diseño (Pencil) | ✅ 23 pantallas + system design. Exportado en `docs/design/`. (Editable solo en Pencil/Cowork.) |
| Repo + CI/CD | ✅ Monorepo, ramas `main`/`develop` protegidas, Backend CI en verde. |
| Backend — ciclo de servicio | ✅ Implementado y verificado (9/9 tests + smoke). `backend/src/`. |
| Backend — administración | ✅ Implementado y verificado (22/22 tests + smoke). `backend/src/routes/` + `src/store/admin.js`. |
| App Flutter | ⏳ Pendiente. Spec en `docs/specs/RestaurantOS-Flutter-Material3.md` + starter en `docs/flutter-starter/`. |

## 2. Estructura

```
app/                Flutter (por inicializar) · ver docs/flutter-starter/
backend/            Node API + WebSocket (ciclo de servicio hecho)
docs/
  api.md            Contrato REST + WebSocket (ciclo de servicio)
  api-admin.md      Contrato de administración (fase 2 backend)
  branching.md      Estrategia de ramas
  github-setup.md   Remoto + protección de ramas (gh)
  handoff.md        ESTE archivo
  flutter-starter/  Tema Dart listo (ColorScheme + SemanticColors)
  specs/            Especificaciones de diseño/implementación
  design/           Pantallas + system design (PNG)
.github/workflows/  backend-ci.yml · app-ci.yml
```

## 3. Flujo de trabajo (recap)

1. `git switch develop && git pull`
2. `git switch -c feature/<algo>`
3. Commits con Conventional Commits (`feat(...)`, `fix(...)`).
4. `git push -u origin feature/<algo>` → PR a `develop` → CI verde → merge (squash).
5. Releases: PR `develop → main`, tag `vX.Y.Z`.

Detalle en `docs/branching.md`. App CI se activa cuando exista `app/pubspec.yaml` o `app/lib/**`.

## 4. Correr y probar

Backend:
```bash
cd backend
npm install
npm test            # node:test (22 pruebas: ciclo de servicio + administración)
npm start           # http://localhost:4000 · ws://localhost:4000
# login demo: emp_carlos / 2222 (mesero), emp_sofia / 6666 (admin)
```

App (cuando exista):
```bash
cd app
flutter pub get
flutter run
```

## 5. Prompts para Claude Code (copy-paste, una rama por feature)

### feature/backend-admin
> Implementa la capa de administración del backend siguiendo `docs/api-admin.md`: menú CRUD + colecciones (incluido el CRUD pendiente en `routes/menu.js`), empleados, turnos, inventario, compras (sugerencias + órdenes), reportes, dashboard y `PUT /api/config`. Reusa `requireRole` y el patrón de `store.js`; agrega datos demo (insumos bajo mínimo, colecciones, turnos, cuentas pagadas) y tests `node:test`, incluyendo permisos (mesero/hostess → 403). Mantén el estilo y los eventos WebSocket existentes.

### feature/app-bootstrap
> Inicializa el proyecto Flutter en `app/` con `flutter create --org com.gazillioncode --project-name restaurantos --platforms=android app`. Integra el tema de `docs/flutter-starter/` (`colors.dart`, `theme.dart`) en `lib/theme/`. Añade dependencias `go_router`, `flutter_riverpod`, `dio`, `web_socket_channel`. Crea `lib/main.dart` con `MaterialApp.router` usando el tema, un `lib/router.dart` y un `Scaffold` responsivo (NavigationRail ≥840dp / NavigationBar <840dp) según `docs/specs/RestaurantOS-Flutter-Material3.md`. Implementa la pantalla de Login (PIN) conectada a `POST /api/auth/login` (`docs/api.md`).

### feature/app-service-cycle
> Implementa las pantallas del ciclo de servicio en Flutter según los diseños de `docs/design/` y los contratos de `docs/api.md`: Mesas, POS + modal de ingredientes (bottom sheet en teléfono), Pedido/Carrito, Cocina KDS, Barra KDS y Cobro. Usa Riverpod para estado, `dio` para REST y `web_socket_channel` para realtime (suscríbete a `ticket:*`, `table:*`, `dish:ready`). Respeta las reglas de negocio (el mesero solo entrega). Crea widgets reutilizables en `lib/widgets/` (botón grande, KDS ticket, table tile, line item, stepper).

### feature/app-admin
> Implementa las pantallas de administración en Flutter según `docs/design/` y `docs/api-admin.md`: Dashboard, Menú y Platillos, Crear Menú, Inventario, Compras IA, Empleados, Turnos, Reportes y Marca Blanca. Reusa el tema y los widgets; protege por rol según la matriz del contrato.

## 6. Cuándo volver a Cowork (diseño)

Solo para lo que vive en Pencil: **nuevas pantallas o cambios visuales**, **re-exportar imágenes** para video/marketing, o **redactar nuevas specs/recursos**. El archivo de diseño es `pencil-new.pen` y no se edita desde VS Code.

## 7. Pendientes de configuración (opcional, GitHub)

- Subir el check `analyze-test-build` (App CI) a la protección de `develop`/`main` cuando la app exista (`docs/github-setup.md`).
- Habilitar *Allow auto-merge* en Settings → General si quieres `gh pr merge --auto`.
