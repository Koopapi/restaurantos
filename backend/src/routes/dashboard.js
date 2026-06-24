import { Router } from 'express';
import * as admin from '../store/admin.js';
import { requireAuth, requireRole } from '../auth.js';

const router = Router();

// gerente (operativo) | admin
router.get('/', requireAuth, requireRole('gerente', 'admin'), (req, res, next) => {
  try {
    res.json(admin.dashboard(req.query.range ?? 'hoy'));
  } catch (err) {
    next(err);
  }
});

export default router;
