import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/system/application/platform_config_providers.dart';

class RippleApp extends ConsumerWidget {
  const RippleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Remote Config drives the accent — edit `accent_color` in the
    // dashboard and the running app recolors within seconds.
    final accent = ref.watch(accentColorProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Ripplet',
      theme: AppTheme.light(accent),
      darkTheme: AppTheme.dark(accent),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
