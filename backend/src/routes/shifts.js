import { Router } from 'express';
import * as admin from '../store/admin.js';
import { requireAuth, requireRole } from '../auth.js';

const router = Router();
const manager = requireRole('gerente', 'admin');

router.get('/', requireAuth, manager, (req, res) => {
  res.json(admin.listShifts({ week: req.query.week }));
});

router.post('/', requireAuth, manager, (req, res, next) => {
  try {
    const { employeeId, date, type, start, end } = req.body ?? {};
    res.status(201).json(admin.createShift({ employeeId, date, type, start, end }));
  } catch (err) {
    next(err);
  }
});

router.put('/:id', requireAuth, manager, (req, res, next) => {
  try {
    res.json(admin.updateShift(req.params.id, req.body));
  } catch (err) {
    next(err);
  }
});

router.delete('/:id', requireAuth, manager, (req, res, next) => {
  try {
    res.json(admin.deleteShift(req.params.id));
  } catch (err) {
    next(err);
  }
});

export default router;
