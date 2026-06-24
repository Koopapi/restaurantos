# Backend — RestaurantOS

API REST + WebSocket (Node.js + Express + `ws`). Fase piloto: **store en memoria** sembrado con datos demo (El Pirrus); fase siguiente: PostgreSQL.

## Correr

```bash
npm install
cp .env.example .env
npm start          # http://localhost:4000  ·  ws://localhost:4000
```

## Alcance (resumen)

- **Auth:** login por empleado + PIN → sesión con rol (server-side).
- **REST:** empleados, mesas, menú, cuentas/líneas, tickets KDS, pagos.
- **WebSocket:** difusión en tiempo real de cambios de mesas y comandas.
- **Reglas de negocio:** IDs asignados por el servidor; el mesero no avanza estados de cocina (solo entrega); ruteo Comida→Cocina, Bebidas→Barra.

> La implementación de `src/` se construye por fases (ver tablero del repo). La estructura prevista: `src/server.js`, `src/store.js`, `src/routes/`, `src/realtime.js`.
