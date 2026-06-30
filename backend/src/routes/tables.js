import { Router } from 'express';
import * as store from '../store.js';
import { requireAuth, requireRole } from '../auth.js';

const router = Router();

router.get('/', requireAuth, (req, res) => {
  res.json(store.listTables());
});

router.post('/:id/assign', requireAuth, requireRole('hostess', 'gerente', 'admin'), (req, res, next) => {
  try {
    const { guests, waitlistId } = req.body ?? {};
    res.json(store.assignTable(req.params.id, { guests, waitlistId }));
  } catch (err) {
    next(err);
  }
});

router.post('/:id/out-of-service', requireAuth, requireRole('gerente', 'admin'), (req, res, next) => {
  try {
    res.json(store.outOfService(req.params.id));
  } catch (err) {
    next(err);
  }
});

router.post('/:id/restore', requireAuth, requireRole('gerente', 'admin'), (req, res, next) => {
  try {
    res.json(store.restoreTable(req.params.id));
  } catch (err) {
    next(err);
  }
});

export default router;
