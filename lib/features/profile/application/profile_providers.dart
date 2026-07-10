import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

final freshProfileOverrideProvider = StateProvider<UserProfile?>((_) => null);

final myProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) return null;
  final fresh = ref.watch(freshProfileOverrideProvider);
  if (fresh != null && fresh.userId == session.id) return fresh;
  return ref.read(profileRepositoryProvider).getByUserId(session.id);
});
