import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../models/soul.dart';
import '../services/api_client.dart';
import '../services/chat_service.dart';
import '../services/memory_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.watch(apiClientProvider));
});

final memoryServiceProvider = Provider<MemoryService>((ref) {
  return MemoryService();
});

// Chat state
class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;
  final Soul? activeSoul;
  final bool showSoulSuggestion;
  final String? soulSuggestionJson;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.activeSoul,
    this.showSoulSuggestion = false,
    this.soulSuggestionJson,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
    Soul? activeSoul,
    bool? showSoulSuggestion,
    String? soulSuggestionJson,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        activeSoul: activeSoul ?? this.activeSoul,
        showSoulSuggestion: showSoulSuggestion ?? this.showSoulSuggestion,
        soulSuggestionJson: soulSuggestionJson ?? this.soulSuggestionJson,
      );
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatService _chatService;
  final MemoryService _memoryService;

  ChatNotifier(this._chatService, this._memoryService) : super(const ChatState()) {
    _init();
  }

  Future<void> _init() async {
    final msgs = await _memoryService.getRecentContext();
    await _chatService.shouldGenerateSoul();
    state = state.copyWith(messages: msgs);
  }

  Future<void> sendMessage(String content) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _chatService.sendMessage(content);
      final msgs = await _memoryService.getRecentContext();
      state = state.copyWith(
        messages: msgs,
        isLoading: false,
      );

      // Check if soul generation is needed
      final shouldGen = await _chatService.shouldGenerateSoul();
      if (shouldGen) {
        final suggestion = await _chatService.generateSoulSuggestion();
        state = state.copyWith(
          showSoulSuggestion: true,
          soulSuggestionJson: suggestion,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> acceptSoulSuggestion() async {
    if (state.soulSuggestionJson == null) return;
    await _chatService.saveSoulFromJson(state.soulSuggestionJson!);
    state = state.copyWith(showSoulSuggestion: false);
  }

  void dismissSoulSuggestion() {
    state = state.copyWith(showSoulSuggestion: false);
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(
    ref.watch(chatServiceProvider),
    ref.watch(memoryServiceProvider),
  );
});
