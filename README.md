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
├── backend/        # API REST + WebSocket (Node + Express) + Dockerfile
├── infra/          # docker-compose del stack
├── scripts/        # bootstrap.sh (levanta todo con un comando)
├── docs/
│   └── design/     # System design + pantallas exportadas (PNG)
├── .github/        # Workflows de CI/CD y plantillas
└── docs/branching.md  # Estrategia de ramas
```

## Requisitos

- **Docker** + Docker Compose — vía recomendada para el backend.
- **Node.js** 20+ — para correr el `backend/` sin contenedor.
- **Flutter** 3.22+ (Dart 3) y Android SDK — para `app/`.

## Cómo correr

### Backend con Docker (recomendado)

Un solo comando genera el `.env` (con `JWT_SECRET` autogenerado), construye la
imagen y levanta el contenedor:

```bash
bash scripts/bootstrap.sh
# API → http://localhost:4000/api · WS → ws://localhost:4000/ws
```

Operación manual del stack:

```bash
docker compose --env-file .env -f infra/docker-compose.yml up -d --build   # levantar
docker compose --env-file .env -f infra/docker-compose.yml logs -f backend # logs
docker compose --env-file .env -f infra/docker-compose.yml down            # detener
```

### Backend sin Docker

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
- **Estrategia de ramas y flujo de trabajo:** `docs/branching.md`
- **Pantallas (diseño Material 3):** `docs/design/`

## Roles

Mesero · Cocina · Barista · Hostess · Gerente · Admin. Login por PIN con verificación de rol en el backend.

## Licencia

Propietario — Gazillion Code. Todos los derechos reservados.
