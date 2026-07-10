import 'package:koolbase_flutter/koolbase_flutter.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.username,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? username;
  final String? avatarUrl;

  factory AppUser.fromKoolbase(KoolbaseUser u) => AppUser(
    id: u.id,
    email: u.email,
    displayName: u.fullName,
    // KoolbaseUser has no username field; Ripplet stores the @handle
    // in user metadata
    username: u.metadata?['username'] as String?,
    avatarUrl: u.avatarUrl,
  );
}
