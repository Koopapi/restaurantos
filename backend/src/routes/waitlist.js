import { Router } from 'express';
import * as store from '../store.js';
import { requireAuth, requireRole } from '../auth.js';

const router = Router();
const hostess = requireRole('hostess', 'gerente', 'admin');

router.get('/', requireAuth, hostess, (req, res) => {
  res.json(store.listWaitlist());
});

router.post('/', requireAuth, hostess, (req, res, next) => {
  try {
    const { name, size, phone } = req.body ?? {};
    res.status(201).json(store.addWaitlist({ name, size, phone }));
  } catch (err) {
    next(err);
  }
});

router.post('/:id/seat', requireAuth, hostess, (req, res, next) => {
  try {
    res.json(store.seatWaitlist(req.params.id, { tableId: req.body?.tableId }));
  } catch (err) {
    next(err);
  }
});

export default router;
