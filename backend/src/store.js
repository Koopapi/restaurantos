// In-memory store + demo seed + business-logic mutations.
// Mutations emit domain events on `events` (EventEmitter); realtime.js broadcasts them.
// Swappable for PostgreSQL later behind the same function contracts.
import { EventEmitter } from 'node:events';

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
const notFound = (what) => new ApiError(404, 'NOT_FOUND', `${what} no encontrado`);
const conflict = (msg) => new ApiError(409, 'CONFLICT', msg);
const invalid = (msg) => new ApiError(422, 'VALIDATION', msg);

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
const db = {
  employees: [],
  tables: [],
  menu: [],
  accounts: [],
  tickets: [],
  waitlist: [],
  config: null,
};

let seq = 0;
const id = (prefix) => `${prefix}_${++seq}`;
const now = () => new Date().toISOString();

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

  db.menu = [
    item('Aguachile Verde', 'Camarón crudo en limón, chile serrano y pepino', 189, 'Aguachiles', 'Camarón', 'cocina', ['cebolla', 'pepino', 'cilantro'], [{ name: 'Extra camarón', price: 45 }, { name: 'Sin chile', price: 0 }]),
    item('Aguachile Negro', 'Camarón en salsa de chiles secos y soya', 199, 'Aguachiles', 'Camarón', 'cocina', ['cebolla morada', 'pepino'], [{ name: 'Extra camarón', price: 45 }]),
    item('Ceviche de Pescado', 'Pescado fresco, jitomate, cebolla y limón', 169, 'Ceviches', 'Pescado', 'cocina', ['jitomate', 'cebolla', 'cilantro', 'aguacate'], [{ name: 'Tostadas extra', price: 25 }]),
    item('Ceviche Mixto', 'Pescado, camarón y pulpo', 219, 'Ceviches', 'Mixto', 'cocina', ['jitomate', 'cebolla', 'aguacate'], []),
    item('Tostada de Atún', 'Atún sellado, aguacate y chipotle', 145, 'Tostadas', 'Atún', 'cocina', ['aguacate', 'ajonjolí'], [{ name: 'Extra aguacate', price: 20 }]),
    item('Cerveza Clara', 'Botella 355ml', 55, 'Bebidas', 'Cervezas', 'barra', [], [{ name: 'Michelada', price: 25 }]),
    item('Margarita', 'Tequila, limón y sal', 120, 'Bebidas', 'Cócteles', 'barra', ['sal'], [{ name: 'Doble', price: 60 }]),
    item('Agua de Horchata', 'Vaso 500ml', 45, 'Bebidas', 'Aguas frescas', 'barra', [], []),
    item('Refresco', 'Lata 355ml', 35, 'Bebidas', 'Refrescos', 'barra', [], []),
    item('Limonada', 'Natural o mineral', 45, 'Bebidas', 'Aguas frescas', 'barra', [], [{ name: 'Mineral', price: 10 }]),
  ];

  db.config = {
    brandName: 'El Pirrus',
    logoUrl: null,
    primaryColor: '#E8743B',
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
  return db;
}

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
function emit(type, data) {
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
const round2 = (n) => Math.round(n * 100) / 100;

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
