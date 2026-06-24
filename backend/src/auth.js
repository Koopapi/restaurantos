// PIN→JWT auth + role middleware. JWT (HS256) implemented on node:crypto to
// avoid extra deps; same Bearer contract a library would produce.
import crypto from 'node:crypto';
import { findEmployee, ApiError } from './store.js';

const SECRET = process.env.JWT_SECRET || 'dev-insecure-secret';
const TTL_SECONDS = 60 * 60 * 12; // 12h

const b64url = (buf) => Buffer.from(buf).toString('base64url');
const b64urlJson = (obj) => b64url(JSON.stringify(obj));

function sign(payload) {
  const header = b64urlJson({ alg: 'HS256', typ: 'JWT' });
  const now = Math.floor(Date.now() / 1000);
  const body = b64urlJson({ ...payload, iat: now, exp: now + TTL_SECONDS });
  const data = `${header}.${body}`;
  const sig = crypto.createHmac('sha256', SECRET).update(data).digest('base64url');
  return `${data}.${sig}`;
}

function verify(token) {
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  const [header, body, sig] = parts;
  const expected = crypto.createHmac('sha256', SECRET).update(`${header}.${body}`).digest('base64url');
  // constant-time compare
  const a = Buffer.from(sig);
  const b = Buffer.from(expected);
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) return null;
  let payload;
  try {
    payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
  } catch {
    return null;
  }
  if (payload.exp && payload.exp < Math.floor(Date.now() / 1000)) return null;
  return payload;
}

export function login({ employeeId, pin }) {
  const employee = findEmployee(employeeId);
  if (!employee || !employee.active || employee.pin !== String(pin ?? '')) {
    throw new ApiError(401, 'INVALID_PIN', 'PIN incorrecto');
  }
  const token = sign({ employeeId: employee.id, role: employee.role });
  const { pin: _omit, ...safe } = employee;
  return { token, employee: safe };
}

export function authPayloadFromToken(token) {
  return token ? verify(token) : null;
}

// Express middleware: require a valid Bearer token.
export function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  const payload = authPayloadFromToken(token);
  if (!payload) return next(new ApiError(401, 'UNAUTHORIZED', 'Token inválido o ausente'));
  const employee = findEmployee(payload.employeeId);
  if (!employee || !employee.active) return next(new ApiError(401, 'UNAUTHORIZED', 'Empleado inválido'));
  req.auth = { employeeId: payload.employeeId, role: payload.role };
  next();
}

// Express middleware factory: require one of the given roles.
export function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.auth) return next(new ApiError(401, 'UNAUTHORIZED', 'No autenticado'));
    if (!roles.includes(req.auth.role)) {
      return next(new ApiError(403, 'FORBIDDEN', 'Rol sin permiso para esta acción'));
    }
    next();
  };
}
