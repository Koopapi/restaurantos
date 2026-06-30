import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'state/providers.dart';
import 'theme/theme.dart';

void main() {
  runApp(const ProviderScope(child: RestaurantOsApp()));
}

class RestaurantOsApp extends ConsumerWidget {
  const RestaurantOsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    // Color de marca desde la config (white-label): re-tematiza en runtime.
    final primary = ref.watch(configProvider).valueOrNull?.primaryColorValue ??
        const Color(0xFFFF9800);
    return MaterialApp.router(
      title: 'RestaurantOS',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(primary),
      routerConfig: router,
    );
  }
}
