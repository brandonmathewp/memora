import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/memory_service.dart';
import '../providers/chat_provider.dart';
import '../models/message.dart';

class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  final _searchController = TextEditingController();
  List<Message> _searchResults = [];
  Map<String, String> _worldBible = {};
  int _messageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final memoryService = ref.read(memoryServiceProvider);
    final bible = await memoryService.getWorldBible();
    final count = await memoryService.getMessageCount();
    setState(() {
      _worldBible = bible;
      _messageCount = count;
    });
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    final memoryService = ref.read(memoryServiceProvider);
    final results = await memoryService.search(query);
    setState(() => _searchResults = results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('记忆管理')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('消息数', _messageCount.toString()),
                  _statItem('世界观条目', _worldBible.length.toString()),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Search
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('搜索记忆',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: '输入关键词...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _search(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _search,
                        icon: const Icon(Icons.search),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Search results
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...(_searchResults.map((msg) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.role == 'user' ? '你' : 'AI',
                          style: TextStyle(
                            fontSize: 12,
                            color: msg.role == 'user'
                                ? Colors.blue
                                : Colors.purple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg.content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ))),
          ],

          // World Bible
          if (_worldBible.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('世界观设定',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...(_worldBible.entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${e.key}: ',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Expanded(child: Text(e.value)),
                            ],
                          ),
                        ))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
