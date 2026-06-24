import { Router } from 'express';
import * as admin from '../store/admin.js';
import { requireAuth, requireRole } from '../auth.js';

const router = Router();
const manager = requireRole('gerente', 'admin');

router.get('/', requireAuth, manager, (req, res) => {
  res.json(admin.listCollections());
});

router.post('/', requireAuth, manager, (req, res, next) => {
  try {
    const { name, schedule, itemIds } = req.body ?? {};
    res.status(201).json(admin.createCollection({ name, schedule, itemIds }));
  } catch (err) {
    next(err);
  }
});

router.put('/:id', requireAuth, manager, (req, res, next) => {
  try {
    res.json(admin.updateCollection(req.params.id, req.body));
  } catch (err) {
    next(err);
  }
});

router.post('/:id/activate', requireAuth, manager, (req, res, next) => {
  try {
    res.json(admin.activateCollection(req.params.id));
  } catch (err) {
    next(err);
  }
});

export default router;
