// In-memory store + demo seed + business-logic mutations.
// Mutations emit domain events on `events` (EventEmitter); realtime.js broadcasts them.
// Swappable for PostgreSQL later behind the same function contracts.
import { EventEmitter } from 'node:events';
import menuData from './menu-data.js';

export const events = new EventEmitter();

// ---------------------------------------------------------------------------
// Errors
// ---------------------------------------------------------------------------
export class ApiError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}
export const notFound = (what) => new ApiError(404, 'NOT_FOUND', `${what} no encontrado`);
export const conflict = (msg) => new ApiError(409, 'CONFLICT', msg);
export const invalid = (msg) => new ApiError(422, 'VALIDATION', msg);
export const forbidden = (msg) => new ApiError(403, 'FORBIDDEN', msg);

// ---------------------------------------------------------------------------
// State (shared with store/admin.js — exported so admin mutations reuse it)
// ---------------------------------------------------------------------------
export const db = {
  employees: [],
  tables: [],
  menu: [],
  accounts: [],
  tickets: [],
  waitlist: [],
  config: null,
  // administración (fase 2)
  menuCollections: [],
  inventory: [],
  purchaseOrders: [],
  shifts: [],
};

let seq = 0;
export const id = (prefix) => `${prefix}_${++seq}`;
export const now = () => new Date().toISOString();
export const round2 = (n) => Math.round(n * 100) / 100;

// ---------------------------------------------------------------------------
// Seed (El Pirrus demo)
// ---------------------------------------------------------------------------
export function seed(overrides = {}) {
  seq = 0;
  db.employees = [
    { id: 'emp_maria', name: 'María', role: 'mesero', pin: '1111', initials: 'MA', color: '#E8743B', shift: 'matutino', active: true },
    { id: 'emp_carlos', name: 'Carlos', role: 'mesero', pin: '2222', initials: 'CA', color: '#2E86AB', shift: 'vespertino', active: true },
    { id: 'emp_ana', name: 'Ana', role: 'cocina', pin: '3333', initials: 'AN', color: '#C0392B', shift: 'matutino', active: true },
    { id: 'emp_luis', name: 'Luis', role: 'barista', pin: '4444', initials: 'LU', color: '#16A085', shift: 'vespertino', active: true },
    { id: 'emp_roberto', name: 'Roberto', role: 'gerente', pin: '5555', initials: 'RO', color: '#8E44AD', shift: 'completo', active: true },
    { id: 'emp_sofia', name: 'Sofía', role: 'admin', pin: '6666', initials: 'SO', color: '#2C3E50', shift: 'completo', active: true },
    { id: 'emp_valeria', name: 'Valeria', role: 'hostess', pin: '7777', initials: 'VA', color: '#D81B60', shift: 'matutino', active: true },
  ];

  db.tables = [];
  const shapes = ['redonda', 'cuadrada', 'rectangular'];
  for (let n = 1; n <= 12; n++) {
    db.tables.push({
      id: `tbl_${n}`,
      number: n,
      capacity: n % 4 === 0 ? 6 : n % 2 === 0 ? 4 : 2,
      status: 'disponible',
      shape: shapes[n % shapes.length],
      party: null,
      waiterId: null,
      reserveName: null,
      reserveTime: null,
    });
  }

  // Catálogo real de El Pirrus (147 platillos) desde menu-data.js.
  db.menu = menuData.map((m) =>
    item(m.name, m.description, m.price, m.category, m.subcategory, m.station, m.ingredients, m.modifiers),
  );

  db.config = {
    brandName: 'El Pirrus',
    logoUrl: null,
    primaryColor: '#FF9800',
    taxLabel: process.env.TAX_LABEL || 'IVA',
    taxRate: Number(process.env.TAX_RATE ?? 0.085),
    urgencyMinutes: Number(process.env.URGENCY_MINUTES ?? 15),
    maxQtyPerLine: Number(process.env.MAX_QTY_PER_LINE ?? 20),
    currency: 'MXN',
    ...overrides.config,
  };

  db.accounts = [];
  db.tickets = [];
  db.waitlist = [];

  seedAdmin();
  return db;
}

// Demo data for the administration layer: menu collections, inventory (some
// below minimum), shifts for the current week, and paid accounts spread across
// recent days so reports/dashboard have numbers.
function seedAdmin() {
  db.menuCollections = [
    { id: id('col'), name: 'Menú Almuerzo', active: true, schedule: '12:00-17:00', itemIds: db.menu.slice(0, 5).map((m) => m.id) },
    { id: id('col'), name: 'Menú Cena', active: false, schedule: '18:00-23:00', itemIds: db.menu.map((m) => m.id) },
    { id: id('col'), name: 'Barra', active: false, schedule: null, itemIds: db.menu.filter((m) => m.station === 'barra').map((m) => m.id) },
  ];

  const inv = (name, category, unit, stock, minStock, cost, supplier, autoReorder = false) => ({
    id: id('inv'),
    name,
    category,
    unit,
    stock,
    minStock,
    status: stock < minStock ? 'bajo' : 'ok',
    autoReorder,
    supplier: supplier ?? null,
    cost,
    lastRestock: now(),
  });
  db.inventory = [
    inv('Camarón', 'Mariscos', 'kg', 8, 12, 220, 'Pesca del Pacífico', true),
    inv('Pescado blanco', 'Mariscos', 'kg', 15, 10, 160, 'Pesca del Pacífico'),
    inv('Pulpo', 'Mariscos', 'kg', 3, 6, 280, 'Pesca del Pacífico', true),
    inv('Limón', 'Frutas y verduras', 'kg', 4, 10, 28, 'Central de Abastos'),
    inv('Cebolla morada', 'Frutas y verduras', 'kg', 9, 8, 22, 'Central de Abastos'),
    inv('Aguacate', 'Frutas y verduras', 'kg', 5, 8, 75, 'Central de Abastos', true),
    inv('Cilantro', 'Frutas y verduras', 'manojo', 30, 20, 8, 'Central de Abastos'),
    inv('Chile serrano', 'Frutas y verduras', 'kg', 2, 5, 40, 'Central de Abastos'),
    inv('Tostadas', 'Abarrotes', 'paquete', 40, 15, 35, 'Distribuidora Sol'),
    inv('Cerveza clara', 'Bebidas', 'caja', 6, 10, 320, 'Cervecera Regional', true),
    inv('Tequila', 'Bebidas', 'botella', 12, 6, 380, 'Licores MX'),
    inv('Refresco', 'Bebidas', 'caja', 4, 8, 180, 'Distribuidora Sol'),
  ];

  // Turnos de la semana (lunes a domingo de la semana que contiene "hoy").
  db.shifts = [];
  const monday = startOfWeek(new Date());
  const waiters = ['emp_maria', 'emp_carlos', 'emp_ana', 'emp_luis', 'emp_valeria'];
  for (let d = 0; d < 5; d++) {
    const date = isoDate(addDays(monday, d));
    db.shifts.push({ id: id('shift'), employeeId: waiters[d % waiters.length], date, type: 'matutino', start: '08:00', end: '16:00' });
    db.shifts.push({ id: id('shift'), employeeId: waiters[(d + 1) % waiters.length], date, type: 'vespertino', start: '16:00', end: '23:00' });
  }

  // Cuentas pagadas demo (varios días, métodos y meseros).
  db.purchaseOrders = [];
  seedPaidAccounts();
}

function seedPaidAccounts() {
  const today = new Date();
  const samples = [
    { daysAgo: 0, waiterId: 'emp_maria', serviceType: 'mesa', items: [[0, 2], [5, 3]], method: 'tarjeta', tip: 50 },
    { daysAgo: 0, waiterId: 'emp_carlos', serviceType: 'llevar', items: [[2, 1], [7, 2]], method: 'efectivo', tip: 0 },
    { daysAgo: 1, waiterId: 'emp_maria', serviceType: 'mesa', items: [[1, 1], [6, 2]], method: 'tarjeta', tip: 40 },
    { daysAgo: 2, waiterId: 'emp_carlos', serviceType: 'domicilio', items: [[3, 2], [8, 1]], method: 'transferencia', tip: 30 },
    { daysAgo: 4, waiterId: 'emp_maria', serviceType: 'mesa', items: [[0, 1], [4, 1], [5, 2]], method: 'efectivo', tip: 20 },
    { daysAgo: 9, waiterId: 'emp_carlos', serviceType: 'mesa', items: [[2, 3]], method: 'tarjeta', tip: 60 },
    { daysAgo: 20, waiterId: 'emp_maria', serviceType: 'mesa', items: [[1, 2], [9, 1]], method: 'efectivo', tip: 0 },
  ];

  for (const s of samples) {
    const at = isoDateTime(addDays(today, -s.daysAgo));
    const lines = s.items.map(([idx, qty]) => {
      const mi = db.menu[idx];
      return { id: id('line'), menuItemId: mi.id, name: mi.name, qty, unitPrice: mi.price, removedIngredients: [], addedModifiers: [], notes: null, station: mi.station, sent: true };
    });
    const subtotal = round2(lines.reduce((sum, l) => sum + l.qty * l.unitPrice, 0));
    const tax = round2(subtotal * db.config.taxRate);
    const total = round2(subtotal + tax + s.tip);
    db.accounts.push({
      id: id('acc'),
      serviceType: s.serviceType,
      tableId: s.serviceType === 'mesa' ? 'tbl_1' : null,
      guests: s.serviceType === 'mesa' ? 2 : null,
      waiterId: s.waiterId,
      customerName: null,
      phone: null,
      address: null,
      tags: [],
      notes: null,
      lines,
      status: 'pagada',
      openedAt: at,
      paidAt: at,
      payment: { method: s.method, amountReceived: s.method === 'efectivo' ? total : null, tip: s.tip, total, change: 0 },
      subtotal,
      tax,
      total,
    });
  }
}

// --- date helpers (UTC) ---
function addDays(date, days) {
  const d = new Date(date);
  d.setUTCDate(d.getUTCDate() + days);
  return d;
}
function startOfWeek(date) {
  const d = new Date(date);
  const day = (d.getUTCDay() + 6) % 7; // lunes=0
  return addDays(d, -day);
}
const isoDate = (date) => new Date(date).toISOString().slice(0, 10);
const isoDateTime = (date) => new Date(date).toISOString();

function item(name, description, price, category, subcategory, station, ingredients, modifiers) {
  return {
    id: id('menu'),
    name,
    description,
    price,
    category,
    subcategory,
    station,
    ingredients,
    modifiers: modifiers.map((m) => ({ id: id('mod'), ...m })),
    available: true,
  };
}

// ---------------------------------------------------------------------------
// Read helpers
// ---------------------------------------------------------------------------
export const getConfig = () => db.config;
export const listEmployees = () => db.employees.map(({ pin, ...rest }) => rest);
export const findEmployee = (employeeId) => db.employees.find((e) => e.id === employeeId);

export const listTables = () => db.tables;
export const getTable = (tableId) => db.tables.find((t) => t.id === tableId);

export function listMenu({ category, subcategory, q } = {}) {
  let items = db.menu;
  if (category) items = items.filter((m) => m.category === category);
  if (subcategory) items = items.filter((m) => m.subcategory === subcategory);
  if (q) {
    const needle = q.toLowerCase();
    items = items.filter((m) => m.name.toLowerCase().includes(needle) || m.description.toLowerCase().includes(needle));
  }
  return items;
}
export const getMenuItem = (menuItemId) => db.menu.find((m) => m.id === menuItemId);

export function listAccounts({ status, waiterId } = {}) {
  let accts = db.accounts;
  if (status) accts = accts.filter((a) => a.status === status);
  if (waiterId) accts = accts.filter((a) => a.waiterId === waiterId);
  return accts;
}
export const getAccount = (accountId) => db.accounts.find((a) => a.id === accountId);

export function listTickets({ station, status } = {}) {
  let tks = db.tickets;
  if (station) tks = tks.filter((t) => t.station === station);
  if (status) tks = tks.filter((t) => t.status === status);
  return tks;
}
export const getTicket = (ticketId) => db.tickets.find((t) => t.id === ticketId);

export const listWaitlist = () => db.waitlist;

export const snapshot = () => ({ tables: db.tables, tickets: db.tickets, config: db.config });

// ---------------------------------------------------------------------------
// Tables
// ---------------------------------------------------------------------------
export function emit(type, data) {
  events.emit('broadcast', { type, data, at: now() });
}

export function assignTable(tableId, { guests, waitlistId }) {
  const table = getTable(tableId);
  if (!table) throw notFound('Mesa');
  if (table.status === 'fuera_servicio') throw conflict('Mesa fuera de servicio');
  if (table.status === 'ocupada') throw conflict('Mesa ya ocupada');
  if (!Number.isInteger(guests) || guests < 1) throw invalid('guests debe ser un entero ≥ 1');

  table.status = 'por_atender';
  table.party = guests;
  table.waiterId = null;

  if (waitlistId) {
    const entry = db.waitlist.find((w) => w.id === waitlistId);
    if (entry) {
      entry.status = 'sentado';
      entry.seatedAt = now();
      emit('waitlist:updated', db.waitlist);
    }
  }

  emit('table:updated', table);
  emit('table:needs_attention', table); // persistente: notifica a meseros
  return table;
}

export function outOfService(tableId) {
  const table = getTable(tableId);
  if (!table) throw notFound('Mesa');
  if (table.status === 'ocupada') throw conflict('No se puede sacar de servicio una mesa ocupada');
  table.status = 'fuera_servicio';
  table.party = null;
  table.waiterId = null;
  emit('table:updated', table);
  return table;
}

export function restoreTable(tableId) {
  const table = getTable(tableId);
  if (!table) throw notFound('Mesa');
  if (table.status !== 'fuera_servicio') throw conflict('La mesa no está fuera de servicio');
  table.status = 'disponible';
  emit('table:updated', table);
  return table;
}

// ---------------------------------------------------------------------------
// Accounts
// ---------------------------------------------------------------------------
function recalcTotals(account) {
  const subtotal = account.lines.reduce((sum, l) => sum + l.qty * l.unitPrice, 0);
  const tax = round2(subtotal * db.config.taxRate);
  account.subtotal = round2(subtotal);
  account.tax = tax;
  account.total = round2(account.subtotal + tax);
}

export function createAccount({ serviceType, tableId, guests, waiterId, customerName, phone, address, tags, notes }) {
  if (!['mesa', 'llevar', 'domicilio'].includes(serviceType)) throw invalid('serviceType inválido');
  if (serviceType === 'mesa') {
    const table = getTable(tableId);
    if (!table) throw notFound('Mesa');
    if (table.status === 'ocupada') throw conflict('Mesa ya ocupada');
    if (table.status === 'fuera_servicio') throw conflict('Mesa fuera de servicio');
  }

  const account = {
    id: id('acc'),
    serviceType,
    tableId: serviceType === 'mesa' ? tableId : null,
    guests: guests ?? null,
    waiterId,
    customerName: customerName ?? null,
    phone: phone ?? null,
    address: address ?? null,
    tags: tags ?? [],
    notes: notes ?? null,
    lines: [],
    status: 'abierta',
    openedAt: now(),
    paidAt: null,
    payment: null,
    subtotal: 0,
    tax: 0,
    total: 0,
  };
  db.accounts.push(account);

  if (serviceType === 'mesa') {
    const table = getTable(tableId);
    table.status = 'ocupada';
    table.waiterId = waiterId;
    if (guests) table.party = guests;
    emit('table:updated', table);
  }

  emit('account:updated', account);
  return account;
}

function assertOpen(account) {
  if (!account) throw notFound('Cuenta');
  if (account.status !== 'abierta') throw conflict('La cuenta no está abierta');
}

export function addLine(accountId, { menuItemId, qty, removedIngredients, addedModifiers, notes }) {
  const account = getAccount(accountId);
  assertOpen(account);
  const menuItem = getMenuItem(menuItemId);
  if (!menuItem) throw notFound('Platillo');
  if (!menuItem.available) throw conflict('Platillo no disponible');
  if (!Number.isInteger(qty) || qty < 1) throw invalid('qty debe ser un entero ≥ 1');
  if (qty > db.config.maxQtyPerLine) throw invalid(`qty excede el máximo (${db.config.maxQtyPerLine})`);

  const mods = (addedModifiers ?? []).map((m) => {
    const def = menuItem.modifiers.find((x) => x.id === m.id || x.name === m.name);
    if (!def) throw invalid(`Modificador inválido: ${m.id ?? m.name}`);
    return { id: def.id, name: def.name, price: def.price };
  });
  const unitPrice = round2(menuItem.price + mods.reduce((s, m) => s + m.price, 0));

  const line = {
    id: id('line'),
    menuItemId,
    name: menuItem.name,
    qty,
    unitPrice,
    removedIngredients: removedIngredients ?? [],
    addedModifiers: mods,
    notes: notes ?? null,
    station: menuItem.station,
    sent: false,
  };
  account.lines.push(line);
  recalcTotals(account);
  emit('account:updated', account);
  return account;
}

export function updateLine(accountId, lineId, { qty }) {
  const account = getAccount(accountId);
  assertOpen(account);
  const line = account.lines.find((l) => l.id === lineId);
  if (!line) throw notFound('Línea');
  if (line.sent) throw conflict('No se puede editar una línea ya enviada');
  if (!Number.isInteger(qty) || qty < 1) throw invalid('qty debe ser un entero ≥ 1');
  if (qty > db.config.maxQtyPerLine) throw invalid(`qty excede el máximo (${db.config.maxQtyPerLine})`);
  line.qty = qty;
  recalcTotals(account);
  emit('account:updated', account);
  return account;
}

export function deleteLine(accountId, lineId) {
  const account = getAccount(accountId);
  assertOpen(account);
  const line = account.lines.find((l) => l.id === lineId);
  if (!line) throw notFound('Línea');
  if (line.sent) throw conflict('No se puede eliminar una línea ya enviada');
  account.lines = account.lines.filter((l) => l.id !== lineId);
  recalcTotals(account);
  emit('account:updated', account);
  return account;
}

function tableLabel(account) {
  if (account.serviceType === 'mesa') {
    const table = getTable(account.tableId);
    return table ? `Mesa ${table.number}` : 'Mesa';
  }
  return account.serviceType === 'llevar' ? 'Para llevar' : 'Domicilio';
}

export function sendAccount(accountId) {
  const account = getAccount(accountId);
  assertOpen(account);
  const pending = account.lines.filter((l) => !l.sent);
  if (pending.length === 0) throw conflict('No hay líneas nuevas por enviar');

  const waiter = findEmployee(account.waiterId);
  const label = tableLabel(account);
  const byStation = new Map();
  for (const line of pending) {
    if (!byStation.has(line.station)) byStation.set(line.station, []);
    byStation.get(line.station).push(line);
  }

  const tickets = [];
  for (const [station, lines] of byStation) {
    const ticket = {
      id: id('tkt'),
      accountId: account.id,
      station, // ruteo: cocina | barra
      status: 'pendiente',
      lines: lines.map((l) => ({ name: l.name, qty: l.qty })),
      waiterName: waiter ? waiter.name : null,
      label,
      serviceType: account.serviceType,
      createdAt: now(),
      startedAt: null,
      readyAt: null,
      deliveredAt: null,
    };
    db.tickets.push(ticket);
    tickets.push(ticket);
    emit('ticket:created', ticket);
  }

  for (const line of pending) line.sent = true;
  emit('account:updated', account);
  return { account, tickets };
}

export function payAccount(accountId, { method, amountReceived, tip }) {
  const account = getAccount(accountId);
  assertOpen(account);
  if (!['efectivo', 'tarjeta', 'transferencia'].includes(method)) throw invalid('method inválido');
  const tipAmount = round2(tip ?? 0);
  if (tipAmount < 0) throw invalid('tip inválido');

  const total = round2(account.total + tipAmount);
  let change = null;
  if (method === 'efectivo') {
    if (amountReceived == null) throw invalid('amountReceived requerido para efectivo');
    if (amountReceived < total) throw invalid('amountReceived insuficiente');
    change = round2(amountReceived - total);
  }

  account.status = 'pagada';
  account.paidAt = now();
  account.payment = { method, amountReceived: amountReceived ?? null, tip: tipAmount, total, change };
  account.total = total;

  if (account.serviceType === 'mesa') {
    const table = getTable(account.tableId);
    if (table) {
      table.status = 'disponible';
      table.party = null;
      table.waiterId = null;
      emit('table:updated', table);
    }
  }

  emit('account:updated', account);
  return account;
}

export function cancelAccount(accountId) {
  const account = getAccount(accountId);
  if (!account) throw notFound('Cuenta');
  if (account.status === 'pagada') throw conflict('No se puede cancelar una cuenta pagada');
  account.status = 'cancelada';
  if (account.serviceType === 'mesa') {
    const table = getTable(account.tableId);
    if (table && table.status === 'ocupada') {
      table.status = 'disponible';
      table.party = null;
      table.waiterId = null;
      emit('table:updated', table);
    }
  }
  emit('account:updated', account);
  return account;
}

// ---------------------------------------------------------------------------
// Tickets (KDS)
// ---------------------------------------------------------------------------
export function advanceTicket(ticketId, role) {
  const ticket = getTicket(ticketId);
  if (!ticket) throw notFound('Ticket');
  // ruteo de permiso por estación
  if (role === 'cocina' && ticket.station !== 'cocina') throw new ApiError(403, 'FORBIDDEN', 'Cocina solo avanza tickets de cocina');
  if (role === 'barista' && ticket.station !== 'barra') throw new ApiError(403, 'FORBIDDEN', 'Barista solo avanza tickets de barra');

  if (ticket.status === 'pendiente') {
    ticket.status = 'en_proceso';
    ticket.startedAt = now();
  } else if (ticket.status === 'en_proceso') {
    ticket.status = 'lista';
    ticket.readyAt = now();
    emit('ticket:advanced', ticket);
    emit('dish:ready', { ticketId: ticket.id, tableLabel: ticket.label, station: ticket.station });
    return ticket;
  } else {
    throw conflict(`No se puede avanzar un ticket en estado ${ticket.status}`);
  }
  emit('ticket:advanced', ticket);
  return ticket;
}

export function deliverTicket(ticketId) {
  const ticket = getTicket(ticketId);
  if (!ticket) throw notFound('Ticket');
  if (ticket.status !== 'lista') throw conflict('Solo se entrega un ticket en estado "lista"');
  ticket.status = 'entregada';
  ticket.deliveredAt = now();
  emit('ticket:delivered', ticket);
  return ticket;
}

// ---------------------------------------------------------------------------
// Waitlist
// ---------------------------------------------------------------------------
export function addWaitlist({ name, size, phone }) {
  if (!name || typeof name !== 'string') throw invalid('name requerido');
  if (!Number.isInteger(size) || size < 1) throw invalid('size debe ser un entero ≥ 1');

  // sugiere la mesa libre más pequeña que alcanza
  const candidate = db.tables
    .filter((t) => t.status === 'disponible' && t.capacity >= size)
    .sort((a, b) => a.capacity - b.capacity)[0];

  const entry = {
    id: id('wl'),
    name,
    size,
    phone: phone ?? null,
    status: 'esperando',
    suggestedTableId: candidate ? candidate.id : null,
    createdAt: now(),
    seatedAt: null,
  };
  db.waitlist.push(entry);
  emit('waitlist:updated', db.waitlist);
  return entry;
}

export function seatWaitlist(waitlistId, { tableId }) {
  const entry = db.waitlist.find((w) => w.id === waitlistId);
  if (!entry) throw notFound('Entrada de lista de espera');
  if (entry.status === 'sentado') throw conflict('La entrada ya fue sentada');
  const table = assignTable(tableId, { guests: entry.size }); // emite table:updated + needs_attention
  entry.status = 'sentado';
  entry.seatedAt = now();
  emit('waitlist:updated', db.waitlist);
  return { waitlist: entry, table };
}
