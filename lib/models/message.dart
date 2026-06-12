class Message {
  final int? id;
  final String role; // 'user' or 'assistant'
  final String content;
  final int timestamp;
  final String? conversationId;

  const Message({
    this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.conversationId,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'role': role,
        'content': content,
        'timestamp': timestamp,
        'conversation_id': conversationId,
      };

  factory Message.fromMap(Map<String, dynamic> map) => Message(
        id: map['id'] as int?,
        role: map['role'] as String,
        content: map['content'] as String,
        timestamp: map['timestamp'] as int,
        conversationId: map['conversation_id'] as String?,
      );
}
