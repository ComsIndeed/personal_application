import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_application/core/database/app_database.dart';
import 'package:personal_application/core/models/message/enums.dart';
import 'package:personal_application/core/models/message/message_part.dart';
import 'package:personal_application/core/services/llm_service.dart';
import 'package:uuid/v4.dart';

class AssistantChatState {
  final List<Message> messages;
  final String? streamingText;
  final String currentConversationId;
  final bool isLoading;

  const AssistantChatState({
    this.messages = const [],
    this.streamingText,
    required this.currentConversationId,
    this.isLoading = false,
  });

  bool get isStreaming => streamingText != null;

  AssistantChatState copyWith({
    List<Message>? messages,
    String? streamingText,
    String? currentConversationId,
    bool? isLoading,
    bool clearStreaming = false,
  }) {
    return AssistantChatState(
      messages: messages ?? this.messages,
      streamingText: clearStreaming
          ? null
          : (streamingText ?? this.streamingText),
      currentConversationId:
          currentConversationId ?? this.currentConversationId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AssistantChatCubit extends Cubit<AssistantChatState> {
  final LLMService _llmService;
  final AppDatabase _db;
  StreamSubscription? _streamSubscription;

  AssistantChatCubit({required AppDatabase db, LLMService? llmService})
    : _db = db,
      _llmService = llmService ?? LLMService(),
      super(
        AssistantChatState(currentConversationId: const UuidV4().generate()),
      ) {
    loadMessages();
  }

  void selectConversation(String conversationId) {
    emit(state.copyWith(currentConversationId: conversationId));
    loadMessages();
  }

  Future<void> loadMessages() async {
    emit(state.copyWith(isLoading: true));
    final messages =
        await (_db.select(_db.messages)
              ..where(
                (t) => t.conversationId.equals(state.currentConversationId),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    emit(state.copyWith(messages: messages, isLoading: false));
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isStreaming) return;

    final conversationId = state.currentConversationId;

    // 1. Ensure conversation exists in DB
    final existingConvo = await (_db.select(
      _db.conversations,
    )..where((t) => t.id.equals(conversationId))).getSingleOrNull();

    if (existingConvo == null) {
      await _db
          .into(_db.conversations)
          .insert(
            ConversationsCompanion.insert(
              id: Value(conversationId),
              title: Value(
                text.length > 30 ? '${text.substring(0, 30)}...' : text,
              ),
            ),
          );
    }

    // 2. Save user message
    final userCompanion = MessagesCompanion.insert(
      conversationId: conversationId,
      role: MessageRole.user,
      parts: [TextPart(text: text)],
    );
    await _db.into(_db.messages).insert(userCompanion);

    // Refresh local list
    await loadMessages();

    // 3. Start streaming response
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
          // 4. Save assistant message when done
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
