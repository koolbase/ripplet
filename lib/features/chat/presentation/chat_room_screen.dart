import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/application/auth_controller.dart';
import '../../moderation/application/moderation_menu.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/domain/user_profile.dart';
import '../../system/application/platform_config_providers.dart';
import '../application/chat_providers.dart';
import '../data/chat_repository.dart';
import '../domain/conversation_summary.dart';
import '../domain/message.dart';

const _reactionEmojis = ['❤️', '😂', '👍', '😮'];

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({super.key, required this.conversationId, this.summary});

  final String conversationId;

  /// Passed via router `extra` when opened from the chat list; when null
  /// (deep link / hot restart) the header falls back to a plain title.
  final ConversationSummary? summary;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  UserProfile? get _other {
    final s = widget.summary;
    if (s == null) return null;
    return UserProfile(
      userId: s.otherUserId,
      username: s.otherUsername,
      displayName: s.otherDisplayName,
      avatarUrl: s.otherAvatarUrl,
    );
  }

  Future<void> _send({File? image}) async {
    final text = _input.text.trim();
    final me = ref.read(myProfileProvider).valueOrNull;
    final other = _other;
    if ((text.isEmpty && image == null) || me == null || other == null) {
      return;
    }

    // Optimistic: clear immediately; the realtime event renders the
    // message. On failure, restore the text so nothing is lost.
    _input.clear();
    try {
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            conversationId: widget.conversationId,
            me: me,
            other: other,
            text: text,
            image: image,
          );
    } catch (e) {
      if (mounted) {
        _input.text = text;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Send failed: $e')));
      }
    }
  }

  Future<void> _attachImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );
    if (picked != null) await _send(image: File(picked.path));
  }

  Future<void> _showReactions(Message message) async {
    final myId = ref.read(sessionProvider)?.id;
    if (myId == null) return;
    final emoji = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final e in _reactionEmojis)
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.pop(context, e),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(e, style: const TextStyle(fontSize: 32)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (emoji == null) return;
    try {
      await ref
          .read(chatRepositoryProvider)
          .toggleReaction(message: message, emoji: emoji, userId: myId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Reaction failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(sessionProvider)?.id;
    final messages = ref.watch(messagesProvider(widget.conversationId));
    final reactionsOn = ref.watch(reactionsEnabledProvider);
    final s = widget.summary;

    return Scaffold(
      appBar: AppBar(
        title: s == null
            ? const Text('Chat')
            : Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: s.otherAvatarUrl != null
                        ? CachedNetworkImageProvider(s.otherAvatarUrl!)
                        : null,
                    child: s.otherAvatarUrl == null
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.otherDisplayName,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
        actions: [
          if (s != null)
            ModerationMenu(
              otherUserId: s.otherUserId,
              otherDisplayName: s.otherDisplayName,
              conversationId: widget.conversationId,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Could not load: $e')),
              data: (items) => items.isEmpty
                  ? const Center(child: Text('Say hello 👋'))
                  : ListView.builder(
                      controller: _scroll,
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final m = items[items.length - 1 - i];
                        return _Bubble(
                          message: m,
                          mine: m.senderId == myId,
                          showReactions: reactionsOn,
                          onLongPress: reactionsOn
                              ? () => _showReactions(m)
                              : null,
                        );
                      },
                    ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _attachImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(hintText: 'Message'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.showReactions,
    required this.onLongPress,
  });

  final Message message;
  final bool mine;
  final bool showReactions;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 3),
              padding: message.imageUrl != null
                  ? const EdgeInsets.all(4)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: mine ? scheme.primary : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: message.imageUrl!,
                        width: 220,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const SizedBox(
                          width: 220,
                          height: 160,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const SizedBox(
                          width: 220,
                          height: 100,
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  if (message.text.isNotEmpty)
                    Padding(
                      padding: message.imageUrl != null
                          ? const EdgeInsets.fromLTRB(8, 6, 8, 4)
                          : EdgeInsets.zero,
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: mine ? scheme.onPrimary : scheme.onSurface,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (showReactions && message.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Wrap(
                  spacing: 4,
                  children: [
                    for (final e in message.reactions.entries)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Text(
                          '${e.key} ${e.value.length}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
