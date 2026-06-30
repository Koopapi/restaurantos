// Preview de desarrollo: renderiza POS y Cocina KDS con datos de muestra
// (El Pirrus) SIN backend ni login, para validar el diseño en el emulador.
// Uso:  flutter run -t lib/preview.dart -d emulator-5554
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/employee.dart';
import 'features/kds/kds_screen.dart';
import 'features/pos/pos_screen.dart';
import 'models/account.dart';
import 'models/app_config.dart';
import 'models/menu_item.dart';
import 'models/ticket.dart';
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

class _FakeAccountNotifier extends CurrentAccountNotifier {
  @override
  Future<Account> build(String accountId) async => _account;
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
                  ButtonSegment(value: 1, label: Text('Cocina KDS')),
                ],
                selected: {_screen},
                onSelectionChanged: (s) => setState(() => _screen = s.first),
              ),
            ),
          ],
        ),
        body: _screen == 0
            ? const PosScreen()
            : const KdsScreen(station: 'cocina'),
      ),
    );
  }
}
