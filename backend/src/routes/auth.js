import { Router } from 'express';
import { login, requireAuth } from '../auth.js';
import { findEmployee } from '../store.js';

const router = Router();

router.post('/login', (req, res, next) => {
  try {
    const { employeeId, pin } = req.body ?? {};
    res.json(login({ employeeId, pin }));
  } catch (err) {
    next(err);
  }
});

router.get('/me', requireAuth, (req, res) => {
  const { pin, ...employee } = findEmployee(req.auth.employeeId);
  res.json({ employee });
});

router.post('/logout', requireAuth, (req, res) => {
  // Tokens son stateless; el cliente descarta el suyo. Endpoint por simetría.
  res.json({ ok: true });
});

export default router;
