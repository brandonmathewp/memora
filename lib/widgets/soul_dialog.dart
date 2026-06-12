import 'package:flutter/material.dart';

class SoulSuggestionDialog extends StatelessWidget {
  final String soulJson;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const SoulSuggestionDialog({
    super.key,
    required this.soulJson,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('人设建议'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '根据我们的对话，我总结了以下AI人格设定，是否采用？',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatJson(soulJson),
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text('以后再说'),
        ),
        FilledButton(
          onPressed: onAccept,
          child: const Text('采用'),
        ),
      ],
    );
  }

  String _formatJson(String json) {
    // Simple formatting: extract key fields and present them nicely
    final buffer = StringBuffer();
    final nameMatch = RegExp(r'"name"\s*:\s*"([^"]*)"').firstMatch(json);
    final roleMatch = RegExp(r'"role"\s*:\s*"([^"]*)"').firstMatch(json);
    final personalityMatch =
        RegExp(r'"personality"\s*:\s*"([^"]*)"').firstMatch(json);
    final styleMatch =
        RegExp(r'"communication_style"\s*:\s*"([^"]*)"').firstMatch(json);
    final valuesMatch =
        RegExp(r'"core_values"\s*:\s*\[(.*?)\]', dotAll: true).firstMatch(json);

    if (nameMatch != null) buffer.writeln('名称: ${nameMatch.group(1)}');
    if (roleMatch != null) buffer.writeln('角色: ${roleMatch.group(1)}');
    if (personalityMatch != null) {
      buffer.writeln('性格: ${personalityMatch.group(1)}');
    }
    if (styleMatch != null) buffer.writeln('风格: ${styleMatch.group(1)}');
    if (valuesMatch != null) {
      final values = RegExp(r'"([^"]*)"')
          .allMatches(valuesMatch.group(1)!)
          .map((m) => m.group(1))
          .join(', ');
      buffer.writeln('核心价值观: $values');
    }

    return buffer.toString().trim();
  }
}
