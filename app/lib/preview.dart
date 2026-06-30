// Preview de desarrollo: renderiza POS y Cocina KDS con datos de muestra
// (El Pirrus) SIN backend ni login, para validar el diseño en el emulador.
// Uso:  flutter run -t lib/preview.dart -d emulator-5554
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/accounts/accounts_screen.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/employee.dart';
import 'features/hostess/hostess_screen.dart';
import 'features/kds/kds_screen.dart';
import 'features/pos/pos_screen.dart';
import 'features/tables/tables_screen.dart';
import 'features/admin/brand_screen.dart';
import 'features/admin/dashboard_screen.dart';
import 'features/admin/inventory_screen.dart';
import 'models/admin.dart';
import 'state/admin_providers.dart';
import 'models/account.dart';
import 'models/app_config.dart';
import 'models/menu_item.dart';
import 'models/restaurant_table.dart';
import 'models/ticket.dart';
import 'models/waitlist_entry.dart';
import 'state/providers.dart';
import 'theme/theme.dart';
import 'theme/tokens.dart';

final _menu = <MenuItem>[
  const MenuItem(
      id: 'm1',
      name: 'Aguachile Negro',
      description:
          'Camarón curtido en limón, pepino, cebolla morada, chiltepín, salsa negra especial',
      price: 250,
      category: 'Aguachiles',
      station: 'cocina',
      ingredients: ['Cebolla', 'Pepino', 'Chiltepín']),
  const MenuItem(
      id: 'm2',
      name: '½ Negro',
      description: 'Media orden de aguachile negro',
      price: 170,
      category: 'Aguachiles',
      station: 'cocina'),
  const MenuItem(
      id: 'm3',
      name: 'Aguachile Verde',
      description: 'Camarón, chile serrano, chiltepín, salsa verde especial',
      price: 250,
      category: 'Aguachiles',
      station: 'cocina',
      ingredients: ['Cebolla', 'Pepino']),
  const MenuItem(
      id: 'm4',
      name: '½ Verde',
      description: 'Media orden de aguachile verde',
      price: 170,
      category: 'Aguachiles',
      station: 'cocina'),
  const MenuItem(
      id: 'm5',
      name: 'Ceviche Mixto',
      description: 'Camarón, pulpo y pescado curtidos en limón',
      price: 220,
      category: 'Ceviches',
      station: 'cocina'),
  const MenuItem(
      id: 'm6',
      name: 'Tostada de Atún',
      description: 'Atún fresco sellado, aguacate y ajonjolí',
      price: 95,
      category: 'Ceviches',
      station: 'cocina'),
  const MenuItem(
      id: 'm7',
      name: 'Pulpo Zarandeado',
      description: 'Pulpo a la parrilla con salsa de la casa',
      price: 310,
      category: 'Barra Caliente',
      station: 'cocina'),
  const MenuItem(
      id: 'm8',
      name: 'Michelada',
      description: 'Cerveza preparada con clamato y especias',
      price: 90,
      category: 'Bebidas',
      station: 'barra'),
  const MenuItem(
      id: 'm9',
      name: 'Agua de Jamaica',
      description: 'Jarra de 1 litro, natural',
      price: 45,
      category: 'Bebidas',
      station: 'barra'),
];

const _account = Account(
  id: 'acc1',
  serviceType: 'mesa',
  tableId: '1',
  guests: 2,
  waiterId: 'emp_carlos',
  status: 'abierta',
  lines: [
    AccountLine(
        id: 'l1',
        menuItemId: 'm1',
        name: 'Aguachile Negro',
        qty: 1,
        unitPrice: 250,
        station: 'cocina',
        sent: true),
    AccountLine(
        id: 'l2',
        menuItemId: 'm2',
        name: '½ Negro',
        qty: 1,
        unitPrice: 170,
        station: 'cocina',
        sent: false),
    AccountLine(
        id: 'l3',
        menuItemId: 'm5',
        name: 'Ceviche Mixto',
        qty: 2,
        unitPrice: 220,
        station: 'cocina',
        sent: false,
        removedIngredients: ['Cebolla']),
  ],
  subtotal: 860,
  tax: 73.1,
  total: 933.1,
);

List<Ticket> _tickets() {
  final now = DateTime.now();
  return [
    Ticket(
        id: 't1',
        accountId: 'acc1',
        station: 'cocina',
        status: 'pendiente',
        label: 'Mesa 5',
        serviceType: 'mesa',
        waiterName: 'Carlos',
        createdAt: now.subtract(const Duration(minutes: 3)),
        lines: const [
          TicketLine(name: 'Aguachile Negro', qty: 1),
          TicketLine(name: 'Tostada de Atún', qty: 2),
        ]),
    Ticket(
        id: 't2',
        accountId: 'acc2',
        station: 'cocina',
        status: 'en_proceso',
        label: 'Mesa 2',
        serviceType: 'mesa',
        waiterName: 'Diana',
        createdAt: now.subtract(const Duration(minutes: 18)),
        lines: const [TicketLine(name: 'Pulpo Zarandeado', qty: 1)]),
    Ticket(
        id: 't3',
        accountId: 'acc3',
        station: 'cocina',
        status: 'lista',
        label: 'Para llevar',
        serviceType: 'llevar',
        waiterName: 'María',
        createdAt: now.subtract(const Duration(minutes: 7)),
        lines: const [
          TicketLine(name: 'Ceviche Mixto', qty: 1),
          TicketLine(name: '½ Verde', qty: 1),
        ]),
    Ticket(
        id: 't4',
        accountId: 'acc4',
        station: 'cocina',
        status: 'pendiente',
        label: 'Mesa 8',
        serviceType: 'mesa',
        waiterName: 'Carlos',
        createdAt: now.subtract(const Duration(minutes: 1)),
        lines: const [TicketLine(name: 'Aguachile Verde', qty: 2)]),
  ];
}

const _tables = <RestaurantTable>[
  RestaurantTable(id: 'tbl1', number: 1, capacity: 2, status: 'ocupada', party: 2),
  RestaurantTable(id: 'tbl2', number: 2, capacity: 4, status: 'disponible'),
  RestaurantTable(id: 'tbl3', number: 3, capacity: 4, status: 'disponible'),
  RestaurantTable(id: 'tbl4', number: 4, capacity: 2, status: 'disponible'),
  RestaurantTable(id: 'tbl5', number: 5, capacity: 6, status: 'disponible'),
  RestaurantTable(id: 'tbl6', number: 6, capacity: 2, status: 'reservada', reserveName: 'Familia López', reserveTime: '20:00'),
  RestaurantTable(id: 'tbl7', number: 7, capacity: 4, status: 'disponible'),
  RestaurantTable(id: 'tbl8', number: 8, capacity: 8, status: 'disponible'),
  RestaurantTable(id: 'tbl9', number: 9, capacity: 4, status: 'por_atender'),
  RestaurantTable(id: 'tbl10', number: 10, capacity: 2, status: 'fuera_servicio'),
  RestaurantTable(id: 'tbl11', number: 11, capacity: 6, status: 'disponible'),
  RestaurantTable(id: 'tbl12', number: 12, capacity: 4, status: 'disponible'),
];

const _account2 = Account(
  id: 'acc2',
  serviceType: 'llevar',
  waiterId: 'emp_diana',
  status: 'abierta',
  lines: [
    AccountLine(id: 'l9', menuItemId: 'm6', name: 'Tostada de Atún', qty: 3, unitPrice: 95, station: 'cocina', sent: true),
  ],
  subtotal: 285,
  tax: 24.2,
  total: 309.2,
);

const _waitlist = <WaitlistEntry>[
  WaitlistEntry(id: 'wl1', name: 'Familia Pérez', size: 4, phone: '55 1234 5678', status: 'esperando', suggestedTableId: 'tbl3'),
  WaitlistEntry(id: 'wl2', name: 'Roberto y Ana', size: 2, status: 'esperando', suggestedTableId: 'tbl4'),
  WaitlistEntry(id: 'wl3', name: 'Grupo Hernández', size: 8, status: 'esperando', suggestedTableId: 'tbl8'),
  WaitlistEntry(id: 'wl4', name: 'Sofía M.', size: 10, status: 'esperando'),
];

class _FakeAccountNotifier extends CurrentAccountNotifier {
  @override
  Future<Account> build(String accountId) async => _account;
}

class _FakeTables extends TablesNotifier {
  @override
  Future<List<RestaurantTable>> build() async => _tables;
}

class _FakeOpenAccounts extends OpenAccountsNotifier {
  @override
  Future<List<Account>> build() async => const [_account, _account2];
}

class _FakeWaitlist extends WaitlistNotifier {
  @override
  Future<List<WaitlistEntry>> build() async => _waitlist;
}

const _dash = DashboardData(
  sales: 12480,
  tickets: 86,
  avgTicket: 145.10,
  tips: 1240,
  trend: [
    (label: '2026-06-23', value: 8200),
    (label: '2026-06-24', value: 9100),
    (label: '2026-06-25', value: 11800),
    (label: '2026-06-26', value: 13900),
    (label: '2026-06-27', value: 9700),
    (label: '2026-06-28', value: 7300),
    (label: '2026-06-29', value: 9400),
  ],
  byServiceType: [
    (type: 'mesa', amount: 8120),
    (type: 'llevar', amount: 2960),
    (type: 'domicilio', amount: 1400),
  ],
  topDishes: [
    (name: 'Aguachile Negro', qty: 42),
    (name: 'Ceviche Mixto', qty: 31),
    (name: 'Pulpo Zarandeado', qty: 24),
    (name: 'Tostada de Atún', qty: 18),
  ],
  tablesOccupied: 3,
  tablesTotal: 12,
  activeAccounts: 4,
  kitchenTickets: 2,
  barTickets: 1,
);

const _inventory = <InventoryItem>[
  InventoryItem(id: 'i1', name: 'Camarón', category: 'Mariscos', unit: 'kg', stock: 18, minStock: 10, status: 'ok', autoReorder: true, cost: 180, supplier: 'Mariscos del Pacífico'),
  InventoryItem(id: 'i2', name: 'Pulpo', category: 'Mariscos', unit: 'kg', stock: 6, minStock: 8, status: 'bajo', autoReorder: true, cost: 220, supplier: 'Mariscos del Pacífico'),
  InventoryItem(id: 'i3', name: 'Limón', category: 'Verduras', unit: 'kg', stock: 40, minStock: 25, status: 'ok', autoReorder: false, cost: 25),
  InventoryItem(id: 'i4', name: 'Cerveza', category: 'Bebidas', unit: 'cartón', stock: 4, minStock: 6, status: 'bajo', autoReorder: true, cost: 280, supplier: 'Distribuidora Sur'),
  InventoryItem(id: 'i5', name: 'Aguacate', category: 'Verduras', unit: 'pza', stock: 50, minStock: 30, status: 'ok', autoReorder: false, cost: 12),
  InventoryItem(id: 'i6', name: 'Tostadas', category: 'Abarrotes', unit: 'paq', stock: 22, minStock: 12, status: 'ok', autoReorder: false, cost: 35),
];

class _FakeInventory extends InventoryNotifier {
  @override
  Future<List<InventoryItem>> build() async => _inventory;
}

class _FakeTickets extends TicketsNotifier {
  @override
  Future<List<Ticket>> build(String station) async => _tickets();
}

class _FakeAuth extends AuthController {
  @override
  AuthState build() => const AuthState(
        status: AuthStatus.authenticated,
        employee: Employee(id: 'emp_sofia', name: 'Sofía Admin', role: 'admin'),
      );
}

void main() {
  runApp(
    ProviderScope(
      overrides: [
        menuProvider.overrideWith((ref) async => _menu),
        configProvider.overrideWith((ref) async => AppConfig.fallback),
        currentAccountIdProvider.overrideWith((ref) => 'acc1'),
        currentAccountProvider.overrideWith(_FakeAccountNotifier.new),
        ticketsProvider.overrideWith(_FakeTickets.new),
        authControllerProvider.overrideWith(_FakeAuth.new),
        tablesProvider.overrideWith(_FakeTables.new),
        openAccountsProvider.overrideWith(_FakeOpenAccounts.new),
        waitlistProvider.overrideWith(_FakeWaitlist.new),
        dashboardProvider.overrideWith((ref) async => _dash),
        inventoryProvider.overrideWith(_FakeInventory.new),
      ],
      child: const _PreviewApp(),
    ),
  );
}

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();
  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  int _screen = const int.fromEnvironment('SCREEN', defaultValue: 0);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Scaffold(
        backgroundColor: BrandColors.bg,
        appBar: AppBar(
          title: const Text('Preview · El Pirrus'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: Sp.lg),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('POS')),
                  ButtonSegment(value: 1, label: Text('KDS')),
                  ButtonSegment(value: 2, label: Text('Mesas')),
                  ButtonSegment(value: 3, label: Text('Cuentas')),
                  ButtonSegment(value: 4, label: Text('Hostess')),
                  ButtonSegment(value: 5, label: Text('Dashboard')),
                  ButtonSegment(value: 6, label: Text('Inventario')),
                  ButtonSegment(value: 7, label: Text('Marca')),
                ],
                selected: {_screen},
                onSelectionChanged: (s) => setState(() => _screen = s.first),
              ),
            ),
          ],
        ),
        body: switch (_screen) {
          0 => const PosScreen(),
          1 => const KdsScreen(station: 'cocina'),
          2 => const TablesScreen(initialSelectedId: 'tbl1'),
          3 => const AccountsScreen(),
          4 => const HostessScreen(),
          5 => const DashboardScreen(),
          6 => const InventoryScreen(),
          _ => const BrandScreen(),
        },
      ),
    );
  }
}
