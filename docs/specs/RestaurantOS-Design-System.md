# RestaurantOS — Sistema de Diseño e Implementación

Guía para reconstruir el rediseño (archivo Pencil `pencil-new.pen`) en **React + shadcn/ui** (Tailwind + Radix). Mantiene la identidad actual —oscuro + naranja— refinando jerarquía, contraste, espaciado y áreas táctiles, y soporta **marca blanca** (color configurable en runtime).

El diseño cubre **15 pantallas tablet** y **8 pantallas móvil**. Tablet es el dispositivo principal; móvil es para el mesero en piso. Donde aplica, el tablero de cocina/barra (KDS) se piensa también para pantalla grande montada.

---

## 1. Principios

1. **Una intención por pantalla.** Una región dominante; lo demás es subordinado.
2. **Touch-first.** Objetivos táctiles ≥ 44 px; nada depende de hover.
3. **Estado siempre visible.** Cada superficie con datos tiene loading / vacío / error / éxito.
4. **Tiempo real.** Comandas y mesas cambian de estado al instante; indicadores de nuevo/urgente.
5. **Marca blanca de primera clase.** `--primary` y el azul de acento se inyectan por CSS variables.
6. **Consistencia.** Mismos componentes y escala de espaciado en todo el sistema.

---

## 2. Tokens — CSS Variables (tema oscuro por defecto)

shadcn/ui consume variables semánticas en `:root`. Pega esto en `globals.css`. El tema oscuro es el predeterminado de la app; `.light` queda disponible para condiciones de mucha luz en piso.

```css
:root {
  /* superficies */
  --background: #0A0B0D;
  --foreground: #F5F6F8;
  --card: #15171C;
  --card-foreground: #F5F6F8;
  --popover: #1D2027;
  --popover-foreground: #F5F6F8;

  /* marca (configurable por tenant) */
  --primary: #FF9800;
  --primary-foreground: #1A1206;

  /* neutrales shadcn */
  --secondary: #1D2027;
  --secondary-foreground: #F5F6F8;
  --muted: #1D2027;
  --muted-foreground: #A0A6B0;
  --accent: #23272F;
  --accent-foreground: #F5F6F8;
  --border: #2C313B;
  --input: #2C313B;
  --ring: #FF9800;

  /* estados / semánticos (extensión propia) */
  --destructive: #FF4D4F;
  --destructive-foreground: #FFFFFF;
  --success: #34C759;
  --warning: #F5B73B;
  --info: #5B8DEF;            /* azul de acento secundario, también marca blanca */
  /* fondos "soft" = color al 12% (sufijo 1F en hex8) */
  --primary-soft: #FF98001F;
  --success-soft: #34C7591F;
  --warning-soft: #F5B73B1F;
  --destructive-soft: #FF4D4F1F;
  --info-soft: #5B8DEF1F;

  /* radio base; shadcn deriva sm/md/lg */
  --radius: 0.875rem;        /* 14px (cards, modales). pills = 9999px */
  --text-muted-2: #6B717C;   /* texto terciario / placeholders apagados */
}

.light {
  --background: #F6F7F9;
  --foreground: #15171C;
  --card: #FFFFFF;
  --card-foreground: #15171C;
  --popover: #FFFFFF;
  --popover-foreground: #15171C;
  --secondary: #EEF0F3;
  --secondary-foreground: #15171C;
  --muted: #EEF0F3;
  --muted-foreground: #5B626E;
  --accent: #E7EAEF;
  --accent-foreground: #15171C;
  --border: #DCE0E6;
  --input: #DCE0E6;
  /* --primary y semánticos se conservan */
}
```

### Extensión Tailwind (colores que shadcn no trae)

```ts
// tailwind.config.ts  → theme.extend.colors
success:   "var(--success)",
warning:   "var(--warning)",
info:      "var(--info)",
"primary-soft":     "var(--primary-soft)",
"success-soft":     "var(--success-soft)",
"warning-soft":     "var(--warning-soft)",
"destructive-soft": "var(--destructive-soft)",
"info-soft":        "var(--info-soft)",
```

### Tipografía

Fuente única **Inter** (Google Fonts / `next/font`). Escala usada en el diseño:

| Rol | Tamaño / peso |
|---|---|
| Título de pantalla (H1) | 24 px / 700 |
| Título de sección / card | 16 px / 600 |
| Valor de métrica | 26–32 px / 700 |
| Cuerpo | 14–15 px / 400–500 |
| Etiqueta / meta | 12–13 px / 500 |
| Badge / micro | 11 px / 600 |

### Espaciado y radios

Escala (px): **4 · 8 · 12 · 16 · 24 · 32**. Radios: **8** (chips/inputs/celdas), **14** (cards/modales), **20** (login/sheet superior), **pill** (botones de estado, badges, segmentos). Padding interior estándar de card: 18–20; gap entre secciones: 18–24.

---

## 3. Mapeo de componentes → shadcn/ui

| Componente en Pencil | shadcn/ui | Notas de implementación |
|---|---|---|
| `comp/ButtonPrimary` / `ButtonOutline` | `Button` (`variant="default"` / `"outline"`) | En piso usar `size` alto (`h-11`/`h-12`). Botón verde "Entregar" del KDS = variante con `bg-success`. |
| `comp/Badge` (dot + label) | `Badge` + variantes soft propias | Crear variantes `success/warning/info/destructive` con `bg-*-soft text-*`. El punto es un `<span>` redondo. |
| `comp/Sidebar` + `comp/NavItem` | `Sidebar` de shadcn (o nav propio) | Ítem activo: `bg-primary text-primary-foreground`. Footer con avatar + rol. Colapsable a iconos en tablet chico. |
| `comp/MobileTabBar` | Nav inferior propio | Cápsula flotante (≈56 px, `rounded-full`), 5 destinos por rol, ítem activo con `bg-primary-soft text-primary`. |
| `comp/Input` | `Input` + `Label` | Fondo `--input`, borde `--border`. |
| `comp/Toggle` | `Switch` | On = `--primary`. |
| `comp/Stepper` | Compuesto (`Button` − / valor / `Button` +) | Botones 40×40 táctiles; "+" en `--primary`. |
| `comp/MetricCard` | `Card` | Icon-chip + valor grande + etiqueta. |
| `comp/ProductCard` | `Card` | Thumb + nombre + desc + precio + botón "+" (`aspect` libre). |
| `comp/LineItem` | Fila propia | Nombre + precio + `Stepper`; badge "enviado" cuando la línea ya se mandó a cocina. |
| `comp/KdsTicket` | `Card` + `Badge` + barra de acento | Acento izquierdo por estado; timer; acción según estado (ver §6). |
| `comp/TableTile` | `Card` (estado por color) | Borde + fondo soft según estado de mesa. |
| Tablas (Inventario, Empleados, Compras IA) | `Table` | Jerarquía Table → Row → Cell. Estados con `Badge`. Toggle de auto-pedido = `Switch`. |
| Modal de ingredientes | `Dialog` (tablet) / `Sheet` lado inferior (móvil) | Chips de ingredientes = `ToggleGroup`/`Toggle`; quitado = tachado en `--destructive`. |
| Segmento "Hoy / 7 días / 30 días" | `Tabs` o `ToggleGroup` | Activo en `--primary`. |
| Chips de categoría / subcategoría | `ToggleGroup` (single) | Subcategoría seleccionada: `bg-primary-soft border-primary text-primary`. |
| Gráfica de barras (Dashboard) | `recharts` `<BarChart>` | Barra del día actual en `--primary`, resto `--primary-soft`. |

---

## 4. Patrón responsivo

| | Tablet (principal) | Móvil (mesero) | Pantalla grande (KDS) |
|---|---|---|---|
| Navegación | Sidebar fija 248 px | Tab bar inferior (cápsula) | Sin nav; tablero a pantalla completa |
| Densidad | Media; 2–3 zonas | 1 columna dominante | Columnas por estado, texto grande |
| Detalle | Panel lateral derecho (320–360) | Pantalla aparte o `Sheet` | — |
| Modal | `Dialog` centrado | `Sheet` desde abajo con grabber | — |
| Grids | 3–4 columnas | 2 columnas | Columnas por estado |

Breakpoints sugeridos (Tailwind): móvil `< 768`, tablet `768–1279`, KDS/escritorio `≥ 1280`. La jerarquía se conserva en todos los breakpoints: el panel lateral colapsa a hoja/secciones apiladas; nunca scroll horizontal salvo el riel de categorías.

---

## 5. Inventario de pantallas y navegación por rol

**Tablet (15):** Login · Dashboard · POS · Modal de ingredientes · Nueva Cuenta · Mesas · Cocina KDS · Barra KDS · Hostess / Lista de Espera · Cobro · Menú y Platillos · Crear Nuevo Menú · Inventario · Compras IA · Empleados · Gestionar Turnos · Exportar Reportes · Marca Blanca.

**Móvil (8):** Login · POS · Modal (sheet) · Pedido Actual · Mesas · Cocina KDS · Dashboard · Nueva Cuenta.

| Rol | Accede a |
|---|---|
| Mesero | POS, Nueva Cuenta, Pedido/Cuentas, Mesas (ver), Cobro, ver Cocina/Barra |
| Cocina | Cocina KDS |
| Barista | Barra KDS |
| Hostess | Mesas (asignación) + Lista de Espera |
| Gerente | Todo lo operativo + Menú, Compras IA, Inventario, Empleados, Turnos, Reportes, Marca Blanca |
| Admin | Todo lo de Gerente + Dashboard |

El login enruta al usuario a su pantalla por defecto según rol. La autorización debe validarse en el backend (no solo en el cliente).

---

## 6. Reglas de estado del KDS (comanda)

Flujo: **Pendiente → En preparación → Lista → Entregada**.

| Estado | Acento / Badge | Acción del botón | Quién la ejecuta |
|---|---|---|---|
| Pendiente | `warning` | "Iniciar preparación" (primary) | Cocina / Barba |
| En preparación | `info` (azul) | "Marcar Listo" (primary) | Cocina / Barra |
| Lista | `success` | "Entregar" (verde, `bg-success`) | **Mesero** |

Regla de negocio a conservar: el **mesero no puede** iniciar preparación ni marcar listo; solo **entrega** cuando ya está lista. El temporizador pasa a `warning`/`destructive` al superar `urgencyMinutes` (configurable en Marca Blanca). Ruteo: Comida → Cocina; Bebidas/Yukapioca → Barra.

---

## 7. Estados de mesa (Gestión de Mesas)

| Estado | Color | Token |
|---|---|---|
| Disponible | verde | `success` |
| Ocupada | rojo | `destructive` |
| Reservada | azul | `info` |
| Por atender | ámbar | `warning` |
| Fuera de servicio | gris | `muted` |

"Por atender" se origina cuando la hostess asigna una mesa: se **notifica a todos los meseros** (persistente) hasta que uno la toma. La lista de espera sugiere la **mesa libre más pequeña que alcanza** para el grupo.

---

## 8. Notas de implementación

- **Realtime:** WebSocket para comandas y mesas; reflejar cambios al instante en todos los dispositivos. IDs asignados por el servidor (evitar colisiones del cliente).
- **Estados de UI:** todo listado/tablero implementa loading (skeleton), vacío (icono + mensaje, como en KDS), error y reconexión visibles.
- **Accesibilidad / piso:** contraste alto, objetivos táctiles ≥ 44 px, texto legible con poca luz, tolerancia a toques repetidos.
- **Marca blanca:** cambiar `--primary` y `--info` por tenant (inyectar en `:root` al cargar). La etiqueta de impuesto (IVA), `urgencyMinutes` y `maxQtyPerLine` son configuración de negocio.
- **Login por PIN** rápido para piso, pero con verificación de rol server-side.

---

## 9. Inventario de componentes reutilizables (en el .pen)

`ButtonPrimary`, `ButtonOutline`, `Badge`, `NavItem`, `Sidebar`, `MobileTabBar`, `Input`, `Toggle`, `Stepper`, `MetricCard`, `ProductCard`, `LineItem`, `KdsTicket`, `TableTile`. Editar el componente propaga a todas las instancias — igual que un componente de shadcn bien encapsulado.
