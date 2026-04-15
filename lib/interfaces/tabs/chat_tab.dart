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
      final reasoning = m.parts
          .whereType<ReasoningPart>()
          .map((p) => p.reasoning)
          .join('\n');
      final role = m.role == MessageRole.user ? 'user' : 'assistant';

      return TextMessage(
        id: m.id,
        authorId: role,
        text: text,
        createdAt: m.createdAt,
        status: m.role == MessageRole.error ? MessageStatus.error : null,
        metadata: reasoning.isNotEmpty ? {'reasoning': reasoning} : null,
      );
    }).toList();

    // Add streaming message if active
    if (state.streamingText != null || state.streamingReasoning != null) {
      uiMessages.add(
        TextStreamMessage(
          id: 'streaming-msg',
          authorId: 'assistant',
          streamId: 'streaming-msg',
          createdAt: DateTime.now(),
          metadata: state.streamingReasoning != null
              ? {'reasoning': state.streamingReasoning}
              : null,
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
                      final reasoning =
                          message.metadata?['reasoning'] as String?;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (reasoning != null && reasoning.isNotEmpty)
                            _ReasoningBlock(
                              reasoning: reasoning,
                              isStreaming: message.id == 'streaming-msg',
                            ),
                          FlyerChatTextStreamMessage(
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
                          ),
                        ],
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
                      final reasoning =
                          message.metadata?['reasoning'] as String?;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (reasoning != null && reasoning.isNotEmpty)
                            _ReasoningBlock(
                              reasoning: reasoning,
                              isStreaming: message.id == 'streaming-msg',
                            ),
                          FlyerChatTextMessage(message: message, index: index),
                        ],
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

class _ReasoningBlock extends StatefulWidget {
  final String reasoning;
  final bool isStreaming;
  const _ReasoningBlock({required this.reasoning, this.isStreaming = false});

  @override
  State<_ReasoningBlock> createState() => _ReasoningBlockState();
}

class _ReasoningBlockState extends State<_ReasoningBlock>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isStreaming; // Default to expanded if streaming
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final displayTail = widget.reasoning.length > 60
        ? '...${widget.reasoning.substring(widget.reasoning.length - 60)}'
        : widget.reasoning;

    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      margin: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : Colors.black.withAlpha(5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.black.withAlpha(10),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thinking',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!_expanded) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        displayTail.replaceAll('\n', ' '),
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black26,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.isStreaming)
                      FadeTransition(
                        opacity: _pulseController,
                        child: Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
                ],
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  widget.reasoning,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black45,
                    fontSize: 13,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
