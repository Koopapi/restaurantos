# RestaurantOS

Sistema de punto de venta y operación en vivo para restaurante (caso real: marisquería **El Pirrus**). Cubre el ciclo completo de servicio en piso — recepción, mesas, toma de orden, cocina/barra (KDS), entrega y cobro — más administración (menú, inventario, compras, empleados, turnos, reportes y marca blanca).

- **App:** Flutter (Material 3) con design system propio **claro + naranja**, alto contraste para sol directo, **white-label** (color de marca configurable en vivo). Fase 1: **Android** (tablet + teléfono).
- **Backend:** Node.js + Express + WebSocket (tiempo real), store en memoria sembrado con el catálogo real de El Pirrus.

## Estructura del monorepo

```
RestaurantOS/
├── app/            # Aplicación Flutter (Android) — POS y operación en vivo
├── backend/        # API REST + WebSocket (Node + Express) + Dockerfile
├── infra/          # docker-compose del stack
├── scripts/        # bootstrap.sh (levanta el backend con un comando)
├── docs/
│   ├── api-admin.md   # Contrato de la capa de administración
│   ├── branching.md   # Estrategia de ramas
│   └── design/        # System design + pantallas (PNG)
└── .github/        # Workflows de CI/CD y plantillas
```

---

## Requisitos previos

Instala según lo que vayas a correr:

| Para… | Necesitas |
|---|---|
| **Backend con Docker** (recomendado) | [Docker Desktop](https://www.docker.com/products/docker-desktop/) (incluye Docker Compose) |
| **Backend sin Docker** | [Node.js 20+](https://nodejs.org) |
| **App Android** | [Flutter 3.22+ (Dart 3)](https://docs.flutter.dev/get-started/install) + Android SDK (viene con [Android Studio](https://developer.android.com/studio)) |
| **Probar en tablet/teléfono real** | Un dispositivo Android con **Depuración USB** activada |

Verifica tu entorno Flutter con: `flutter doctor` (todo lo de *Android toolchain* debe estar en verde).

---

## Puesta en marcha

### 1. Clonar

```bash
git clone https://github.com/Koopapi/restaurantos.git
cd restaurantos
```

### 2. Levantar el backend (API + WebSocket)

> El backend sirve el catálogo real, la lógica del ciclo de servicio y el tiempo real. Déjalo corriendo en una terminal.

**Opción A — Docker (recomendado).** Con Docker Desktop **abierto**, desde la raíz del repo:

```bash
bash scripts/bootstrap.sh
```

Esto genera el `.env` (con `JWT_SECRET` autogenerado), construye la imagen y levanta el contenedor. Al terminar verás:

```
API   → http://localhost:4000/api
WS    → ws://localhost:4000
```

Operación manual del stack:

```bash
docker compose --env-file .env -f infra/docker-compose.yml up -d --build   # levantar
docker compose --env-file .env -f infra/docker-compose.yml logs -f backend # ver logs
docker compose --env-file .env -f infra/docker-compose.yml down            # detener
```

**Opción B — sin Docker (Node):**

```bash
cd backend
npm install
npm start          # http://localhost:4000
```

### 3. Correr la app Android

```bash
cd app
flutter pub get
```

> No necesitas `flutter create`: la carpeta `android/` ya viene en el repo (package `com.gazillioncode.restaurantos`, con el permiso de HTTP en claro para desarrollo).

#### 3.A — En una TABLET ANDROID REAL  *(recomendado para el piloto)*

1. **Activa el modo desarrollador** en la tablet: *Ajustes → Acerca del dispositivo → toca 7 veces en «Número de compilación»*. Luego entra a *Opciones de desarrollador* y activa **Depuración USB**.
2. **Conecta la tablet por USB** y acepta el diálogo *«¿Permitir depuración USB?»*. Verifica que Flutter la vea:
   ```bash
   flutter devices
   ```
3. La **tablet y la computadora del backend deben estar en la MISMA red Wi-Fi**.
4. **Averigua la IP local** de la computadora que corre el backend:
   - macOS: `ipconfig getifaddr en0`
   - Linux: `hostname -I | awk '{print $1}'`
   - Windows: `ipconfig` → busca la *Dirección IPv4* (ej. `192.168.1.50`)
5. **Corre la app apuntando a esa IP** (la tablet no puede usar `localhost`):
   ```bash
   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:4000
   ```
   (reemplaza `192.168.1.50` por tu IP del paso 4).

> **Si no conecta:** revisa que el **firewall** de la computadora permita el puerto `4000`, que ambos equipos estén en la misma red, y que el backend esté arriba (`http://localhost:4000/api/health`). La app ya permite HTTP en claro (network security config), no necesitas HTTPS para el piloto.

#### 3.B — En un EMULADOR Android

```bash
flutter emulators                       # lista los emuladores (créalos en Android Studio)
flutter emulators --launch <id>         # arranca uno (p. ej. Pixel_Tablet)
flutter run                             # usa http://10.0.2.2:4000 por defecto (alias del host)
```

---

## Login demo

En la pantalla de login hay **accesos rápidos** por rol; toca el chip y teclea su PIN:

| Rol | PIN | Empleado | Pantallas |
|---|---|---|---|
| **Hostess** | `7777` | Valeria | Mesas (asignar) + Lista de Espera |
| **Mesero** | `2222` | Carlos | POS, Nueva Cuenta, Cuentas, Mesas, Cobro |
| **Admin** | `6666` | Sofía | Todo (Dashboard, Marca y Tema, Turnos, Menú, Inventario…) |
| **Cocina** | `3333` | Ana | Cocina KDS |
| **Barra** | `4444` | Luis | Barra KDS |

## Probar el flujo completo

Ciclo de servicio: **Mesas → abrir cuenta → POS** (agrega platillos) **→ Enviar a Cocina/Barra → (login Cocina) KDS** (marcar listo) **→ (Mesero) Entregar → Cobrar**.
White-label: como **Admin → Marca y Tema → elige un color → Publicar** → toda la app se re-tematiza en vivo.

## Pruebas

```bash
cd backend && npm test     # API (node:test)
cd app && flutter test     # smoke test del login
```

---

## Documentación

- **Contrato de administración (API):** `docs/api-admin.md`
- **Estrategia de ramas y flujo de trabajo:** `docs/branching.md`
- **System design y pantallas (PNG):** `docs/design/`

## Roles

Mesero · Cocina · Barista · Hostess · Gerente · Admin. Login por PIN con verificación de rol en el backend.

## Licencia

Propietario — Gazillion Code. Todos los derechos reservados.
