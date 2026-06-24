# GitHub — creación del remoto y protección de ramas

Reemplaza `<owner>` por tu usuario u organización (p. ej. `gazillioncode`) y `restaurantos` por el nombre final del repo.

## 1. Crear el remoto y subir ramas — elige UNA opción

### Opción A — Publicar desde VS Code (más simple, sin `gh` ni tokens)

Con `git init` + commit + `develop` ya hechos:
1. Panel **Source Control** → botón **"Publish Branch" / "Publish to GitHub"**.
2. Elige **private repository**, nombre `restaurantos` (autoriza en el navegador la 1ª vez).
3. Sube la otra rama: `git push -u origin develop`.

### Opción B — GitHub CLI (`gh`)

```bash
# instalar si hace falta (macOS con Homebrew)
brew install gh
gh auth login
gh auth status

# crear remoto y subir
gh repo create <owner>/restaurantos --private --source=. --remote=origin --push
git push -u origin develop
```

### Opción C — Manual (crea el repo vacío en github.com, sin README)

```bash
git remote add origin https://github.com/<owner>/restaurantos.git
git push -u origin main
git push -u origin develop
```

> Si `git push` por HTTPS pide credenciales y no las tienes en el llavero, usa un Personal Access Token como contraseña, o la Opción A (VS Code maneja la auth por ti).

## 2. Definir develop como rama por defecto (opcional, recomendado)

```bash
gh repo edit <owner>/restaurantos --default-branch develop
```

## 3. Proteger ramas — por UI

Repo en GitHub → **Settings → Branches → Add branch protection rule** (una por `main` y otra por `develop`):

- Branch name pattern: `main` (y luego `develop`)
- ✅ Require a pull request before merging → Require approvals: **1**
  - ⚠️ **Si trabajas solo, deja approvals en `0`** (GitHub no permite aprobar tu propio PR; con `1` no podrías mergear). Súbelo a `1` cuando haya equipo.
- ✅ Require status checks to pass before merging → **strict** (up to date)
  - Selecciona los checks que aparezcan tras la primera corrida de CI:
    - `build-test` (Backend CI)
    - `analyze-test-build` (App CI)
- ✅ Do not allow bypassing the above settings
- 🚫 Allow force pushes: off · 🚫 Allow deletions: off

> Los nombres de los status checks aparecen en la lista solo **después** de que el workflow corrió al menos una vez (haz un PR de prueba o un push que dispare la CI).

## 4. Proteger ramas — por CLI (`gh api`)

`main` (incluye revisión + checks + sin bypass):

```bash
gh api -X PUT repos/<owner>/restaurantos/branches/main/protection \
  -H "Accept: application/vnd.github+json" \
  --input - <<'JSON'
{
  "required_status_checks": { "strict": true, "contexts": ["build-test"] },
  "enforce_admins": true,
  "required_pull_request_reviews": { "required_approving_review_count": 1 },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_linear_history": true
}
JSON
```

`develop` (mismo criterio; agrega el check de app cuando exista):

```bash
gh api -X PUT repos/<owner>/restaurantos/branches/develop/protection \
  -H "Accept: application/vnd.github+json" \
  --input - <<'JSON'
{
  "required_status_checks": { "strict": true, "contexts": ["build-test"] },
  "enforce_admins": false,
  "required_pull_request_reviews": { "required_approving_review_count": 1 },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
```

> Cuando la App CI ya corra, añade `"analyze-test-build"` al array `contexts`.
> Nota: la API exige que los contexts existan; si falla por contexto inexistente, primero corre la CI una vez (o quita el check y agrégalo luego por UI).

## 5. Verificar

```bash
gh api repos/<owner>/restaurantos/branches/main/protection | jq '.required_pull_request_reviews, .required_status_checks'
```
