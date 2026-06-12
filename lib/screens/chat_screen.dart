import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_webview.dart';
import '../widgets/soul_dialog.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Check and show soul suggestion after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSoulSuggestion();
    });
  }

  void _checkSoulSuggestion() {
    final chatState = ref.read(chatProvider);
    if (chatState.showSoulSuggestion) {
      _showSoulDialog(chatState.soulSuggestionJson ?? '');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.listen(chatProvider, (prev, next) {
      if (next.showSoulSuggestion && next.soulSuggestionJson != null) {
        _showSoulDialog(next.soulSuggestionJson!);
      }
    });
  }

  void _showSoulDialog(String json) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SoulSuggestionDialog(
        soulJson: json,
        onAccept: () {
          ref.read(chatProvider.notifier).acceptSoulSuggestion();
          Navigator.of(ctx).pop();
        },
        onDismiss: () {
          ref.read(chatProvider.notifier).dismissSoulSuggestion();
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _handleSend() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memora'),
        actions: [
          if (chatState.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Chat area
          Expanded(
            child: ChatWebView(messages: chatState.messages),
          ),

          // Error banner
          if (chatState.error != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.shade50,
              child: Text(
                chatState.error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: '输入消息...',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: chatState.isLoading ? null : _handleSend,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}
