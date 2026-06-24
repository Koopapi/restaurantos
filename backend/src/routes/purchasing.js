import { Router } from 'express';
import * as admin from '../store/admin.js';
import { requireAuth, requireRole } from '../auth.js';

const router = Router();
const manager = requireRole('gerente', 'admin');

router.get('/suggestions', requireAuth, manager, (req, res) => {
  res.json(admin.suggestPurchases());
});

router.get('/orders', requireAuth, manager, (req, res) => {
  res.json(admin.listPurchaseOrders());
});

router.post('/orders', requireAuth, manager, (req, res, next) => {
  try {
    res.status(201).json(admin.createPurchaseOrder({ items: req.body?.items }));
  } catch (err) {
    next(err);
  }
});

router.post('/orders/:id/approve', requireAuth, manager, (req, res, next) => {
  try {
    res.json(admin.approvePurchaseOrder(req.params.id));
  } catch (err) {
    next(err);
  }
});

router.post('/orders/:id/receive', requireAuth, manager, (req, res, next) => {
  try {
    res.json(admin.receivePurchaseOrder(req.params.id));
  } catch (err) {
    next(err);
  }
});

export default router;
