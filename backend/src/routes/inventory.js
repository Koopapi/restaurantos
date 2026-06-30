import { Router } from 'express';
import * as admin from '../store/admin.js';
import { requireAuth, requireRole } from '../auth.js';

const router = Router();
const manager = requireRole('gerente', 'admin');

router.get('/', requireAuth, manager, (req, res) => {
  const { q, status } = req.query;
  res.json(admin.listInventory({ q, status }));
});

router.get('/alerts', requireAuth, manager, (req, res) => {
  res.json(admin.inventoryAlerts());
});

router.post('/', requireAuth, manager, (req, res, next) => {
  try {
    const { name, category, unit, stock, minStock, cost, supplier } = req.body ?? {};
    res.status(201).json(admin.createInventoryItem({ name, category, unit, stock, minStock, cost, supplier }));
  } catch (err) {
    next(err);
  }
});

router.put('/:id', requireAuth, manager, (req, res, next) => {
  try {
    res.json(admin.updateInventoryItem(req.params.id, req.body));
  } catch (err) {
    next(err);
  }
});

router.patch('/:id/auto-reorder', requireAuth, manager, (req, res, next) => {
  try {
    res.json(admin.setAutoReorder(req.params.id, req.body?.autoReorder));
  } catch (err) {
    next(err);
  }
});

export default router;
