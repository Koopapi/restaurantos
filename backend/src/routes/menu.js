import { Router } from 'express';
import * as store from '../store.js';
import * as admin from '../store/admin.js';
import { requireAuth, requireRole } from '../auth.js';
import { ApiError } from '../store.js';

const router = Router();
const manager = requireRole('gerente', 'admin');

router.get('/', requireAuth, (req, res) => {
  const { category, subcategory, q } = req.query;
  res.json(store.listMenu({ category, subcategory, q }));
});

router.get('/:id', requireAuth, (req, res, next) => {
  const item = store.getMenuItem(req.params.id);
  if (!item) return next(new ApiError(404, 'NOT_FOUND', 'Platillo no encontrado'));
  res.json(item);
});

// --- CRUD (gerente|admin) ---
router.post('/', requireAuth, manager, (req, res, next) => {
  try {
    res.status(201).json(admin.createMenuItem(req.body));
  } catch (err) {
    next(err);
  }
});

router.put('/:id', requireAuth, manager, (req, res, next) => {
  try {
    res.json(admin.updateMenuItem(req.params.id, req.body));
  } catch (err) {
    next(err);
  }
});

router.patch('/:id/availability', requireAuth, manager, (req, res, next) => {
  try {
    res.json(admin.setMenuAvailability(req.params.id, req.body?.available));
  } catch (err) {
    next(err);
  }
});

router.delete('/:id', requireAuth, manager, (req, res, next) => {
  try {
    res.json(admin.deleteMenuItem(req.params.id));
  } catch (err) {
    next(err);
  }
});

export default router;
