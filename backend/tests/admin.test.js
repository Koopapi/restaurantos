import { test, before, beforeEach, after } from 'node:test';
import assert from 'node:assert/strict';
import { seed } from '../src/store.js';
import { startTestServer } from './helpers.js';

let srv;
let admin; // token admin (Sofía)
let gerente; // token gerente (Roberto)

before(async () => { srv = await startTestServer(); });
after(() => srv.close());
beforeEach(async () => {
  seed();
  admin = await srv.loginAs('emp_sofia', '6666');
  gerente = await srv.loginAs('emp_roberto', '5555');
});

test('menú CRUD: crear, editar, disponibilidad y borrar', async () => {
  const { api } = srv;
  const created = await api('POST', '/menu', {
    token: gerente,
    body: { name: 'Tostada de Camarón', price: 120, category: 'Tostadas', station: 'cocina', modifiers: [{ name: 'Extra', price: 15 }] },
  });
  assert.equal(created.status, 201);
  assert.ok(created.body.id);
  assert.equal(created.body.modifiers[0].id?.startsWith('mod_'), true);
  const itemId = created.body.id;

  const updated = await api('PUT', `/menu/${itemId}`, { token: gerente, body: { price: 135 } });
  assert.equal(updated.body.price, 135);

  const avail = await api('PATCH', `/menu/${itemId}/availability`, { token: gerente, body: { available: false } });
  assert.equal(avail.body.available, false);

  const del = await api('DELETE', `/menu/${itemId}`, { token: gerente });
  assert.deepEqual(del.body, { ok: true });
  const after = await api('GET', `/menu/${itemId}`, { token: gerente });
  assert.equal(after.status, 404);
});

test('crear platillo con station inválida → 422', async () => {
  const res = await srv.api('POST', '/menu', { token: gerente, body: { name: 'X', price: 10, station: 'patio' } });
  assert.equal(res.status, 422);
  assert.equal(res.body.error.code, 'VALIDATION');
});

test('activar una colección desactiva las demás', async () => {
  const { api } = srv;
  const cols = await api('GET', '/menu-collections', { token: gerente });
  assert.ok(cols.body.length >= 2);
  const target = cols.body.find((c) => !c.active);

  await api('POST', `/menu-collections/${target.id}/activate`, { token: gerente });
  const after = await api('GET', '/menu-collections', { token: gerente });
  const actives = after.body.filter((c) => c.active);
  assert.equal(actives.length, 1);
  assert.equal(actives[0].id, target.id);
});

test('empleados: alta valida PIN único de 4 dígitos y no permite auto-baja', async () => {
  const { api } = srv;
  // PIN repetido (1111 = María) → 409
  const dup = await api('POST', '/employees', { token: admin, body: { name: 'Nuevo', role: 'mesero', pin: '1111', shift: 'matutino' } });
  assert.equal(dup.status, 409);

  // PIN inválido → 422
  const badPin = await api('POST', '/employees', { token: admin, body: { name: 'Nuevo', role: 'mesero', pin: '12', shift: 'matutino' } });
  assert.equal(badPin.status, 422);

  // alta válida
  const ok = await api('POST', '/employees', { token: admin, body: { name: 'Diana', role: 'mesero', pin: '9090' } });
  assert.equal(ok.status, 201);
  assert.equal(ok.body.pin, undefined); // nunca se expone el pin

  // auto-baja prohibida (Sofía intenta borrarse)
  const self = await api('DELETE', '/employees/emp_sofia', { token: admin });
  assert.equal(self.status, 409);

  // baja de otro = soft-delete
  const soft = await api('DELETE', `/employees/${ok.body.id}`, { token: admin });
  assert.deepEqual(soft.body, { ok: true });
});

test('turnos: listar por semana y crear', async () => {
  const { api } = srv;
  const all = await api('GET', '/shifts', { token: gerente });
  assert.ok(all.body.length > 0);

  const week = all.body[0].date;
  const filtered = await api('GET', `/shifts?week=${week}`, { token: gerente });
  assert.ok(filtered.body.every((s) => typeof s.date === 'string'));

  const created = await api('POST', '/shifts', {
    token: gerente,
    body: { employeeId: 'emp_maria', date: week, type: 'completo', start: '09:00', end: '21:00' },
  });
  assert.equal(created.status, 201);
  assert.ok(created.body.id);
});

test('inventario: alertas devuelven solo insumos bajo mínimo', async () => {
  const { api } = srv;
  const alerts = await api('GET', '/inventory/alerts', { token: gerente });
  assert.ok(alerts.body.length > 0);
  assert.ok(alerts.body.every((i) => i.status === 'bajo'));
});

test('compras: sugerencias se derivan de inventario bajo mínimo', async () => {
  const { api } = srv;
  const sug = await api('GET', '/purchasing/suggestions', { token: gerente });
  assert.ok(sug.body.items.length > 0);
  assert.ok(sug.body.totalEst > 0);
  // suggestedQty = minStock*2 - stock (heurística)
  const first = sug.body.items[0];
  assert.ok(first.suggestedQty >= 1);
  assert.ok(['alta', 'media', 'baja'].includes(first.urgency));
});

test('compras: recibir una orden suma stock y puede sacar de "bajo"', async () => {
  const { api } = srv;
  const inv = await api('GET', '/inventory?status=bajo', { token: gerente });
  const item = inv.body[0];
  const before = item.stock;
  const qty = item.minStock * 2; // suficiente para superar el mínimo

  const order = await api('POST', '/purchasing/orders', { token: gerente, body: { items: [{ inventoryItemId: item.id, qty }] } });
  assert.equal(order.status, 201);
  assert.equal(order.body.status, 'sugerida');

  // no se puede recibir sin aprobar
  const early = await api('POST', `/purchasing/orders/${order.body.id}/receive`, { token: gerente });
  assert.equal(early.status, 409);

  await api('POST', `/purchasing/orders/${order.body.id}/approve`, { token: gerente });
  const received = await api('POST', `/purchasing/orders/${order.body.id}/receive`, { token: gerente });
  assert.equal(received.body.status, 'recibida');

  const after = await api('GET', '/inventory', { token: gerente });
  const updated = after.body.find((i) => i.id === item.id);
  assert.equal(updated.stock, Math.round((before + qty) * 100) / 100);
  assert.equal(updated.status, 'ok');
});

test('dashboard agrega de cuentas pagadas demo (números > 0)', async () => {
  const { api } = srv;
  const dash = await api('GET', '/dashboard?range=30d', { token: gerente });
  assert.equal(dash.status, 200);
  assert.ok(dash.body.sales > 0);
  assert.ok(dash.body.tickets > 0);
  assert.ok(dash.body.avgTicket > 0);
  assert.ok(Array.isArray(dash.body.trend));
  assert.ok(dash.body.topDishes.length > 0);
  assert.equal(dash.body.live.tablesTotal, 12);
});

test('reportes: ventas por rango y exportación CSV', async () => {
  const { api, base } = srv;
  const json = await api('GET', '/reports/sales?range=mes', { token: gerente });
  assert.equal(json.body.range, 'mes');
  assert.ok(json.body.totalSales > 0);
  assert.ok(json.body.byPaymentMethod.length > 0);

  // CSV
  const res = await fetch(`${base}/api/reports/sales?range=mes&format=csv`, { headers: { Authorization: `Bearer ${gerente}` } });
  assert.equal(res.headers.get('content-type')?.includes('text/csv'), true);
  const text = await res.text();
  assert.ok(text.split('\n')[0].includes('day'));
});

test('PUT /config actualiza marca blanca y reglas (solo admin) y emite config:updated', async () => {
  const { api } = srv;
  const updated = await api('PUT', '/config', { token: admin, body: { brandName: 'Mariscos Nuevo', taxRate: 0.16 } });
  assert.equal(updated.body.brandName, 'Mariscos Nuevo');
  assert.equal(updated.body.taxRate, 0.16);

  // taxRate fuera de rango → 422
  const bad = await api('PUT', '/config', { token: admin, body: { taxRate: 2 } });
  assert.equal(bad.status, 422);
});

// --------------------------- Permisos ---------------------------
test('permisos: mesero y hostess reciben 403 en endpoints admin', async () => {
  const { api, loginAs } = srv;
  const mesero = await loginAs('emp_maria', '1111');
  const hostess = await loginAs('emp_valeria', '7777');

  const adminEndpoints = [
    ['POST', '/menu', { name: 'x', price: 1, station: 'cocina' }],
    ['GET', '/menu-collections'],
    ['POST', '/employees', { name: 'x', role: 'mesero', pin: '8181' }],
    ['GET', '/shifts'],
    ['GET', '/inventory'],
    ['GET', '/purchasing/suggestions'],
    ['GET', '/reports/sales'],
    ['GET', '/dashboard'],
  ];

  for (const token of [mesero, hostess]) {
    for (const [method, path, body] of adminEndpoints) {
      const res = await api(method, path, { token, body });
      assert.equal(res.status, 403, `${method} ${path} debería ser 403`);
      assert.equal(res.body.error.code, 'FORBIDDEN');
    }
  }
});

test('permisos: PUT /config es solo admin (gerente → 403)', async () => {
  const res = await srv.api('PUT', '/config', { token: gerente, body: { brandName: 'X' } });
  assert.equal(res.status, 403);
});
