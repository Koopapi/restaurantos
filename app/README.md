# App — RestaurantOS (Flutter + Material 3)

App Android (tablet + teléfono) del POS y operación en vivo. Tema claro de alto
contraste, acento violeta. Esta fase (**bootstrap**) incluye: tema, navegación
responsiva y **login por PIN** conectado al backend. Las pantallas de operación
y administración llegan en fases siguientes.

## Estructura

```
app/
├── pubspec.yaml
└── lib/
    ├── main.dart                 # MaterialApp.router + tema
    ├── router.dart               # GoRouter con redirect por sesión
    ├── config/api_config.dart    # URL base del backend (configurable)
    ├── core/api_client.dart      # Dio + token JWT + manejo de errores
    ├── theme/                    # colors.dart · theme.dart (Material 3)
    └── features/
        ├── auth/                 # login PIN, repositorio y estado de sesión
        └── home/                 # shell responsivo (NavigationRail / NavigationBar)
```

## Requisitos previos (instalar en tu Mac)

- **Flutter SDK** 3.22+  → https://docs.flutter.dev/get-started/install/macos
- **Android Studio** (incluye Android SDK + emulador) o un teléfono Android con
  *depuración USB* activada.
- Verifica con: `flutter doctor`

## Puesta en marcha (la primera vez)

Este repo trae el código Dart (`lib/`) pero **no** las carpetas de plataforma
(`android/`, `ios/`), que se generan con Flutter:

```bash
cd app
# genera android/ con el package com.gazillioncode.restaurantos (no toca lib/ ni pubspec)
flutter create --org com.gazillioncode --project-name restaurantos --platforms=android .
flutter pub get
```

> Tras `flutter create`, añade en `android/app/src/main/AndroidManifest.xml`,
> dentro de la etiqueta `<application ...>`, el atributo:
> `android:networkSecurityConfig="@xml/network_security_config"`
> (el archivo ya existe en `android/app/src/main/res/xml/`). Esto permite HTTP en
> claro en desarrollo. Sin esto, Android 9+ bloquea las peticiones al backend.

## Correr

1. Levanta el backend (en la raíz del repo): `bash scripts/bootstrap.sh`.
2. Corre el app:

```bash
# Emulador de Android (usa 10.0.2.2 para ver el localhost del host) — default:
flutter run

# Dispositivo físico: apunta a la IP LAN de tu Mac que corre el backend
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:4000
```

El **dispositivo y la Mac deben estar en la misma red WiFi**. Obtén tu IP con
`ipconfig getifaddr en0`.

## Credenciales demo

| Empleado | PIN | Rol |
|---|---|---|
| `emp_carlos` | `2222` | mesero |
| `emp_sofia` | `6666` | admin |
| `emp_roberto` | `5555` | gerente |
| `emp_valeria` | `7777` | hostess |
| `emp_ana` | `3333` | cocina |
| `emp_luis` | `4444` | barista |

## Tests

```bash
flutter test        # smoke test del arranque (pantalla de login)
```
