import { test, before, beforeEach, after } from 'node:test';
import assert from 'node:assert/strict';
import { seed } from '../src/store.js';
import { startTestServer } from './helpers.js';

let srv;
before(async () => { srv = await startTestServer(); });
after(() => srv.close());
beforeEach(() => seed());

test('flujo completo: abrir cuenta → enviar → ruteo cocina/barra → listo → entregar → cobrar libera mesa', async () => {
  const { api, loginAs } = srv;
  const mesero = await loginAs('emp_maria', '1111');

  // Abre cuenta de mesa → mesa pasa a ocupada
  const created = await api('POST', '/accounts', {
    token: mesero,
    body: { serviceType: 'mesa', tableId: 'tbl_1', guests: 2 },
  });
  assert.equal(created.status, 201);
  const accId = created.body.id;

  const tables = await api('GET', '/tables', { token: mesero });
  assert.equal(tables.body.find((t) => t.id === 'tbl_1').status, 'ocupada');

  // Agrega un platillo de cocina y una bebida de barra
  const dish = await api('GET', '/menu?category=Aguachiles', { token: mesero });
  const drink = await api('GET', '/menu?category=Bebidas', { token: mesero });
  await api('POST', `/accounts/${accId}/lines`, { token: mesero, body: { menuItemId: dish.body[0].id, qty: 2 } });
  const afterDrink = await api('POST', `/accounts/${accId}/lines`, { token: mesero, body: { menuItemId: drink.body[0].id, qty: 1 } });

  // Totales server-side: subtotal = Σ(qty×unitPrice), tax = subtotal×0.085
  const acc = afterDrink.body;
  const subtotal = acc.lines.reduce((s, l) => s + l.qty * l.unitPrice, 0);
  assert.equal(acc.subtotal, Math.round(subtotal * 100) / 100);
  assert.equal(acc.tax, Math.round(subtotal * 0.085 * 100) / 100);
  assert.equal(acc.total, Math.round((acc.subtotal + acc.tax) * 100) / 100);

  // Enviar → un ticket por estación
  const sent = await api('POST', `/accounts/${accId}/send`, { token: mesero });
  assert.equal(sent.status, 200);
  assert.equal(sent.body.tickets.length, 2);
  const stations = sent.body.tickets.map((t) => t.station).sort();
  assert.deepEqual(stations, ['barra', 'cocina']);
  const cocinaTicket = sent.body.tickets.find((t) => t.station === 'cocina');

  // Cocina avanza: pendiente → en_proceso → lista
  const cocina = await loginAs('emp_ana', '3333');
  let adv = await api('POST', `/tickets/${cocinaTicket.id}/advance`, { token: cocina });
  assert.equal(adv.body.status, 'en_proceso');
  adv = await api('POST', `/tickets/${cocinaTicket.id}/advance`, { token: cocina });
  assert.equal(adv.body.status, 'lista');

  // Mesero entrega
  const delivered = await api('POST', `/tickets/${cocinaTicket.id}/deliver`, { token: mesero });
  assert.equal(delivered.body.status, 'entregada');

  // Cobrar en efectivo → calcula cambio y libera la mesa
  const paid = await api('POST', `/accounts/${accId}/pay`, {
    token: mesero,
    body: { method: 'efectivo', amountReceived: acc.total + 100, tip: 0 },
  });
  assert.equal(paid.body.status, 'pagada');
  assert.equal(paid.body.payment.change, Math.round((acc.total + 100 - acc.total) * 100) / 100);

  const tablesAfter = await api('GET', '/tables', { token: mesero });
  assert.equal(tablesAfter.body.find((t) => t.id === 'tbl_1').status, 'disponible');
});

test('login inválido devuelve 401 con código INVALID_PIN', async () => {
  const { api } = srv;
  const res = await api('POST', '/auth/login', { body: { employeeId: 'emp_maria', pin: '0000' } });
  assert.equal(res.status, 401);
  assert.equal(res.body.error.code, 'INVALID_PIN');
});

test('waitlist sugiere la mesa libre más pequeña que alcanza y la sienta', async () => {
  const { api, loginAs } = srv;
  const hostess = await loginAs('emp_valeria', '7777');
  const added = await api('POST', '/waitlist', { token: hostess, body: { name: 'Pérez', size: 2 } });
  assert.equal(added.status, 201);
  assert.ok(added.body.suggestedTableId);

  const seated = await api('POST', `/waitlist/${added.body.id}/seat`, {
    token: hostess,
    body: { tableId: added.body.suggestedTableId },
  });
  assert.equal(seated.body.waitlist.status, 'sentado');
  assert.equal(seated.body.table.status, 'por_atender');
});
