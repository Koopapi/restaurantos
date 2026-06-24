import { Router } from 'express';
import * as store from '../store.js';
import * as admin from '../store/admin.js';
import { requireAuth, requireRole } from '../auth.js';

const router = Router();
const manager = requireRole('gerente', 'admin');

router.get('/', requireAuth, manager, (req, res) => {
  res.json(store.listEmployees());
});

router.post('/', requireAuth, manager, (req, res, next) => {
  try {
    const { name, role, pin, shift } = req.body ?? {};
    res.status(201).json(admin.createEmployee({ name, role, pin, shift }));
  } catch (err) {
    next(err);
  }
});

router.put('/:id', requireAuth, manager, (req, res, next) => {
  try {
    const { name, role, shift, active } = req.body ?? {};
    res.json(admin.updateEmployee(req.params.id, { name, role, shift, active }));
  } catch (err) {
    next(err);
  }
});

router.patch('/:id/pin', requireAuth, manager, (req, res, next) => {
  try {
    res.json(admin.setEmployeePin(req.params.id, req.body?.pin));
  } catch (err) {
    next(err);
  }
});

router.delete('/:id', requireAuth, manager, (req, res, next) => {
  try {
    res.json(admin.deleteEmployee(req.params.id, req.auth.employeeId));
  } catch (err) {
    next(err);
  }
});

export default router;
