import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:restaurantos/router.dart';
import 'package:restaurantos/theme/theme.dart';

void main() {
  testWidgets('arranca en la pantalla de Login (PIN)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            theme: buildAppTheme(),
            routerConfig: ref.watch(goRouterProvider),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('RestaurantOS'), findsOneWidget);
    expect(find.text('Inicia sesión con tu PIN'), findsOneWidget);
    // El teclado numérico muestra los dígitos.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}
