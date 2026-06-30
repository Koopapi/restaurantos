import { Router } from 'express';
import * as store from '../store.js';
import { requireAuth, requireRole } from '../auth.js';

const router = Router();

router.get('/', requireAuth, (req, res) => {
  const { station, status } = req.query;
  res.json(store.listTickets({ station, status }));
});

// cocina/barista avanzan su estación; gerente|admin pueden avanzar cualquiera.
router.post('/:id/advance', requireAuth, requireRole('cocina', 'barista', 'gerente', 'admin'), (req, res, next) => {
  try {
    res.json(store.advanceTicket(req.params.id, req.auth.role));
  } catch (err) {
    next(err);
  }
});

// El mesero NO avanza; solo entrega cuando está "lista".
router.post('/:id/deliver', requireAuth, requireRole('mesero', 'gerente', 'admin'), (req, res, next) => {
  try {
    res.json(store.deliverTicket(req.params.id));
  } catch (err) {
    next(err);
  }
});

export default router;
