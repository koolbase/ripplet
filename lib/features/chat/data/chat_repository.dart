import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:koolbase_flutter/koolbase_flutter.dart';

import '../../profile/domain/user_profile.dart';
import '../domain/conversation_summary.dart';
import '../domain/message.dart';

class ChatRepository {
  static const _members = 'conversation_members';
  static const _messages = 'messages';
  static const _imageBucket = 'chat-images';

  /// All conversations for [userId], newest activity first.
  Future<List<ConversationSummary>> conversationsFor(String userId) async {
    final result = await Koolbase.db
        .collection(_members)
        .where('user_id', isEqualTo: userId)
        .orderBy('last_message_at', descending: true)
        .limit(50)
        .get();
    return result.records
        .map((r) => ConversationSummary.fromJson(r.data))
        .toList();
  }

  /// Creates deliver new messages; updates deliver reaction changes.
  Stream<Message> messageEventsFor(String conversationId) {
    Iterable<Message> parse(Map<String, dynamic> r) sync* {
      if (r['conversation_id'] == conversationId) {
        yield Message.fromRecord(r[r'$id'] as String? ?? '', r);
      }
    }

    final created = Koolbase.realtime
        .onRecordCreated(collection: _messages)
        .expand(parse);
    final updated = Koolbase.realtime
        .onRecordUpdated(collection: _messages)
        .expand(parse);
    return StreamGroup.merge([created, updated]);
  }

  Stream<ConversationSummary> memberEventsFor(String userId) {
    Iterable<ConversationSummary> parse(Map<String, dynamic> r) sync* {
      if (r['user_id'] == userId) {
        yield ConversationSummary.fromJson(r);
      }
    }

    final created = Koolbase.realtime
        .onRecordCreated(collection: _members)
        .expand(parse);
    final updated = Koolbase.realtime
        .onRecordUpdated(collection: _members)
        .expand(parse);
    return StreamGroup.merge([created, updated]);
  }

  /// Messages in a conversation, oldest first (natural chat order).
  Future<List<Message>> messagesFor(String conversationId) async {
    final result = await Koolbase.db
        .collection(_messages)
        .where('conversation_id', isEqualTo: conversationId)
        .orderBy('created_at')
        .limit(100)
        .get();
    return result.records.map((r) => Message.fromRecord(r.id, r.data)).toList();
  }

  Future<String> openConversation({
    required UserProfile me,
    required UserProfile other,
  }) async {
    final conversationId = ConversationSummary.idFor(me.userId, other.userId);
    await _upsertMember(
      conversationId: conversationId,
      owner: me,
      counterpart: other,
    );
    await _upsertMember(
      conversationId: conversationId,
      owner: other,
      counterpart: me,
    );
    return conversationId;
  }

  Future<void> _upsertMember({
    required String conversationId,
    required UserProfile owner,
    required UserProfile counterpart,
    String? lastMessage,
    DateTime? lastMessageAt,
  }) {
    final summary = ConversationSummary(
      conversationId: conversationId,
      userId: owner.userId,
      otherUserId: counterpart.userId,
      otherUsername: counterpart.username,
      otherDisplayName: counterpart.displayName,
      otherAvatarUrl: counterpart.avatarUrl,
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt,
    );
    final data = summary.toJson();
    if (lastMessage == null) {
      // Opening (not sending): don't clobber an existing preview.
      data.remove('last_message');
      data.remove('last_message_at');
    }
    return Koolbase.db.upsert(
      collection: _members,
      match: {'conversation_id': conversationId, 'user_id': owner.userId},
      data: data,
    );
  }

  Future<Message> sendMessage({
    required String conversationId,
    required UserProfile me,
    required UserProfile other,
    required String text,
    File? image,
  }) async {
    final now = DateTime.now().toUtc();
    String? imageUrl;
    if (image != null) {
      final result = await Koolbase.storage.upload(
        bucket: _imageBucket,
        path: '$conversationId/${now.millisecondsSinceEpoch}_${me.userId}.jpg',
        file: image,
      );
      imageUrl = result.downloadUrl;
    }
    final message = Message(
      id: '',
      conversationId: conversationId,
      senderId: me.userId,
      text: text,
      imageUrl: imageUrl,
      createdAt: now,
    );
    final record = await Koolbase.db.insert(
      collection: _messages,
      data: message.toJson(),
    );
    final preview = text.isNotEmpty ? text : '📷 Photo';
    await _upsertMember(
      conversationId: conversationId,
      owner: me,
      counterpart: other,
      lastMessage: preview,
      lastMessageAt: now,
    );
    await _upsertMember(
      conversationId: conversationId,
      owner: other,
      counterpart: me,
      lastMessage: preview,
      lastMessageAt: now,
    );
    return Message.fromRecord(record.id, record.data);
  }

  Future<void> toggleReaction({
    required Message message,
    required String emoji,
    required String userId,
  }) async {
    final updated = message.withReaction(emoji, userId);
    await Koolbase.db.upsert(
      collection: _messages,
      match: {
        'conversation_id': message.conversationId,
        'sender_id': message.senderId,
        'created_at': message.createdAt.toUtc().toIso8601String(),
      },
      data: updated.toJson(),
    );
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});
