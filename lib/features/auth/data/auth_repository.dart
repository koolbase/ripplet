import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koolbase_flutter/koolbase_flutter.dart';

import '../domain/app_user.dart';

class AuthRepository {
  KoolbaseAuthClient get _auth => Koolbase.auth;

  Stream<AppUser?> authStateChanges() => _auth.authStateChanges.map(
    (u) => u == null ? null : AppUser.fromKoolbase(u),
  );

  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    final user = await _auth.signUp(email: email, password: password);
    return AppUser.fromKoolbase(user);
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final user = await _auth.login(email: email, password: password);
    return AppUser.fromKoolbase(user);
  }

  Future<void> signOut() => _auth.logout();

  Future<AppUser?> restoreSession() async {
    await _auth.restoreSession();
    final user = _auth.currentUser;
    return user == null ? null : AppUser.fromKoolbase(user);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
