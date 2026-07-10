class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    this.reactions = const {},
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;

  /// emoji -> list of user ids who reacted with it.
  final Map<String, List<String>> reactions;

  factory Message.fromRecord(String id, Map<String, dynamic> data) => Message(
    id: id,
    conversationId: data['conversation_id'] as String,
    senderId: data['sender_id'] as String,
    text: (data['text'] as String?) ?? '',
    imageUrl: data['image_url'] as String?,
    createdAt: DateTime.parse(data['created_at'] as String),
    reactions: _parseReactions(data['reactions']),
  );

  static Map<String, List<String>> _parseReactions(dynamic raw) {
    if (raw is! Map) return const {};
    return raw.map(
      (k, v) => MapEntry(
        k as String,
        (v as List?)?.map((e) => e as String).toList() ?? <String>[],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'conversation_id': conversationId,
    'sender_id': senderId,
    'text': text,
    'image_url': imageUrl,
    // ISO-8601 sorts lexicographically == chronologically, so
    // orderBy on this JSONB key gives correct time ordering.
    'created_at': createdAt.toUtc().toIso8601String(),
    'reactions': reactions,
  };

  Message withReaction(String emoji, String userId) {
    final next = {
      for (final e in reactions.entries) e.key: List<String>.from(e.value),
    };
    final users = next.putIfAbsent(emoji, () => []);
    users.contains(userId) ? users.remove(userId) : users.add(userId);
    if (users.isEmpty) next.remove(emoji);
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      text: text,
      imageUrl: imageUrl,
      createdAt: createdAt,
      reactions: next,
    );
  }
}
