import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koolbase_flutter/koolbase_flutter.dart';

import '../../auth/application/auth_controller.dart';

class DeleteAccountController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> deleteAccount() async {
    state = const AsyncLoading();
    final session = ref.read(sessionProvider);
    if (session == null) return false;
    final userId = session.id;

    Future<void> attempt(String what, Future<void> Function() op) async {
      try {
        await op();
      } catch (e) {
        debugPrint('[ripple] delete-cascade $what failed (continuing): $e');
      }
    }

    // Anonymize my messages: strip content, keep thread shape for others.
    await attempt('messages', () async {
      final mine = await Koolbase.db
          .collection('messages')
          .where('sender_id', isEqualTo: userId)
          .limit(500)
          .get();
      for (final r in mine.records) {
        await attempt('message ${r.id}', () async {
          await Koolbase.db.upsert(
            collection: 'messages',
            match: {
              'conversation_id': r.data['conversation_id'],
              'sender_id': userId,
              'created_at': r.data['created_at'],
            },
            data: {
              ...r.data,
              'text': '',
              'image_url': null,
              'reactions': <String, dynamic>{},
              'deleted': true,
            },
          );
        });
      }
    });

    await attempt('counterpart previews', () async {
      final rows = await Koolbase.db
          .collection('conversation_members')
          .where('other_user_id', isEqualTo: userId)
          .limit(200)
          .get();
      for (final r in rows.records) {
        await attempt('preview ${r.id}', () async {
          await Koolbase.db.upsert(
            collection: 'conversation_members',
            match: {
              'conversation_id': r.data['conversation_id'],
              'user_id': r.data['user_id'],
            },
            data: {
              ...r.data,
              'other_display_name': 'Deleted user',
              'other_username': '',
              'other_avatar_url': null,
              'last_message': '',
            },
          );
        });
      }
    });

    // My own chat-list rows: delete outright.
    await attempt('memberships', () async {
      await Koolbase.db.deleteWhere(
        collection: 'conversation_members',
        filters: {'user_id': userId},
      );
    });

    // My profile row + avatar object.
    String? avatarPath;
    await attempt('profile', () async {
      final res = await Koolbase.db
          .collection('profiles')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();
      if (res.records.isNotEmpty) {
        final url = res.records.first.data['avatar_url'] as String?;
        if (url != null) {
          const marker = '/avatars/';
          final i = url.indexOf(marker);
          if (i != -1) avatarPath = url.substring(i + marker.length);
        }
      }
      await Koolbase.db.deleteWhere(
        collection: 'profiles',
        filters: {'user_id': userId},
      );
    });
    if (avatarPath != null) {
      await attempt('avatar', () async {
        await Koolbase.storage.delete(bucket: 'avatars', path: avatarPath!);
      });
    }

    // ── 2. Auth deletion — must succeed or the whole operation failed ──
    try {
      await Koolbase.auth.deleteAccount();
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final deleteAccountControllerProvider =
    AsyncNotifierProvider<DeleteAccountController, void>(
      DeleteAccountController.new,
    );
