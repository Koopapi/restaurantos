# Contribuir a RestaurantOS

## Flujo de trabajo (resumen)

1. Parte de `develop` actualizado.
2. Crea una rama `feature/...` o `fix/...` (ver [docs/branching.md](docs/branching.md)).
3. Commits con [Conventional Commits](https://www.conventionalcommits.org/): `feat(pos): ...`, `fix(kds): ...`.
4. Abre un Pull Request hacia `develop`. La CI debe pasar.
5. Merge con squash y borra la rama.

`main` y `develop` están protegidas: no se hace push directo.

## Estilo de código

- **Dart/Flutter:** `dart format .` y `flutter analyze` sin warnings.
- **Node:** seguir `.editorconfig`; mantener funciones pequeñas y sin secretos en el repo.
- Variables sensibles en `.env` (ver `.env.example`), nunca commiteadas.

## Estructura

- `app/` Flutter (Material 3, Android).
- `backend/` API REST + WebSocket (Node + Express).
- `docs/` diseño y especificaciones.

## Antes de abrir PR

- [ ] Compila y corre localmente.
- [ ] Tests/análisis en verde.
- [ ] Documentación actualizada si cambia comportamiento.
