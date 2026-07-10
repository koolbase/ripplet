import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koolbase_flutter/koolbase_flutter.dart';

import '../domain/user_profile.dart';

class ProfileRepository {
  static const _collection = 'profiles';
  static const _avatarBucket = 'avatars';

  Future<bool> isUsernameTaken(String username, {String? userId}) async {
    final result = await Koolbase.db
        .collection(_collection)
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    if (result.records.isEmpty) return false;
    final owner = result.records.first.data['user_id'] as String?;
    return owner != userId;
  }

  Future<String> uploadAvatar(String userId, File image) async {
    final result = await Koolbase.storage.upload(
      bucket: _avatarBucket,
      path: '$userId.jpg',
      file: image,
      overwrite: true,
    );
    return result.downloadUrl;
  }

  Future<UserProfile> saveProfile(UserProfile profile) async {
    await Koolbase.db.upsert(
      collection: _collection,
      match: {'user_id': profile.userId},
      data: profile.toJson(),
    );
    return profile;
  }

  Future<UserProfile> completeOnboarding({
    required String userId,
    required String username,
    required String displayName,
    File? avatar,
  }) async {
    String? avatarUrl;
    if (avatar != null) {
      avatarUrl = await uploadAvatar(userId, avatar);
    }
    await Koolbase.auth.updateProfile(
      fullName: displayName,
      avatarUrl: avatarUrl,
    );
    return saveProfile(
      UserProfile(
        userId: userId,
        username: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
      ),
    );
  }

  Future<UserProfile?> getByUserId(String userId) async {
    final result = await Koolbase.db
        .collection(_collection)
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .get();
    if (result.records.isEmpty) return null;
    return UserProfile.fromJson(result.records.first.data);
  }

  Future<List<UserProfile>> searchByUsername(String username) async {
    final result = await Koolbase.db
        .collection(_collection)
        .where('username', isEqualTo: username)
        .limit(10)
        .get();
    return result.records.map((r) => UserProfile.fromJson(r.data)).toList();
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});
