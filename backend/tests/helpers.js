import { createServer } from '../src/server.js';

// Spins up the app on an ephemeral port and returns a tiny fetch-based client.
export async function startTestServer() {
  const { server } = createServer({ doSeed: false }); // tests seed explicitly
  await new Promise((resolve) => server.listen(0, resolve));
  const { port } = server.address();
  const base = `http://127.0.0.1:${port}`;

  async function api(method, path, { token, body } = {}) {
    const headers = {};
    if (token) headers.Authorization = `Bearer ${token}`;
    if (body !== undefined) headers['Content-Type'] = 'application/json';
    const res = await fetch(`${base}/api${path}`, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
    const text = await res.text();
    const json = text ? JSON.parse(text) : null;
    return { status: res.status, body: json };
  }

  async function loginAs(employeeId, pin) {
    const { body } = await api('POST', '/auth/login', { body: { employeeId, pin } });
    return body.token;
  }

  return { base, api, loginAs, close: () => new Promise((r) => server.close(r)) };
}
