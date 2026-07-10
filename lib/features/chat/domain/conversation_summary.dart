class ConversationSummary {
  const ConversationSummary({
    required this.conversationId,
    required this.userId,
    required this.otherUserId,
    required this.otherUsername,
    required this.otherDisplayName,
    this.otherAvatarUrl,
    this.lastMessage,
    this.lastMessageAt,
  });

  final String conversationId;
  final String userId; // owner of this membership doc
  final String otherUserId;
  final String otherUsername;
  final String otherDisplayName;
  final String? otherAvatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  static String idFor(String userA, String userB) {
    final pair = [userA, userB]..sort();
    return pair.join('_');
  }

  factory ConversationSummary.fromJson(Map<String, dynamic> json) =>
      ConversationSummary(
        conversationId: json['conversation_id'] as String,
        userId: json['user_id'] as String,
        otherUserId: json['other_user_id'] as String,
        otherUsername: json['other_username'] as String,
        otherDisplayName: json['other_display_name'] as String,
        otherAvatarUrl: json['other_avatar_url'] as String?,
        lastMessage: json['last_message'] as String?,
        lastMessageAt: json['last_message_at'] != null
            ? DateTime.parse(json['last_message_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
    'conversation_id': conversationId,
    'user_id': userId,
    'other_user_id': otherUserId,
    'other_username': otherUsername,
    'other_display_name': otherDisplayName,
    'other_avatar_url': otherAvatarUrl,
    'last_message': lastMessage,
    'last_message_at': lastMessageAt?.toIso8601String(),
  };
}
