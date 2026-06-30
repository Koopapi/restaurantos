import { test, before, beforeEach, after } from 'node:test';
import assert from 'node:assert/strict';
import { seed } from '../src/store.js';
import { startTestServer } from './helpers.js';

let srv;
before(async () => { srv = await startTestServer(); });
after(() => srv.close());
beforeEach(() => seed());

test('el mesero NO puede avanzar tickets (403)', async () => {
  const { api, loginAs } = srv;
  const mesero = await loginAs('emp_maria', '1111');
  const created = await api('POST', '/accounts', { token: mesero, body: { serviceType: 'mesa', tableId: 'tbl_2', guests: 2 } });
  const dish = await api('GET', '/menu?category=Aguachiles', { token: mesero });
  await api('POST', `/accounts/${created.body.id}/lines`, { token: mesero, body: { menuItemId: dish.body[0].id, qty: 1 } });
  const sent = await api('POST', `/accounts/${created.body.id}/send`, { token: mesero });
  const ticketId = sent.body.tickets[0].id;

  const res = await api('POST', `/tickets/${ticketId}/advance`, { token: mesero });
  assert.equal(res.status, 403);
  assert.equal(res.body.error.code, 'FORBIDDEN');
});

test('barista solo avanza tickets de barra, no de cocina (403)', async () => {
  const { api, loginAs } = srv;
  const mesero = await loginAs('emp_maria', '1111');
  const created = await api('POST', '/accounts', { token: mesero, body: { serviceType: 'mesa', tableId: 'tbl_3', guests: 2 } });
  const dish = await api('GET', '/menu?category=Aguachiles', { token: mesero }); // cocina
  await api('POST', `/accounts/${created.body.id}/lines`, { token: mesero, body: { menuItemId: dish.body[0].id, qty: 1 } });
  const sent = await api('POST', `/accounts/${created.body.id}/send`, { token: mesero });
  const cocinaTicket = sent.body.tickets.find((t) => t.station === 'cocina');

  const barista = await loginAs('emp_luis', '4444');
  const res = await api('POST', `/tickets/${cocinaTicket.id}/advance`, { token: barista });
  assert.equal(res.status, 403);
});

test('qty por línea no puede exceder Config.maxQtyPerLine (422)', async () => {
  const { api, loginAs } = srv;
  const mesero = await loginAs('emp_maria', '1111');
  const created = await api('POST', '/accounts', { token: mesero, body: { serviceType: 'llevar', guests: 1 } });
  const dish = await api('GET', '/menu?category=Aguachiles', { token: mesero });
  const res = await api('POST', `/accounts/${created.body.id}/lines`, {
    token: mesero,
    body: { menuItemId: dish.body[0].id, qty: 21 },
  });
  assert.equal(res.status, 422);
  assert.equal(res.body.error.code, 'VALIDATION');
});

test('hostess no puede abrir cuentas (403) y mesero no puede asignar mesas (403)', async () => {
  const { api, loginAs } = srv;
  const hostess = await loginAs('emp_valeria', '7777');
  const mesero = await loginAs('emp_maria', '1111');

  const openAcc = await api('POST', '/accounts', { token: hostess, body: { serviceType: 'mesa', tableId: 'tbl_4', guests: 2 } });
  assert.equal(openAcc.status, 403);

  const assign = await api('POST', '/tables/tbl_4/assign', { token: mesero, body: { guests: 2 } });
  assert.equal(assign.status, 403);
});

test('peticiones sin token devuelven 401', async () => {
  const { api } = srv;
  const res = await api('GET', '/tables');
  assert.equal(res.status, 401);
});

test('no se puede sacar de servicio una mesa ocupada (409)', async () => {
  const { api, loginAs } = srv;
  const mesero = await loginAs('emp_maria', '1111');
  const gerente = await loginAs('emp_roberto', '5555');
  await api('POST', '/accounts', { token: mesero, body: { serviceType: 'mesa', tableId: 'tbl_5', guests: 2 } });
  const res = await api('POST', '/tables/tbl_5/out-of-service', { token: gerente });
  assert.equal(res.status, 409);
  assert.equal(res.body.error.code, 'CONFLICT');
});
