import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../data/moderation_repository.dart';
import 'moderation_providers.dart';

const _reportReasons = [
  'Spam',
  'Harassment or bullying',
  'Inappropriate content',
  'Pretending to be someone else',
  'Something else',
];

/// App-bar ⋮ menu for the chat room: Report user / Block user.
class ModerationMenu extends ConsumerWidget {
  const ModerationMenu({
    super.key,
    required this.otherUserId,
    required this.otherDisplayName,
    this.conversationId,
  });

  final String otherUserId;
  final String otherDisplayName;
  final String? conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedIdSetProvider).contains(otherUserId);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'report':
            _report(context, ref);
          case 'block':
            _confirmBlock(context, ref);
          case 'unblock':
            ref.read(blockedIdsProvider.notifier).unblock(otherUserId);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'report', child: Text('Report user')),
        blocked
            ? const PopupMenuItem(value: 'unblock', child: Text('Unblock user'))
            : const PopupMenuItem(value: 'block', child: Text('Block user')),
      ],
    );
  }

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Report $otherDisplayName',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final r in _reportReasons)
              ListTile(title: Text(r), onTap: () => Navigator.pop(context, r)),
          ],
        ),
      ),
    );
    if (reason == null || !context.mounted) return;

    final me = ref.read(sessionProvider);
    if (me == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(moderationRepositoryProvider)
          .reportUser(
            reporterId: me.id,
            reportedUserId: otherUserId,
            conversationId: conversationId,
            reason: reason,
          );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Report submitted. Thank you for keeping Ripplet safe.'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not submit report: $e')),
      );
    }
  }

  Future<void> _confirmBlock(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block $otherDisplayName?'),
        content: const Text(
          'They will disappear from your chats and search. You can unblock '
          'them anytime from this menu.',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Block'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(blockedIdsProvider.notifier).block(otherUserId);
    if (context.mounted) context.go('/chats');
  }
}
