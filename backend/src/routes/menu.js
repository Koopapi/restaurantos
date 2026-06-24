import { Router } from 'express';
import * as store from '../store.js';
import { requireAuth } from '../auth.js';
import { ApiError } from '../store.js';

const router = Router();

router.get('/', requireAuth, (req, res) => {
  const { category, subcategory, q } = req.query;
  res.json(store.listMenu({ category, subcategory, q }));
});

router.get('/:id', requireAuth, (req, res, next) => {
  const item = store.getMenuItem(req.params.id);
  if (!item) return next(new ApiError(404, 'NOT_FOUND', 'Platillo no encontrado'));
  res.json(item);
});

// CRUD (POST/PUT/DELETE) → fase administración (gerente|admin). Pendiente.

export default router;
