import { Router } from 'express';
import * as admin from '../store/admin.js';
import { requireAuth, requireRole } from '../auth.js';

const router = Router();
const manager = requireRole('gerente', 'admin');

// Serializa un arreglo de objetos planos a CSV.
function toCsv(rows) {
  if (!rows.length) return '';
  const headers = Object.keys(rows[0]);
  const escape = (v) => {
    const s = v == null ? '' : String(v);
    return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  };
  return [headers.join(','), ...rows.map((r) => headers.map((h) => escape(r[h])).join(','))].join('\n');
}

// Si ?format=csv, devuelve las filas indicadas como text/csv; si no, el JSON completo.
function respond(res, format, payload, csvRows) {
  if (format === 'csv') {
    res.type('text/csv').send(toCsv(csvRows));
  } else {
    res.json(payload);
  }
}

router.get('/sales', requireAuth, manager, (req, res, next) => {
  try {
    const report = admin.salesReport(req.query.range ?? 'hoy');
    respond(res, req.query.format, report, report.byDay);
  } catch (err) {
    next(err);
  }
});

router.get('/products', requireAuth, manager, (req, res, next) => {
  try {
    const report = admin.productsReport(req.query.range ?? 'hoy');
    respond(res, req.query.format, report, report.topItems);
  } catch (err) {
    next(err);
  }
});

router.get('/employees', requireAuth, manager, (req, res, next) => {
  try {
    const report = admin.employeesReport(req.query.range ?? 'hoy');
    respond(res, req.query.format, report, report.byEmployee);
  } catch (err) {
    next(err);
  }
});

router.get('/inventory', requireAuth, manager, (req, res, next) => {
  try {
    const report = admin.inventoryReport();
    respond(res, req.query.format, report, report.items);
  } catch (err) {
    next(err);
  }
});

export default router;
