#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────
# bootstrap.sh — pone en marcha RestaurantOS desde cero.
#
# Uso: bash scripts/bootstrap.sh
#
# Qué hace (idempotente — puedes correrlo varias veces):
#   1. Si no existe `.env`, lo copia desde `.env.example`.
#   2. Rellena los secrets vacíos (JWT_SECRET) con `openssl rand`.
#   3. Construye y levanta el stack docker-compose.
#   4. Espera a que el backend esté healthy y muestra los datos de acceso.
# ─────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

ENV_FILE="$REPO_DIR/.env"
ENV_EXAMPLE="$REPO_DIR/.env.example"

# Wrapper para docker compose con el .env y el archivo de infra.
compose() {
    docker compose --env-file "$ENV_FILE" -f infra/docker-compose.yml "$@"
}

C_OK="\033[1;32m✓\033[0m"
C_INFO="\033[1;34mℹ\033[0m"
C_WARN="\033[1;33m⚠\033[0m"
step() { printf "\n${C_INFO} %s\n" "$1"; }
ok()   { printf "  ${C_OK} %s\n" "$1"; }
warn() { printf "  ${C_WARN} %s\n" "$1"; }

# 1. .env
step "Verificando .env"
if [[ ! -f "$ENV_FILE" ]]; then
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    ok "Creado .env desde .env.example"
else
    ok ".env ya existe"
fi

# 2. Secrets faltantes. Cubre 3 casos: línea ausente, vacía o placeholder.
fill_secret() {
    local var=$1
    local hex_size=${2:-32}
    local new_val
    if grep -qE "^${var}=" "$ENV_FILE" 2>/dev/null; then
        local current
        current=$(grep -E "^${var}=" "$ENV_FILE" | head -1 | cut -d= -f2-)
        if [[ -z "$current" || "$current" =~ ^replace_with_ || "$current" == "change_me"* ]]; then
            new_val=$(openssl rand -hex "$hex_size")
            if sed --version >/dev/null 2>&1; then
                sed -i "s|^${var}=.*|${var}=${new_val}|" "$ENV_FILE"
            else
                sed -i '' "s|^${var}=.*|${var}=${new_val}|" "$ENV_FILE"
            fi
            ok "Generado ${var}"
        else
            ok "${var} ya definido"
        fi
    else
        new_val=$(openssl rand -hex "$hex_size")
        printf '\n%s=%s\n' "$var" "$new_val" >> "$ENV_FILE"
        ok "Añadido ${var} (no estaba en .env)"
    fi
}
step "Generando secrets"
fill_secret JWT_SECRET 32

# 3. Levantar stack
step "Construyendo y levantando el stack"
compose up -d --build
ok "Contenedores arriba"

# 4. Esperar healthy
step "Esperando a que el backend esté healthy"
BACKEND_PORT=$(grep -E '^BACKEND_PORT=' "$ENV_FILE" | cut -d= -f2- || true)
BACKEND_PORT=${BACKEND_PORT:-4000}
for i in $(seq 1 30); do
    if curl -fsS "http://localhost:${BACKEND_PORT}/api/health" >/dev/null 2>&1; then
        ok "Backend healthy en http://localhost:${BACKEND_PORT}"
        break
    fi
    sleep 2
    if [[ "$i" == "30" ]]; then
        warn "El backend no respondió a tiempo. Revisa: compose logs backend"
    fi
done

step "Listo"
cat <<EOF
  API   → http://localhost:${BACKEND_PORT}/api
  WS    → ws://localhost:${BACKEND_PORT}/ws
  Login demo: emp_carlos / 2222 (mesero) · emp_sofia / 6666 (admin)

  Logs:    docker compose --env-file .env -f infra/docker-compose.yml logs -f backend
  Detener: docker compose --env-file .env -f infra/docker-compose.yml down
EOF
