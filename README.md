# RestaurantOS

Sistema de punto de venta y operación en vivo para restaurante (caso real: marisquería **El Pirrus**). Cubre el ciclo completo de servicio en piso — recepción, mesas, toma de orden, cocina/barra (KDS), entrega y cobro — más administración (menú, inventario, compras, empleados, turnos, reportes y marca blanca).

- **App:** Flutter + Material 3 (Material You), tema claro de alto contraste, acento violeta. Fase 1: **Android** (tablet + teléfono).
- **Backend:** Node.js + Express + WebSocket (tiempo real), backend-first y preparado para multi-tenant.
- **Diseño:** ver `docs/` (system design + pantallas + especificaciones).

> Estado actual: diseño de sistema completo y scaffold del repositorio. El código de `backend/` y `app/` se construye por fases (ver Issues / tablero).

## Estructura del monorepo

```
RestaurantOS/
├── app/            # Aplicación Flutter (Material 3) — Android
├── backend/        # API REST + WebSocket (Node + Express)
├── docs/
│   ├── design/     # System design + pantallas exportadas (PNG)
│   ├── specs/      # Especificaciones de diseño/implementación
│   └── reference/  # Capturas del build anterior (referencia)
├── .github/        # Workflows de CI/CD y plantillas
└── docs/branching.md  # Estrategia de ramas
```

## Requisitos

- **Flutter** 3.22+ (Dart 3) y Android SDK — para `app/`.
- **Node.js** 20+ — para `backend/`.

## Cómo correr (cuando el código esté disponible)

Backend:

```bash
cd backend
npm install
npm start          # API en http://localhost:4000, WS en ws://localhost:4000
```

App (Android):

```bash
cd app
flutter pub get
flutter run        # con un emulador o dispositivo Android conectado
```

## Documentación

- **System design (1 hoja):** `docs/design/M3-00-System-Design.png`
- **Especificación de implementación Flutter:** `docs/specs/RestaurantOS-Flutter-Material3.md`
- **Estrategia de ramas y flujo de trabajo:** `docs/branching.md`
- **Pantallas (diseño Material 3):** `docs/design/`

## Roles

Mesero · Cocina · Barista · Hostess · Gerente · Admin. Login por PIN con verificación de rol en el backend.

## Licencia

Propietario — Gazillion Code. Todos los derechos reservados.
