import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koolbase_flutter/koolbase_flutter.dart';

class ModerationRepository {
  static const _reports = 'reports';
  static const _blocks = 'blocks';

  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    String? conversationId,
    required String reason,
  }) async {
    await Koolbase.db.insert(
      collection: _reports,
      data: {
        'reporter_id': reporterId,
        'reported_user_id': reportedUserId,
        'conversation_id': conversationId,
        'reason': reason,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<void> blockUser({
    required String userId,
    required String blockedUserId,
  }) async {
    // Upsert: blocking twice is idempotent, no duplicate rows.
    await Koolbase.db.upsert(
      collection: _blocks,
      match: {'user_id': userId, 'blocked_user_id': blockedUserId},
      data: {
        'user_id': userId,
        'blocked_user_id': blockedUserId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<void> unblockUser({
    required String userId,
    required String blockedUserId,
  }) async {
    await Koolbase.db.deleteWhere(
      collection: _blocks,
      filters: {'user_id': userId, 'blocked_user_id': blockedUserId},
    );
  }

  /// The caller's block list (ids only — that's all filtering needs).
  Future<Set<String>> blockedUserIds(String userId) async {
    final result = await Koolbase.db
        .collection(_blocks)
        .where('user_id', isEqualTo: userId)
        .limit(500)
        .get();
    return result.records
        .map((r) => r.data['blocked_user_id'] as String)
        .toSet();
  }
}

final moderationRepositoryProvider = Provider<ModerationRepository>(
  (ref) => ModerationRepository(),
);
