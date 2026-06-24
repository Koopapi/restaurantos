// WebSocket hub: authenticates connections via ?token=, sends a snapshot,
// then broadcasts every domain event emitted by the store.
import { WebSocketServer } from 'ws';
import { events, snapshot } from './store.js';
import { authPayloadFromToken } from './auth.js';

export function attachRealtime(server) {
  const wss = new WebSocketServer({ noServer: true });

  // Upgrade only /ws with a valid token.
  server.on('upgrade', (req, socket, head) => {
    const url = new URL(req.url, 'http://localhost');
    if (url.pathname !== '/ws') {
      socket.destroy();
      return;
    }
    const payload = authPayloadFromToken(url.searchParams.get('token'));
    if (!payload) {
      socket.write('HTTP/1.1 401 Unauthorized\r\n\r\n');
      socket.destroy();
      return;
    }
    wss.handleUpgrade(req, socket, head, (ws) => {
      ws.auth = payload;
      wss.emit('connection', ws, req);
    });
  });

  wss.on('connection', (ws) => {
    send(ws, { type: 'snapshot', data: snapshot(), at: new Date().toISOString() });
  });

  const onBroadcast = (envelope) => {
    const msg = JSON.stringify(envelope);
    for (const client of wss.clients) {
      if (client.readyState === client.OPEN) client.send(msg);
    }
  };
  events.on('broadcast', onBroadcast);

  wss.on('close', () => events.off('broadcast', onBroadcast));
  return wss;
}

function send(ws, envelope) {
  if (ws.readyState === ws.OPEN) ws.send(JSON.stringify(envelope));
}
