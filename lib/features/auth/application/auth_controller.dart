import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/app_user.dart';

class SessionController extends Notifier<AppUser?> {
  @override
  AppUser? build() {
    final sub = ref
        .read(authRepositoryProvider)
        .authStateChanges()
        .listen((user) => state = user);
    ref.onDispose(sub.cancel);
    return null;
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Called once at startup (see main.dart) to restore a persisted session.
  Future<void> restore() async {
    state = await _repo.restoreSession();
  }

  Future<void> signIn(String email, String password) async {
    state = await _repo.signIn(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    state = await _repo.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    try {
      await _repo.signOut();
    } catch (_) {
      // Server-side logout failed (expired token, network, etc.) —
      // still clear the local session; the refresh token is dead to us.
    } finally {
      state = null;
    }
  }
}

final sessionProvider = NotifierProvider<SessionController, AppUser?>(
  SessionController.new,
);
