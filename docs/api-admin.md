# Contrato de API — Administración (backend, fase 2)

Extiende `docs/api.md` (ciclo de servicio). Mismas convenciones: base `/api`, JWT `Authorization: Bearer`, errores `{ error: { code, message } }`, IDs server-side. Casi todo aquí requiere rol **gerente** o **admin** (ver matriz al final).

## Entidades nuevas

```
MenuCollection { id, name, active, schedule?, itemIds[] }      // "Menú Almuerzo", etc.

InventoryItem  { id, name, category, unit, stock, minStock,
                 status, autoReorder, supplier?, cost, lastRestock }
                 status ∈ ok | bajo            // derivado: stock < minStock ⇒ bajo

PurchaseOrder  { id, status, items[ {inventoryItemId, name, qty, estCost} ],
                 total, createdAt, approvedAt? }
                 status ∈ sugerida | aprobada | recibida

Shift          { id, employeeId, date, type, start, end }
                 type ∈ matutino | vespertino | completo
```

`Config` (de `docs/api.md`) se vuelve **escribible** por admin (marca blanca + reglas de negocio).

## Menú (CRUD + colecciones)

```
POST   /api/menu                 { name, description, price, category, subcategory,
                                   station, ingredients[], modifiers[], available } → MenuItem
PUT    /api/menu/:id             { ...campos }                                       → MenuItem
PATCH  /api/menu/:id/availability { available }                                      → MenuItem
DELETE /api/menu/:id                                                                  → { ok }

GET    /api/menu-collections                                   → MenuCollection[]
POST   /api/menu-collections     { name, schedule?, itemIds[] } → MenuCollection
PUT    /api/menu-collections/:id { ...campos }                  → MenuCollection
POST   /api/menu-collections/:id/activate                       → MenuCollection   // desactiva las demás
```

Emite `menu:updated`.

## Empleados

```
GET    /api/employees                                   → Employee[] (sin pin)
POST   /api/employees   { name, role, pin, shift }      → Employee
PUT    /api/employees/:id { name, role, shift, active } → Employee
PATCH  /api/employees/:id/pin    { pin }                → { ok }
DELETE /api/employees/:id                               → { ok }   // o soft-delete: active=false
```

Validar: `pin` 4 dígitos único; no permitir borrarse a sí mismo; `role` válido. Emite `employee:updated`.

## Turnos

```
GET    /api/shifts?week=YYYY-MM-DD            → Shift[]   (semana que contiene esa fecha)
POST   /api/shifts   { employeeId, date, type, start, end } → Shift
PUT    /api/shifts/:id { ...campos }          → Shift
DELETE /api/shifts/:id                        → { ok }
```

## Inventario

```
GET    /api/inventory?q=&status=               → InventoryItem[]
POST   /api/inventory  { name, category, unit, stock, minStock, cost, supplier? } → InventoryItem
PUT    /api/inventory/:id { ...campos }         → InventoryItem
PATCH  /api/inventory/:id/auto-reorder { autoReorder } → InventoryItem
GET    /api/inventory/alerts                    → InventoryItem[]   // status=bajo
```

Emite `inventory:updated`.

## Compras (sugerencias “IA” + órdenes)

```
GET    /api/purchasing/suggestions   → { items: [ {inventoryItemId, name, supplier, suggestedQty, estCost, urgency} ], totalEst }
        // deriva de inventario bajo mínimo; suggestedQty = minStock*2 - stock (heurística); urgency por déficit
POST   /api/purchasing/orders  { items: [ {inventoryItemId, qty} ] } → PurchaseOrder  (status=sugerida)
POST   /api/purchasing/orders/:id/approve                            → PurchaseOrder  (status=aprobada)
POST   /api/purchasing/orders/:id/receive                            → PurchaseOrder  (status=recibida; suma stock)
```

> "IA" en esta fase = heurística determinista sobre mínimos/consumo. Dejar la función aislada (`suggestPurchases()`) para sustituir por un modelo después.

## Reportes

```
GET /api/reports/sales?range=hoy|semana|mes|trimestre      → { range, totalSales, tickets, avgTicket, tips, byDay[], byPaymentMethod[] }
GET /api/reports/products?range=                            → { topItems: [ {name, qty, revenue} ] }
GET /api/reports/employees?range=                           → { byEmployee: [ {employeeId, name, sales, tickets} ] }
GET /api/reports/inventory                                  → { value, lowStock, items[] }
# Exportación: aceptar ?format=csv → devuelve text/csv; por defecto JSON.
```

## Dashboard

```
GET /api/dashboard?range=hoy|7d|30d → {
  sales, tickets, avgTicket, tips,
  trend: [ {label, value} ],            // ventas por día (para la gráfica)
  byServiceType: [ {type, amount} ],
  topDishes: [ {name, qty} ],
  live: { tablesOccupied, tablesTotal, activeAccounts, kitchenTickets, barTickets }
}
```

`live` puede reusar el estado actual del store; el resto se agrega de cuentas pagadas en el rango. (En piloto con store en memoria, los reportes históricos pueden ser limitados; documentarlo.)

## Config / Marca Blanca

```
GET /api/config                  → Config   (público; ya existe)
PUT /api/config { brandName?, logoUrl?, primaryColor?, taxLabel?, taxRate?,
                  urgencyMinutes?, maxQtyPerLine?, currency? } → Config   (admin)
        → emite config:updated (los clientes re-aplican tema/reglas)
```

## Eventos WebSocket nuevos

| Evento | Cuándo | data |
|--------|--------|------|
| `menu:updated` | alta/edición/colección | `MenuItem` o `{ collectionId }` |
| `inventory:updated` | cambio de stock/orden | `InventoryItem` |
| `employee:updated` | alta/edición/baja | `Employee` (sin pin) |
| `config:updated` | cambia marca/reglas | `Config` |

## Matriz de roles (administración)

| Acción | gerente | admin | otros |
|--------|:--:|:--:|:--:|
| Menú CRUD / colecciones | ✓ | ✓ | — |
| Empleados / PIN / rol | ✓ | ✓ | — |
| Turnos | ✓ | ✓ | — |
| Inventario / auto-pedido | ✓ | ✓ | — |
| Compras (sugerir/aprobar/recibir) | ✓ | ✓ | — |
| Reportes | ✓ | ✓ | — |
| Dashboard | ✓ (operativo) | ✓ | — |
| Config / Marca Blanca | — | ✓ | — |

## Notas de implementación

- Reutilizar `requireRole(...)` de `auth.js` y el patrón de `store.js` (mutación + `emit`).
- Mantener cada módulo en `src/routes/<modulo>.js` y la lógica en `store.js` (o `src/store/<modulo>.js` si crece).
- Sembrar datos demo: ~12 insumos (algunos bajo mínimo), 2–3 colecciones de menú, turnos de la semana, y algunas cuentas pagadas para que reportes/dashboard tengan números.
- Añadir tests `node:test` para: menú CRUD + activar colección, baja de stock al recibir orden, sugerencias de compra, agregación de dashboard, y permisos (mesero/hostess → 403 en endpoints admin).
