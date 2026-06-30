# Backend — RestaurantOS

API REST + WebSocket (Node.js + Express + `ws`). Fase piloto: **store en memoria** sembrado con datos demo (El Pirrus); fase siguiente: PostgreSQL.

## Correr

### Con Docker (desde la raíz del repo)

```bash
bash scripts/bootstrap.sh   # genera .env, construye la imagen y levanta el contenedor
```

El `Dockerfile` (Node 20 alpine, usuario sin privilegios) y el
`infra/docker-compose.yml` viven en el repo; el healthcheck usa `GET /api/health`.

### Sin Docker

```bash
npm install
cp .env.example .env
npm start          # http://localhost:4000  ·  ws://localhost:4000
```

## Alcance (resumen)

- **Auth:** login por empleado + PIN → sesión con rol (server-side).
- **Ciclo de servicio** (`docs/api.md`): mesas, menú, cuentas/líneas, tickets KDS, pagos, waitlist.
- **Administración** (`docs/api-admin.md`): menú CRUD + colecciones, empleados, turnos, inventario, compras (sugerencias heurísticas + órdenes), reportes, dashboard y `PUT /config` (marca blanca).
- **WebSocket:** difusión en tiempo real. Eventos: `snapshot`, `table:*`, `account:updated`, `ticket:*`, `dish:ready`, `waitlist:updated`, `menu:updated`, `inventory:updated`, `employee:updated`, `config:updated`.
- **Reglas de negocio:** IDs asignados por el servidor; el mesero no avanza estados de cocina (solo entrega); ruteo Comida→Cocina, Bebidas→Barra; totales server-side.

## Estructura de `src/`

```
src/
├── server.js        # Express + arranque + montaje de /ws
├── realtime.js      # hub WebSocket (snapshot + broadcast)
├── store.js         # estado en memoria + seed demo + ciclo de servicio
├── auth.js          # login PIN→JWT + requireRole
├── store/admin.js   # mutaciones y agregaciones de administración
└── routes/          # auth, tables, menu, menu-collections, accounts, tickets,
                     # waitlist, employees, shifts, inventory, purchasing,
                     # reports, dashboard, config
```

> **Piloto (store en memoria):** los reportes/dashboard se agregan de cuentas pagadas
> en memoria, por lo que el histórico se reinicia al reiniciar el proceso. El seed
> incluye cuentas pagadas demo en días recientes para que haya números. La fase
> siguiente migra a PostgreSQL conservando los mismos contratos.
