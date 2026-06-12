import '../models/message.dart';
import '../models/soul.dart';
import '../models/dynamic_suggestion.dart';
import '../data/database.dart';
import 'api_client.dart';
import '../config/constants.dart';

class ChatService {
  final ApiClient _apiClient;

  ChatService(this._apiClient);

  Future<String> sendMessage(String userContent) async {
    final soul = await MemoraDatabase.getActiveSoul();
    final worldBible = await MemoraDatabase.getWorldBible();
    final recentMessages = await MemoraDatabase.getRecentMessages(limit: 20);

    final now = DateTime.now().millisecondsSinceEpoch;

    // Save user message
    await MemoraDatabase.insertMessage(Message(
      role: 'user',
      content: userContent,
      timestamp: now,
    ));

    // Build system prompt
    String? systemPrompt;
    if (soul != null) {
      final worldContext = worldBible.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');
      systemPrompt = '${soul.toSystemPrompt()}\n'
          '${worldContext.isNotEmpty ? '\n世界观设定：\n$worldContext' : ''}';
    }

    // Build messages for API
    final apiMessages = recentMessages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();
    apiMessages.add({'role': 'user', 'content': userContent});

    // Call API
    final reply = await _apiClient.chatCompletion(
      messages: apiMessages,
      systemPrompt: systemPrompt,
    );

    // Save assistant message
    await MemoraDatabase.insertMessage(Message(
      role: 'assistant',
      content: reply,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));

    // Check if soul generation should be triggered
    await _maybeTriggerSoulGeneration();

    return reply;
  }

  Future<bool> shouldGenerateSoul() async {
    final count = await _countMessages();
    final hasExisting = await MemoraDatabase.hasSuggestion('soul');
    if (hasExisting) return false;

    return AppConstants.soulGenerationRounds.contains(count) ||
        AppConstants.soulGenerationRounds.any((r) => count >= r);
  }

  Future<String> generateSoulSuggestion() async {
    final recentMessages = await MemoraDatabase.getRecentMessages(limit: 50);
    final history =
        recentMessages.map((m) => '${m.role}: ${m.content}').join('\n');

    final prompt = '''根据以下对话历史，总结用户期望的AI人格。
输出格式为JSON，包含：
- name: AI的名字
- role: AI的角色定位
- personality: 性格描述（温暖/幽默/理性等）
- communication_style: 沟通风格（长句/短句、正式/随意等）
- core_values: 核心价值观列表

对话历史：
$history''';

    return _apiClient.chatCompletion(
      messages: [{'role': 'user', 'content': prompt}],
      temperature: 0.3,
      maxTokens: 1024,
    );
  }

  Future<void> saveSoulFromJson(String jsonStr) async {
    // Simple JSON parsing (user API returns JSON)
    final s = jsonStr;
    final name = _extractField(s, 'name') ?? 'Memora';
    final role = _extractField(s, 'role') ?? 'AI伴侣';
    final personality = _extractField(s, 'personality') ?? '温暖、善解人意';
    final style = _extractField(s, 'communication_style') ?? '自然随意';
    final values = _extractListField(s, 'core_values') ?? ['陪伴', '理解', '真诚'];

    final now = DateTime.now();
    final soul = Soul(
      id: 'active',
      name: name,
      role: role,
      personality: personality,
      communicationStyle: style,
      coreValues: values,
      createdAt: now,
      updatedAt: now,
    );
    await MemoraDatabase.saveSoul(soul);

    await MemoraDatabase.saveSuggestion(DynamicSuggestion(
      type: 'soul',
      content: jsonStr,
      createdAt: now.millisecondsSinceEpoch,
      applied: true,
    ));
  }

  Future<int> _countMessages() async {
    // Count user messages to determine round
    final recent = await MemoraDatabase.getRecentMessages(limit: 200);
    return recent.where((m) => m.role == 'user').length;
  }

  Future<void> _maybeTriggerSoulGeneration() async {
    // Placeholder: the UI layer checks shouldGenerateSoul()
  }

  String? _extractField(String json, String field) {
    final regex = RegExp('"$field"\\s*:\\s*"([^"]*)"');
    final match = regex.firstMatch(json);
    return match?.group(1);
  }

  List<String>? _extractListField(String json, String field) {
    final regex = RegExp('"$field"\\s*:\\s*\\[(.*?)\\]', dotAll: true);
    final match = regex.firstMatch(json);
    if (match == null) return null;
    return RegExp('"([^"]*)"')
        .allMatches(match.group(1)!)
        .map((m) => m.group(1)!)
        .toList();
  }
}
