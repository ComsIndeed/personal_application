import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flyer_chat_text_message/flyer_chat_text_message.dart';
import 'package:personal_application/core/services/assistant_chat_cubit.dart';
import 'package:personal_application/core/models/message/enums.dart';
import 'package:personal_application/core/models/message/message_part.dart';
import 'package:flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';
import 'package:personal_application/theme/app_theme.dart';
import 'package:personal_application/interfaces/widgets/chat_composer.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final _chatController = InMemoryChatController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncMessages(context.read<AssistantChatCubit>().state);
    });
  }

  void _syncMessages(AssistantChatState state) {
    final uiMessages = state.messages.map<Message>((m) {
      final text = m.parts.whereType<TextPart>().map((p) => p.text).join('\n');
      final role = m.role == MessageRole.user ? 'user' : 'assistant';

      return TextMessage(
        id: m.id,
        authorId: role,
        text: text,
        createdAt: m.createdAt,
        status: m.role == MessageRole.error ? MessageStatus.error : null,
      );
    }).toList();

    // Add streaming message if active
    if (state.streamingText != null) {
      uiMessages.add(
        TextStreamMessage(
          id: 'streaming-msg',
          authorId: 'assistant',
          streamId: 'streaming-msg',
          createdAt: DateTime.now(),
        ),
      );
    }

    // Sort by createdAt ascending (oldest first) so newest are at the bottom
    uiMessages.sort((a, b) => a.createdAt!.compareTo(b.createdAt!));

    // Use setMessages for atomic update
    _chatController.setMessages(uiMessages, animated: false);
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocListener<AssistantChatCubit, AssistantChatState>(
        listener: (context, state) => _syncMessages(state),
        child: BlocBuilder<AssistantChatCubit, AssistantChatState>(
          builder: (context, state) {
            return Chat(
              theme: isDark
                  ? ChatTheme.fromThemeData(AppTheme.dark())
                  : ChatTheme.fromThemeData(AppTheme.light()),
              currentUserId: 'user',
              chatController: _chatController,
              resolveUser: (id) async {
                return User(id: id);
              },
              builders: Builders(
                textStreamMessageBuilder:
                    (
                      context,
                      message,
                      index, {
                      required bool isSentByMe,
                      MessageGroupStatus? groupStatus,
                    }) {
                      return FlyerChatTextStreamMessage(
                        message: message,
                        index: index,
                        mode: .instantMarkdown,
                        streamState: StreamStateStreaming(
                          context
                                  .read<AssistantChatCubit>()
                                  .state
                                  .streamingText ??
                              '',
                        ),
                      );
                    },
                textMessageBuilder:
                    (
                      context,
                      message,
                      index, {
                      required bool isSentByMe,
                      MessageGroupStatus? groupStatus,
                    }) {
                      return FlyerChatTextMessage(
                        message: message,
                        index: index,
                      );
                    },
                composerBuilder: (context) => Align(
                  alignment: Alignment.bottomCenter,
                  child: ChatComposer(
                    isStreaming: state.isStreaming,
                    onStop: () =>
                        context.read<AssistantChatCubit>().stopGeneration(),
                    onSend: (text) {
                      context.read<AssistantChatCubit>().sendMessage(text);
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
