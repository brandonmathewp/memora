import '../data/database.dart';
import '../models/message.dart';

class MemoryService {
  Future<List<Message>> getRecentContext({int limit = 20}) async {
    return MemoraDatabase.getRecentMessages(limit: limit);
  }

  Future<List<Message>> search(String query) async {
    return MemoraDatabase.searchMessages(query);
  }

  Future<Map<String, String>> getWorldBible() async {
    return MemoraDatabase.getWorldBible();
  }

  Future<void> updateWorldEntry(String key, String value) async {
    await MemoraDatabase.setWorldEntry(key, value);
  }

  Future<void> clearConversation() async {
    // TODO: Implement conversation cleanup
  }

  Future<int> getMessageCount() async {
    final msgs = await MemoraDatabase.getRecentMessages(limit: 10000);
    return msgs.length;
  }
}
