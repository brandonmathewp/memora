class DynamicSuggestion {
  final int? id;
  final String type; // 'soul' or 'world'
  final String content;
  final int createdAt;
  final bool applied;

  const DynamicSuggestion({
    this.id,
    required this.type,
    required this.content,
    required this.createdAt,
    this.applied = false,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'type': type,
        'content': content,
        'created_at': createdAt,
        'applied': applied ? 1 : 0,
      };

  factory DynamicSuggestion.fromMap(Map<String, dynamic> map) =>
      DynamicSuggestion(
        id: map['id'] as int?,
        type: map['type'] as String,
        content: map['content'] as String,
        createdAt: map['created_at'] as int,
        applied: (map['applied'] as int) == 1,
      );
}
