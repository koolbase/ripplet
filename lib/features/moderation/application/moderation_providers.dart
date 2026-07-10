import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/moderation_repository.dart';

class BlockedIdsController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final session = ref.watch(sessionProvider);
    if (session == null) return {};
    return ref.read(moderationRepositoryProvider).blockedUserIds(session.id);
  }

  Future<void> block(String blockedUserId) async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    // Optimistic: filter immediately, then persist.
    final current = state.valueOrNull ?? <String>{};
    state = AsyncData({...current, blockedUserId});
    await ref
        .read(moderationRepositoryProvider)
        .blockUser(userId: session.id, blockedUserId: blockedUserId);
  }

  Future<void> unblock(String blockedUserId) async {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    final current = state.valueOrNull ?? <String>{};
    state = AsyncData({...current}..remove(blockedUserId));
    await ref
        .read(moderationRepositoryProvider)
        .unblockUser(userId: session.id, blockedUserId: blockedUserId);
  }
}

final blockedIdsProvider =
    AsyncNotifierProvider<BlockedIdsController, Set<String>>(
      BlockedIdsController.new,
    );

final blockedIdSetProvider = Provider<Set<String>>((ref) {
  return ref.watch(blockedIdsProvider).valueOrNull ?? const {};
});
