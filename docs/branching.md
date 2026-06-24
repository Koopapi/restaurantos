# Estrategia de ramas y flujo de trabajo

Modelo basado en GitFlow simplificado, pensado para entregas continuas y un piloto en operación.

## Ramas permanentes

| Rama | Propósito | Reglas |
|------|-----------|--------|
| `main` | Código en **producción**. Cada merge es una versión liberada. | Protegida. Solo merge vía PR desde `release/*` o `hotfix/*`. Tag `vX.Y.Z`. |
| `develop` | Rama de **integración**. Base de las features. | Protegida. Merge vía PR con CI en verde. |

## Ramas temporales

| Patrón | Nace de | Se integra a | Uso |
|--------|---------|--------------|-----|
| `feature/<área>-<desc>` | `develop` | `develop` | Nueva funcionalidad. Ej: `feature/pos-modal-ingredientes` |
| `fix/<desc>` | `develop` | `develop` | Corrección no urgente. |
| `release/<X.Y.Z>` | `develop` | `main` + `develop` | Estabilización previa a producción (solo bugfixes y versión). |
| `hotfix/<desc>` | `main` | `main` + `develop` | Corrección urgente en producción. |

## Convención de commits (Conventional Commits)

```
<tipo>(<alcance>): <descripción corta>

tipos: feat, fix, docs, style, refactor, perf, test, build, ci, chore
alcance: app, backend, pos, kds, mesas, auth, ci, ...
```

Ejemplos: `feat(pos): modal de ingredientes con extras`, `fix(kds): timer de urgencia`, `ci(app): build de APK en PR`.

## Flujo de un cambio

1. `git switch develop && git pull`
2. `git switch -c feature/mi-cambio`
3. Commits pequeños y descriptivos.
4. `git push -u origin feature/mi-cambio`
5. Abrir **Pull Request** hacia `develop`. CI debe pasar (lint, análisis, tests).
6. Revisión → merge (squash) → borrar la rama.

## Reglas de protección sugeridas (GitHub)

- `main` y `develop`: requerir PR, requerir CI en verde, requerir 1 revisión, prohibir push directo.
- Bloquear force-push y borrado de `main`/`develop`.

## Versionado

Semántico: `MAJOR.MINOR.PATCH`. Las releases se etiquetan en `main` (`git tag -a v0.1.0 -m "..."`).
