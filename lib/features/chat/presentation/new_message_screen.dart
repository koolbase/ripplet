import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../profile/application/profile_providers.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/user_profile.dart';
import '../application/chat_providers.dart';
import '../data/chat_repository.dart';
import '../domain/conversation_summary.dart';

class NewMessageScreen extends ConsumerStatefulWidget {
  const NewMessageScreen({super.key});

  @override
  ConsumerState<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends ConsumerState<NewMessageScreen> {
  final _search = TextEditingController();
  List<UserProfile> _results = const [];
  bool _searching = false;
  bool _opening = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String raw) async {
    final username = raw.trim().toLowerCase().replaceFirst('@', '');
    if (username.isEmpty) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await ref
          .read(profileRepositoryProvider)
          .searchByUsername(username);
      final myId = ref.read(myProfileProvider).valueOrNull?.userId;
      if (mounted) {
        setState(
          () => _results = results.where((p) => p.userId != myId).toList(),
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _open(UserProfile other) async {
    final me = ref.read(myProfileProvider).valueOrNull;
    if (me == null || _opening) return;
    setState(() => _opening = true);
    try {
      final conversationId = await ref
          .read(chatRepositoryProvider)
          .openConversation(me: me, other: other);
      ref.invalidate(conversationsProvider);
      if (mounted) {
        context.pushReplacement(
          '/chats/$conversationId',
          extra: ConversationSummary(
            conversationId: conversationId,
            userId: me.userId,
            otherUserId: other.userId,
            otherUsername: other.username,
            otherDisplayName: other.displayName,
            otherAvatarUrl: other.avatarUrl,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open chat: $e')));
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: const Text('New Message'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              autocorrect: false,
              textInputAction: TextInputAction.search,
              onSubmitted: _runSearch,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search by exact @username',
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('Type a username and press search.'))
                : ListView(
                    children: [
                      for (final p in _results)
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: p.avatarUrl != null
                                ? CachedNetworkImageProvider(p.avatarUrl!)
                                : null,
                            child: p.avatarUrl == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(p.displayName),
                          subtitle: Text('@${p.username}'),
                          onTap: () => _open(p),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
