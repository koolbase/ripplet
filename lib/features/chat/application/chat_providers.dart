import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../data/chat_repository.dart';
import '../../moderation/application/moderation_providers.dart';
import '../domain/conversation_summary.dart';
import '../domain/message.dart';

final conversationsRefreshTick = StateProvider<int>((_) => 0);

final conversationsProvider = StreamProvider<List<ConversationSummary>>((ref) {
  final session = ref.watch(sessionProvider);
  final repo = ref.watch(chatRepositoryProvider);
  if (session == null) return Stream.value(const []);

  final controller = StreamController<List<ConversationSummary>>();
  final byConversation = <String, ConversationSummary>{};

  void emit() {
    final blocked = ref.read(blockedIdSetProvider);
    final items =
        byConversation.values
            .where((c) => !blocked.contains(c.otherUserId))
            .toList()
          ..sort(
            (a, b) => (b.lastMessageAt ?? DateTime(0)).compareTo(
              a.lastMessageAt ?? DateTime(0),
            ),
          );
    controller.add(items);
  }

  void mergeFetched(List<ConversationSummary> fetched) {
    for (final c in fetched) {
      final existing = byConversation[c.conversationId]?.lastMessageAt;
      if (existing == null ||
          (c.lastMessageAt?.isAfter(existing) ?? false) ||
          c.lastMessageAt == existing) {
        byConversation[c.conversationId] = c;
      }
    }
    emit();
  }

  Future<void> load() async {
    try {
      mergeFetched(await repo.conversationsFor(session.id));
    } catch (e, st) {
      if (byConversation.isEmpty) controller.addError(e, st);
    }
  }

  load();

  // Pull-to-refresh: re-run the guarded merge, keep everything alive.
  ref.listen(conversationsRefreshTick, (_, __) => load());
  ref.listen(blockedIdSetProvider, (_, __) => emit());

  final sub = repo
      .memberEventsFor(session.id)
      .listen(
        (c) {
          byConversation[c.conversationId] = c;
          emit();
        },
        onError: (Object e) {
          debugPrint('[ripple] member event error: $e');
        },
      );

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  return controller.stream;
});

final messagesProvider = StreamProvider.autoDispose
    .family<List<Message>, String>((ref, conversationId) {
      final repo = ref.watch(chatRepositoryProvider);
      final controller = StreamController<List<Message>>();
      final byId = <String, Message>{};

      void emit() {
        final blocked = ref.read(blockedIdSetProvider);
        final items =
            byId.values.where((m) => !blocked.contains(m.senderId)).toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        controller.add(items);
      }

      repo
          .messagesFor(conversationId)
          .then((initial) {
            for (final m in initial) {
              byId[m.id] = m;
            }
            emit();
          })
          .catchError((Object e, StackTrace st) {
            controller.addError(e, st);
          });

      final sub = repo
          .messageEventsFor(conversationId)
          .listen(
            (m) {
              byId[m.id] = m;
              emit();
            },
            onError: (Object e) {
              debugPrint('[ripple] message event error received');
            },
          );

      ref.onDispose(() {
        sub.cancel();
        controller.close();
      });
      return controller.stream;
    });
