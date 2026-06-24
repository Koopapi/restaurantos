import { Router } from 'express';
import * as store from '../store.js';
import { requireAuth, requireRole } from '../auth.js';
import { ApiError } from '../store.js';

const router = Router();
const waiter = requireRole('mesero', 'gerente', 'admin');

router.post('/', requireAuth, waiter, (req, res, next) => {
  try {
    const { serviceType, tableId, guests, customerName, phone, address, tags, notes } = req.body ?? {};
    const account = store.createAccount({
      serviceType,
      tableId,
      guests,
      waiterId: req.auth.employeeId,
      customerName,
      phone,
      address,
      tags,
      notes,
    });
    res.status(201).json(account);
  } catch (err) {
    next(err);
  }
});

router.get('/', requireAuth, requireRole('mesero', 'gerente', 'admin'), (req, res) => {
  const { status, waiterId } = req.query;
  res.json(store.listAccounts({ status, waiterId }));
});

router.get('/:id', requireAuth, (req, res, next) => {
  const account = store.getAccount(req.params.id);
  if (!account) return next(new ApiError(404, 'NOT_FOUND', 'Cuenta no encontrada'));
  res.json(account);
});

router.post('/:id/lines', requireAuth, waiter, (req, res, next) => {
  try {
    const { menuItemId, qty, removedIngredients, addedModifiers, notes } = req.body ?? {};
    res.status(201).json(store.addLine(req.params.id, { menuItemId, qty, removedIngredients, addedModifiers, notes }));
  } catch (err) {
    next(err);
  }
});

router.patch('/:id/lines/:lineId', requireAuth, waiter, (req, res, next) => {
  try {
    res.json(store.updateLine(req.params.id, req.params.lineId, { qty: req.body?.qty }));
  } catch (err) {
    next(err);
  }
});

router.delete('/:id/lines/:lineId', requireAuth, waiter, (req, res, next) => {
  try {
    res.json(store.deleteLine(req.params.id, req.params.lineId));
  } catch (err) {
    next(err);
  }
});

router.post('/:id/send', requireAuth, waiter, (req, res, next) => {
  try {
    res.json(store.sendAccount(req.params.id));
  } catch (err) {
    next(err);
  }
});

router.post('/:id/pay', requireAuth, requireRole('mesero', 'gerente'), (req, res, next) => {
  try {
    const { method, amountReceived, tip } = req.body ?? {};
    res.json(store.payAccount(req.params.id, { method, amountReceived, tip }));
  } catch (err) {
    next(err);
  }
});

router.post('/:id/cancel', requireAuth, requireRole('gerente', 'admin'), (req, res, next) => {
  try {
    res.json(store.cancelAccount(req.params.id));
  } catch (err) {
    next(err);
  }
});

export default router;
