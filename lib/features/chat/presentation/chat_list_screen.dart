import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../system/application/code_push_provider.dart';
import '../../system/presentation/code_push_banner.dart';
import '../application/chat_providers.dart';
import '../domain/conversation_summary.dart';

String _timestamp(DateTime? t) {
  if (t == null) return '';
  final local = t.toLocal();
  final now = DateTime.now();
  if (local.year == now.year &&
      local.month == now.month &&
      local.day == now.day) {
    return DateFormat.jm().format(local);
  }
  return DateFormat.MMMd().format(local);
}

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showBanner = ref.watch(codePushAppliedProvider);
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ripplet'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/new-message'),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(conversationsRefreshTick.notifier).state++,
        child: conversations.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(child: Text('Could not load chats: $e')),
            ],
          ),
          data: (items) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (showBanner) const CodePushBanner(),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(
                    child: Text(
                      'No conversations yet.\nTap + to say hello.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              for (final c in items) _ConversationTile(summary: c),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.summary});

  final ConversationSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: summary.otherAvatarUrl != null
            ? CachedNetworkImageProvider(summary.otherAvatarUrl!)
            : null,
        child: summary.otherAvatarUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(
        summary.otherDisplayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        summary.lastMessage ?? 'Say hello 👋',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        _timestamp(summary.lastMessageAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: () =>
          context.push('/chats/${summary.conversationId}', extra: summary),
    );
  }
}
