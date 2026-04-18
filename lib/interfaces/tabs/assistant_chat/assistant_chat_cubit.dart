import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_application/core/database/app_database.dart';
import 'package:personal_application/core/models/conversation.dart';
import 'package:personal_application/core/models/message/message.dart';
import 'package:personal_application/core/models/message/enums.dart';
import 'package:personal_application/core/models/message/message_part.dart';
import 'package:personal_application/core/services/llm_service.dart';
import 'package:uuid/v4.dart';

class AssistantChatState {
  final List<Message> messages;
  final String? streamingText;
  final String? streamingReasoning;
  final String currentConversationId;
  final bool isStreaming;
  final bool isLoading;
  final LLMProvider provider;
  final String? model;

  const AssistantChatState({
    this.messages = const [],
    this.streamingText,
    this.streamingReasoning,
    required this.currentConversationId,
    this.isStreaming = false,
    this.isLoading = false,
    this.provider = LLMProvider.gemini,
    this.model,
  });

  // Removed getter to use explicit state field

  AssistantChatState copyWith({
    List<Message>? messages,
    String? streamingText,
    String? streamingReasoning,
    String? currentConversationId,
    bool? isLoading,
    LLMProvider? provider,
    String? model,
    bool? isStreaming,
    bool clearStreaming = false,
  }) {
    return AssistantChatState(
      messages: messages ?? this.messages,
      streamingText: clearStreaming
          ? null
          : (streamingText ?? this.streamingText),
      streamingReasoning: clearStreaming
          ? null
          : (streamingReasoning ?? this.streamingReasoning),
      currentConversationId:
          currentConversationId ?? this.currentConversationId,
      isLoading: isLoading ?? this.isLoading,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      isStreaming: isStreaming ?? (clearStreaming ? false : this.isStreaming),
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
    loadInitialModel();
  }

  Future<void> loadInitialModel() async {
    try {
      final models = await _llmService.listModels(state.provider);
      if (models.isNotEmpty) {
        emit(state.copyWith(model: models.first));
      }
    } catch (e) {
      // Handle error or stay null
    }
  }

  void setModel(LLMProvider provider, String model) {
    emit(state.copyWith(provider: provider, model: model));
  }

  void selectConversation(String conversationId) {
    emit(state.copyWith(currentConversationId: conversationId));
    loadMessages();
  }

  void startNewChat() {
    emit(
      state.copyWith(
        currentConversationId: const UuidV4().generate(),
        messages: [],
      ),
    );
  }

  Future<List<Conversation>> getConversations() async {
    return await (_db.select(
      _db.conversations,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
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
    String fullReasoning = "";
    emit(
      state.copyWith(
        streamingText: "",
        streamingReasoning: "",
        isStreaming: true,
      ),
    );

    if (state.model == null) {
      await loadInitialModel();
    }

    if (state.model == null) {
      emit(state.copyWith(clearStreaming: true));
      return;
    }

    try {
      final stream = _llmService.generateContentStream(
        history: state.messages,
        provider: state.provider,
        model: state.model!,
      );

      _streamSubscription = stream.listen(
        (delta) {
          if (delta.reasoning != null) {
            fullReasoning += delta.reasoning!;
            emit(state.copyWith(streamingReasoning: fullReasoning));
          }
          if (delta.content != null) {
            fullResponse += delta.content!;
            emit(state.copyWith(streamingText: fullResponse));
          }
        },
        onDone: () async {
          // 4. Save assistant message when done
          if (fullResponse.isNotEmpty || fullReasoning.isNotEmpty) {
            final parts = <MessagePart>[];
            if (fullReasoning.isNotEmpty) {
              parts.add(ReasoningPart(reasoning: fullReasoning));
            }
            if (fullResponse.isNotEmpty) {
              parts.add(TextPart(text: fullResponse));
            }

            final aiCompanion = MessagesCompanion.insert(
              conversationId: conversationId,
              role: MessageRole.model,
              parts: parts,
            );
            await _db.into(_db.messages).insert(aiCompanion);
            await loadMessages();
          }
          emit(state.copyWith(clearStreaming: true));
        },
        onError: (error) async {
          final errorMessage = MessagesCompanion.insert(
            conversationId: conversationId,
            role: MessageRole.error,
            parts: [TextPart(text: error.toString())],
          );
          await _db.into(_db.messages).insert(errorMessage);
          await loadMessages();
          emit(state.copyWith(clearStreaming: true));
        },
      );
    } catch (e) {
      final errorMessage = MessagesCompanion.insert(
        conversationId: conversationId,
        role: MessageRole.error,
        parts: [TextPart(text: e.toString())],
      );
      await _db.into(_db.messages).insert(errorMessage);
      await loadMessages();
      emit(state.copyWith(clearStreaming: true));
    }
  }

  void stopGeneration() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    emit(state.copyWith(clearStreaming: true));
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }
}
