import { Router } from 'express';
import * as store from '../store.js';
import * as admin from '../store/admin.js';
import { requireAuth, requireRole } from '../auth.js';

const router = Router();

router.get('/config', requireAuth, (req, res) => {
  res.json(store.getConfig());
});

// Marca blanca + reglas de negocio (solo admin).
router.put('/config', requireAuth, requireRole('admin'), (req, res, next) => {
  try {
    res.json(admin.updateConfig(req.body));
  } catch (err) {
    next(err);
  }
});

export default router;
