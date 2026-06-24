// Express app + HTTP server + WebSocket mount. Exports createServer() for tests;
// auto-starts only when run directly.
import http from 'node:http';
import express from 'express';
import cors from 'cors';
import { seed, ApiError } from './store.js';
import { attachRealtime } from './realtime.js';
import authRoutes from './routes/auth.js';
import tableRoutes from './routes/tables.js';
import menuRoutes from './routes/menu.js';
import accountRoutes from './routes/accounts.js';
import ticketRoutes from './routes/tickets.js';
import waitlistRoutes from './routes/waitlist.js';
import configRoutes from './routes/config.js';

export function createApp() {
  const app = express();
  app.use(cors());
  app.use(express.json());

  app.get('/api/health', (req, res) => res.json({ ok: true }));
  app.use('/api/auth', authRoutes);
  app.use('/api/tables', tableRoutes);
  app.use('/api/menu', menuRoutes);
  app.use('/api/accounts', accountRoutes);
  app.use('/api/tickets', ticketRoutes);
  app.use('/api/waitlist', waitlistRoutes);
  app.use('/api', configRoutes);

  // 404
  app.use((req, res) => {
    res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Ruta no encontrada' } });
  });

  // Error handler — convierte ApiError al cuerpo estándar.
  // eslint-disable-next-line no-unused-vars
  app.use((err, req, res, next) => {
    if (err instanceof ApiError) {
      return res.status(err.status).json({ error: { code: err.code, message: err.message } });
    }
    console.error(err);
    res.status(500).json({ error: { code: 'INTERNAL', message: 'Error interno' } });
  });

  return app;
}

// Builds app + http server + ws hub. Seeds the store unless told otherwise.
export function createServer({ doSeed = true } = {}) {
  if (doSeed) seed();
  const app = createApp();
  const server = http.createServer(app);
  const wss = attachRealtime(server);
  return { app, server, wss };
}

const isMain = process.argv[1] && import.meta.url === `file://${process.argv[1]}`;
if (isMain) {
  const port = Number(process.env.PORT || 4000);
  const { server } = createServer();
  server.listen(port, () => {
    console.log(`RestaurantOS backend → http://localhost:${port}/api · ws://localhost:${port}/ws`);
  });
}
