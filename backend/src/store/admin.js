// Administration-layer mutations + read models (menu CRUD/collections,
// employees, shifts, inventory, purchasing, reports, dashboard, config).
// Reuses the shared in-memory state and helpers from ../store.js.
import {
  db, id, now, emit, round2,
  notFound, conflict, invalid,
  getMenuItem, findEmployee, getConfig, listTables,
} from '../store.js';

const ROLES = ['mesero', 'cocina', 'barista', 'hostess', 'gerente', 'admin'];
const STATIONS = ['cocina', 'barra'];

// ---------------------------------------------------------------------------
// Menú — CRUD
// ---------------------------------------------------------------------------
function normalizeModifiers(modifiers) {
  return (modifiers ?? []).map((m) => {
    if (!m || typeof m.name !== 'string' || typeof m.price !== 'number') throw invalid('modifier inválido (name, price)');
    return { id: m.id || id('mod'), name: m.name, price: m.price };
  });
}

export function createMenuItem(data) {
  const { name, description, price, category, subcategory, station, ingredients, modifiers, available } = data ?? {};
  if (!name || typeof name !== 'string') throw invalid('name requerido');
  if (typeof price !== 'number' || price < 0) throw invalid('price debe ser un número ≥ 0');
  if (!STATIONS.includes(station)) throw invalid('station inválida (cocina|barra)');

  const item = {
    id: id('menu'),
    name,
    description: description ?? '',
    price,
    category: category ?? 'General',
    subcategory: subcategory ?? null,
    station,
    ingredients: ingredients ?? [],
    modifiers: normalizeModifiers(modifiers),
    available: available ?? true,
  };
  db.menu.push(item);
  emit('menu:updated', item);
  return item;
}

export function updateMenuItem(menuItemId, fields) {
  const item = getMenuItem(menuItemId);
  if (!item) throw notFound('Platillo');
  const f = fields ?? {};
  if (f.station !== undefined && !STATIONS.includes(f.station)) throw invalid('station inválida (cocina|barra)');
  if (f.price !== undefined && (typeof f.price !== 'number' || f.price < 0)) throw invalid('price debe ser un número ≥ 0');
  for (const key of ['name', 'description', 'price', 'category', 'subcategory', 'station', 'ingredients', 'available']) {
    if (f[key] !== undefined) item[key] = f[key];
  }
  if (f.modifiers !== undefined) item.modifiers = normalizeModifiers(f.modifiers);
  emit('menu:updated', item);
  return item;
}

export function setMenuAvailability(menuItemId, available) {
  const item = getMenuItem(menuItemId);
  if (!item) throw notFound('Platillo');
  if (typeof available !== 'boolean') throw invalid('available debe ser booleano');
  item.available = available;
  emit('menu:updated', item);
  return item;
}

export function deleteMenuItem(menuItemId) {
  const item = getMenuItem(menuItemId);
  if (!item) throw notFound('Platillo');
  db.menu = db.menu.filter((m) => m.id !== menuItemId);
  // limpia referencias en colecciones
  for (const col of db.menuCollections) col.itemIds = col.itemIds.filter((mid) => mid !== menuItemId);
  emit('menu:updated', { deletedId: menuItemId });
  return { ok: true };
}

// ---------------------------------------------------------------------------
// Menú — colecciones
// ---------------------------------------------------------------------------
export const listCollections = () => db.menuCollections;

function validateItemIds(itemIds) {
  if (!Array.isArray(itemIds)) throw invalid('itemIds debe ser un arreglo');
  for (const mid of itemIds) if (!getMenuItem(mid)) throw invalid(`itemId inexistente: ${mid}`);
  return itemIds;
}

export function createCollection({ name, schedule, itemIds }) {
  if (!name || typeof name !== 'string') throw invalid('name requerido');
  const collection = { id: id('col'), name, active: false, schedule: schedule ?? null, itemIds: validateItemIds(itemIds ?? []) };
  db.menuCollections.push(collection);
  emit('menu:updated', { collectionId: collection.id });
  return collection;
}

export function updateCollection(collectionId, fields) {
  const col = db.menuCollections.find((c) => c.id === collectionId);
  if (!col) throw notFound('Colección');
  const f = fields ?? {};
  if (f.name !== undefined) col.name = f.name;
  if (f.schedule !== undefined) col.schedule = f.schedule;
  if (f.itemIds !== undefined) col.itemIds = validateItemIds(f.itemIds);
  emit('menu:updated', { collectionId: col.id });
  return col;
}

export function activateCollection(collectionId) {
  const col = db.menuCollections.find((c) => c.id === collectionId);
  if (!col) throw notFound('Colección');
  for (const c of db.menuCollections) c.active = c.id === collectionId; // desactiva las demás
  emit('menu:updated', { collectionId: col.id });
  return col;
}

// ---------------------------------------------------------------------------
// Empleados
// ---------------------------------------------------------------------------
const safe = ({ pin, ...rest }) => rest;

function validatePin(pin) {
  if (!/^\d{4}$/.test(String(pin ?? ''))) throw invalid('pin debe ser de 4 dígitos');
  if (db.employees.some((e) => e.pin === String(pin))) throw conflict('PIN ya en uso');
}

function initialsFor(name) {
  return name.trim().slice(0, 2).toUpperCase();
}

export function createEmployee({ name, role, pin, shift }) {
  if (!name || typeof name !== 'string') throw invalid('name requerido');
  if (!ROLES.includes(role)) throw invalid('role inválido');
  validatePin(pin);
  const employee = {
    id: id('emp'),
    name,
    role,
    pin: String(pin),
    initials: initialsFor(name),
    color: '#607D8B',
    shift: shift ?? 'completo',
    active: true,
  };
  db.employees.push(employee);
  emit('employee:updated', safe(employee));
  return safe(employee);
}

export function updateEmployee(employeeId, { name, role, shift, active }) {
  const employee = findEmployee(employeeId);
  if (!employee) throw notFound('Empleado');
  if (role !== undefined && !ROLES.includes(role)) throw invalid('role inválido');
  if (name !== undefined) { employee.name = name; employee.initials = initialsFor(name); }
  if (role !== undefined) employee.role = role;
  if (shift !== undefined) employee.shift = shift;
  if (active !== undefined) employee.active = !!active;
  emit('employee:updated', safe(employee));
  return safe(employee);
}

export function setEmployeePin(employeeId, pin) {
  const employee = findEmployee(employeeId);
  if (!employee) throw notFound('Empleado');
  if (!/^\d{4}$/.test(String(pin ?? ''))) throw invalid('pin debe ser de 4 dígitos');
  if (db.employees.some((e) => e.pin === String(pin) && e.id !== employeeId)) throw conflict('PIN ya en uso');
  employee.pin = String(pin);
  return { ok: true };
}

export function deleteEmployee(employeeId, requesterId) {
  const employee = findEmployee(employeeId);
  if (!employee) throw notFound('Empleado');
  if (employeeId === requesterId) throw conflict('No puedes darte de baja a ti mismo');
  employee.active = false; // soft-delete
  emit('employee:updated', safe(employee));
  return { ok: true };
}

// ---------------------------------------------------------------------------
// Turnos
// ---------------------------------------------------------------------------
const TYPES = ['matutino', 'vespertino', 'completo'];

export function listShifts({ week } = {}) {
  if (!week) return db.shifts;
  const monday = startOfWeek(week);
  const sunday = addDays(monday, 7);
  return db.shifts.filter((s) => {
    const d = new Date(`${s.date}T00:00:00Z`);
    return d >= monday && d < sunday;
  });
}

export function createShift({ employeeId, date, type, start, end }) {
  if (!findEmployee(employeeId)) throw invalid('employeeId inexistente');
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date ?? '')) throw invalid('date debe ser YYYY-MM-DD');
  if (!TYPES.includes(type)) throw invalid('type inválido');
  const shift = { id: id('shift'), employeeId, date, type, start: start ?? null, end: end ?? null };
  db.shifts.push(shift);
  return shift;
}

export function updateShift(shiftId, fields) {
  const shift = db.shifts.find((s) => s.id === shiftId);
  if (!shift) throw notFound('Turno');
  const f = fields ?? {};
  if (f.type !== undefined && !TYPES.includes(f.type)) throw invalid('type inválido');
  if (f.employeeId !== undefined && !findEmployee(f.employeeId)) throw invalid('employeeId inexistente');
  for (const key of ['employeeId', 'date', 'type', 'start', 'end']) if (f[key] !== undefined) shift[key] = f[key];
  return shift;
}

export function deleteShift(shiftId) {
  const exists = db.shifts.some((s) => s.id === shiftId);
  if (!exists) throw notFound('Turno');
  db.shifts = db.shifts.filter((s) => s.id !== shiftId);
  return { ok: true };
}

// ---------------------------------------------------------------------------
// Inventario
// ---------------------------------------------------------------------------
const recomputeStatus = (it) => { it.status = it.stock < it.minStock ? 'bajo' : 'ok'; return it; };

export function listInventory({ q, status } = {}) {
  let items = db.inventory;
  if (status) items = items.filter((i) => i.status === status);
  if (q) {
    const needle = q.toLowerCase();
    items = items.filter((i) => i.name.toLowerCase().includes(needle) || i.category.toLowerCase().includes(needle));
  }
  return items;
}

export function createInventoryItem({ name, category, unit, stock, minStock, cost, supplier }) {
  if (!name || typeof name !== 'string') throw invalid('name requerido');
  if (typeof stock !== 'number' || stock < 0) throw invalid('stock debe ser ≥ 0');
  if (typeof minStock !== 'number' || minStock < 0) throw invalid('minStock debe ser ≥ 0');
  const item = recomputeStatus({
    id: id('inv'),
    name,
    category: category ?? 'General',
    unit: unit ?? 'pieza',
    stock,
    minStock,
    status: 'ok',
    autoReorder: false,
    supplier: supplier ?? null,
    cost: cost ?? 0,
    lastRestock: now(),
  });
  db.inventory.push(item);
  emit('inventory:updated', item);
  return item;
}

export function updateInventoryItem(itemId, fields) {
  const item = db.inventory.find((i) => i.id === itemId);
  if (!item) throw notFound('Insumo');
  const f = fields ?? {};
  for (const key of ['name', 'category', 'unit', 'stock', 'minStock', 'cost', 'supplier']) if (f[key] !== undefined) item[key] = f[key];
  recomputeStatus(item);
  emit('inventory:updated', item);
  return item;
}

export function setAutoReorder(itemId, autoReorder) {
  const item = db.inventory.find((i) => i.id === itemId);
  if (!item) throw notFound('Insumo');
  if (typeof autoReorder !== 'boolean') throw invalid('autoReorder debe ser booleano');
  item.autoReorder = autoReorder;
  emit('inventory:updated', item);
  return item;
}

export const inventoryAlerts = () => db.inventory.filter((i) => i.status === 'bajo');

// ---------------------------------------------------------------------------
// Compras ("IA" = heurística determinista; aislada para sustituir por modelo)
// ---------------------------------------------------------------------------
export function suggestPurchases() {
  const low = db.inventory.filter((i) => i.stock < i.minStock);
  const items = low.map((i) => {
    const suggestedQty = Math.max(1, i.minStock * 2 - i.stock); // reabastecer al doble del mínimo
    const deficitRatio = (i.minStock - i.stock) / Math.max(1, i.minStock);
    const urgency = deficitRatio >= 0.6 ? 'alta' : deficitRatio >= 0.3 ? 'media' : 'baja';
    return {
      inventoryItemId: i.id,
      name: i.name,
      supplier: i.supplier,
      suggestedQty,
      estCost: round2(suggestedQty * i.cost),
      urgency,
    };
  }).sort((a, b) => b.estCost - a.estCost);
  const totalEst = round2(items.reduce((s, x) => s + x.estCost, 0));
  return { items, totalEst };
}

export function createPurchaseOrder({ items }) {
  if (!Array.isArray(items) || items.length === 0) throw invalid('items requerido');
  const lines = items.map(({ inventoryItemId, qty }) => {
    const inv = db.inventory.find((i) => i.id === inventoryItemId);
    if (!inv) throw invalid(`insumo inexistente: ${inventoryItemId}`);
    if (typeof qty !== 'number' || qty <= 0) throw invalid('qty debe ser > 0');
    return { inventoryItemId, name: inv.name, qty, estCost: round2(qty * inv.cost) };
  });
  const order = {
    id: id('po'),
    status: 'sugerida',
    items: lines,
    total: round2(lines.reduce((s, l) => s + l.estCost, 0)),
    createdAt: now(),
    approvedAt: null,
  };
  db.purchaseOrders.push(order);
  return order;
}

export const listPurchaseOrders = () => db.purchaseOrders;

export function approvePurchaseOrder(orderId) {
  const order = db.purchaseOrders.find((o) => o.id === orderId);
  if (!order) throw notFound('Orden de compra');
  if (order.status !== 'sugerida') throw conflict(`No se puede aprobar una orden ${order.status}`);
  order.status = 'aprobada';
  order.approvedAt = now();
  return order;
}

export function receivePurchaseOrder(orderId) {
  const order = db.purchaseOrders.find((o) => o.id === orderId);
  if (!order) throw notFound('Orden de compra');
  if (order.status !== 'aprobada') throw conflict('Solo se recibe una orden aprobada');
  order.status = 'recibida';
  for (const line of order.items) {
    const inv = db.inventory.find((i) => i.id === line.inventoryItemId);
    if (inv) {
      inv.stock = round2(inv.stock + line.qty); // suma stock
      inv.lastRestock = now();
      recomputeStatus(inv);
      emit('inventory:updated', inv);
    }
  }
  return order;
}

// ---------------------------------------------------------------------------
// Reportes / Dashboard — agregan de cuentas pagadas (limitado en piloto)
// ---------------------------------------------------------------------------
const SALES_RANGES = { hoy: 0, semana: 7, mes: 30, trimestre: 90 };
const DASH_RANGES = { hoy: 0, '7d': 7, '30d': 30 };

function cutoffFor(range, table) {
  const days = table[range];
  if (days === undefined) throw invalid('range inválido');
  if (days === 0) { const d = new Date(); d.setUTCHours(0, 0, 0, 0); return d; }
  return addDays(new Date(), -days);
}

function paidIn(cutoff) {
  return db.accounts.filter((a) => a.status === 'pagada' && a.paidAt && new Date(a.paidAt) >= cutoff);
}

function aggregate(accounts) {
  const totalSales = round2(accounts.reduce((s, a) => s + a.total, 0));
  const tips = round2(accounts.reduce((s, a) => s + (a.payment?.tip ?? 0), 0));
  const tickets = accounts.length;
  const avgTicket = tickets ? round2(totalSales / tickets) : 0;
  return { totalSales, tips, tickets, avgTicket };
}

function groupByDay(accounts) {
  const map = new Map();
  for (const a of accounts) {
    const day = a.paidAt.slice(0, 10);
    map.set(day, round2((map.get(day) ?? 0) + a.total));
  }
  return [...map.entries()].sort(([a], [b]) => a.localeCompare(b)).map(([day, total]) => ({ day, total }));
}

function topProducts(accounts, limit = 10) {
  const map = new Map();
  for (const a of accounts) {
    for (const l of a.lines) {
      const cur = map.get(l.name) ?? { name: l.name, qty: 0, revenue: 0 };
      cur.qty += l.qty;
      cur.revenue = round2(cur.revenue + l.qty * l.unitPrice);
      map.set(l.name, cur);
    }
  }
  return [...map.values()].sort((a, b) => b.qty - a.qty).slice(0, limit);
}

export function salesReport(range = 'hoy') {
  const accounts = paidIn(cutoffFor(range, SALES_RANGES));
  const byMethod = new Map();
  for (const a of accounts) {
    const m = a.payment?.method ?? 'desconocido';
    const cur = byMethod.get(m) ?? { method: m, amount: 0, count: 0 };
    cur.amount = round2(cur.amount + a.total);
    cur.count += 1;
    byMethod.set(m, cur);
  }
  return {
    range,
    ...aggregate(accounts),
    byDay: groupByDay(accounts),
    byPaymentMethod: [...byMethod.values()],
  };
}

export function productsReport(range = 'hoy') {
  return { range, topItems: topProducts(paidIn(cutoffFor(range, SALES_RANGES))) };
}

export function employeesReport(range = 'hoy') {
  const accounts = paidIn(cutoffFor(range, SALES_RANGES));
  const map = new Map();
  for (const a of accounts) {
    const cur = map.get(a.waiterId) ?? { employeeId: a.waiterId, name: findEmployee(a.waiterId)?.name ?? '—', sales: 0, tickets: 0 };
    cur.sales = round2(cur.sales + a.total);
    cur.tickets += 1;
    map.set(a.waiterId, cur);
  }
  return { range, byEmployee: [...map.values()].sort((a, b) => b.sales - a.sales) };
}

export function inventoryReport() {
  const value = round2(db.inventory.reduce((s, i) => s + i.stock * i.cost, 0));
  return {
    value,
    lowStock: db.inventory.filter((i) => i.status === 'bajo').length,
    items: db.inventory,
  };
}

export function dashboard(range = 'hoy') {
  const accounts = paidIn(cutoffFor(range, DASH_RANGES));
  const agg = aggregate(accounts);

  const byTypeMap = new Map();
  for (const a of accounts) {
    byTypeMap.set(a.serviceType, round2((byTypeMap.get(a.serviceType) ?? 0) + a.total));
  }

  const tables = listTables();
  const config = getConfig();
  const activeAccounts = db.accounts.filter((a) => a.status === 'abierta');
  const openTickets = db.tickets.filter((t) => t.status !== 'entregada');

  return {
    sales: agg.totalSales,
    tickets: agg.tickets,
    avgTicket: agg.avgTicket,
    tips: agg.tips,
    trend: groupByDay(accounts).map(({ day, total }) => ({ label: day, value: total })),
    byServiceType: [...byTypeMap.entries()].map(([type, amount]) => ({ type, amount })),
    topDishes: topProducts(accounts, 5).map(({ name, qty }) => ({ name, qty })),
    live: {
      tablesOccupied: tables.filter((t) => t.status === 'ocupada').length,
      tablesTotal: tables.length,
      activeAccounts: activeAccounts.length,
      kitchenTickets: openTickets.filter((t) => t.station === 'cocina').length,
      barTickets: openTickets.filter((t) => t.station === 'barra').length,
      currency: config.currency,
    },
  };
}

// ---------------------------------------------------------------------------
// Config / Marca Blanca
// ---------------------------------------------------------------------------
export function updateConfig(fields) {
  const f = fields ?? {};
  const config = getConfig();
  if (f.taxRate !== undefined && (typeof f.taxRate !== 'number' || f.taxRate < 0 || f.taxRate > 1)) throw invalid('taxRate debe estar entre 0 y 1');
  if (f.urgencyMinutes !== undefined && (!Number.isInteger(f.urgencyMinutes) || f.urgencyMinutes < 1)) throw invalid('urgencyMinutes debe ser un entero ≥ 1');
  if (f.maxQtyPerLine !== undefined && (!Number.isInteger(f.maxQtyPerLine) || f.maxQtyPerLine < 1)) throw invalid('maxQtyPerLine debe ser un entero ≥ 1');
  for (const key of ['brandName', 'logoUrl', 'primaryColor', 'taxLabel', 'taxRate', 'urgencyMinutes', 'maxQtyPerLine', 'currency']) {
    if (f[key] !== undefined) config[key] = f[key];
  }
  emit('config:updated', config);
  return config;
}

// --- date helpers (UTC) ---
function addDays(date, days) { const d = new Date(date); d.setUTCDate(d.getUTCDate() + days); return d; }
function startOfWeek(dateStr) {
  const d = new Date(`${dateStr}T00:00:00Z`);
  const day = (d.getUTCDay() + 6) % 7; // lunes = 0
  return addDays(d, -day);
}
