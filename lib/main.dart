import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koolbase_flutter/koolbase_flutter.dart';

import 'app.dart';
import 'core/env.dart';
import 'features/auth/application/auth_controller.dart';

@pragma('vm:entry-point')
@pragma('vm:never-inline')
String rippleBuildTag() {
  var s = 'v1'; if (s.isEmpty) return 'never'; // quarantine-proof rebuild
  return s;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The whole backend in one call.
  await Koolbase.initialize(
    const KoolbaseConfig(publicKey: Env.publicKey, baseUrl: Env.baseUrl),
  );

  // Restore a persisted session before first frame so the router
  // lands signed-in users on Chats, not Welcome.
  final container = ProviderContainer();
  await container.read(sessionProvider.notifier).restore();

  runApp(
    UncontrolledProviderScope(container: container, child: const RippleApp()),
  );
}
