import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_application/core/database/app_database.dart';
import 'package:personal_application/core/models/message/enums.dart';
import 'package:personal_application/core/models/message/message_part.dart';
import 'package:personal_application/core/services/llm_service.dart';

class AssistantChatState {
  final List<Message> messages;
  final String? streamingText;
  final bool isLoading;

  const AssistantChatState({
    this.messages = const [],
    this.streamingText,
    this.isLoading = false,
  });

  bool get isStreaming => streamingText != null;

  AssistantChatState copyWith({
    List<Message>? messages,
    String? streamingText,
    bool? isLoading,
    bool clearStreaming = false,
  }) {
    return AssistantChatState(
      messages: messages ?? this.messages,
      streamingText: clearStreaming
          ? null
          : (streamingText ?? this.streamingText),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AssistantChatCubit extends Cubit<AssistantChatState> {
  final LLMService _llmService;
  final AppDatabase _db;
  final String conversationId;
  StreamSubscription? _streamSubscription;

  AssistantChatCubit({
    required AppDatabase db,
    required this.conversationId,
    LLMService? llmService,
  }) : _db = db,
       _llmService = llmService ?? LLMService(),
       super(const AssistantChatState()) {
    loadMessages();
  }

  Future<void> loadMessages() async {
    emit(state.copyWith(isLoading: true));
    final messages =
        await (_db.select(_db.messages)
              ..where((t) => t.conversationId.equals(conversationId))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    emit(state.copyWith(messages: messages, isLoading: false));
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isStreaming) return;

    // 1. Save user message to database
    final userCompanion = MessagesCompanion.insert(
      conversationId: conversationId,
      role: MessageRole.user,
      parts: [TextPart(text: text)],
    );
    await _db.into(_db.messages).insert(userCompanion);

    // Refresh local list
    await loadMessages();

    // 2. Start streaming response
    String fullResponse = "";
    emit(state.copyWith(streamingText: ""));

    try {
      final stream = _llmService.generateContentStream(
        history: state.messages,
        provider: LLMProvider.gemini,
        model: 'gemini-1.5-flash',
      );

      _streamSubscription = stream.listen(
        (chunk) {
          fullResponse += chunk;
          emit(state.copyWith(streamingText: fullResponse));
        },
        onDone: () async {
          // 3. Save assistant message when done
          if (fullResponse.isNotEmpty) {
            final aiCompanion = MessagesCompanion.insert(
              conversationId: conversationId,
              role: MessageRole.model,
              parts: [TextPart(text: fullResponse)],
            );
            await _db.into(_db.messages).insert(aiCompanion);
            await loadMessages();
          }
          emit(state.copyWith(clearStreaming: true));
        },
        onError: (error) {
          emit(state.copyWith(clearStreaming: true));
          // Handle error (e.g., add an error message to list or show snackbar)
        },
      );
    } catch (e) {
      emit(state.copyWith(clearStreaming: true));
    }
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }
}
