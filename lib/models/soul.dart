class Soul {
  final String id;
  final String name;
  final String role;
  final String personality;
  final String communicationStyle;
  final List<String> coreValues;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Soul({
    required this.id,
    required this.name,
    required this.role,
    required this.personality,
    required this.communicationStyle,
    required this.coreValues,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'role': role,
        'personality': personality,
        'communication_style': communicationStyle,
        'core_values': coreValues.join(','),
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Soul.fromMap(Map<String, dynamic> map) => Soul(
        id: map['id'] as String,
        name: map['name'] as String,
        role: map['role'] as String,
        personality: map['personality'] as String,
        communicationStyle: map['communication_style'] as String,
        coreValues: (map['core_values'] as String).split(','),
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );

  String toSystemPrompt() => '''
你是$name，身份是$role。
性格特征：$personality
沟通风格：$communicationStyle
核心价值观：${coreValues.join('、')}

请始终以上述人设回复用户的每一条消息。
''';
}
