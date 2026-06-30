# App — RestaurantOS (Flutter, Android)

App del POS y operación en vivo para tablet y teléfono Android. **Design system propio claro + naranja** (alto contraste para sol directo), touch-first, con **white-label** (color de marca configurable en vivo desde *Marca y Tema*). Cubre todo el ciclo de servicio y la administración.

> La guía completa de instalación (backend con Docker, dependencias y cómo correr en una **tablet Android real**) está en el [README de la raíz](../README.md). Aquí va lo específico de la app.

## Estructura

```
app/
├── pubspec.yaml
├── android/                      # plataforma Android (ya versionada, no requiere `flutter create`)
└── lib/
    ├── main.dart                 # MaterialApp.router; el tema deriva del color de marca (white-label)
    ├── router.dart               # GoRouter con redirect por sesión
    ├── preview.dart              # harness de desarrollo (previsualiza pantallas sin backend)
    ├── config/api_config.dart    # URL base del backend (configurable por --dart-define)
    ├── core/                     # api_client (Dio + JWT) · realtime (WebSocket)
    ├── data/                     # repositorios REST (ciclo de servicio + administración)
    ├── state/                    # providers Riverpod
    ├── models/                   # modelos de dominio
    ├── theme/                    # tokens · tema · colores
    ├── widgets/                  # design system (AppCard, GradientButton, …) y comunes
    └── features/                 # auth · home · pos · tables · kds · accounts · hostess · admin
```

## Requisitos

- **Flutter 3.22+ (Dart 3)** y **Android SDK** (Android Studio). Verifica con `flutter doctor`.
- Una **tablet/teléfono Android** con *Depuración USB* (recomendado) o un **emulador**.

## Correr

Primero deja el **backend** corriendo (ver [README raíz](../README.md) → *Levantar el backend*). Luego:

```bash
flutter pub get
```

**Tablet/teléfono real** (la app apunta a la IP LAN de la máquina que corre el backend):

```bash
flutter run --dart-define=API_BASE_URL=http://<IP-LAN-del-backend>:4000
# IP en macOS: ipconfig getifaddr en0   ·   Linux: hostname -I   ·   Windows: ipconfig
```

**Emulador** (usa `10.0.2.2` = host por defecto):

```bash
flutter run
```

> La URL base es configurable en compilación con `--dart-define=API_BASE_URL=...`; por defecto `http://10.0.2.2:4000` (emulador). La app permite HTTP en claro en desarrollo (network security config ya incluido en `android/`).

## Previsualizar el diseño sin backend (dev)

`lib/preview.dart` renderiza pantallas con datos de muestra de El Pirrus, sin login ni servidor:

```bash
flutter run -t lib/preview.dart                          # selector de pantallas arriba
flutter run -t lib/preview.dart --dart-define=SCREEN=9   # abre directo una pantalla (0..11)
```

## Login demo

Accesos rápidos por rol en el login (toca el chip y teclea el PIN):

| Rol | PIN | | Rol | PIN |
|---|---|---|---|---|
| Hostess | `7777` | | Cocina | `3333` |
| Mesero | `2222` | | Barra | `4444` |
| Admin | `6666` | | Gerente | `5555` |

## Tests

```bash
flutter test        # smoke test del arranque (login)
```
