import { Router } from 'express';
import * as store from '../store.js';
import { requireAuth, requireRole } from '../auth.js';

const router = Router();

router.get('/config', requireAuth, (req, res) => {
  res.json(store.getConfig());
});

router.get('/employees', requireAuth, requireRole('gerente', 'admin'), (req, res) => {
  res.json(store.listEmployees());
});

export default router;
